#!/usr/bin/env python3
# Native UI testlerinin ekran görüntülerini test sonucundan (.xcresult) çıkarır ve okunur adlarla bir klasöre koyar:
#   <senaryo>-<cihaz>-<tema>.png   ör. tasarim-1-iphone-koyu.png
# Web referans görüntüleriyle (scripts/referans.mjs, ekran/referans/) aynı adlandırma: yan yana karşılaştırılır.
# scripts/native-ui-testleri.sh kullanır (GitHub Actions). Xcode 16+ `xcresulttool export attachments` gerekir.
# Düşen testlerin hata mesajları `hatalar-<cihaz>.txt`'ye yazılır (küçük zip'e de girer). Hata anındaki ekler
# (ekran kaydı, dokunma olayları) kendi uzantılarıyla `hata-<test>-<cihaz>-<sıra>.<uzantı>` olarak saklanır.
# Kullanım: python3 scripts/native-ekranlar.py <sonuç.xcresult> <cihaz: iphone|iphone-kucuk|ipad> <çıktı klasörü>
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def main() -> None:
    result, device, out = Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3])
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(
            ["xcrun", "xcresulttool", "export", "attachments", "--path", str(result), "--output-path", tmp],
            check=True,
        )
        manifest = json.loads((Path(tmp) / "manifest.json").read_text())
        count = 0
        for test in manifest:
            for a in test.get("attachments", []):
                # suggestedHumanReadableName: "<senaryo>-<tema>_<sıra>_<UUID>.png"; testteki ada cihazı ekle.
                # Başka adlı ekler (ör. hata anında Xcode'un aldığı görüntü) ayrı adla saklanır, betiği durdurmaz.
                full = a.get("suggestedHumanReadableName", a["exportedFileName"])
                m = re.match(r"^(.+)-(koyu|acik)(?:_|\.png$|$)", full)
                if m:
                    target = f"{m.group(1)}-{device}-{m.group(2)}.png"
                else:
                    test_name = re.sub(r"\W+", "", test.get("testIdentifier", "test").split("/")[-1])
                    ext = Path(a["exportedFileName"]).suffix or ".dat"
                    target = f"hata-{test_name}-{device}-{count}{ext}"
                    print(f"ek: {full} → {target}")
                shutil.copy(Path(tmp) / a["exportedFileName"], out / target)
                count += 1
    print(f"{count} ekran görüntüsü → {out}")
    failures(result, device, out)
    if count == 0:
        sys.exit("ekran görüntüsü bulunamadı")


def failures(result: Path, device: str, out: Path) -> None:
    """Düşen testleri ve hata mesajlarını hatalar-<cihaz>.txt'ye yazar (Xcode 16+ xcresulttool test-results)"""
    try:
        raw = subprocess.run(
            ["xcrun", "xcresulttool", "get", "test-results", "tests", "--path", str(result)],
            check=True, capture_output=True, text=True,
        ).stdout
        data = json.loads(raw)
    except Exception as e:  # noqa: BLE001
        (out / f"hatalar-{device}.txt").write_text(f"test sonuçları okunamadı: {e}\n")
        return
    lines: list[str] = []

    def walk(node: dict, path: list[str]) -> None:
        name = node.get("name", "")
        if node.get("nodeType") == "Failure Message":
            lines.append(f"{' / '.join(path)}: {name}")
        elif node.get("nodeType") == "Test Case" and node.get("result") == "Failed" and not node.get("children"):
            lines.append(f"{' / '.join(path + [name])}: başarısız (mesaj yok)")
        for c in node.get("children", []):
            walk(c, path + ([name] if node.get("nodeType") in ("Test Case", "Test Suite") else []))

    for n in data.get("testNodes", []):
        walk(n, [])
    text = "\n".join(lines) if lines else "Düşen test yok."
    (out / f"hatalar-{device}.txt").write_text(text + "\n")
    print(text)


if __name__ == "__main__":
    main()
