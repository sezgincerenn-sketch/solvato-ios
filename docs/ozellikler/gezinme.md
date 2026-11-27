# Gezinme, Ana sayfa, İlerleme ve Profil

Durum: **onaylandı (25 Kasım 2026)**, native'de uygulandı (26 Kasım 2026). İşaretli ölçütler çekirdek testleriyle doğrulandı; ekran ölçütleri Codemagic simülatör görüntüleriyle kapanacak. Yalnız native iOS'a yazılır (`ios-native/`). Kapsadığı revizeler
(`docs/ozellikler/tasarim-revize.md`): R3, R13, R14, R15, R18, R19, R20, R23, R24, R25, R26 ve R5'in Profil tarafı.
Tanıtımdaki değişiklikler (R5 soru adımı, R9, R12, R27, R28, R29) ayrı dokümanda.

**Başvuru:** davranışın çalışan hâli web'deki revize önizlemesinde
(https://claude.ai/artifact/LpuacK4CoaKn3vT7gmNQzm; kod `revize-onizleme` dalında, 1. ve 2. grup kayıtları). Çizimler
revize tuvalinde (https://claude.ai/artifact/SdkZ6penhSPigESECB5rYY). Native, önizlemedeki ölçü, metin ve davranışı
izler; tek fark alt menünün iOS 26'da gerçek cam olması.

## Amaç

Uygulamanın dört ana bölümü alt menüden tek dokunuşla açılsın; Profil ve öğretmen kodu kolay bulunsun; Ana sayfa ve
İlerleme daha az kafa karıştırsın (neye basılır, neyi gösterir).

## Kullanıcı ne görür

- **Değişti (Ceren, 27 Kasım; `gezinme-cubugu.md`):** üstteki başlık ve geri/Ayarlar düğmeleri Apple'ın gezinme
  çubuğu (büyük başlık, "‹ Profil" geri düğmesi). İlerleme'de haftalık rapor sağ üstteki paylaş simgesinden (Bu hafta
  kartında düğme yok); Profil'de "Tüm ilerleme" kalktı.
- **Değişti (Ceren, 26 Kasım):** Seri, Tamamlanan tur, Çözülen soru kutuları Profil'den İlerleme'ye taşındı (başlığın ve
  Başlangıç kartının altında, Doğruluk kartının üstünde).

### Alt menü (R13)

- **Değişti (Ceren, 26 Kasım):** kendi kapsülümüz yerine **Apple'ın sekme çubuğu** (`UI/SystemTabs.swift`): iOS 26'da gerçek
  Liquid Glass ve seçili sekmede kayan cam, Apple simgeleri (ev, grafik, kitap, kişi), mor vurgu; iOS 17–25'te klasik
  sekme çubuğu. Kaydırınca küçülmez, açık sekmeye tekrar dokununca sayfa en üste kayar. Aşağıdaki kapsül ölçüleri artık
  geçerli değil (web önizlemesinde kapsül kalır).

- Ekranın altında, kenarlardan 16 pt içeride **yüzen kapsül**. Dört sekme, soldan sağa: **Ana sayfa · İlerleme ·
  Öğren · Profil**. Simgeler: ev, sütun grafiği, kitap, kişi (çizgi simgeler, 22 pt).
- Seçili sekme mor zeminli (kapsül içinde ikinci bir yuvarlak), simge ve yazı mor; diğerleri soluk.
- **Cam görünüm (karar: 1. yol):** kapsül uygulamanın kendi çizimidir (ölçüler web önizlemesiyle aynı).
  - iOS 26 ve üstü: zemin Apple'ın cam efekti (`glassEffect`, kapsül biçiminde, dokunuşa tepki veren türü).
  - iOS 17–25: aynı kapsül, bulanık yarı saydam zemin (sistem materyali) ve ince kenar; cam kırılması yok.
- Kaydırınca menü **küçülmez**, hep aynı boyutta durur (Ceren'in kararı).
- Açık sekmeye **tekrar dokununca** o sayfa en üste kayar (Ceren'in kararı). Başka sekmeye dokununca yığın sıfırlanır
  (bugünkü gibi).
- Menü yalnız dört sekme ekranında görünür; turlar, dersler, Ayarlar, Oyunlar, öğretmen kodu ekranlarında görünmez
  (bugünkü gibi).
- Sayfaların en altındaki içerik kapsülün altında kalmaz: kaydırma alanının sonunda kapsül kadar boşluk bırakılır.

### Ana sayfa

- **Üst bant (R15):** logo; sağda seri hapı ve XP hapı. **Avatar kalkar** (Profil artık sekme).
  - Seri hapı **basılmaz**, yalnız bilgi verir (erişilebilirlik: "5 gün seri" / "Seri yok. Bugün bir tur çözünce
    başlar").
  - XP hapına dokununca Profil sekmesi açılır.
- **Bugün kartı:**
  - Porte yerine **10 bölmeli çubuk** (R18). Her bölme hedefin onda biri (hedef 20 → bölme 2 soru, 50 → 5 soru);
    dolu bölme mor, hedef tamamlanınca bütün bölmeler yeşil. Erişilebilirlik: "20 soruluk hedefin 12 sorusu çözüldü".
  - Sağ üstte bugünkü gibi "12/20 soru" (tamamsa "Hedef tamam · 20/20 soru").
  - Düğme başlığı bugünkü gibi ("Bugünün çalışması" / "Devam et" / "Bir tur daha"); alt yazı (R3):
    **"Karma · 10 soru · ~3 dk"**, öğretmen konu seçtiyse **"Karma · 10 soru · ~3 dk · öğretmeninin konuları"**.
- **Oyunlar kartı:** bugünkü gibi.
- **Konu kartları (R19):** sağdaki yıldız ve ▶ yerine **yüzde halkası** (44 pt): o konudaki doğruluk oranı kadar konu
  renginde dolu, ortasında "%80". Hiç çözülmemişse boş halka ve soluk "–". Kartın tamamı yine basılır ve turu başlatır.
  - Akor satırı akor doğruluğunu, Ritmi Tut satırı Ritim doğruluğunu gösterir (Ritmi Tut hiç oynanmadıysa boş halka).
  - Diyez & Bemol: diyezli/bemollü nota konumlarının toplam doğruluğu.
- **Öğretmen kodu varken:** bugünkü gibi öğretmenin konuları üstte, diğerleri "Diğer konular (N)" altında. Öğrenci
  Profil'de "Diğer konuları da göster"i açtıysa bu grup Ana sayfa her açıldığında açık gelir (R20).

### İlerleme

- Üstte büyük başlık **"İlerleme"** (R23), Öğren sekmesindeki başlıkla aynı ölçü. Boş durumda da var.
- **"Öğrenme yolu / Sıradaki" kartı kalkar** (R24), hem boş durumda hem dolu durumda.
- **Konular kartı:**
  - "Konular" başlığının altındaki çizgi kalkar: ilk satırın üst çizgisi yok, sonraki satırlar arasında çizgi var
    (R26).
  - Her satırın sağındaki "›" yerine küçük mor hap **"Çalış ▶"** (R25). Satırın tamamı basılır ve o konuda tur başlar
    (bugünkü gibi).
- Diğer kartlar bugünkü sırayla: Doğruluk, Bu hafta, Konular, Zorlandığın notalar, Son turlar.

### Öğren

- Sekme ve sayfa başlığının adı **"Öğren"** (eski Çalışma). İçerik değişmez.

### Profil

- Sekme ekranı: başlık "Profil", **geri oku yok**, sağ üstte Ayarlar dişlisi (R14). Kaydırarak geri gitme yok.
- **Alttaki "Ayarlar" düğmesi kalkar** (R14). "Haftalık raporu öğretmenine gönder" ve "Tüm ilerleme" kalır.
- **Öğretmen kodu kartı** (R14, R20, R5): avatar kartının hemen altında. Dokununca öğretmen kodu ekranı açılır.
  - Kod uygulanmamışsa başlık ve alt yazı tanıtımdaki seçime göre:
    - Öğretmenim var: **"Öğretmen kodunu gir"** · "Öğretmeninin gönderdiği kodu yaz"; kart mor çerçeveyle öne çıkar.
    - Ben öğretmenim: **"Öğrenci kodu hazırla"** · "Öğrencilerine konu, seviye ve hedef gönder"; kart öne çıkar.
    - Kendi kendime ya da tanıtım atlandıysa: "Öğretmen kodu" · "Öğretmeninin kodunu gir ya da öğrencine kod hazırla".
  - Kod uygulanmışsa: "Öğretmen kodu" · "Uygulandı · K7M-2QX", altında "Öğretmeninin konuları Ana sayfada üstte.
    Diğer konuları da açık tutabilirsin." ve iki düğme:
    - **"Diğer konuları da göster"** (açıkken "Diğer konular açık ✓"): Ana sayfadaki "Diğer konular" grubu açık gelir.
    - **"Kodu kaldır"** (kırmızı yazı): **yalnız öğretmenin konu seçimi kalkar** (Ceren'in kararı); kodun ayarladığı
      seviye, hedef, notalar ve anahtar olduğu gibi kalır. Kod satırı silinir, "Öğretmen kodu kaldırıldı" bildirimi.
- **Ayarlar:** "Öğretmen kodu" satırı Ayarlar'dan kalkar (artık Profil'de).

## Kurallar ve sınır durumları

- **Yeni ayarlar** (mevcut ayar nesnesinin içinde; depolama anahtarı değişmez, CLAUDE.md "anahtarları yeniden
  adlandırma"): `showRestTopics` (bool, varsayılan false), `teacherRole` ("" | "student" | "self" | "teacher",
  varsayılan ""; tanıtım dokümanında yazılır, burada yalnız okunur). Eski kayıtlarda yoksa varsayılan kullanılır.
- **Yüzde hesabı:** `round(doğru / toplam × 100)`; toplam 0 ise boş halka. Seviye ve öğretmen kısıtı halkayı
  etkilemez.
- **Ünvan/seviye kartı, XP:** değişmez.
- **iPad:** kapsül ortada, en fazla bugünkü sütun genişliğinde; dört sekme aynı. İki sütunlu İlerleme düzeni
  korunur, başlık iki sütunun üstünde.
- **Koyu/açık tema:** kapsül, halka ve hap renkleri tasarım sistemindeki değerlerden (ham renk yok); iki temada da
  okunur.
- **Hareketi azalt / Saydamlığı azalt:** saydamlık azaltılmışsa kapsül düz zeminli olur (sistem davranışı).
- **VoiceOver:** sekmeler "Ana sayfa, sekme, 1/4"; seçili sekme "seçili". Halkalar "Yüzde 80 doğru" / "Henüz
  çözülmedi". Seri hapı düğme değil, yalnız okunur.
- **İpucu turu:** son adımın metni "İlerleme, Öğren ve Profil: Gelişimini İlerleme'de gör, notaları Öğren'de çalış;
  öğretmen kodu ve ayarlar Profil'de." Sıralama değişikliği (R29) tanıtım dokümanında.

## Kabul ölçütleri

- [ ] Alt menüde dört sekme, sırası ve adları: Ana sayfa · İlerleme · Öğren · Profil; seçili sekme mor zeminli.
- [ ] iOS 26 cihazda/simülatörde kapsül cam efektli; iOS 17 simülatöründe bulanık zeminli kapsül (iki ekran görüntüsü).
- [ ] Kaydırınca menü boyutu değişmiyor; sayfa sonundaki içerik menünün altında kalmıyor.
- [ ] Açık sekmeye tekrar dokununca sayfa en üste kayıyor; başka sekmeye geçince yığın sıfırlanıyor.
- [ ] Ana sayfada avatar yok; seri hapına dokununca hiçbir şey olmuyor; XP hapı Profil sekmesini açıyor.
- [x] Bugün çubuğu: hedef 10/20/30/50 için dolu bölme sayısı `floor(min(çözülen, hedef) × 10 / hedef)`; hedef
      tamamsa 10 bölme yeşil.
- [x] Düğme alt yazısı öğretmen konusu yokken "Karma · 10 soru · ~3 dk", varken "… · öğretmeninin konuları".
- [ ] Dokuz konu satırının hepsinde yüzde halkası; çözülmemiş konuda "–"; yıldız ve ▶ yok.
- [ ] İlerleme'de "İlerleme" başlığı var, öğrenme yolu kartı yok (boş ve dolu durumda).
- [ ] Konular'da ilk satırın üstünde çizgi yok; her satırda "Çalış ▶"; satıra dokununca o konuda tur.
- [ ] Profil'de geri oku yok, alt "Ayarlar" düğmesi yok; Ayarlar'da "Öğretmen kodu" satırı yok.
- [x] Öğretmen kodu kartının başlığı tanıtım seçimine göre (üç durum + kodlu durum) yukarıdaki gibi.
- [ ] "Diğer konuları da göster" açıkken Ana sayfada "Diğer konular" grubu açık geliyor; uygulama yeniden açılınca da.
- [x] "Kodu kaldır": konu seçimi kalkıyor, seviye/hedef/notalar değişmiyor, Ana sayfa "Pratik Kategorileri" düzenine
      dönüyor.
- [ ] Koyu ve açık temada, iPhone SE ve iPad'de taşma yok (ekran görüntüleri).
- [x] Çekirdek testleri: halka yüzdesi, bölme sayısı, kart başlığı seçimi ve "Kodu kaldır" sonrası ayarlar.

## Kapsam dışı

- Tanıtım adımları (R5 soru, R9, R12, R27, R28, R29): ayrı doküman.
- Turlar (R2, R8, R16, R22) ve kodlar (R30, R31, R32): ayrı doküman ya da küçük işler.
- Apple'ın hazır sekme çubuğu (TabView) kullanımı ve kaydırınca küçülme.
- Android ve web sürümü (web önizlemesi yalnız başvuru).

## Etkilenen dosyalar (tahmini)

- `SolvatoCore/App/ScreenStack.swift`: `profile` sekme ekranı olur (yığını sıfırlar, kaydırarak geri yok).
- `SolvatoCore/Logic/Settings.swift`: `showRestTopics`, `teacherRole` alanları (okuma/yazma, varsayılanlar).
- `SolvatoCore/App/HomeContent.swift`, `ProgressContent.swift`, `ProfileSettingsContent.swift`: halka yüzdeleri,
  bölme sayısı, alt yazı, kart başlıkları; testleri.
- `Solvato/UI/Shell.swift` (`NavBar`): kapsül, dört sekme, cam/yedek zemin, ikinci dokunuşta en üste kaydırma.
- `Solvato/AppRoot.swift`: sekme düzeni, menünün göründüğü ekranlar, kaydırma alanlarına alt boşluk.
- `Solvato/Screens/HomeScreen.swift`, `ProgressScreen.swift`, `ProfileScreen.swift`, `SettingsScreen.swift`,
  `StudyScreen.swift`; yeni küçük parçalar: yüzde halkası, hedef çubuğu, sekme başlığı.
- `docs/ozellikler/native-ios.md` (E-04, E-10, E-11, E-12, E-15, G-10), `README.md`, UI test senaryoları
  (`SolvatoUITests/senaryolar.json`).

## Gizlilik etkisi

Yok. Yeni veri yalnız telefondaki ayarlara yazılır; ağ isteği yok.
