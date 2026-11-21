# Plan: iOS yayını, repo ayrımı, test ortamı, analitik ve admin paneli

Tarih: 21 Kasım 2026. Durum: **onaylandı** (kararlar en altta).
Hedef yayın (URUN.md): 23 Aralık – 5 Ocak.

## Önce bilinmesi gereken üç şey

### 1. "Web kodu" uygulamanın kendisi

Solvato'nun tek bir kodu var: `src/` (React). iOS ve Android uygulamaları bu kodu telefonun içindeki bir web görünümünde
çalıştırıyor (Capacitor). Yani `src/` silinirse iOS uygulaması da silinir. Ayrı bir "web sitesi" kodu yok.

Silinebilecek "web" parçaları şunlar:

| Parça                                                                             | Ne işe yarıyor                    | Öneri                                                |
| --------------------------------------------------------------------------------- | --------------------------------- | ---------------------------------------------------- |
| Tek dosyalık önizleme (`build:single`, `vite.single.config.ts`, önizleme sayfası) | Senin tarayıcıda deneme bağlantın | TestFlight telefonunda çalışınca sil                 |
| Tarayıcıya özel yedek kodlar (paylaşım, panoya kopyalama vb.)                     | Uygulama tarayıcıda açılırsa      | Sil (küçük temizlik)                                 |
| Geliştirme sunucusu (`npm run dev`)                                               | Geliştirme ve ekran görüntüsü     | **Kalmalı**: Claude ekranları bununla kontrol ediyor |

Önizlemeyi hemen silersek TestFlight kurulana kadar uygulamayı deneyecek bir yerin kalmaz. Ayrıca sonrasında her
küçük değişikliği görmek için bir bulut derlemesi gerekir (~10–15 dk, ayda 500 ücretsiz dakika).

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

### Paket 2 — iOS App Store hazırlığı (2–3 oturum)

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

## Önerilen sıra

| Sıra | İş                                                                           | Neden bu sırada                            |
| ---- | ---------------------------------------------------------------------------- | ------------------------------------------ |
| 1    | Apple Developer üyeliği başvurusu (sen)                                      | Onayı gün alabilir; her şey buna bağlı     |
| 2    | Paket 1: repo ayrımı                                                         | Kısa, sonraki işleri sadeleştirir          |
| 3    | Paket 3 + Paket 2/1: Codemagic + TestFlight + rehber                         | Telefonunda deneyebilmen her şeyden önemli |
| 4    | Paket 2: iPad kontrolü, sessiz mod, gizlilik/destek sayfası                  | Mağaza engelleri                           |
| 5    | Paket 4: analitik özellik dokümanı → sunucu ve veritabanı → uygulama → admin | Yayına yetişirse 1.0'a, yetişmezse 1.1'e   |
| 6    | Web önizlemesinin silinmesi                                                  | TestFlight çalışınca                       |
| 7    | App Store'a gönderim                                                         | `magaza-kontrol` temiz olunca              |

Yayın tarihine dair uyarı: analitik 1.0'a girerse gizlilik beyanları ve inceleme riski artar, takvim sıkışır.
Önerim 1.0'ı bugünkü gibi veri toplamadan çıkarmak, analitiği 1.1'de eklemek. Yine de 1.0'dan itibaren veri
istiyorsan Paket 4'ü öne alırız.

## Kararlar (21 Kasım)

| Konu                 | Karar                                                                                     |
| -------------------- | ----------------------------------------------------------------------------------------- |
| Veri modeli          | **Anonim analitik**: isim ve hesap yok, rastgele cihaz kimliği, Ayarlar'dan kapatılabilir |
| Analitik zamanlaması | **1.1**: 1.0 veri toplamadan çıkar                                                        |
| Web önizlemesi       | **TestFlight çalışınca** silinir                                                          |
| Apple Developer      | **Hesap var**                                                                             |
| Cihazlar             | iPhone + iPad                                                                             |

## Hâlâ açık

Yok. Repolar açıldı (21 Kasım): `solvato-ios` (aktif, eski `solvato`nun tüm geçmişiyle), `solvato-android` (dondurulmuş),
`solvato-admin` (boş iskelet). Sessiz modda ses: evet, uygulandı.
