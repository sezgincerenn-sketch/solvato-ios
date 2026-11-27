# 0.8: Erişilebilirlik, iPad düzenleri, performans ve güvenlik ölçümleri

Native iOS planının (`docs/PLAN.md` Paket 0) 0.8 aşaması. Yalnız native sürüm (`ios-native/`); web kodu değişmez.
Kararlar Ceren'in, 27 Kasım. Bu doküman bitince `inceleyici` ajanının karşılaştıracağı ölçüttür.

## Amaç

- Görme zorluğu olan, büyük yazı ya da VoiceOver kullanan öğrenci ve öğretmenler uygulamayı kullanabilsin.
- iPad'de her yön ve her pencere boyutu (Split View, Stage Manager) düzgün görünsün.
- Açılış, bellek, akıcılık ve boyut ölçülebilir olsun; her derlemede otomatik ölçülsün, bozulma fark edilsin.
- App Store'daki erişilebilirlik etiketleri (Accessibility Nutrition Labels) dürüstçe işaretlenebilsin.

**Birebir uyum:** telefonun varsayılan yazı boyutunda, VoiceOver kapalıyken uygulama bugünkü görünümle piksel piksel
aynı kalır. Değişiklikler yalnız bu ayarlar açıkken görünür (bilinçli fark; `native-ios.md` "Bilinçli farklar"a yazılır).

## Kullanıcı ne görür

### 1. Büyük yazı (Dinamik Yazı) — sınırlı

- Telefonun Ayarlar › Ekran ve Parlaklık › Metin Boyutu (ya da Erişilebilirlik › Daha Büyük Metin) büyütülünce
  Solvato'daki **metinler** büyür: başlıklar, kart yazıları, açıklamalar, düğme yazıları, ayar satırları, ders metinleri.
- **Üst sınır:** iOS'un en büyük normal boyutu (xxxLarge). Erişilebilirlikteki daha büyük boyutlarda (AX1–AX5) yazı
  bu sınırda kalır. Varsayılan boyuttan (Large) küçük seçilirse yazı da küçülür, en küçük sınır xSmall.
