#!/usr/bin/env python3
# Native iOS güvenlik denetimi (0.8, docs/ozellikler/erisilebilirlik-ipad.md §5). Her ios-native gönderiminde
# .github/workflows/native-ekranlar.yml koşar; bir kural bozulursa hata koduyla biter (iş kırmızı olur).
#   python3 scripts/native-guvenlik.py                 # kaynak: ağ API'leri, dış adresler, bağımlılıklar, gizlilik bildirimi
#   python3 scripts/native-guvenlik.py --paket X.app   # derlenmiş paket: ATS gevşetmesi yok, gizlilik bildirimi pakette
# Kurallar: uygulama hiçbir yere ağ isteği göndermez ("Data Not Collected"); App Store bağlantısı yalnız paylaşılan
# metnin içinde (AppStoreLink.swift); üçüncü taraf kod yok (yalnız SolvatoCore); gizlilik bildirimi yalnız kullanılan
# API'leri beyan eder.
import plistlib
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NATIVE = ROOT / "ios-native"
SOURCES = [NATIVE / "Solvato", NATIVE / "SolvatoCore" / "Sources"]

# Ağ isteği yapabilen ya da dışarıyı açan API'ler
FORBIDDEN = [
    (r"\bURLSession\b", "URLSession"),
    (r"\bNSURLConnection\b", "NSURLConnection"),
    (r"^\s*import\s+(Network|WebKit|SafariServices|CFNetwork)\b", "ağ/web çatısı"),
    (r"\bWKWebView\b", "WKWebView"),
    (r"\bSFSafariViewController\b", "SFSafariViewController"),
    (r"\bopenURL\b", "openURL"),
    (r"UIApplication\.shared\.open\(", "UIApplication.open"),
    (r"(?<![A-Za-z])Link\([^)]*destination:", "SwiftUI Link"),
    (r"\bData\(contentsOf:\s*URL\(string:", "uzak adresten veri"),
]
# Dış adres yalnız burada (paylaşım metnine giren App Store bağlantısı)
URL_ALLOWED = {"SolvatoCore/Sources/SolvatoCore/Logic/AppStoreLink.swift": "https://apps.apple.com/"}
# Gizlilik bildirimindeki "required reason API" beyanları: tür → gerekçe
PRIVACY_APIS = {
    "NSPrivacyAccessedAPICategoryUserDefaults": ["CA92.1"],
    "NSPrivacyAccessedAPICategorySystemBootTime": ["35F9.1"],
}

errors: list[str] = []


def strip_comment(line: str) -> str:
    """Satır sonu yorumunu atar (metin içindeki // korunur)"""
    out, in_str, i = [], False, 0
    while i < len(line):
        c = line[i]
        if c == '"' and (i == 0 or line[i - 1] != "\\"):
            in_str = not in_str
        if not in_str and line.startswith("//", i):
            break
        out.append(c)
        i += 1
    return "".join(out)


def check_sources() -> None:
    files = [p for d in SOURCES for p in d.rglob("*.swift")]
    for p in files:
        rel = str(p.relative_to(NATIVE))
        for n, raw in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
            line = strip_comment(raw)
            for pat, name in FORBIDDEN:
                if re.search(pat, line):
                    errors.append(f"{rel}:{n}: {name} kullanılmamalı: {raw.strip()}")
            for url in re.findall(r"https?://[^\s\"\\)]+", line):
                allowed = URL_ALLOWED.get(rel)
                if not allowed or not url.startswith(allowed):
                    errors.append(f"{rel}:{n}: dış adres: {url}")
    print(f"Kaynak taraması: {len(files)} Swift dosyası")


