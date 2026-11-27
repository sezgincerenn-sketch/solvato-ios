# Apple gezinme çubuğu, haftalık rapor düğmesi, Profil sadeleştirmesi

Durum: **uygulandı (27 Kasım 2026)**; ekran ölçütleri GitHub Actions ekran görüntüleri ve TestFlight'la kapanacak.
Native revize (yalnız `ios-native/`). Kararlar Ceren'in, 27 Kasım. Bu doküman bitince `inceleyici` ajanının
karşılaştıracağı ölçüttür. Giriş (Misafir / Apple / Google) bu dokümanda **yok**: ayrı iş, `docs/ozellikler/hesap.md`
yeniden yazılarak (isim değişikliğinden sonra).

## Amaç

- Üstteki başlık, geri ve Ayarlar düğmeleri iPhone'un kendi uygulamalarındaki gibi olsun (Apple'ın gezinme çubuğu;
  iOS 26'da Liquid Glass). Alt menü zaten Apple'ın sekme çubuğu (`gezinme.md`); üst kısım da ona uysun.
- Haftalık rapor İlerleme'de büyük düğme yerine sağ üstteki paylaş simgesinden gönderilsin; Profil'deki tekrar eden
  "Tüm ilerleme" düğmesi kalksın.

**Bilinçli fark:** bu revize React sürümünden ayrılır; bitince `native-ios.md` "Bilinçli farklar"a yazılır.

## Kullanıcı ne görür

### 1. Gezinme çubuğu (başlıklı ekranlar)

**Sekme ekranları: İlerleme, Öğren, Profil**

- Başlık **büyük ve sola dayalı** ("İlerleme", "Öğren", "Profil"), Solvato'nun yazı tipiyle (Outfit, kalın), bugünkü
  başlık rengiyle. Sayfa aşağı kaydırılınca başlık küçülüp üst çubuğun ortasına geçer (Ayarlar uygulaması gibi); yukarı
  kaydırınca yeniden büyür.
- **Profil:** sağ üstte Ayarlar dişlisi, Apple'ın yuvarlak (iOS 26'da cam) çubuk düğmesi olarak. Dokununca Ayarlar açılır.
- **İlerleme:** sağ üstte **Apple paylaş simgesi** (kare + yukarı ok). Dokununca bugünkü "Öğretmenine haftalık rapor
  gönder" düğmesinin açtığı paylaşım menüsü açılır (aynı metin, sonunda App Store bağlantısı). VoiceOver adı:
  "Haftalık raporu öğretmenine gönder".
- **Öğren:** sağ üstte düğme yok.
- **Ana sayfa** olduğu gibi kalır (logo, seri ve XP satırı özel tasarım; gezinme çubuğu yok).

**Alt ekranlar**

- Ayarlar, Çalışılacak notalar, Öğretmen kodu, Gizlilik, Lisanslar, dersler, Oyunlar, Günün meydan okuması, Arkadaşına
  meydan oku, oyun sonucu, Akor düellosu kurulumu.
- Sol üstte Apple'ın geri düğmesi: **‹ + önceki ekranın adı** ("‹ Profil", "‹ Ayarlar", "‹ Öğren", "‹ Ana sayfa",
  "‹ Oyunlar"). Ad sığmazsa iOS kendisi "‹ Geri"ye ya da yalnız ‹'ye kısaltır. iOS 26'da cam yuvarlak düğme.
- Başlık **küçük, ortada** (Outfit, kalın): "Ayarlar", "Gizlilik", dersin adı… Uzun ders adı tek satıra sığmazsa
  sonu "…" ile kısalır; ekranın içindeki başlık metni ayrıca durmaz (çift başlık olmasın).
- Sol kenardan kaydırarak geri dönmek çalışmaya devam eder (Apple'ın kendi hareketi; parmakla sürüklenir, yarıda
  bırakılırsa geri gelir).
- Alt ekranlarda alt menü bugünkü gibi **görünmez** (alt ekranlar ve turlar tam ekran; `gezinme.md`).

**Değişmeyenler**

- Turlar (soru, akor, Ritmi Tut, akor düellosu oyunu): sol üstteki ✕, adım noktaları, sayaç ve çıkış onayı aynı.
- Tanıtım, açılış, kutlama, tur sonucu ekranı aynı.
- Kaydırma konumunun hatırlanması (bir alt ekrandan dönünce sayfa aynı yerde) ve açık sekmeye tekrar dokununca en üste
  kayma çalışmaya devam eder.

### 2. İlerleme › Bu hafta kartı

- Kartın altındaki büyük "Öğretmenine haftalık rapor gönder" düğmesi **kalkar**. Kartın geri kalanı (seri, 7 gün,
  özet) aynı. Gönderme yalnız sağ üstteki paylaş simgesinden.

### 3. Profil

- En alttaki **"Tüm ilerleme"** düğmesi kalkar (İlerleme zaten alt menüde).
- **"Haftalık raporu öğretmenine gönder"** düğmesi Profil'de **kalır** (yeri ve görünümü aynı).

## Kurallar ve sınır durumları

