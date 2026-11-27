#!/usr/bin/env python3
# Performans tablosu (0.8, docs/ozellikler/erisilebilirlik-ipad.md §4): PerformanceTests'in xcodebuild çıktısındaki
# "measured [ad, birim] average: değer" satırlarını okur, ölçümü sınırla karşılaştırır, `ekranlar` dalındaki
# performans.md'ye en üste bir satır ekler (eski satırlar korunur). Sınır aşıldıysa ikinci çıktı dosyasına not yazar,
# iş sonunda kırmızı olur (.github/workflows/native-ekranlar.yml).
#   python3 scripts/native-performans.py <xcodebuild günlüğü> <eski performans.md|-> <yeni performans.md> <aşım dosyası> <commit>
import datetime
import re
import sys
from pathlib import Path

# (test adı, ölçü adında geçen, tablo başlığı, birim dönüştürme, birim yazısı, sınır)
METRICS = [
    ("testSogukAcilis", "AppLaunch", "Soğuk açılış", lambda v, u: v, "sn", 1.5),
    ("testSekmeGecisi", "sekme", "Sekme geçişi", lambda v, u: v, "sn", 0.3),
    ("testBellekTur", "Memory Peak Physical", "Bellek (tur, tepe)", lambda v, u: v / 1024 if "kB" in u else v, "MB", 150),
    # Takılma oranı ms/sn → yüzde (10 ms/sn = %1)
    ("testKaydirmaPratik", "Hitch Time Ratio", "Kaydırma Pratik (takılma)", lambda v, u: v / 10 if "ms" in u else v, "%", 1.0),
    ("testKaydirmaIlerleme", "Hitch Time Ratio", "Kaydırma İlerleme (takılma)", lambda v, u: v / 10 if "ms" in u else v, "%", 1.0),
]
LINE = re.compile(r"Test Case '-\[\S+ (\w+)\]' measured \[([^,\]]+), ([^\]]+)\] average: ([0-9.]+)")


def fmt(v: float, unit: str) -> str:
    s = f"{v:.2f}".rstrip("0").rstrip(".") if unit != "MB" else f"{v:.0f}"
    s = s.replace(".", ",")
    return f"%{s}" if unit == "%" else f"{s} {unit}"


def main() -> int:
    log, old, new, flag, commit = sys.argv[1:6]
    text = Path(log).read_text(encoding="utf-8", errors="replace") if Path(log).exists() else ""
    found: dict[str, tuple[float, str]] = {}
    for test, label, unit, value in LINE.findall(text):
        for t, key, title, conv, u, limit in METRICS:
            if t == test and key.lower() in label.lower():
                found[title] = (conv(float(value), unit), u)
    rows_old = []
    if old != "-" and Path(old).exists():
        rows_old = [l for l in Path(old).read_text(encoding="utf-8").splitlines() if l.startswith("| 20")]
    over = []
    cells = []
    for t, key, title, conv, u, limit in METRICS:
        if title in found:
            v, _ = found[title]
            bad = v > limit
            if bad:
                over.append(f"{title}: {fmt(v, u)} > {fmt(limit, u)}")
            cells.append(("🔴 " if bad else "") + fmt(v, u))
        else:
            cells.append("—")
    head = "| Tarih | Commit | " + " | ".join(m[2] for m in METRICS) + " |"
    limits = "| Sınır | | " + " | ".join(fmt(m[5], m[4]) for m in METRICS) + " |"
    sep = "|" + " --- |" * (len(METRICS) + 2)
    rows = rows_old
    if found:
        date = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=3))).strftime("%Y-%m-%d %H:%M")
        rows = [f"| {date} | {commit[:7]} | " + " | ".join(cells) + " |"] + rows_old
    doc = [
        "# Native performans ölçümleri",
        "",
        "GitHub Actions her `ios-native` gönderiminde iPhone simülatöründe ölçer (SolvatoUITests/PerformanceTests).",
        "En yeni ölçüm en üstte; 🔴 sınırı aşan değer (iş kırmızı olur). Sınırlar: docs/ozellikler/erisilebilirlik-ipad.md.",
        "Uygulama boyutu TestFlight koşusunun özetinde; Ritmi Tut dokunuş gecikmesi elle ölçülür.",
        "",
        head,
        sep,
        limits,
        *rows[:200],
        "",
    ]
    Path(new).write_text("\n".join(doc), encoding="utf-8")
    print("\n".join(doc[6:12]))
    if not found:
        print("Performans ölçümü bulunamadı (testler koşmamış olabilir)")
    if over:
        Path(flag).write_text("\n".join(over) + "\n", encoding="utf-8")
        print("SINIR AŞILDI:\n" + "\n".join(over))
    return 0


if __name__ == "__main__":
    sys.exit(main())
