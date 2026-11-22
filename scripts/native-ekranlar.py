#!/usr/bin/env python3
# Native UI testlerinin ekran görüntülerini test sonucundan (.xcresult) çıkarır ve okunur adlarla bir klasöre koyar:
#   <senaryo>-<cihaz>-<tema>.png   ör. tasarim-1-iphone-koyu.png
# Web referans görüntüleriyle (scripts/referans.mjs, ekran/referans/) aynı adlandırma: yan yana karşılaştırılır.
# Codemagic'te `ios-native` iş akışı kullanır (codemagic.yaml). Xcode 16+ `xcresulttool export attachments` gerekir.
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
                    target = f"hata-{test_name}-{device}-{count}.png"
                    print(f"ek: {full} → {target}")
                shutil.copy(Path(tmp) / a["exportedFileName"], out / target)
                count += 1
    print(f"{count} ekran görüntüsü → {out}")
    if count == 0:
        sys.exit("ekran görüntüsü bulunamadı")


if __name__ == "__main__":
    main()