def check_dependencies() -> None:
    # project.yml: packages altında yalnız SolvatoCore; ATS ayarı yok
    yml = (NATIVE / "project.yml").read_text(encoding="utf-8")
    if "NSAppTransportSecurity" in yml:
        errors.append("project.yml: NSAppTransportSecurity (ATS gevşetmesi) olmamalı")
    m = re.search(r"^packages:\n((?:[ \t]+.*\n|\n)*)", yml, re.M)
    pkgs = re.findall(r"^  ([A-Za-z0-9_-]+):", m.group(1), re.M) if m else []
    if pkgs != ["SolvatoCore"]:
        errors.append(f"project.yml: paketler yalnız SolvatoCore olmalı, bulunan: {pkgs}")
    if re.search(r"\b(url|github|gitlab)\s*:", m.group(1) if m else ""):
        errors.append("project.yml: uzak paket adresi olmamalı")
    # SolvatoCore'un bağımlılığı yok
    pkg = (NATIVE / "SolvatoCore" / "Package.swift").read_text(encoding="utf-8")
    if ".package(" in pkg:
        errors.append("SolvatoCore/Package.swift: dış paket bağımlılığı olmamalı")
    # Package.resolved varsa boş olmalı
    for r in NATIVE.rglob("Package.resolved"):
        if ".build" in r.parts:
            continue
        if '"identity"' in r.read_text(encoding="utf-8") or '"package"' in r.read_text(encoding="utf-8"):
            errors.append(f"{r.relative_to(ROOT)}: üçüncü taraf paket sabitlenmiş")
    print(f"Bağımlılıklar: {pkgs}")


def check_privacy(data: bytes, where: str) -> None:
    p = plistlib.loads(data)
    if p.get("NSPrivacyTracking") is not False:
        errors.append(f"{where}: NSPrivacyTracking false olmalı")
    if p.get("NSPrivacyTrackingDomains"):
        errors.append(f"{where}: izleme alanı olmamalı")
    if p.get("NSPrivacyCollectedDataTypes"):
        errors.append(f"{where}: toplanan veri türü olmamalı")
    apis = {a.get("NSPrivacyAccessedAPIType"): a.get("NSPrivacyAccessedAPITypeReasons") for a in p.get("NSPrivacyAccessedAPITypes", [])}
    if apis != PRIVACY_APIS:
        errors.append(f"{where}: beyan edilen API'ler {apis}, beklenen {PRIVACY_APIS}")
    print(f"Gizlilik bildirimi ({where}): {sorted(apis)}")


def plist_bytes(path: Path) -> bytes:
    """İkili plist'i de okur (macOS'ta plutil, değilse doğrudan)"""
    data = path.read_bytes()
    try:
        plistlib.loads(data)
        return data
    except Exception:
        return subprocess.run(["plutil", "-convert", "xml1", "-o", "-", str(path)], check=True, capture_output=True).stdout


def check_bundle(app: Path) -> None:
    info = plistlib.loads(plist_bytes(app / "Info.plist"))
    ats = info.get("NSAppTransportSecurity")
    if ats:
        errors.append(f"{app.name}/Info.plist: NSAppTransportSecurity olmamalı: {ats}")
    manifest = app / "PrivacyInfo.xcprivacy"
    if not manifest.exists():
        errors.append(f"{app.name}: PrivacyInfo.xcprivacy pakette yok")
    else:
        check_privacy(plist_bytes(manifest), f"{app.name}/PrivacyInfo.xcprivacy")
    # Paketin içindeki çerçeveler: yalnız Swift çalışma kitaplıkları olabilir (üçüncü taraf çerçeve yok)
    fw = app / "Frameworks"
    extra = [f.name for f in fw.iterdir() if not f.name.startswith("libswift") and not f.name.startswith("libXCTest")] if fw.exists() else []
    if extra:
        errors.append(f"{app.name}/Frameworks: beklenmeyen çerçeve: {extra}")
    print(f"Paket: {app.name} · ATS {'var' if ats else 'yok'} · çerçeveler: {extra or 'yok'}")


def main() -> int:
    if len(sys.argv) >= 3 and sys.argv[1] == "--paket":
        check_bundle(Path(sys.argv[2]))
    else:
        check_sources()
        check_dependencies()
        check_privacy((NATIVE / "Solvato" / "PrivacyInfo.xcprivacy").read_bytes(), "Solvato/PrivacyInfo.xcprivacy")
    if errors:
        print("\nGÜVENLİK DENETİMİ BAŞARISIZ:")
        for e in errors:
            print("  - " + e)
        return 1
    print("Güvenlik denetimi: sorun yok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
