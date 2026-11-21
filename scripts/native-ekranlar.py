#!/usr/bin/env python3
# Native UI testlerinin ekran görüntülerini test sonucundan (.xcresult) çıkarır ve okunur adlarla bir klasöre koyar:
#   <cihaz>/<ekran>-<tema>.png   ör. iphone/tasarim-1-dark.png
# Codemagic'te `ios-native` iş akışı kullanır (codemagic.yaml). Xcode 16+ `xcresulttool export attachments` gerekir.
# Kullanım: python3 scripts/native-ekranlar.py <sonuç.xcresult> <çıktı klasörü>
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def main() -> None:
    result, out = Path(sys.argv[1]), Path(sys.argv[2])
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
                # suggestedHumanReadableName: "<ad>_<sıra>_<UUID>.png"; yalnızca testteki adı bırak
                name = a.get("suggestedHumanReadableName", a["exportedFileName"]).split("_")[0]
                shutil.copy(Path(tmp) / a["exportedFileName"], out / f"{name}.png")
                count += 1
    print(f"{count} ekran görüntüsü → {out}")
    if count == 0:
        sys.exit("ekran görüntüsü bulunamadı")


if __name__ == "__main__":
    main()