- **Büyümeyenler:** porte ve nota sembolleri, piyano klavyesi ve tuş adları, Solfie, ikonlar, puan halkası ve yüzde
  halkası içindeki sayılar, alt menü (Apple'ın sekme çubuğu kendi kuralıyla büyür), açılış animasyonu.
- Düzen bozulmaz: düğme yazıları gerekirse iki satıra iner ama kesilmez ve taşmaz; yan yana iki kutu sığmazsa yazı
  küçülür (en çok %80'e) yerine kutu alta geçmez. Tur ekranları (soru, akor, Ritmi Tut, düello) kaydırmasız sığmaya
  devam eder; sığmazsa o ekranlarda metin sınırı bir basamak düşük tutulur (xxLarge).

### 2. VoiceOver

- **Her düğme ve dokunulan öğenin Türkçe adı** var; dekoratif öğeler (arka plan ışıkları, Solfie, süs çizgileri)
  okunmaz. Kartlar tek öğe olarak okunur: "Sol Anahtarı, %72, 10 soru" gibi; basılabilen kartta "düğme" denir.
- **Soru turu:**
  - Üstteki noktalar tek öğe: "3. soru, 10 sorudan" (`tur-ekranlari.md`).
  - Portedeki nota **adı ve yeri söylenmeden** okunur: "Porte: Sol anahtarı, bir nota". Akor portesi: "Porte: Sol
    anahtarı, bir akor". Ritim sorusu: "Porte: bir ritim". Terim sorusunda terimin kendisi okunur (cevap değil).
  - Kulak sorusu: "Dinle, düğme" — dokununca ses çalar, notanın adı okunmaz.
  - Piyano tuşları "Do tuşu", "Do diyez tuşu" (zaten var); şıklar kendi yazılarıyla.
  - Cevaptan sonra sonuç **duyurulur**: "Doğru" ya da "Yanlış. Doğru cevap: Sol" (R1 kartıyla aynı metin); süre dolunca
    "Süre doldu. Doğru cevap: Sol". Sıradaki soruda odak sorunun başına gelir.
  - Süre çubuğu: "Kalan süre 5 saniye"; her saniye duyurulmaz, yalnız son 3 saniye.
- **Akor turu:** aynı kurallar; "Akoru bas" klavyesinde seçilen tuşlar "seçili" diye okunur, "Seçilen" listesi okunur.
- **Ritmi Tut:** "Dokun" alanı doğrudan dokunmaya açık (VoiceOver açıkken de parmak değdiği an vuruş sayılır; çift
  dokunma gerekmez). Sayma "1, 2, 3, 4" duyurulmaz (tıklar zaten duyuluyor). Sonuç başlığı ve ipucu duyurulur.
- **Düello:** iki oyuncunun alanı "1. oyuncu", "2. oyuncu" diye ayrılır.
- **Tur sonucu ve kutlama:** başlık, puan, yıldız sayısı ("3 yıldızdan 2") ve kazanılan XP tek seferde okunur.
- **İlerleme:** 7 günlük şerit tek öğe ("Bu hafta: Pazartesi tamam, Salı eksik…" — zaten var); Doğruluk çipleri
  "seçili" durumuyla; grafik ve halkalar yüzdeleriyle okunur.
- **Ana sayfa ipuçları:** balon açılınca odak balona gelir, "1/6" ve metin okunur; Atla / Sıradaki erişilebilir.
- **Açılış animasyonu** VoiceOver açıkken beklemeden geçer (bugün dokununca geçiyor; VoiceOver'da kendiliğinden).
- **Hareketi azalt** açıkken: sayfa geçişleri ve kart animasyonları yerine kısa solma; kutlama konfetisi yok,
  yıldızlar sırayla değil birlikte belirir; seri alevi titremez (açılış zaten anında kalkıyor).

### 3. iPad düzenleri

- **Her yön:** dikey, ters dikey, iki yatay; bütün ekranlar (bugün `project.yml` izin veriyor; ekran ekran kontrol).
- **Split View ve Stage Manager:** Solvato başka uygulamayla yan yana açılabilir.
  - Pencere dar olunca (iPhone genişliği, "compact") **iPhone düzeni**: tek sütun, 1 oktav klavye, tam genişlik.
  - Geniş pencerede iPad düzeni: içerik ortada en çok 1100 pt, alt ekranlar 680 pt, Çalışma 820 pt (G-03), Pratik ve
    İlerleme iki sütun, soru turunda iki sütun ve 2–3 oktav (E-05).
  - Pencere boyutu tur ortasında değişirse tur kaldığı yerden devam eder; cevaplar kaybolmaz.
- Stage Manager'da en küçük pencerede de hiçbir yazı ya da düğme kesilmez.

### 4. Performans (her derlemede otomatik)

GitHub Actions her `main` gönderiminde simülatörde ölçer; sonuçlar `ekranlar` dalında `performans.md` tablosunda
(tarih, commit, değer, sınır). Sınır aşılırsa iş kırmızı olur ve tabloda işaretlenir; TestFlight yine elle başlatılır.

| Ölçüm                                 | Sınır (simülatörde)          |
| ------------------------------------- | ---------------------------- |
| Soğuk açılış (ilk kareye kadar)       | 1,5 sn                       |
| Pratik ↔ İlerleme sekme geçişi        | 0,3 sn                       |
| Bellek (10 soruluk tur boyunca, tepe) | 150 MB                       |
| Pratik ve İlerleme kaydırma           | takılan kare oranı %1'den az |
| Uygulama boyutu (TestFlight paketi)   | 25 MB                        |
| Ritmi Tut dokunuş gecikmesi (ölçülen) | bugünkü değerden kötü değil  |

Sınırlar ilk ölçümden sonra gerçek değerlere göre Ceren'e sorularak sıkılaştırılabilir.

### 5. Güvenlik denetimi (her derlemede otomatik + bir kez elle)

- **Ağ yok:** kaynak kodda `URLSession`, `Network`, `WKWebView`, `openURL` ve dış adres taraması; derlenmiş pakette
  `NSAppTransportSecurity` gevşetmesi yok. Bulunursa iş kırmızı (App Store bağlantısı yalnız paylaşılan metin içinde).
- **Veri koruması:** kayıt dosyaları `completeUntilFirstUserAuthentication` (bugünkü G-09); testle doğrulanır.
- **Dışarıdan gelen girdi:** öğretmen kodu, meydan okuma kodu, panodan yapıştırma rastgele ve bozuk girdilerle
  (çok uzun metin, emoji, boşluk, eksik/fazla karakter) denenir; uygulama çökmez, yanlış ayar uygulanmaz.
- **Gizlilik bildirimi:** `PrivacyInfo.xcprivacy` yalnız kullanılan API'leri beyan eder (UserDefaults); derlenmiş
  pakette doğrulanır.
- **Üçüncü taraf kod yok:** `Package.resolved` ve proje bağımlılıkları yalnız `SolvatoCore`.

## Kurallar ve sınır durumları

- Varsayılan yazı boyutu + VoiceOver kapalı + Hareketi azalt kapalı: görünüm bugünküyle aynı (ekran testleri
  değişmemeli).
- Koyu ve açık tema: büyük yazıda da renkler token'lardan; kontrast WCAG AA (normal metin 4,5:1) — soluk yazılar
  (`textFaint`) yalnız yer tutucu ve süs metinlerinde.
- Ses kapalıyken VoiceOver duyuruları yine çalışır (sistem sesi, uygulama sesi değil).
- iPhone SE (küçük ekran) + xxxLarge: tur ekranları sığar (gerekirse xxLarge sınırı), diğer ekranlar kaydırılır.
- İlk kullanım (tanıtım) VoiceOver'la baştan sona tamamlanabilir; deneme sorularında da nota adı okunmaz.
- Tablette klavye kısayolları, fare imleci: kapsam dışı (bilgisayara özgü, `native-ios.md` "Bilinçli farklar").

## Kabul ölçütleri

Büyük yazı

- [ ] Varsayılan boyutta bütün ekran testleri (`native-ekranlar.yml`) önceki görüntülerle aynı.
- [ ] xxxLarge'da Pratik, İlerleme, Profil, Ayarlar, Öğren, bir ders ve Oyunlar'da yazı büyüyor; kesik ya da taşan
      yazı yok (ekran testleri `-UIPreferredContentSizeCategoryName` ile iPhone SE ve iPhone'da).
- [ ] AX5'te yazılar xxxLarge boyutunda kalıyor.
- [ ] Porte, klavye, ikonlar ve Solfie büyük yazıda aynı boyutta.
- [ ] iPhone SE + xxxLarge'da soru turu, akor turu ve Ritmi Tut kaydırmadan sığıyor.

VoiceOver

- [ ] Otomatik erişilebilirlik denetimi (`XCUIApplication.performAccessibilityAudit`, iOS 17) bütün ekranlarda hatasız
      ya da kalan uyarılar burada gerekçesiyle listeli.
- [ ] Soru turunda portedeki nota "Porte: Sol anahtarı, bir nota" diye okunuyor; nota adı ya da yeri hiçbir öğede yok.
- [ ] Cevaptan sonra "Doğru" / "Yanlış. Doğru cevap: …" duyuruluyor.
- [ ] Noktalar "3. soru, 10 sorudan" diye okunuyor.
- [x] Ritmi Tut VoiceOver açıkken tek dokunuşla vuruş sayıyor. (Ceren, 27 Kasım)
- [x] Tanıtım ve ilk tur VoiceOver'la görmeden tamamlanabiliyor (Ceren telefonda denedi, 27 Kasım).
- [ ] Hareketi azalt açıkken konfeti yok, yıldızlar birlikte, sayfa geçişleri solma.

iPad

- [ ] Bütün ekranlar dört yönde ekran testinde (iPad, dikey ve yatay) taşmasız.
- [x] Split View'da 1/3 genişlikte iPhone düzeni, 1/2 ve 2/3 genişlikte uygun düzen; tur ortasında boyut değişince tur
      sürüyor.
- [x] Stage Manager en küçük pencerede yazı ve düğme kesilmiyor.

Performans ve güvenlik

- [ ] `performans.yml` (ya da `native-ekranlar.yml` içinde bir iş) her gönderimde çalışıyor ve tabloyu güncelliyor.
- [ ] İlk ölçüm değerleri bu dokümana ve PLAN'a yazıldı; hepsi sınırın altında.
- [ ] Ağ taraması ve gizlilik bildirimi kontrolü her gönderimde çalışıyor.
- [ ] Kod girişleri için bozuk girdi testleri `swift test`'te (çökme yok, yanlış ayar yok).

Mağaza

- [ ] App Store Connect'te işaretlenebilecek erişilebilirlik etiketleri listelendi (VoiceOver, Larger Text, Dark
      Interface, Reduced Motion, Sufficient Contrast) ve hangilerinin doğru olduğu Ceren'e bildirildi.

## Kapsam dışı

- Erişilebilirlik boyutlarına (AX1–AX5) kadar büyüyen yazı ve buna göre değişen düzenler (Ceren: sınırlı büyüsün).
- Nota okuma sorularını görme engelliler için yeniden tasarlamak (ör. notayı sesle ya da dokunarak anlatmak).
- Sesli Kontrol, Anahtar Denetimi, Braille ekran için özel uyarlama (sistem varsayılanı yeterli).
- Tablette donanım klavyesi kısayolları, fare/trackpad imleci.
- Yeni özellik ya da görünüm değişikliği (varsayılan ayarlarda görünüm aynı kalır).

## Etkilenen dosyalar (tahmini)

- `ios-native/Solvato/Design/Typography.swift`: `Font.ui` / `.mono` / `.term` `UIFontMetrics` ile ölçeklenir, üst sınır;
  porte ve klavye için ölçeklenmeyen ayrı yazı.
- `ios-native/Solvato/Screens/*`, `UI/*`: erişilebilirlik adları, gruplar, duyurular (`AccessibilityNotification`),
  Hareketi azalt dalları; `QuizScreen`, `ChordQuizScreen`, `RhythmTapScreen` (`.allowsDirectInteraction`),
  `RoundDotsView`, `ResultScreen`, `Coachmark`, `SplashScreen`.
- `ios-native/Solvato/Notation/*`: porte öğesinin erişilebilirlik metni (nota adı olmadan).
- `ios-native/SolvatoUITests/`: büyük yazı, iPad yön, erişilebilirlik denetimi ve performans testleri.
- `.github/workflows/native-ekranlar.yml` (+ belki `performans.yml`), `ios-native/project.yml` (gerekirse).
- `ios-native/SolvatoCore/Tests/`: kod girişleri bozuk girdi testleri.
- `docs/ozellikler/native-ios.md` (Bilinçli farklar, G-02/G-03 kabul işaretleri), `README.md`, `docs/PLAN.md`.

## Gizlilik etkisi

Yok. Ölçümler yalnız GitHub Actions'ta, simülatörde yapılır; uygulama hiçbir yere veri göndermez. VoiceOver ve yazı
boyutu iOS'un kendi ayarlarıdır, uygulama kaydetmez.

## Uygulama notları (27 Kasım)

Ne nerede:

- **Yazı boyutu:** `Typography.swift` `.ui` / `.mono` / `.term` telefonun yazı boyutuyla ölçeklenir (varsayılan
  Large'da piksel piksel aynı); büyümeyen yerler `…Fixed` (klavye tuş adları, halka ve rozet içindeki sayılar, açılış,
  logo, porte içindeki yazılar, soru turundaki büyük terim sembolü, ders şemalarındaki tuş adları). Sınır
  `AppTypeSize`: uygulama xSmall…xxxLarge (`SolvatoApp`), tur ekranları (soru, akor, Ritmi Tut, düello) xxLarge
  (`AppRoot`). Sabit yükseklikli düğmeler (tur sonucu, akor turu ana düğmesi) en az o yükseklikte büyür; yan yana
  kutulardaki sayılar en çok %80'e küçülür.
- **VoiceOver metinleri** çekirdekte ve testli: `SolvatoCore/App/AccessibilityText.swift` (noktalar, porte, cevap
  duyurusu, süre, yıldız). Duyurular `UI/Accessibility.swift` (`Announce`, VoiceOver kapalıyken bir şey yapmaz).
  Soru ve akor turunda sıradaki soruda odak soru başlığına gelir; ana sayfa ipucu balonu açılınca odak balona gelir.
  Akor portesi de adı söylemeden okunur ("Porte: Sol anahtarı, bir akor"); akor klavyesinde tuşlar "seçili / doğru /
  yanlış" değeriyle.
- **Hareketi azalt:** sayfa geçişleri zaten anında (kayan geçiş yalnız parmakla kenardan kaydırırken); kart
  animasyonları, konfeti, yıldızlar ve seri alevi `UI/Motion.swift` ve `CelebrationView`'da daha önce de hareketsizdi.
- **iPad:** düzenler pencere genişliğine (size class) bakıyor; dar pencerede iPhone düzeni. `TabletColumn` artık dal
  kurmuyor, pencere boyutu değişince ekran (ör. Ritmi Tut turu) sıfırlanmıyor. Soru turu ve tanıtım denemesi yüksekliği
  ekranın değil pencerenin yüksekliğinden alıyor (Stage Manager).
- **Testler:** `SolvatoUITests/AccessibilityTests.swift` (büyük yazı, iPad dört yön, otomatik erişilebilirlik
  denetimi), `PerformanceTests.swift` (açılış, sekme geçişi, bellek, kaydırma; sekme geçişi uygulamadaki işaretle
  ölçülür, `Solvato/Perf.swift`). Bozuk girdi ve veri koruması `SolvatoCore/Tests/.../InputFuzzTests.swift`.
- **Güvenlik:** `scripts/native-guvenlik.py` (kaynak: ayrı Linux işi; paket: ekran işinde derlemeden sonra).
  Performans tablosu `scripts/native-performans.py` → `ekranlar` dalı `performans.md`. Uygulama boyutu TestFlight
  koşusunun özetinde (25 MB'ı aşarsa uyarı); Ritmi Tut dokunuş gecikmesi elle (otomatik ölçümü simülatörde anlamlı değil).

Dokümandan sapmalar (Ceren'e bildirildi):

- **Veri koruması:** kayıtlar bugün `completeUntilFirstUserAuthentication` değil, daha sıkı
  `completeFileProtectionUnlessOpen` ile yazılıyor (G-09). Test bugünkü değeri doğrular; değiştirilmedi.
- **Gizlilik bildirimi** UserDefaults'un yanında Ritmi Tut'un kullandığı sistem saatini de (SystemBootTime, 35F9.1)
  beyan ediyor; doğru ve gerekli. Denetim ikisini birlikte bekler.

Elle denenenler (simülatörde otomatik yapılamıyor; Ceren 27 Kasım'da TestFlight 2008'de denedi, tamam): VoiceOver'la tanıtım ve ilk tur; Ritmi Tut'ta VoiceOver açıkken tek
dokunuş; iPad'de Split View 1/3, 1/2, 2/3 ve Stage Manager'ın en küçük penceresi.

### Mağaza erişilebilirlik etiketleri (App Store Connect › Accessibility)

| Etiket              | Öneri                         | Neden                                                                                                                                                                         |
| ------------------- | ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Dark Interface      | İşaretlendi (Ceren, 27 Kasım) | Koyu tema var ve varsayılan; sistem ayarına da uyuyor.                                                                                                                        |
| Reduced Motion      | İşaretlendi (Ceren, 27 Kasım) | Hareketi azalt açıkken animasyon, konfeti ve titreyen alev yok.                                                                                                               |
| Sufficient Contrast | Denetimden sonra              | Otomatik denetimin kontrast bulguları temizlenince; soluk yazılar yalnız süs metinlerinde olmalı.                                                                             |
| VoiceOver           | Şimdilik işaretlenmez         | Ekranlar okunuyor, ama ana iş (portedeki notayı okumak) görerek yapılıyor; Apple "temel işler VoiceOver'la yapılabilmeli" diyor. Ceren'in denemesinden sonra yeniden bakılır. |
| Larger Text         | İşaretlenmez                  | Apple en az %200 büyüme bekliyor; yazı bilerek xxxLarge'da (yaklaşık %135) duruyor.                                                                                           |

### İlk ölçümler (27 Kasım, commit 7bfd203, GitHub Actions iPhone simülatörü)

| Ölçüm                      | Değer               | Sınır  | Not                                                                                 |
| -------------------------- | ------------------- | ------ | ----------------------------------------------------------------------------------- |
| Soğuk açılış (ilk kare)    | 3,41 sn (3,19–4,01) | 1,5 sn | Aşıyor. Bulut Mac'teki simülatör yavaş; telefonda ölçülmedi. Sınır kararı Ceren'de. |
| Pratik → İlerleme geçişi   | 0,07 sn             | 0,3 sn | Tamam (uygulamadaki işaretle ölçülür).                                              |
| Bellek (tur boyunca, tepe) | 55 MB               | 150 MB | İlk koşuda tur testi yarıda kaldı (test düzeltildi); tam tur değeri sonraki koşuda. |
| Kaydırma takılması         | ölçülemiyor         | %1     | Simülatör takılma oranı vermiyor, yalnız süre; cihazda Instruments ile bakılır.     |
| Uygulama boyutu (IPA)      | 4,4 MB              | 25 MB  | Tamam (TestFlight 2008).                                                            |

### Otomatik erişilebilirlik denetimi (27 Kasım)

`performAccessibilityAudit`, koyu ve açık temada 10 ekran; bulgular `ekranlar` dalında `denetim-<cihaz>.txt`. iPhone'da:

- **Dinamik yazı (338):** bilerek büyümeyen yazılar (klavye, halkalar, rozetler, porte) ve xxxLarge sınırı. Gerekçe: §1.
- **Kontrast (73):** Apple'ın denetimi ekran görüntüsünden örnekliyor; yarı saydam kart ve gradyan zeminlerde çok uyarı
  veriyor. Token hesabı: bütün metin renkleri (`text`…`textSubtle`, renkli `…Text`) iki temada kart zemininde 4,5:1'in
  üstünde; ana düğme beyaz/mor 5,7:1. Tek eksik `textFaint` koyu temada kart üstünde **4,29:1**; yer tutucunun
  yanında birkaç okunan yazıda da kullanılıyor (ünvan listesindeki XP'ler, "SEÇİLEN", "✕ Temizle", İlerleme'de zayıf
  not). Düzeltme görünümü değiştireceği için Ceren'e soruldu.
- **Dokunma alanı (48):** akor ve ders klavyelerindeki siyah tuşlar (gerçek piyano oranı, küçültülemez) ve tıklanamayan
  bilgi öğeleri (noktalar, hedef çubuğu); denetim bunları yanlışlıkla dokunulabilir sayıyor.
- **Kesik yazı (8):** ders listesi alt yazıları ve Oyunlar kartı alt yazısı tek satırda "…" ile kısalıyor (web'le aynı
  tasarım), İlerleme'de "Bugün" etiketi. Varsayılan boyutta, 0.8'den önce de böyleydi.
- iPad'de denetim 30 dakika sınırına takıldı (kısmi sonuç, 53 bulgu, aynı türler).

Büyük yazı görüntülerinde (iPhone SE, xxxLarge ve AX5) tek kusur İlerleme'deki "Tamamlanan tur" etiketinin kelimeyi
ortadan bölmesiydi; düzeltildi (kelimeler alt alta). Tur ekranları kaydırmasız sığıyor; AX5'te yazı xxxLarge'da kalıyor.
