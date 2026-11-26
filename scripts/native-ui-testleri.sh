#!/usr/bin/env bash
# Native iOS UI testleri ve ekran görüntüleri: uygulamayı bir kez simülatör için derler, ios-native/ui-testleri.txt'teki
# testleri seçilen cihazlarda (iPhone, küçük iPhone, iPad) koşar, görüntüleri build/ekranlar/'a çıkarır
# (<senaryo>-<cihaz>-<koyu|acik>.png), build/native-ekranlar.zip ve küçük kopyası native-ekranlar-kucuk.zip'i yapar.
# Mac'te, `xcodegen generate` sonrası depo kökünden çalışır. Kullananlar: codemagic.yaml (ios-native-test) ve
# .github/workflows/native-ekranlar.yml. Görüntü yoksa hata koduyla biter.
cd "$(dirname "$0")/.."
set -o pipefail
# iOS simülatörü kurulu değilse indir (Xcode 26'da ayrı geliyor)
if ! xcrun simctl list runtimes | grep -q "^iOS"; then xcodebuild -downloadPlatform iOS; fi
xcrun simctl list runtimes
xcrun simctl list runtimes -j > /tmp/runtimes.json
xcrun simctl list devicetypes -j > /tmp/types.json
python3 scripts/native-simulatorler.py /tmp/runtimes.json /tmp/types.json > /tmp/devices.txt
cat /tmp/devices.txt
[ "$(wc -l < /tmp/devices.txt)" -ge 3 ] || { echo "Üç simülatör bulunamadı"; exit 1; }
mkdir -p build/ekranlar
# Hangi cihazlar ve testler: ios-native/ui-testleri.txt (boş test listesi = hepsi)
CIHAZLAR=$(sed -n 's/^cihazlar:[[:space:]]*//p' ios-native/ui-testleri.txt)
TESTLER=$(sed -n 's/^testler:[[:space:]]*//p' ios-native/ui-testleri.txt)
SADECE=""
for t in $TESTLER; do SADECE="$SADECE -only-testing:SolvatoUITests/ScreenshotTests/$t"; done
echo "Cihazlar: ${CIHAZLAR:-hepsi} · Testler: ${TESTLER:-hepsi}"
# Bir kez derle, her cihazda derlemeden koş
xcodebuild build-for-testing -project ios-native/Solvato.xcodeproj -scheme Solvato \
  -destination "generic/platform=iOS Simulator" -derivedDataPath build/dd \
  CODE_SIGNING_ALLOWED=NO < /dev/null > build/xcodebuild-derleme.log 2>&1 || true
echo "── derleme: hatalar ──"
grep -E "error:|: error" build/xcodebuild-derleme.log | sort -u | head -80 || true
grep -q "TEST BUILD SUCCEEDED" build/xcodebuild-derleme.log || { tail -25 build/xcodebuild-derleme.log; exit 1; }
while IFS='|' read -r SLUG TYPE RUNTIME; do
  if [ -n "$CIHAZLAR" ] && ! echo " $CIHAZLAR " | grep -q " $SLUG "; then continue; fi
  UDID=$(xcrun simctl create "solvato-$SLUG" "$TYPE" "$RUNTIME")
  echo "$SLUG: $TYPE ($UDID)"
  # Tam çıktı dosyaya; ekrana önce düşen testler, sonra son satırlar. Takılan test 10 dakikada kesilir.
  xcodebuild test-without-building -project ios-native/Solvato.xcodeproj -scheme Solvato \
    -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath build/dd $SADECE \
    -test-timeouts-enabled YES -maximum-test-execution-time-allowance 600 \
    -resultBundlePath "build/ui-$SLUG.xcresult" < /dev/null > "build/xcodebuild-$SLUG.log" 2>&1 || true
  echo "── $SLUG: hatalar ──"
  grep -E "error:|: error|failed \(|XCTAssert|Test Case .* failed" "build/xcodebuild-$SLUG.log" | sort -u | head -80 || true
  echo "── $SLUG: son satırlar ──"
  tail -25 "build/xcodebuild-$SLUG.log"
  mkdir -p build/ekranlar
  { grep -E "error:|: error|failed \(|XCTAssert|Test Case .* failed|crash|Fatal error" "build/xcodebuild-$SLUG.log" | sort -u | head -80
    echo "── son satırlar ──"; tail -40 "build/xcodebuild-$SLUG.log"; } > "build/ekranlar/xcodebuild-$SLUG.txt" || true
  python3 scripts/native-ekranlar.py "build/ui-$SLUG.xcresult" "$SLUG" build/ekranlar || true
  # Uygulama kapandıysa simülatörün çökme raporları (hangi satırda, hangi iş parçacığında) zip'e girer
  for r in ~/Library/Logs/DiagnosticReports/Solvato*.ips; do
    [ -e "$r" ] && cp "$r" "build/ekranlar/cokme-$SLUG-$(basename "$r" .ips).txt"
  done
done < /tmp/devices.txt
# Görüntü olmasa da zip'ler üretilir (hata dosyaları ve çökme raporları içinde); adım sonda düşer
mkdir -p build/ekranlar
cd build && zip -qr native-ekranlar.zip ekranlar
# Sohbete gönderilebilecek küçük kopya (30 MB altı): yalnız iPhone, yarı boyut, JPEG
mkdir -p ekranlar-kucuk
for f in ekranlar/*-iphone-koyu.png ekranlar/*-iphone-acik.png ekranlar/hata-*-iphone-*.png; do
  [ -e "$f" ] || continue
  sips -s format jpeg -s formatOptions 70 --resampleWidth 600 "$f" --out "ekranlar-kucuk/$(basename "${f%.png}").jpg" > /dev/null
done
# Hata mesajları ve test çıktısının özeti küçük zip'e de (sohbete gönderilince neden düştüğü görülsün)
cp ekranlar/*.txt ekranlar-kucuk/ 2>/dev/null || true
zip -qr native-ekranlar-kucuk.zip ekranlar-kucuk
ls -lh native-ekranlar*.zip
ls ekranlar | grep -q png || { echo "Ekran görüntüsü yok"; exit 1; }
