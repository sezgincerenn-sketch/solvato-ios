# Kullanıcı testi revizeleri (28 Kasım)

Durum: **taslak, Ceren'in cevaplarıyla yazıldı (28 Kasım 2026)**. Yalnız native iOS (`ios-native/`). Kaynak: kapalı
test (yüz yüze) notları. Bitince `inceleyici` ajanının karşılaştıracağı ölçüttür. Her madde ayrı commit olabilir.

**Vazgeçilen:** sekme başlıklarının (İlerleme, Öğren, Profil) büyükten küçüğe geçişi bugünkü gibi kalır (Ceren: "bu
revizeden vazgeçtim").

**Bilinçli farklar:** bu revizeler React sürümünden ayrılır; bitince `native-ios.md` "Bilinçli farklar"a yazılır.

## Amaç

İlk kullanımda takılan yerleri gidermek (tanıtım, Ritmi Tut, seri, yan çevirme), Solfado adına geçmek ve öğrenciye
emeğini gösteren küçük eklemeler (toplam çalışma süresi, yardım ekranı).

## Kullanıcı ne görür

### 1. Ad: Solfado

- Uygulamanın görünen adı her yerde **Solfado**: ana ekrandaki simgenin altı, açılış ve Ana sayfa logosu, tanıtım
  metinleri ("Solfado, piyano öğrencileri için…"), paylaşım mesajları ("Solfado'yu App Store'dan indir: …"), haftalık
  rapor, meydan okuma ve öğretmen kodu mesajları, Gizlilik ve Lisanslar metinleri, gizlilik/destek sitesi, bildirim
  metinleri, VoiceOver adları.
- Türkçe ekler sözcüğe uyar: "Solfado'yu", "Solfado'da", "Solfado'nun".
- Maskotun adı **Solfie** kalır.
- Değişmeyenler (kullanıcı görmez): uygulama kimliği `com.solvato.app` (App Store kaydına bağlı), depo adları, kod ve
  klasör adları (`Solvato`, `SolvatoCore`), kayıt anahtarları (eski adlar bilerek korunur), App Store Apple ID.
- App Store Connect'teki ad ve açıklama Ceren tarafından elle değiştirilir (uygulama dışı; özet bunu hatırlatır).

### 2. Tanıtım

**İlk ekran (giriş)**

- Başlık cümlesi tamamlanır: **"Her gün birkaç dakikayla nota okumak kolaylaşsın."**
- Dört kutu (Nota okuma, Ritim, Akor, Kulak) kalkar; yerine basılacakmış gibi görünmeyen **simgeli düz liste**: dört
  satır, solda renkli simge, yanında ad (çerçeve, zemin ve gölge yok). VoiceOver tek öğe olarak okur: "Nota okuma,
  ritim, akor ve kulak çalışmaları".
- Ad sorusu bu ekrana taşınır (ayrı "Merhaba" adımı kalkar): listenin altında "Adın (isteğe bağlı)" kutusu, en altta
  **Başla**.

**Do ve Sol denemeleri**

- Doğru tuşa basınca "Doğru! Bu nota Do." görünür ve **1 saniye sonra kendiliğinden** sonraki adıma geçilir ("Devam"
  düğmesi yok).
- Yanlış tuşa basınca uyarı ("Bu Mi. Do'yu bul." gibi bugünkü metin) **ekranda kalır**; yalnız yeni bir tuşa basınca
  değişir.

**Adımlar birleşir (9 → 6)**

1. Giriş + ad
2. Do denemesi
3. Sol denemesi
4. Öğretmen sorusu (bugünkü gibi; "Ben öğretmenim" seçilirse tanıtım burada biter)
5. **Ayarların**: tek ekranda anahtar (Sol / Fa / İkisi de), seviye (üç seçenek), günlük hedef ve hatırlatma (aç/kapa +
   saat satırı). Ekran kaydırılabilir; en altta **Devam**. Hatırlatma açıksa bildirim izni Devam'a basınca istenir.
6. Hazırsın (bugünkü gibi)

- Üstteki adım noktaları 6'ya iner; geri oku ve "Atla" bugünkü gibi.

### 3. Ana sayfa › seri hapı

- Sağ üstteki seri hapına (alev ve sayı) dokununca hapın altında **kısa balon** açılır, 3 saniye sonra ya da başka
  yere dokununca kapanır:
  - Seri varsa: **"5 günlük seri. Her gün günlük hedefini tamamlayınca 1 artar."**
  - Seri yoksa: **"Bugün hedefini tamamlayınca serin başlar."**
- VoiceOver: hap düğme olur, adı bugünkü ("5 gün seri"), ipucu "Seri hakkında bilgi"; balon açılınca metni duyurulur.

### 4. Günün meydan okuması: günde bir kez

- Bugün oynandıysa Oyunlar › **Günün meydan okuması** sayfasında "Oyna" yerine **bugünkü sonuç**: doğru sayısı (6/10),
  süre, 10 kare (doğru/yanlış), **"Sonucu paylaş"** düğmesi ve altında **"Yeni meydan okuma yarın"**.
- Oyunlar listesindeki satır ve Ana sayfadaki Oyunlar kartı bugünkü gibi "Oynandı" durumunu gösterir.
- Sayfadaki açıklama metni değişir: "Herkes bugün aynı 10 soruyu çözüyor. Günde bir kez oynanır. Bitince sonucunu
  arkadaşlarına gönder, kim daha iyi yapmış görün."
- Gece yarısı (telefonun saatiyle) yeni meydan okuma açılır.

### 5. Karma turda yan çevirme

- Soru turu telefonda yan çevrilmişken **her soru tipi** yan düzende düzgün görünür: solda soru (porte, ritim, terim,
  kulak "Dinle"), sağda cevaplar (klavye ya da şıklar). Piyano sorusundan sonra gelen şıklı soru da yan düzende kalır,
  ekran taşmaz ve kaymaz.
- Dik çevrilince bugünkü dik düzen. Akor turu da aynı kurala uyar.

### 6. Akor soruları: açılınca ses

- Akor turunda ve karma turdaki akor sorularında her soru açıldığında **akor bir kez çalınır** (Ayarlar › Ses kapalıysa
  çalmaz). "Dinle" düğmesi bugünkü gibi kalır, tekrar çalar.

### 7. Ritmi Tut: başlatma

- Tur başlamadan dokunma alanında **"Başlamak için dokun"** yazar; alana dokunmak turu başlatır (Başla düğmesiyle aynı).
- Başla düğmesi bugünkü yerinde kalır. Tur başlayınca alan bugünkü gibi vuruş alır.

### 8. İlerleme › toplam çalışma süresi

- Üstteki üç kutu: **Toplam süre · Tamamlanan tur · Çözülen soru** (Seri kutusu kalkar; seri altta Bu hafta kartında).
- Toplam süre = öğrencinin uygulamada **çalıştığı süre**: soru turları, akor turu, Ritmi Tut, oyunlar (günün meydan
  okuması, arkadaşına meydan oku, akor düellosu) ve **derslerde** geçen süre. Ana sayfa, İlerleme, Ayarlar gibi
  ekranlarda geçen süre sayılmaz; uygulama arka plandayken sayılmaz.
- Görünüm: 1 saatin altında **"35 dk"**, üstünde **"2 sa 15 dk"**; 1 dakikanın altında "0 dk".
- Başlangıç: güncellemeden önce kaydedilmiş son turların süreleri eklenerek başlar (eski kullanıcıda gerçekten
  biraz az olabilir); sonra her çalışma eklenir.
- İlerlemeyi sıfırla toplam süreyi de sıfırlar. Öğretmen yedeği / dışa aktarma varsa toplam süre de içinde.

### 9. Profil › renk seçimi kalkar

- Profil kartındaki altı renkli daire kalkar. Profil resmi hep **mor** (bugünkü varsayılan), içinde ismin baş harfi
  (isim yoksa nota simgesi).
- Daha önce başka renk seçmiş kullanıcının resmi de mor olur.

### 10. Ayarlar › Yardım ve destek

- Ayarlar › Diğer kartına **"Yardım ve destek"** satırı (Gizlilik'in üstünde). Dokununca alt ekran açılır: başlık
  "Yardım ve destek", "‹ Ayarlar" geri düğmesi.
- İçerik: kısa **sık sorulan sorular** (açılır-kapanır satırlar). İlk liste (metinler uygulamadan önce Ceren'e gösterilir):
  - Günlük hedef ve seri nasıl işler?
  - Seviyem nasıl yükselir?
  - Öğretmen kodu nedir, nasıl kullanılır?
  - Haftalık raporu öğretmenime nasıl gönderirim?
  - Ses gelmiyor, ne yapmalıyım? (Ayarlar › Ses ve telefonun sessiz anahtarı)
  - Verilerim nerede, silinir mi? (yalnız bu telefonda; İlerlemeyi sıfırla)
- En altta **"Bize yaz"**: telefonun Mail uygulamasını destek adresiyle açar (konu: "Solfado destek", gövdede sürüm
  numarası). Uygulama kendisi bir şey göndermez. Mail kurulu değilse adres kopyalanır ve "E-posta adresi kopyalandı"
  bildirimi çıkar.
- **Açık:** destek e-posta adresi Ceren'den gelecek; adres gelmeden "Bize yaz" eklenmez.

### 11. Akor düellosu › oyuncu adları

- Kurulumdaki iki ad kutusu **boş** gelir; "1. oyuncu" ve "2. oyuncu" yalnız soluk yer tutucu yazıdır, kutuya dokunup
  hemen yazılabilir.
- Ad boş bırakılırsa oyunda ve sonuçta "1. oyuncu" / "2. oyuncu" kullanılır (bugünkü varsayılan adlar).

### 12. Paylaşım: WhatsApp'ta metin kaybolmasın

- Kod, sonuç ve haftalık rapor paylaşımında WhatsApp'ı paylaşım menüsünün uygulama satırından seçip içeriden kişi
  seçince de **metnin tamamı** (kod, açıklama, App Store bağlantısı) gider; yalnız bağlantı gitmez.
- Diğer uygulamalarda (Mesajlar, Mail, Notlar, Kopyala) bugünkü gibi tam metin.

## Kurallar ve sınır durumları

- Koyu ve açık tema: yeni parçalar (seri balonu, SSS ekranı, tanıtım listesi, günlük sonuç) iki temada da okunur.
- Büyük yazı: seri balonu, SSS ve tanıtımın Ayarların ekranı xxxLarge'da taşmaz (kaydırılabilir).
- iPad: yeni ekranlar 680 pt sütunda; tanıtımın Ayarların ekranı da.
- VoiceOver: seri balonu duyurulur; SSS satırları "daraltılmış / genişletilmiş" okunur; tanıtım listesi tek öğe.
- Hareketi azalt: tanıtımda otomatik geçiş ve seri balonu canlandırmasız.
- Çevrimdışı: hiçbir madde ağ gerektirmez ("Bize yaz" yalnız Mail'i açar).
- Ses kapalı: akor sesi çalmaz; Ritmi Tut'ta bugünkü kural.
- Günün meydan okumasının kaydı bugünkü yerinde; daha önce aynı gün iki kez oynamış kullanıcıda ilk deneme gösterilir.

## Kabul ölçütleri

- [ ] Simgenin altında, açılışta, Ana sayfa logosunda, tanıtımda, paylaşım mesajlarında, Gizlilik/Lisanslar'da ve sitede
      "Solfado" yazıyor; kullanıcıya görünen hiçbir yerde "Solvato" yok (çekirdek testi metinleri tarar).
- [ ] Solfie adı değişmedi; kayıt anahtarları ve uygulama kimliği değişmedi (eski veriler yerinde).
- [ ] Tanıtımın ilk ekranında kutu yok, simgeli liste ve tam cümle var; ad kutusu bu ekranda.
- [ ] Do ve Sol denemesinde doğru tuştan 1 sn sonra kendiliğinden ilerliyor; yanlış tuş uyarısı yeni tuşa kadar kalıyor.
- [ ] Tanıtım 6 adım; anahtar, seviye, hedef ve hatırlatma tek ekranda; öğretmen yolu 4. adımda bitiyor.
- [ ] Seri hapına dokununca doğru metinle balon açılıyor, 3 sn sonra kapanıyor.
- [ ] Günün meydan okuması oynandıysa "Oyna" yok; bugünkü sonuç, "Sonucu paylaş" ve "Yeni meydan okuma yarın" var.
- [ ] Yan çevrilmiş karma turda piyano sorusundan sonra şıklı, ritim ve kulak soruları yan düzende taşmadan görünüyor.
- [ ] Akor sorusu açılınca akor bir kez çalıyor; Ses kapalıyken çalmıyor.
- [ ] Ritmi Tut'ta tur başlamadan alanda "Başlamak için dokun" yazıyor; dokununca tur başlıyor.
- [ ] İlerleme'de Toplam süre · Tamamlanan tur · Çözülen soru; süre turlarda ve derslerde artıyor, diğer ekranlarda
      artmıyor; "35 dk" / "2 sa 15 dk" biçimi (çekirdek testi).
- [ ] Profil'de renk seçimi yok; profil resmi mor.
- [ ] Ayarlar'da Yardım ve destek satırı ve SSS ekranı var; "Bize yaz" Mail'i açıyor (adres geldikten sonra).
- [ ] Düello kurulumunda ad kutuları boş, yer tutucu soluk; boş bırakılınca oyunda "1. oyuncu".
- [ ] WhatsApp'ta uygulama içinden kişi seçince metnin tamamı gidiyor (TestFlight'ta elle denenir).
- [ ] Koyu/açık tema, iPhone SE, iPhone, iPad ekran görüntülerinde yeni parçalar taşmıyor; erişilebilirlik denetiminde
      yeni bulgu yok.

## Kapsam dışı

- Sekme başlıklarının davranışı (vazgeçildi).
- Giriş / hesap (`hesap.md`).
- App Store Connect'teki ad, açıklama ve ekran görüntüleri (Ceren elle).
- Android (dondurulmuş).
- Destek e-posta adresi gelene kadar "Bize yaz".

## Etkilenen dosyalar (tahmini)

- Ad: `ios-native/project.yml` (`CFBundleDisplayName`), `UI/Logo.swift`, `Screens/SplashScreen.swift`,
  `SolvatoCore` metinleri (`AppStoreLink`, `WeeklyReport`, oyun/öğretmen paylaşım metinleri, `Resources/hukuk.json`),
  bildirim metni (`Reminder.swift`), `scripts/site.mjs` / `site/`, altın tablolar (paylaşım metinleri), README.
- Tanıtım: `SolvatoCore/App/OnboardingFlow.swift` (adımlar), `Screens/OnboardingScreen.swift`, testleri, `tanitim.md`.
- Seri balonu: `Screens/HomeScreen.swift`, `SolvatoCore` metin (`HomeContent` ya da `AccessibilityText`).
- Günün meydan okuması: `Screens/GamesScreen.swift`, `SolvatoCore/App/GameScreensContent.swift`.
- Yan çevirme: `Screens/QuizScreen.swift` (yan düzen tüm soru tipleri), `ChordQuizScreen.swift`.
- Akor sesi: `ChordQuizScreen.swift`, `QuizScreen.swift` (akor soruları).
- Ritmi Tut: `Screens/RhythmTapScreen.swift`.
- Toplam süre: `SolvatoCore/Logic/Stats.swift` (yeni alan, yeni anahtar `solvato_` önekli ya da istatistik içinde),
  `Progress` tur sonu, ders süresi (`LessonScreen`), `ProgressScreen` (kutular), `ProgressContent` (biçim), testleri.
- Profil rengi: `Screens/ProfileScreen.swift`, `UI/Shell.swift` (`Avatar`).
- Yardım ve destek: yeni `AppView.help`, `Screens/HelpScreen.swift`, metinler `SolvatoCore` (`HelpContent`),
  `SettingsScreen.swift`.
- Düello: `Screens/ChordDuelScreen.swift`, `DuelGame` (boş ad → varsayılan).
- Paylaşım: `UI/AppButton.swift` (paylaşım öğesi), `ProfileScreen` ve `ProgressScreen` paylaşımları.
- `docs/ozellikler/native-ios.md` (Bilinçli farklar), `docs/URUN.md` (ad), `ui-testleri.txt`.

## Gizlilik etkisi

Yok. Toplam süre yalnız telefonda saklanır. "Bize yaz" Mail uygulamasını açar; uygulama hiçbir yere bir şey göndermez.
Gizlilik metnindeki ad Solfado olur (metin içeriği değişmez).
