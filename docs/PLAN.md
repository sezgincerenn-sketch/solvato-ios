# Plan: native iOS, App Store yayını, test ortamı, analitik ve admin paneli

Tarih: 21 Kasım 2026. Durum: **onaylandı** (kararlar en altta).
Hedef yayın (URUN.md): 23 Aralık – 5 Ocak.

## Önce bilinmesi gereken üç şey

### 1. Uygulama native iOS olarak yeniden yazılıyor (22 Kasım kararı)

Bugünkü uygulama web teknolojisiyle (React) yazılmış ve iPhone içinde bir web görünümünde çalışıyor (Capacitor).
Ceren'in kararı: `solvato-ios` **tamamen native** (Swift / SwiftUI) olacak, güvenlik ve performans açısından tam
optimize edilecek. Bu, aşağıdaki **Paket 0** ve birinci öncelik. Web kodu, native sürüm aynı işlevlere ulaşınca repodan
kalkar; o güne kadar yeni ekranların neye benzeyeceğinin başvuru kaynağı olarak kalır.

### 2. Veri toplamak, bugünkü kararlarımızın tersi

`docs/URUN.md` ve mağaza beyanları şunu söylüyor: sunucu yok, hesap yok, **veri toplanmıyor**. Uygulama 4+, ve
hedef kitlenin çoğu 8–12 yaşında çocuklar. Admin paneli için veri toplamaya başlarsak bunların hepsi değişir:

- App Store gizlilik etiketi "Data Not Collected" olmaktan çıkar. Yerine "Usage Data / Identifiers" gelir; anonim
  tutarsak "Data Not Linked to You" diye beyan edilir.
- Gizlilik politikası (uygulama içi ve web), KVKK metni, mağaza açıklamasındaki "Solvato hiçbir veri toplamaz" cümlesi
  ve `PrivacyInfo.xcprivacy` değişir.
- Çocuklara yönelik uygulamalarda Apple, çocuğu tanımlayan veri gönderilmesine izin vermiyor. Önerim: **isim yok,
  hesap yok**, rastgele bir cihaz kimliği, yalnızca kendi sunucumuz (üçüncü taraf analitik aracı yok), Ayarlar'da
  "Kullanım verisi paylaş" anahtarı.
- "Kullanıcılar kimler" sorusunun cevabı bu modelde isim değil, "cihaz X: iPad, Orta seviye, 12 gündür kullanıyor"
  gibi olur. İsim ve e-postayla takip, hesap sistemi ve açık rıza ister; çocuklar için ebeveyn onayı ister. İlk sürüm
  için önermiyorum.

### 3. "Datayı hem uygulamada hem adminde tutmak" iki farklı şey olabilir