- Koyu ve açık tema: başlık rengi, çubuk arka planı ve düğmeler temaya uyar; açık temada da okunur. Çubuk arka planı
  sayfanın zemin rengiyle aynı (kaydırınca altında içerik görünürse iOS'un kendi bulanık zemini).
- iOS 17–25: aynı yerleşim, klasik (camsız) çubuk ve düğmeler. iOS 26: Liquid Glass.
- iPad: başlık ve düğmeler aynı; içerik genişlikleri (680 / 820 pt) değişmez. Dar pencerede (Split View) aynı.
- Büyük yazı (Dinamik Yazı): başlık da büyür, sınır uygulamanın sınırı (xxxLarge).
- VoiceOver: başlık "başlık" olarak okunur; geri düğmesi "Profil, geri düğmesi" gibi (Apple'ın kendi okuması); paylaş
  düğmesinin adı yukarıda.
- Hareketi azalt: Apple'ın kendi geçişi (iOS ayarına uyar).
- Paylaş simgesi, bugün kartın düğmesinin göründüğü durumlarda görünür (İlerleme boşken de bugünkü davranış neyse o);
  gönderilen metin bugünkü düğmeninkiyle aynı.
- Tur ortasında çıkış onayı, ipucu turu (Ana sayfa) ve kutlama penceresi açıkken geri hareketi bugünkü kurallarla çalışır
  (`ScreenStack.canSwipeBack`).

## Kabul ölçütleri

- [ ] İlerleme, Öğren ve Profil'de başlık büyük, Outfit, sola dayalı; kaydırınca küçülüp ortaya geçiyor.
- [ ] Profil'in sağ üstünde Apple çubuk düğmesi olarak dişli var; Ayarlar'ı açıyor.
- [ ] İlerleme'nin sağ üstünde Apple paylaş simgesi var; haftalık raporun paylaşım menüsünü açıyor; metin bugünküyle aynı.
- [ ] İlerleme'deki Bu hafta kartında gönder düğmesi yok.
- [ ] Profil'de "Tüm ilerleme" düğmesi yok; "Haftalık raporu öğretmenine gönder" duruyor.
- [ ] Bütün alt ekranlarda sol üstte "‹ <önceki ekran>" geri düğmesi ve ortada küçük başlık var; ekranın içinde ikinci bir
      başlık yok.
- [ ] Sol kenardan kaydırarak geri dönülüyor; Ana sayfadaki ipucu turu ve açık pencerelerde geri hareketi çalışmıyor
      (bugünkü gibi).
- [ ] Alt ekranlarda alt menü görünmüyor; turlar, Ana sayfa, tanıtım ve tur sonucu değişmedi (ekran testleri).
- [ ] Bir alt ekrandan dönünce sayfa aynı kaydırma konumunda; açık sekmeye tekrar dokununca en üste kayıyor.
- [ ] Koyu/açık tema, iPhone SE, iPhone, iPad (dikey/yatay) ekran görüntülerinde taşan ya da kesik başlık yok.
- [ ] Erişilebilirlik denetiminde yeni bulgu yok; büyük yazı testinde başlıklar okunur.

## Kapsam dışı

- Giriş / hesap (Misafir, Apple, Google): `hesap.md`, ayrı iş.
- Ana sayfanın üst satırı, tur ekranlarının üst kısmı.
- Sorulardaki "Sıradaki / Devam" metinleri (Ceren: boşver).
- Alt menünün (sekme çubuğu) kendisi.

## Etkilenen dosyalar (tahmini)

- `ios-native/Solvato/AppRoot.swift`: gezinme Apple'ın `NavigationStack`'ine geçer (sekme başına yığın, yol
  `AppModel.nav`'dan); kendi kenardan kaydırma hareketi alt ekranlar için kalkar, turlar için (çıkış onayı) kalır.
- `ios-native/Solvato/UI/Shell.swift` (`ScreenHeader`, `BackButton`), `UI/PercentRing.swift` (`TabTitle`),
  `UI/SystemTabs.swift`; çubuk görünümü (Outfit, renkler) için yeni bir `UI/NavigationBarStyle.swift`.
- Ekranlar: `ProgressScreen` (paylaş düğmesi, kartın düğmesi kalkar), `ProfileScreen` (Tüm ilerleme kalkar, dişli
  araç çubuğuna), `StudyScreen`, `SettingsScreen`, `NotesSettingsScreen`, `TeacherScreen`, `LegalScreen`,
  `GamesScreen`, `ChordDuelScreen` (kurulum), dersler.
- `ios-native/SolvatoCore/App/ScreenStack.swift` (geri hedefinin adı: "‹ Profil" için), testleri.
- `ios-native/SolvatoUITests/` (geri düğmesi adları değişirse: "Geri" → "Profil" gibi), `ui-testleri.txt`.
- `docs/ozellikler/native-ios.md` (Bilinçli farklar), `docs/ozellikler/gezinme.md`, README.

## Gizlilik etkisi

Yok. Paylaşım bugünkü gibi sistemin paylaşım menüsüyle; uygulama hiçbir yere bir şey göndermez.
