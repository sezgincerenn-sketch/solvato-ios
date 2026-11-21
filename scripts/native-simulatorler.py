#!/usr/bin/env python3
# Native UI testleri için üç simülatör seçer: büyük iPhone, küçük iPhone, 13 inç iPad (en yeni iOS sürümüyle).
# Simülatör adları Xcode sürümüyle değiştiği için sabit ad yerine kurulu cihaz türlerinden desenle seçer.
# Çıktı satır satır "<kısa ad>|<cihaz türü>|<runtime kimliği>"; Codemagic `ios-native-*` iş akışları kullanır.
# Kullanım: python3 scripts/native-simulatorler.py <simctl runtimes -j çıktısı> <simctl devicetypes -j çıktısı>
import json
import re
import sys

SECIM = [
    ("iphone", [r"iPhone \d+ Pro", r"iPhone \d+"]),
    ("iphone-kucuk", [r"iPhone SE.*", r"iPhone \d+e"]),
    ("ipad", [r"iPad Pro 13.*", r"iPad Pro.*", r"iPad.*"]),
]


def numbers(text: str) -> list[int]:
    return [int(x) for x in re.findall(r"\d+", text)]


def main() -> None:
    runtimes = json.load(open(sys.argv[1]))["runtimes"]
    types = [t["name"] for t in json.load(open(sys.argv[2]))["devicetypes"]]
    ios = [r for r in runtimes if r.get("platform") == "iOS" and r.get("isAvailable", True)]
    if not ios:
        sys.exit("iOS simülatör sürümü kurulu değil")
    rt = max(ios, key=lambda r: numbers(r["version"]))
    supported = {t["name"] for t in rt.get("supportedDeviceTypes", [])} or set(types)
    for slug, patterns in SECIM:
        for p in patterns:
            hits = [n for n in types if n in supported and re.fullmatch(p, n)]
            if hits:
                print(f"{slug}|{max(hits, key=numbers)}|{rt['identifier']}")
                break


if __name__ == "__main__":
    main()