- **A. Tek yönlü analitik (önerilen):** Uygulama olayları gönderir ("tanıtım 3. adım", "tur bitti", "uygulama
  kapandı"). İlerleme yine telefonda kalır. Hesap gerekmez.
- **B. İki yönlü senkron:** İlerleme sunucuda da tutulur; telefon değişince geri yüklenir, iPhone ile iPad aynı
  ilerlemeyi görür. Bunun için **hesap (giriş)** gerekir. Bu ileride Solvato Plus ve öğretmen panelinin temeli olur
  ama yayın tarihine yetişmez.

Veritabanını A ile başlayıp B'ye genişleyebilecek şekilde tasarlarım (aşağıda).

## İş paketleri

### Paket 0 — Native iOS uygulaması (1. öncelik)

**Birebir uyum (Ceren'in şartı):** native sürüm mevcut uygulamayla ekran ekran aynı olur: akışlar, metinler, renkler,
yazı tipleri, ölçüler, animasyonlar ve kurallar. Yeniden tasarım yok. Aşama 0.1'de her ekranın React sürümünden
iPhone / iPad, koyu / açık görüntüleri alınır; her native ekran aynı durumdaki görüntüsüyle yan yana karşılaştırılarak
kabul edilir. Mantık kuralları (puan, seviye, seri, öğretmen ve meydan okuma kodları) aynı girdilerle aynı sonucu
vermeli: React sürümünden üretilen örnek girdi/çıktı tabloları native testlerde kullanılır. Öğretmen ve meydan okuma
kodları iki sürüm arasında birbirini okuyabilmeli.

**Hedef:** Bugünkü uygulamanın bütün işlevleri, aynı tasarımla, Swift ve SwiftUI ile. Web görünümü yok, üçüncü taraf
kütüphane yok (yalnızca Apple'ın kendi çatıları). iPhone + iPad, en düşük iOS 17.

**Kapsam (bugünkü uygulamadaki her şey):** açılış ve tanıtım, Pratik (ana sayfa, günlük hedef portesi, seviye),
soru turu (nota, ritim, terim, nota yazımı, kulak), akor turu, Ritmi Tut, tur sonucu ve yıldızlar, İlerleme (konular,
yol, haftalık rapor, zorlandığın notalar), Profil (ünvan, geçmiş), Çalışma (Notalar, Ritim, Akorlar, Terimler, arama,
"Kaldığın yer"), Oyunlar (günün meydan okuması, arkadaşına meydan oku, akor düellosu), Ayarlar, öğretmen kodu,
Gizlilik ve Lisanslar, bildirim, titreşim, paylaşım, koyu/açık tema. Bugünkü kod yaklaşık 19.000 satır, 30 ekran.

**Güvenlik:**

- Ağ erişimi yok (1.1'deki anonim analitik hariç; o da yalnızca kendi sunucumuza, HTTPS ile).
- Veriler cihazda, iOS veri koruması açık (cihaz kilitliyken şifreli). Hesap, şifre, anahtar yok.
- Üçüncü taraf kod yok: tedarik zinciri riski ve gizlilik beyanı yükü sıfır.
- Gizlilik bildirimi (privacy manifest) yalnızca gerçekten kullanılan API'lerle; öğretmen kodu ve meydan okuma kodu
  gibi dışarıdan gelen her girdi doğrulanır.

**Performans:**

- Açılış süresi, kare hızı (ProMotion ekranlarda 120 Hz), bellek ve uygulama boyutu için ölçülebilir hedefler;
  otomatik performans testleri her derlemede çalışır.
- Ses: AVAudioEngine ile düşük gecikme. Ritmi Tut'un zamanlama doğruluğu bugünkünden iyi olmalı (en büyük kazanç).
- Nota sembolleri Bravura yazı tipiyle doğrudan çizilir (bugünkü SVG yolları yerine).

**Mac olmadan nasıl:**

- Xcode projesi elle değil, bir yapılandırma dosyasından (XcodeGen) üretilir; proje dosyası bozulma riski kalkar.
- Mantık (puanlama, seviye, seri, öğretmen kodu, ritim değerlendirme, soru seçimi) ayrı bir Swift paketi olur ve bu
  bulut oturumunda testlerle doğrulanır. Bunun için oturum ortamına Swift kurulumu gerekir (`download.swift.org`
  adresine izin; ilk native oturumda istenecek).
- Ekranlar Codemagic'te derlenir; simülatörde UI testleri çalışır ve her ekranın iPhone / iPad, koyu / açık
  görüntüleri derleme çıktısı olarak gelir. Ekran kontrolü bu görüntülerle yapılır.
- Her ara sürüm TestFlight'a gider; Ceren telefonda dener.

**Veri taşıma gerekmiyor:** uygulama henüz yayında değil.

**Aşamalar:**

| Aşama | İş                                                                                                                          | Tahmini süre |
| ----- | --------------------------------------------------------------------------------------------------------------------------- | ------------ |
| 0.1   | Özellik envanteri: bugünkü uygulamanın her ekranı ve kuralı, kabul ölçütleriyle (`docs/ozellikler/native-ios.md`)           | 1–2 oturum   |
| 0.2   | İskelet: XcodeGen projesi, Swift paketi, tasarım sistemi (renk, yazı, ölçüler), Codemagic + UI test görüntüleri, TestFlight | 2–3 oturum   |
| 0.3   | Çekirdek mantık ve veri: soru bankası, seviye, seri, yıldız, öğretmen kodu, oyun kodları, depolama + testler                | 3–4 oturum   |
| 0.4   | Nota çizimi (porte, anahtar, ritim, akor) ve piyano klavyesi                                                                | 3–4 oturum   |
| 0.5   | Ekranlar: tanıtım, Pratik, soru ve akor turları, sonuç                                                                      | 4–5 oturum   |
| 0.6   | Ses ve Ritmi Tut (düşük gecikme), kulak soruları                                                                            | 2–3 oturum   |
| 0.7   | İlerleme, Profil, Çalışma, Oyunlar, Ayarlar, öğretmen kodu, bildirim, paylaşım                                              | 5–6 oturum   |
| 0.8   | Performans ve güvenlik ölçümleri, erişilebilirlik (VoiceOver, Dinamik Yazı), iPad düzenleri                                 | 2–3 oturum   |
| 0.9   | `inceleyici` ile envantere göre tam karşılaştırma, TestFlight'ta kapalı test, web kodunun silinmesi                         | 2 oturum     |

Toplam kabaca 25–30 oturum; Ceren'in TestFlight geri bildirimine bağlı olarak **5–7 hafta**.

**Durum:** 0.1 yazıldı (21 Kasım): `docs/ozellikler/native-ios.md` (19 kural, 18 ekran grubu, kabul ölçütleri) ve
referans görüntü betiği `scripts/referans.mjs`. Altın tablolar 0.3'te, aynı dokümandaki listeye göre üretilir.
0.2 başladı (21 Kasım): iskelet `ios-native/` (README "Native iOS"). Codemagic `ios-native-test` yeşil: çekirdek
testleri (web değerleriyle eşitlik) geçti, uygulama derlendi, 3 cihaz × 2 tema ekran görüntüsü alındı. Bekleyen:
TestFlight için App Store imzalaması (rehber Bölüm A, B 5–7), `src/ui` ve `src/components` parçalarının taşınması.
22 Kasım: imzalama kuruldu, ilk native derleme (`ios-native-testflight`) TestFlight'a yüklendi; ortak arayüz parçaları
(ikon, logo, seçim, rozet, yıldız, gösterge, puan halkası) taşındı. 0.2'de kalan: Avatar, BackButton, ScreenHeader, Toast,
ExitConfirm, TopicLink, PlayChip, NavBar, Coachmark (0.5'te yapıldı; Coachmark Pratik'le birlikte).
0.3 başladı (22 Kasım): `scripts/altin.mjs` altın tabloları üretiyor; `SolvatoCore/Logic/` altında soru bankası ve
seviyeler, ünvan, yıldız, takvim dönemleri, seri ve tur sonu istatistikleri, seviye atlama, kutlama, öğretmen kodu, meydan
okuma kodu, günün meydan okuması, tohumlu oyun soruları, tur için soru seçimi, kulak soruları, zorlandığın notalar yazıldı;
31 test geçiyor (K-01–K-04, K-06–K-09, K-12, K-14–K-16). Akor motoru ve akor turu (K-17), Ritmi Tut puanlama (K-18),
haftalık rapor ve dönem doğruluğu (K-13, K-14), kalıcı depolama (G-09: web anahtarlarıyla dosyalar, veri koruması,
yedek dışı son ders) eklendi; 46 test. **0.3 tamam.** Sırada 0.4: nota çizimi ve piyano klavyesi.
0.4 başladı (22 Kasım): nota çizimi (Notation dili, tek nota portesi, akor portesi, günlük hedef portesi, anahtar ikonu)
web'in SVG çıktısıyla parça parça aynı. Piyano klavyeleri (soru turu 1–3 oktav, akor klavyesi) tuş tuş aynı; 57 test.
Tasarım sistemi ekranında örnekler. 0.4'te kalan: ekranda React görüntüleriyle göz karşılaştırması (Codemagic).
0.5 başladı (22 Kasım): ortak ekran parçaları (Avatar, BackButton, ScreenHeader, Toast, PlayChip, TopicLink, ExitConfirm,
NavBar, TabletColumn) `Solvato/UI/Shell.swift`; tasarım sistemi ekranında örnekler. Uygulama akışı çekirdekte:
gezinme kuralları (`ScreenStack`) ve durum modeli (`AppModel`: tur başlat/bitir, oyun, sıfırlama, tanıtım); 66 test.
Pratik ekranı (E-04): içerik çekirdekte (`HomeContent`; 60 durumda web'le aynı yazılar, aynı sıra), SwiftUI ekranı ve kök
görünüm (`AppRoot`). UI testleri `referans.mjs --json` senaryolarıyla (aynı veri, aynı an) `pratik*` görüntülerini alır;
uygulama normal açılışta hâlâ tasarım sistemiyle açılır (soru turu gelince kök AppRoot olur). 69 test. Sırada: kaydırarak
geri, ana sayfa ipuçları (Coachmark), açılış ve tanıtım, soru turu.
Soru turu (E-05): akış çekirdekte (`QuizRound`: eş sesli siyah tuş, çok oktavda oktav kontrolü, açıklama, ipucu, süre, üç
doğruda alev; testli), SwiftUI `QuizScreen` (porte / ritim / terim / yazım / kulak, klavye ya da şıklar, yan ekranda iki
sütun) ve UI testinde `soru-*` görüntüleri; 74 test. Ses/titreşim 0.6'da; sallanma/nabız animasyonları ve "yan çevir"
ipucu sonra.
Tur sonucu (E-08) ve kutlama (E-09): yazılar çekirdekte (`ResultContent`, `Celebration.rows`; testli), SwiftUI
`ResultScreen`, `CelebrationView` (konfeti), Solfie (SVG'den birebir). **Açılış artık Pratik** (`AppRoot`): Pratik → tur →
sonuç → Bitir akışı çalışır; henüz taşınmayan ekranlarda yalnız başlık ve "Bu ekran native sürüme henüz taşınmadı." notu.
Tasarım sistemi yalnız UI testinde (`-UITestDesignSystem`). 78 test. Açılış animasyonu (E-01, CSS eğrileri çekirdekte:
`Curve.value`) ve ilk açılış tanıtımı (E-02, iki canlı deneme, anahtar, seviye/hedef, günlük hatırlatma bildirimi) yazıldı;
UI testinde `acilis`, `tanitim-*`. Ana sayfa ipuçları (Coachmark, anchor tercihleriyle), kenardan kaydırarak geri (alt
ekranlarda kayar, turlarda çıkış onayı), telefonda yalnız soru/akor turu yan döner (G-02, G-10). Kaydırma konumunun geri
dönüşte korunması sonra. Akor turu (E-06): akış çekirdekte (`ChordRound`, testli), SwiftUI `ChordQuizScreen` (üç soru türü,
süre halkası, formül, seçilen tuşlar), UI testinde `akor`; 82 test. İlerleme (E-10): içerik çekirdekte (`ProgressContent`;
50 durumda web'le aynı yazılar), SwiftUI ekranı (telefonda tek, iPad'de iki sütun; haftalık rapor paylaşımı), UI testinde
`ilerleme*`; 83 test. Profil (E-11: ad, renk, seviye, ünvan listesi, rapor) ve Ayarlar (E-12: hedef, seviye, anahtar, notalar,
cevap yöntemi, ses, titreşim, tema, hatırlatma, sıfırlama); tema artık uygulama durumunda (Persistence); 85 test. Sırada:
Öğretmen kodu, Gizlilik ve Lisanslar, Çalışma, Oyunlar, Ritmi Tut.
Öğretmen kodu (E-13; kurallar `TeacherFlow`), Gizlilik ve Lisanslar (E-14; metinler `legal.ts`'den `hukuk.json`'a birebir); 90 test.
Çalışma sekmesi (E-15): ders listesi, arama ve Kaldığın yer (`Lessons`, altın tablo `calisma.json`); 94 test.
Sırada: ders içerikleri (E-16), Oyunlar (E-17), Ritmi Tut.

**Takvime etkisi:** 23 Aralık – 5 Ocak yayın hedefi tutmaz. Gerçekçi yeni hedef **Ocak sonu – Şubat ortası
2027**. Analitik (1.1) native sürümün üstüne yazılır.

**Android:** `solvato-android` bugünkü React kopyası olarak donmuş kalır. Android'e geçildiğinde aynı karar
(native Kotlin mi, mevcut kod mu) o gün verilir.

### Paket 1 — Repo ayrımı (1 oturum)

Önerilen yapı:

| Repo                     | İçerik                                                    | Durum                     |
| ------------------------ | --------------------------------------------------------- | ------------------------- |
| `solvato-ios`            | iOS uygulaması: `src/` + `ios/`                           | Aktif geliştirme          |
| `solvato-android` (yeni) | Bugünkü `src/` + `android/` anlık kopyası                 | Dondurulmuş, kod yazılmaz |
| `solvato-admin` (yeni)   | Sunucu (Cloudflare Worker), veritabanı (D1), admin paneli | Paket 4'te                |

- Android işi başlayınca `solvato-android`, iOS reposundan o günün `src/`'sini alır. İki repoda aynı kodun iki
  kopyası oluşur; bu bilinen bir maliyet. Ortak bir çekirdek repo (iki uygulama onu paket olarak kullanır)
  daha temiz bir yöntem ama Android başlayana kadar gereksiz karmaşa. O gün yeniden bakarız.
- Bu repodan `android/`, `@capacitor/android` ve Android'e özel kod parçaları (geri tuşu) kaldırılır.
  README ve CLAUDE.md güncellenir.
- **Senin yapman gereken:** GitHub'da boş `solvato-android` ve `solvato-admin` repolarını oluşturmak. Yeni
  repo açma yetkim yok; açınca bu oturuma eklerim.

### Paket 2 — iOS App Store hazırlığı (2–3 oturum, native sürüm için yeniden)

İlk kontrol `docs/APP-STORE-KONTROL.md`'de. Kalanlar:

1. **Bulut derleme:** repoya `codemagic.yaml` (Xcode 26, imzalama, TestFlight'a otomatik yükleme).
2. **iPhone + iPad** (karar verildi, ikisi de):
   - iPad'de tüm ekranları dikey ve yatayda kontrol (`--tablet` ekran görüntüleri), Split View / Stage Manager'da dar
     pencere, büyük ekranda piyano klavyesi ve porte boyutları.
   - 13 inç iPad mağaza görselleri (2048×2732); ham ekranları ben çekerim.
   - Mağaza metnindeki "iPhone ve iPad'de" cümlesi kalır.
3. **Sessiz mod:** sessizde de ses gelsin mi? (önceki kontrolden açık karar; önerim evet)
4. **Gizlilik ve destek sayfaları:** herkese açık bir adres lazım. Paket 4'teki Cloudflare alanında
   (`solvato.pages.dev` gibi) yayınlanabilir. Paket 4 beklenmeden ilk iş olarak kurulabilir.
5. **Sürekli kontrol:** `magaza-kontrol` becerisi her yeni özellikten sonra kısa haliyle çalışır (bitirme adımlarına
   eklenecek), her sürümde tam haliyle. Sonuçlar `docs/APP-STORE-KONTROL.md`'ye eklenir.

### Paket 3 — Kendi iPhone'unda test ve rehber (1 oturum + senin hesap işlerin)

Mac olmadan tek yol **TestFlight**:

1. **Apple Developer Program** üyeliği (yıllık 99 $, onay 1–2 gün sürebilir). TestFlight ve App Store için şart.
   Bireysel mi, şirket mi? Şirket için D-U-N-S numarası gerekir ve süreç haftalar alabilir.
2. App Store Connect'te uygulama kaydı (`com.solvato.app`) ve bir API anahtarı.
3. Codemagic hesabı (kişisel hesapta ayda 500 ücretsiz Mac dakikası), GitHub bağlantısı, API anahtarı.
4. Derleme → TestFlight → telefonuna TestFlight uygulaması → Solvato'yu kur.

Rehber `docs/IOS-TEST-REHBERI.md` olarak hazırlanır: her adımda neye basacağın ve ekranda ne göreceğin.

### Paket 4 — Analitik, veritabanı ve admin paneli (önce özellik dokümanı, sonra 3–5 oturum)

**Altyapı (ücretsiz katman):** Cloudflare Workers (API) + D1 (veritabanı) + Pages (admin paneli), adres
`*.workers.dev` / `*.pages.dev`. Admin paneli Cloudflare Access ile korunur: yalnızca senin e-postanla giriş yapılır.

**Veritabanı taslağı** (iki uygulama ve ileride hesaplar düşünülerek):

| Tablo              | Ne tutar                                                                                                                      |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| `installs`         | Rastgele cihaz kimliği, platform (`ios` / `android`), cihaz türü (telefon / tablet), uygulama sürümü, dil, ilk ve son görülme |
| `sessions`         | Oturum başlangıcı, bitişi, süresi                                                                                             |
| `events`           | Olay adı, ekran, küçük ayrıntılar (seviye, konu, doğruluk), zaman                                                             |
| `funnel_steps`     | Tanımlı adımlar: tanıtım 1–7, ilk tur, ilk tur bitti, 1. gün, 7. gün, öğretmen kodu uygulandı                                 |
| `accounts` (sonra) | Hesap sistemi gelince; `installs` buna bağlanır. Öğretmen paneli ve Plus bunun üstüne kurulur.                                |

**Uygulama tarafı:** olaylar telefonda biriktirilir, internet olunca toplu gönderilir (uygulama çevrimdışı çalışmaya
devam eder). Ayarlar'da açma-kapama anahtarı olur, gizlilik metinleri güncellenir.

**Admin paneli ekranları:** günlük aktif cihaz, ortalama süre, huni (hangi adımda kaç kişi bıraktı), konu ve seviye
dağılımı, iPhone / iPad / Android oranı, sürüm dağılımı, tek cihazın yolculuğu.

Bu paket ürün kararı içerdiği için önce `ozellik` becerisiyle özellik dokümanı yazılır, onayından sonra kodlanır.

## Sıra (22 Kasım'da güncellendi)

| Sıra | İş                                                                                     | Not                                                |
| ---- | -------------------------------------------------------------------------------------- | -------------------------------------------------- |
| 1    | Paket 3: Codemagic + TestFlight kurulumu (Ceren, rehberle)                             | Native sürümün her aşaması da TestFlight'a gidecek |
| 2    | **Paket 0: native iOS** (aşama 0.1'den başlayarak)                                     | **1. öncelik**                                     |
| 3    | Paket 2: gizlilik/destek sayfası, iPad görselleri, mağaza kontrolü (native sürüm için) | Gizlilik sayfası Paket 0'la paralel yapılabilir    |
| 4    | App Store'a 1.0 gönderimi (native, veri toplamadan)                                    | Ocak sonu – Şubat ortası 2027                      |
| 5    | Paket 4: analitik ve admin paneli (1.1)                                                | Native uygulamaya Swift ile eklenir                |
| 6    | Android                                                                                | iOS yayından sonra                                 |

Mevcut React sürümüne bundan sonra yeni özellik eklenmez; yalnızca TestFlight kurulumunu denemek için kullanılabilir.

## Kararlar

| Konu                 | Karar                                                                                     |
| -------------------- | ----------------------------------------------------------------------------------------- |
| Veri modeli          | **Anonim analitik**: isim ve hesap yok, rastgele cihaz kimliği, Ayarlar'dan kapatılabilir |
| Analitik zamanlaması | **1.1**: 1.0 veri toplamadan çıkar                                                        |
| Web önizlemesi       | **TestFlight çalışınca** silinir                                                          |
| Apple Developer      | **Bireysel üyelik** (22 Kasım onaylandı); imzalama ve TestFlight kurulu                   |
| Cihazlar             | iPhone + iPad                                                                             |

## Hâlâ açık

Yok. Repolar açıldı (21 Kasım): `solvato-ios` (aktif, `solvato`nun tüm geçmişiyle; `solvato` dokunulmaz yedek olarak kalır), `solvato-android` (dondurulmuş),
`solvato-admin` (boş iskelet). Sessiz modda ses: evet, uygulandı.
