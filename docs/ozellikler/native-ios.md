# Native iOS: özellik envanteri ve kabul ölçütleri

Paket 0, aşama 0.1 (`docs/PLAN.md`). Bugünkü React uygulamasının (`src/`) her ekranı, her kuralı ve her sistem
davranışı burada listelenir. Native (Swift/SwiftUI) sürüm bu listeyle **birebir** aynı olduğunda kabul edilir.
`inceleyici` ajanı 0.9'da bu dokümana göre karşılaştırma yapar.

## Amaç

Mac'i ve kodu olmayan Ceren için tek bir ölçüt: "native sürüm bugünkü uygulamanın yaptığı her şeyi, aynı görünüşle
yapıyor mu?" Bu doküman o sorunun maddeler halindeki cevabı. Her aşama (0.2–0.8) buradaki maddelerden kendi payını
alır ve bitince işaretler.

## Nasıl kullanılır

- **Başvuru kaynağı kod ve görüntülerdir.** Bu doküman bir harita: ne var, nerede, hangi kurala uymalı. Piksel ölçüleri,
  renk değerleri ve uzun metinler kaynak dosyada; her maddede dosya yazılı. Metinler oradan **harfi harfine** alınır.
- **Referans görüntüler:** `node scripts/referans.mjs` her ekranın her durumunu iPhone (390×844) ve iPad (1024×1366),
  koyu ve açık temada çeker (`ekran/referans/`, git'e girmez). Tarih (18 Kasım 2026, Çarşamba 10:00) ve rastgelelik
  sabit: aynı komut her seferinde aynı görüntüleri verir. Native UI testleri aynı durumların görüntüsünü aynı adla
  üretir; ikisi yan yana karşılaştırılır. Senaryo adları aşağıda her ekranın **Görüntü** satırında.
- **Altın tablolar (0.3'te):** mantık kuralları için React kodundan üretilen girdi/çıktı tabloları (JSON). Native birim
  testleri aynı girdiyle aynı çıktıyı vermeli. Hangi tabloların üretileceği "Altın tablolar" bölümünde.
- **Kabul ölçütü işaretleme:** madde native'de bitince `- [ ]` → `- [x]` yapılır ve commit mesajında madde numarası
  (ör. `K-07`, `E-12`) geçer.
- Fark gerekiyorsa (iOS'ta mümkün değil, ya da hata düzeltmesi) önce Ceren'e sorulur ve buraya "Bilinçli farklar"
  bölümüne yazılır.

## Genel kurallar

### G-01 Platform

- iPhone ve iPad, en düşük iOS 17. Swift + SwiftUI, yalnızca Apple çatıları; web görünümü ve üçüncü taraf kod yok.
- Uygulama kimliği `com.solvato.app`, görünen ad **Solvato**, sürüm metni Ayarlar'ın altında "Sürüm 1.0".
- Ağ isteği yok (App Store: "Data Not Collected"). Native'de `URLSession` kullanılmaz.

### G-02 Yön

- iPhone: dikey kilitli; **yalnızca soru turu ve akor turu** ekranlarında yan çevrilebilir (`utils/orientation.ts`
  `allowLandscape`). Yan ekranda soru ekranı iki sütun olur (solda soru, sağda klavye/şıklar).
- iPad: her ekran her yönde. Soru ekranında iki sütun iPad yatayda da açılır (`useTwoColumn`).
- Kabul:
  - [ ] iPhone'da Pratik, İlerleme, Çalışma, Ayarlar yan çevrilince dönmüyor.
  - [ ] iPhone'da soru turu ve akor turu yan çevrilince iki sütuna geçiyor; klavye 3 oktav oluyor.
  - [ ] iPad'de bütün ekranlar dört yönde çalışıyor.

### G-03 Düzen genişlikleri

- iPhone: tam ekran. iPad: içerik ortada, en geniş 1100 pt. Alt ekranlar (Ayarlar, Profil, Oyunlar, sonuç, Ritmi Tut,
  öğretmen kodu, Gizlilik/Lisanslar) iPad'de en fazla 680 pt; Çalışma ve dersler 820 pt (`ui/TabletColumn.tsx`).
- iPad'de Pratik konu kartları iki sütun, İlerleme kartları iki bağımsız sütun (solda Doğruluk · Sıradaki ·
  Zorlandığın notalar; sağda Bu hafta · Konular · Son turlar).
- Güvenli alan (çentik, ana ekran çubuğu) her ekranda korunur.

### G-04 Tema

- Üç seçenek: Sistem / Koyu / Açık (`state/theme.ts`, varsayılan Sistem). Sistem seçiliyken telefonun teması
  değişince uygulama anında değişir. Üst durum çubuğu temaya uyar.
- Renkler `src/design/tokens.ts` + `tokens.css` (iki tema). Native'de aynı adlarla bir renk kataloğu (Asset Catalog,
  Any/Dark) kurulur; ham renk yazılmaz.
- Kabul:
  - [ ] Her referans görüntü koyu ve açık temada React görüntüsüyle aynı renkleri taşıyor.

### G-05 Yazı tipleri ve semboller

- Arayüz yazısı **Outfit**, sayılar ve kodlar **JetBrains Mono** (`@fontsource`), nota sembolleri **Bravura**
  (SMuFL). Üçü de uygulamaya gömülür; lisansları Lisanslar sayfasında (`src/data/legal.ts`).
- Semboller web'de Bravura'dan çıkarılmış SVG yolları (`src/data/smufl.ts`). Native de **aynı yolları** kullanır
  (`scripts/altin.mjs` → `Resources/smufl.json`, bir kez okunup saklanır): yazı tipi gömmeye göre görünüş birebir
  tutar, uygulama küçük kalır, hızı aynı. Görünüş aynı: aynı boyut, aynı konum (0.4, 22 Kasım).
- Ölçüler `tokens.ts`: `radius xs4 sm8 md12 lg20 pill`, `space` 4'ün katları, yazı boyları `12/14/16/20/24/32`,
  ağırlıklar 400–800.

### G-06 Animasyon

- Ortak animasyonlar `src/index.css`: sallanma (yanlış, 0,44 sn), doğru nabzı (0,52 sn), aşağıdan kayma (0,38 sn),
  belirme (0,3 sn), seri alevi (0,7 sn), konfeti, kutlama kartı, alev titreşimi, Solfie hareketleri.
- Süreler ve eğriler (cubic-bezier) aynen alınır.
- **Hareketi azalt** açıksa animasyonlar kapanır, son kare görünür (açılış dahil), konfeti çıkmaz.
- Kabul:
  - [ ] Her animasyon süresi ve eğrisi kaynaktakiyle aynı.
  - [ ] Hareketi azalt açıkken açılış son karesiyle başlıyor, konfeti yok.

### G-07 Ses

- Bütün sesler kodla üretilir (dosya yok): piyano notası (temel + harmonikler, hızlı atak, üstel sönüm), doğru "ting
  ting" (Sol5→Do6), yanlış iki alçalan "dum", tur sonu üç nota, günlük hedef arpeji, seviye/ünvan arpeji, seri iki
  notası, metronom tıkı (vurgulu ilk vuruş), Ritmi Tut nota sesi (`utils/audio.ts`). Native'de AVAudioEngine ile aynı
  dalga biçimi ve zarf.
- Tek ayar: **Ses** (`soundKeys`) kapalıysa hiçbir ses çalmaz.
- Ses oturumu `playback` + `mixWithOthers`: sessiz düğmesi açıkken de çalar, arkadaki müziği durdurmaz
  (`ios/App/App/AppDelegate.swift`).
- Kabul:
  - [ ] Her ses React sürümüyle kulakla karşılaştırıldığında aynı (perde, süre, sıra).
  - [ ] Sessiz düğmesi açıkken ses geliyor; Spotify çalarken uygulama sesi müziği kesmiyor.
  - [ ] Ses kapalıyken hiçbir ses çalmıyor.

### G-08 Titreşim

- Üç tür: dokunuş (hafif), başarı, hata (`utils/haptics.ts`). Ayarlar › Titreşim kapalıysa hiçbiri.

### G-09 Depolama

Her şey cihazda. Anahtar adları **değişmez** (README, CLAUDE.md). Native'de aynı anahtarlar ve aynı JSON biçimi
kullanılır; böylece ileride bir veri taşıma gerekirse biçim tanıdık kalır. Her anahtar Application Support/Solvato altında
anahtar adıyla bir dosya (`SolvatoCore/Logic/Persistence.swift`): UserDefaults'ta "kilitliyken şifreli" koruma ek bir
yetki ve imzalama değişikliği isterdi; dosyada veri koruması doğrudan açılır.

| Anahtar                  | İçerik                                                     | Kaynak                          |
| ------------------------ | ---------------------------------------------------------- | ------------------------------- |
| `pianote_settings_v1`    | Ayarlar (`Settings`)                                       | `utils/settings.ts`             |
| `notausta_stats_v1`      | İstatistikler (`AppStats`)                                 | `state/stats.ts`                |
| `pianote_theme_v1`       | `system` / `dark` / `light`                                | `state/theme.ts`                |
| `notalik-daily`          | Günün meydan okuması kayıtları (tarih → doğru, süre, kare) | `utils/games.ts`                |
| `notalik_rotate_hint_v1` | "Yan çevir" ipucu kaç kez gösterildi                       | `utils/orientation.ts`          |
| `solvato_last_lesson_v1` | Çalışma'da son açılan ders (yedeklenmez)                   | `screens/study/StudyScreen.tsx` |

- Ayar varsayılanları `utils/settings.ts` `DEFAULTS`. Eski tek `sound` ayarı `soundKeys`'e taşınır (native'de
  gerek yok: yayında eski kullanıcı yok).
- Veri koruması açık (cihaz kilitliyken şifreli): dosyalar `completeFileProtectionUnlessOpen` ile yazılır.
  `solvato_last_lesson_v1` yedeğe girmeyen `NoBackup` alt klasöründe.
- İlerlemeyi sıfırla: istatistikler sıfırlanır; ayarlar ve günün meydan okuması kayıtları kalır.
- Kod hazır ve testli (0.3); tema bugün uygulamada hâlâ `@AppStorage` ile okunuyor, ekranlarla birlikte (0.5) bu katmana
  geçer. Aşağıdaki iki madde cihazda doğrulanınca işaretlenir.
- Kabul:
  - [ ] Uygulama silinip yeniden kurulmadıkça veriler kalıcı; güncellemede kaybolmuyor.
  - [ ] `solvato_last_lesson_v1` iCloud yedeğine girmiyor; diğerleri giriyor.

### G-10 Gezinme

- Üç sekme (alt menü): **Pratik · İlerleme · Çalışma** (`ui/NavBar.tsx`). Sekmeye dokununca yığın sıfırlanır.
- Alt ekranlar yığına eklenir; geri düğmesi ve **sol kenardan kaydırma** bir önceki ekrana döner, önceki ekranın
  kaydırma konumu korunur (`utils/scrollMemory.ts`, `utils/swipeBack.tsx`).
- Tur ekranlarında (soru turu, akor turu, Ritmi Tut, düello) kenardan kaydırma ekranı kaydırmaz, çıkış onayını açar.
- Sonuç ekranları (tur sonucu, oyun sonucu) yığına girmez: oradan geri dönünce turdan önceki ekrana dönülür.
- Kabul:
  - [ ] Ayarlar'dan kaydırarak geri dönünce Profil kaldığı yerde.
  - [ ] Soru turunda kenardan kaydırma "Turdan çıkılsın mı?" penceresini açıyor.
  - [ ] Tur sonucundan "Bitir" turun başlatıldığı ekrana döndürüyor (Pratik ya da İlerleme).

## A. Kurallar (mantık)

Bu bölümün her maddesi 0.3'te Swift paketinde yazılır ve altın tablolarla test edilir.

### K-01 Soru bankası

- 701 soru (`data/questions.ts`): 504 nota (Sol/Fa anahtarı, ek çizgili ileri notalar dahil), 60 diyez/bemol,
  70 ritim, 34 terim, 33 nota yazımı. Kulak soruları her turda yeniden üretilir (K-05).
- Nota soruları üreteçle kurulur (`buildNoteQuestions`, `buildAccidentalQuestions`): kimlikler, şık sırası, soru
  metinleri ve açıklamalar bu üreteçlerin çıktısıyla **aynı** olmalı. 0.3'te banka React'tan JSON olarak dışa
  aktarılır ve native pakete gömülür (elle yeniden yazılmaz).
- Kabul:
  - [x] Native bankada aynı 701 kimlik, aynı metin, şık, doğru cevap, açıklama, porte konumu, ek çizgi ve nota dizisi.

### K-02 Soru seviyesi

- `questionLevel(q)`: nota sorusunda 2+ ek çizgi ya da y>95 / y<25 → İleri; diyez/bemol → Orta; porte içi, hemen
  üstü/altı ve orta Do → Başlangıç; diğer ek çizgiler → Orta. Ritim ve terimlerde sabit kimlik listeleri; yazımda
  kimlik ≥1801 Orta. Dağılım: Başlangıç 362, Orta 155, İleri 184 (ritimde 14, terimlerde 9 İleri soru).
- Kabul:
  - [x] 701 sorunun her birinin seviyesi React'la aynı (altın tablo).

### K-03 Tur için soru seçimi

- `data/session.ts` `pickQuestions`: tur 10 soru. Seviyenin üstündeki sorular gelmez. Karışık turda yalnızca seçili
  anahtar(lar)ın notaları. Orta/İleri'de soruların yarısı kendi seviyesinden. Karışık turda Orta'dan itibaren 3 diyez/
  bemol sorusu (çalışılacak notalar kısıtlı değilse). Diyez & Bemol turu seviyeden bağımsız.
- **Çalışılacak notalar** (Ayarlar / öğretmen kodu): nota soruları süzülür, şıklar seçili notalardan yeniden kurulur
  (nota sırasıyla). Diyez/bemolde temel nota seçili notalardan biri (6'dan az kalırsa kısıtlama yok).
- **Öğretmen konuları**: karışık tur yalnızca seçilen konulardan (en az 5 soru kalırsa).
- Nota sorularının şıkları nota sırasıyla durur; diğerlerinde karıştırılır (yazım sorularında şıklar çizim, sıra sabit).
- Zayıf notalar turu (`getWeakQuestions`): seçilen nota konumlarından en çok 10 soru.
- Hataların tekrarı: son turda yanlış yapılan sorular, aynı sırayla.
- Kabul:
  - [x] Aynı ayarlar ve aynı rastgele sayı dizisiyle aynı 10 soru seçiliyor (altın tablo, rastgele üreteç dışarıdan
        verilir).
  - [x] Başlangıç seviyesinde hiçbir turda Orta/İleri soru yok (1.000 turluk deneme).

### K-04 Seviye (Başlangıç / Orta / İleri)

- `state/stats.ts` `recordLevelProgress`: soru turlarından (oyun ve hata tekrarı dahil; akor ve Ritmi Tut hariç)
  sonra çalışır. Bu seviyede ≥50 soru ve ≥%80 doğru → bir üst seviye açılır, sayaç sıfırlanır, kutlamada "Yeni seviye".
  Açılmazsa sayaç son ~50 soruya ölçeklenir (`n·k`, `c·k` yuvarlanır).
- Ayarlar'da ya da öğretmen koduyla seviye değişirse sayaç sıfırlanır.
- Kabul:
  - [x] Altın tablodaki tur dizileri için seviye ve sayaç her adımda React'la aynı.

### K-05 Kulak soruları

- `data/ear.ts`: tur 10 soru. Başlangıç: 6 nota + 4 akor; Orta/İleri: 5 + 5. Nota sorusu: önce Do4, sonra hedef nota;
  aynı nota arka arkaya gelmez; Başlangıç'ta Do–Sol, sonra 7 nota; çalışılacak notalarla kesişir (en az 3). İleri'de
  çeldiriciler komşu notalar. Akor sorusu: kök Do–La, Başlangıç'ta yalnız majör/minör çalınır, sonra dört tür
  (majör/minör iki kat sık). Şıklar Majör, Minör, Eksik, Artık (sıra sabit).
- Çalma: nota sorusunda iki nota arka arkaya; akorda önce tek tek, sonra birlikte (`components/EarPrompt.tsx`). Soru
  açılınca 0,35 sn sonra kendiliğinden çalar.

### K-06 XP ve ünvan

- Doğru cevap başına 10 XP (soru, akor, Ritmi Tut'ta geçilen ritim).
- 15 ünvan, eşikler `utils/level.ts` `RANKS` (0 Yeni Başlayan … 22.000 Efsane). İlerleme yüzdesi ve kalan XP
  `rankFromXp`.
- "Seviye" yalnız Başlangıç/Orta/İleri; XP basamakları "ünvan" (CLAUDE.md yazım kuralı).
- Kabul:
  - [x] 0–25.000 arası her 50 XP için `rankFromXp` sonucu aynı (altın tablo).

### K-07 Günlük hedef ve seri

- Günlük hedef 10/20/30/50 soru (tanıtımda 10/20/30). Gün içinde çözülen soru sayısı `dailyQuestions[YYYY-MM-DD]`.
- Seri yalnızca o günün hedefi tamamlanınca +1 (`applyProgress`): dün seri sayılmışsa +1, yoksa 1. Gösterilen seri
  (`currentStreak`): son seri günü bugün ya da dün değilse 0.
- Gün yerel saatle hesaplanır. Dün = şimdi − 24 saat (yaz saati geçişinde bile böyle; birebir korunur).
- Kabul:
  - [x] Altın tablodaki gün/tur senaryolarında seri, `lastPlayDate` ve gösterilen seri React'la aynı.

### K-08 Tur sonu istatistik güncellemesi

`App.tsx` `handleComplete` (soru turu) ve `handleSpecialComplete` (akor turu, Ritmi Tut):

- XP, tur sayısı, günlük tur ve soru sayısı, seri (K-07).
- Son turlar listesi: en yenisi başta, en çok 100; ad: konu adı (`ROUND_LABELS`), "Oyun · <konu>", "Zayıf notalar",
  "Hataların tekrarı", "Akorlar", "Ritmi Tut"; süre (sn) akor turunda yok.
- Günlük doğruluk (`dailyAccuracy`), konu doğrulukları (`categoryAccuracy`; ek çizgili notalar ayrıca), nota konumu
  doğruluğu (`noteStats`, anahtar `treble:70`, `bass:45:sharp`), günlük konu sayıları (`dailyTopics`, 60 günden
  eskisi silinir).
- Akor turu doğruluğu Akorlar'a, Ritmi Tut Ritim'e yazılır.
- Kabul:
  - [x] Altın tablodaki tur sonuçları uygulanınca `AppStats` JSON'u React'la birebir aynı (tarih sabit).

### K-09 Yıldızlar

- `utils/stars.ts`: yalnızca doğruluk. %90+ 3, %70+ 2, %50+ 1, altı 0.
- En iyi yıldız konu başına (`bestStars`, anahtar konu adı ya da `chords` / `rhythmtap`); yalnız normal konu
  turlarında yazılır (oyun, hata tekrarı, zayıf notalar sayılmaz). İlk tur 0 yıldız olsa da kaydedilir.
- Sonuç ekranında ipucu: "2. yıldız için %70 doğru yap"; rekor kırılınca "Bu konuda yeni rekor!".

### K-10 Kutlama

- `detectCelebration`: yeni ünvan, günlük hedef tamamlandı, seri arttı; ayrıca K-04'ten yeni seviye. Birden çoksa
  hepsi aynı pencerede, sırayla: ünvan, seviye, hedef, seri.
- Ses: ünvan ya da seviye → seviye arpeji; değilse hedef → hedef arpeji; değilse seri → seri sesi. Kutlama yoksa tur
  sonu melodisi. Pencere 6,5 sn sonra kendiliğinden kapanır.

### K-11 Öğrenme yolu (İlerleme › Sıradaki)

- `screens/progress/PathCard.tsx`: Sol → Fa → (Orta'dan itibaren Diyez & Bemol) → Ritim → Terimler → Akorlar.
  Aşama tamam: ≥15 soru ve ≥%70 doğru. Sıradaki aşama ilk tamamlanmamış olan.

### K-12 Zorlandığın notalar

- `state/weakNotes.ts`: en az 3 kez sorulmuş, %70'in altında bilinen konumlar; en kötüden iyiye, İlerleme'de en çok 6,
  raporda 4. Ad oktavlı ("Fa4"), kendi anahtarında küçük portede.

### K-13 Haftalık rapor

- `utils/weeklyReport.ts`: takvim haftası Pazartesi–Pazar; gelecek günler şeritte silik, metinde yok. İçerik: çalışılan
  gün, hedef tutturulan gün, çözülen soru, haftalık doğruluk ve geçen hafta, konular (çok çözülenden aza), zorlanılan
  notalar, seviye, hedef, seri, öğretmen kodu. Tarih aralığı Türkçe ("16–22 Kasım", ay değişirse "30 Kasım – 6 Aralık").
- Kabul:
  - [x] Altın tablodaki istatistik + tarih için rapor metni React'la karakter karakter aynı.

### K-14 Doğruluk dönemleri

- `utils/dates.ts`: "Bu hafta" Pazartesi–Pazar, "Bu ay" 1'i–son günü; önceki dönem karşılaştırması yalnız önceki
  dönemde ≥10 soru varsa ve yalnız artış gösterilir ("Geçen haftaya göre +7 puan").

### K-15 Öğretmen kodu

- `utils/teacherCode.ts`: 6 karakter (`K7M-2QX`), 32 harflik alfabe (0/O, 1/I yok), 30 bit: işaret 4 · notalar 7 ·
  anahtar 2 · seviye 2 · hedef 2 · tuş adları 1 · konular 7 · kontrol 5; gövde karıştırılır. Girişte küçük harf, tire,
  boşluk, O→0, I→1 düzeltilir. Geçersiz kod (uzunluk, harf, kontrol, işaret, seviye, anahtar, <3 nota) reddedilir.
- Konular 0 = hepsi. Konu listesinin sırası değişmez.
- Kabul:
  - [x] Bütün geçerli ayar birleşimleri (7 nota alt kümesi × 3 anahtar × 3 seviye × 4 hedef × 2 × 128 konu) için
        native kodlayıcı React'la aynı kodu üretiyor; React'ın ürettiği her kodu native çözüyor (altın tablo, örneklem).
  - [x] Bozuk kod örnekleri (altın tablo) native'de de reddediliyor.

### K-16 Oyunlar: tohum, günün meydan okuması, meydan okuma kodu

- `utils/games.ts`. Tohumlu rastgele üreteç (mulberry32 benzeri, 32 bit) ve tohumla karıştırma: aynı tohum iki
  telefonda (React ve native dahil) **aynı soruları aynı sırayla, aynı şıklarla** verir.
- Oyun soruları: kategori + seviye + tohum. Karışık: 5 nota + 5 diğer. Oyunlarda ipucu ve süre yok.
- Günün meydan okuması: tarih → kategori (7 günlük döngü: Karışık, Sol, Fa, Ritim, Karışık, Terimler, Yazım), tohum
  (FNV-1a), numara (gün − 20774). Seviye her zaman Orta. İlk deneme kaydedilir, sonrakiler kaydedilmez. Oyun serisi:
  bugünden (oynanmadıysa dünden) geriye ardışık oynanan gün.
- Meydan okuma kodu: 8 karakter (`ABCD-EFGH`), 40 bit: kategori 3 · seviye 2 · tohum 16 · doğru 4 · süre(sn) 10 ·
  kontrol 5. Öğretmen koduyla karışmaz (farklı uzunluk ve kontrol).
- Kazanan: önce doğru sayısı, eşitse süre; ikisi de eşitse berabere.
- Kabul:
  - [x] 1.000 tohum × 6 kategori × 3 seviye için soru kimlikleri ve şık sırası React'la aynı (altın tablo).
  - [x] 2026 ve 2027'nin her günü için günün kategori, tohum ve numarası aynı.
  - [x] React'ın ürettiği meydan okuma kodlarını native çözüyor, native'in ürettiklerini React çözüyor.

### K-17 Akor motoru ve akor turu

- `data/chords.ts`: 94 akor, 4 seviye (Başlangıç 14, Orta 10, İleri 23, Uzman 47), doğru yazım (Do# minör = Do# Mi
  Sol#), porte konumu, tuşlar, aynı tuş kümeli akorlar (`samePcs`) çeldirici olmaz.
- Akor turu (`screens/ChordQuizSession.tsx`): 10 soru, seviye = soru seviyesi (Uzman yalnız Çalışma'da). Yeni seviye
  ile önceki seviyeler yarı yarıya. Üç tür eşit dağılır: **Akor tanıma** (porte), **Tuşlardan bul** (basılı tuşlar;
  klavyeye sığmazsa porte), **Akoru bas** (çoklu tuş). Çeldiriciler: biri aynı kökün başka türü, diğerleri aynı türün
  başka kökleri. Başlangıç'ta çeldiriciler de Başlangıç akorlarından.
- Süre açıksa soru başına 15 sn halka.
- Kabul:
  - [x] 94 akorun adı, sembolü, yazımı, porte konumu, tuşları ve örnek dizileri React'la aynı (altın tablo).
  - [x] Aynı rastgele sayı dizisiyle aynı 10 soru, aynı soru türleri ve aynı şıklar (altın tablo).

### K-18 Ritmi Tut puanlama

- `data/rhythmTap.ts`: seviye başına 10 ritim (tek ölçü 4/4), tur 6 ritim (Orta/İleri'de 4 kendi seviyesinden + 2 alt
  seviyeden). Tempo Başlangıç 76, Orta 66, İleri 72.
- Değerlendirme: tam pencere ±110 ms (Başlangıç) / ±90 ms, yakın ±200 / ±180 ms; sık notalı ritimde pencere en kısa
  nota aralığının yarısına daralır. Puan: tam 1, yakın 0,6, ıska 0, fazla dokunuş başına −0,2; 0–1 arası. %70 ve üstü
  geçti. Sapma ortalaması ve yön (erken/geç, 45 ms'den büyükse söylenir).
- Zamanlama: tıklar ses saatine önceden zamanlanır, dokunuş aynı saatle ölçülür, ses çıkış gecikmesi düşülür.
  Native'de AVAudioEngine saatiyle; doğruluk bugünkünden iyi olmalı (PLAN), puanlama kuralı aynı kalmalı.
- Kabul:
  - [x] Altın tablodaki (ritim, dokunuş zamanları, tempo, seviye) girdileri için `gradeTaps` sonucu aynı.
  - [ ] iPhone'da metronomla mükemmel çalınan ritim ≥%90 alıyor (cihazda elle test).

### K-19 Süre (zaman yarışı)

- Soru turunda açıksa: nota 5 sn, ritim 8 sn, terim 10 sn; süre dolunca yanlış sayılır. Oyunlarda yok. Akor turunda
  15 sn.

## B. Ekranlar

Her ekran için: kaynak, ne görünür, durumlar, kabul ölçütleri, referans görüntüleri. "Metinler kaynaktaki gibi" her
ekran için geçerli; aşağıda yalnızca kolay gözden kaçacak olanlar yazılı.

### E-01 Açılış animasyonu

- Kaynak: `screens/Splash.tsx`, `components/Logo.tsx`.
- Mor parıltı, logo karesi yaylanarak gelir, beyaz tuşlar aşağıdan yükselir, siyahlar iner, 3. tuş basılır ve sarıya
  döner, anahtar deliği belirir, üç sekizlik nota yükselir, "Solvato" harf harf ("Solv" beyaz, "ato" mor). 2 sn
  sonra 0,38 sn'de söner. Dokununca hemen söner.
- Native: önce sistem açılış ekranı (LaunchScreen, aynı zemin rengi), ardından aynı SwiftUI animasyonu.
- Kabul:
  - [ ] Kare kare aynı sıra ve zamanlama (video karşılaştırması).
  - [ ] Dokununca atlanıyor. Hareketi azalt'ta son kare.
- Görüntü: `acilis` (son kare).

### E-02 Tanıtım (ilk açılış)

- Kaynak: `screens/Onboarding.tsx`. Yalnız `onboarded` false iken; Ayarlar › Tanıtımı tekrar göster ile yeniden.
- 7 adım, üstte adım noktaları, sağ üstte "Atla" (son adım hariç):
  1. **Merhaba**: Solfie (el sallar) "Merhaba, ben Solfie!", "Hadi bir nota bulalım", isim alanı (isteğe bağlı, en
     çok 24 harf), Devam.
  2. **Deneme 1**: Sol anahtarında Do4, "Bu nota Do. Tuşunu bul.", tuş adları görünen klavye. Yanlışta yardım metni,
     kısa süre sonra tekrar denenir. Doğruda "Doğru! Bu nota Do." ve Devam açılır.
  3. **Deneme 2**: Sol4 (ikinci çizgi), "Şimdi sen bul: bu hangi nota?".
  4. **Anahtar**: Sol / Fa / İkisi de (varsayılan Sol).
  5. **Seviye**: Yeni başladım / Bir süredir çalıyorum / Uzun süredir çalıyorum + günlük hedef 10/20/30.
  6. **Hatırlatma**: Evet (saat 17–21, varsayılan 19) / Şimdi değil. "Hatırlat" bildirim izni ister; reddedilirse
     kapalı kalır.
  7. **Hazırsın**: Solfie (sevinç) "Her gün birlikte çalışalım!", "Günde X soru yeter…", Başlayalım.
- iPad'de içerik ortada en fazla 560 pt.
- Kabul:
  - [ ] Atla her adımda tanıtımı bitiriyor, seçilmemiş ayarlar varsayılanda kalıyor.
  - [ ] Seviye adımı seviye sayacını sıfırlıyor.
  - [ ] Bildirim izni reddedilince hatırlatma kapalı.
- Görüntü: `tanitim-1-merhaba`, `tanitim-2-deneme`, `tanitim-2-yanlis`, `tanitim-2-dogru`, `tanitim-4-anahtar`,
  `tanitim-5-seviye`, `tanitim-6-hatirlatma`, `tanitim-7-hazir`.

### E-03 Ana sayfa tanıtımı (ipuçları)

- Kaynak: `ui/Coachmark.tsx`, adımlar `App.tsx` `COACH_STEPS`. Tanıtımdan sonra Pratik'e ilk girişte; öğeyi aydınlatır
  (çevresi karartılır), altında/üstünde kart: Buradan başla → Seviyen → Bir konuya odaklan → Oyunlar → İlerleme ve
  Çalışma. "Atla" / "Sıradaki", son adımda "Anladım". Bitince sayfa başa kayar.
- Görüntü: `pratik-ipucu-1`, `pratik-ipucu-5`.

### E-04 Pratik (ana sayfa)

- Kaynak: `screens/HomeScreen.tsx`, `profile/LevelCard.tsx`, `components/GoalStaff.tsx`, `ui/StatPill.tsx`,
  `ui/TopicLink.tsx`.
- Üstte logo; sağda seri hapı (turuncu alev, seri yoksa soluk; dokununca İlerleme), XP hapı (ünvan sırası rozetli;
  dokununca Profil), avatar (dokununca Profil).
- İsim varsa selam: saate göre "İyi geceler" (<6), "Günaydın" (<12), "Merhaba" (<18), "İyi akşamlar".
- Seviye kartı (kısa): seviye adı, üç basamak, ilerleme çubuğu ve "Orta seviyesine: 12/50 soru · %83 doğru".
- **Bugün** kartı: "12/20 soru" (hedef tamsa "Hedef tamam · "), günlük hedef portesi (her parça bir nota, Re4'ten
  yukarı; hedef >10 ise 10 nota), alt yazı ("… soru kaldı" ya da "Bugünün serisi tamam"), mor düğme: "Bugünün
  çalışması" / "Devam et" / "Bir tur daha", alt yazı öğretmen konusu seçiliyse farklı.
- **Oyunlar** kartı: sağda "Günün oyunu" ya da "Bugün 7/10".
- **Pratik Kategorileri**: Sol Anahtarı, Fa Anahtarı, Diyez & Bemol (Orta'dan itibaren), Akor (bağlantı), Ritim &
  Ölçü, Ritmi Tut (bağlantı), Kulak, Nota Yazımı, Müzik Terimleri. Kartta konu rengi, simge, alt yazı (çalışılacak
  notalar kısıtlıysa "Sadece Do Re Mi"), oynandıysa en iyi yıldız, oynat simgesi.
- Öğretmen konu seçtiyse başlık "Öğretmeninin seçtiği konular"; diğerleri kapalı "Diğer konular (N)" altında.
- Kabul:
  - [ ] Seri 0'da hap soluk ve erişilebilirlik etiketi "Seri yok. Bugün bir tur çözünce başlar".
  - [ ] Hedef 10/20/30/50 için porte nota sayısı ve dolu nota sayısı aynı.
  - [ ] Öğretmen konu seçimiyle kart grupları aynı.
- Görüntü: `pratik-yeni`, `pratik`, `pratik-alt` (kaydırılmış), `pratik-ogretmen`, `pratik-hedef-tamam`.

### E-05 Soru turu

- Kaynak: `screens/QuizSession.tsx`, `components/MusicalStaff.tsx`, `components/Notation.tsx`,
  `components/piano/QuizPiano.tsx`, `components/EarPrompt.tsx`, `components/RotateHint.tsx`.
- Üst çubuk: çıkış (ok, onay açar), 10 nokta + "3/10", sağda "✓ 4". Her 3 doğruda skorda alev parlar.
- Süre açıksa ince çubuk ve saniye (yeşil → amber → kırmızı).
- Konu etiketi (konu renginde): SOL ANAHTARI, FA ANAHTARI, RİTİM & ÖLÇÜ, NOTA YAZIMI, KULAK, MÜZİK TERİMİ.
- Soru alanı türüne göre: porte + nota (diyez/bemol, ek çizgiler), ritim partisyonu, terim partisyonda ya da yazı,
  nota yazımında açıklama, kulakta büyük çal düğmesi.
- Nota sorusunda "İpucu" düğmesi (oyunlarda yok): anahtarın çizgi/aralık ezberi.
- Cevap: nota sorularında ayara göre **Klavye** ya da **Şıklar**; diğerlerinde şıklar (yazım sorularında şıklar küçük
  partisyon çizimi, A–D).
- Klavye: telefonda 1 oktav (tuş adları ayara göre); iPad dikeyde 2, yan ekranda 3 oktav ve cevap oktavıyla alınır
  ("Nota doğru, oktav yanlış"). Diyez/bemolde eş sesli siyah tuş doğru sayılır.
- Doğru: yeşil, nabız, ting, başarı titreşimi, portede nota adı; 0,7 sn sonra sıradaki soru.
- Yanlış: kırmızı sallanma, dum, hata titreşimi, doğru şık yeşil ✓, alttan açıklama kartı ("Doğru cevap: Sol" +
  açıklama), "Sıradaki" / son soruda "Turu bitir".
- "Telefonu yan çevir, klavye büyüsün" ipucu: telefonda, klavye modunda, ilk 3 turda, 6 sn; telefon yan çevrilince
  bir daha çıkmaz.
- Kulak sorusunda ses kapalıysa "Ses kapalı" + "Sesi aç".
- Kabul:
  - [ ] Her soru türü için bekleyen, doğru ve yanlış durum görüntüsü React'la aynı.
  - [ ] iPad'de 2 oktav, iPhone yan ekranda 3 oktav; doğru tuş oktavlı kontrol ediliyor.
  - [ ] Süre dolunca yanlış sayılıyor ve açıklama açılıyor.
- Görüntü: `soru-nota`, `soru-nota-ipucu`, `soru-nota-dogru`, `soru-nota-yanlis`, `soru-nota-siklar`,
  `soru-nota-yatay` (yalnız iPhone yan), `soru-diyez`, `soru-ritim`, `soru-terim`, `soru-yazim`, `soru-kulak`,
  `soru-sure`, `soru-cikis`.

### E-06 Akor turu

- Kaynak: `screens/ChordQuizSession.tsx`, `components/ChordStaffSvg.tsx`, `components/piano/MultiPiano.tsx`.
- Üst çubuk: çıkış, noktalar, "3/10", XP. Etiket: AKOR TANIMA / TUŞLARDAN BUL / AKORU BAS + seviye adı; süre halkası.
- Soru: "Portedeki akor hangisi?", "Klavyede basılı akor hangisi?", "Bu akorun tuşlarına bas" (akor adı ve sembolü).
  Dinle (birlikte) ve arpej düğmeleri; cevaptan sonra formül ipucu.
- Şıklar: akor adı + sembol. Akoru bas: çok tuşlu klavye, "Seçilen" listesi, "✕ Temizle".
- Alt düğme: "Seçenek Seç..." / "Tuşlara Bas..." / "Kontrol Et ✓" / "Sıradaki" / "Turu bitir".
- Doğru: üstte bildirim "Harika! Do majör (+10 XP)", 1,5 sn sonra sıradaki. Yanlış/süre: "Süre doldu. Doğru cevap:
  …" + "Notalar: Do – Mi – Sol".
- Görüntü: `akor` (ilk soru; tohumla "Akoru bas" türü). Diğer türler ve yanlış durumu 0.5'te eklenir.

### E-07 Ritmi Tut

- Kaynak: `screens/RhythmTapSession.tsx`, `components/RhythmTimeline.tsx`.
- Üst: çıkış (onay), 6 bölüm (geçilen yeşil, geçilmeyen amber, şimdiki mor), "76 BPM".
- "Ritmi Tut · 2/6", başlık "Dört vuruş say, sonra ritmi dokunarak çal" / "Ritim yerinde!" / "Bir daha deneyelim".
- Ölçü partisyonu, zaman çizgisi (mor çizgiler hedef anlar, noktalar dokunuşlar, çalarken ilerleyen çizgi).
- 1–4 vuruş ışıkları; büyük dokunma alanı ("Dokunma alanı" / "Hazır…" / "Dinle…" / "Dokun"); Dinle ve Başla.
- Sonuç: "5/6 vuruş yerinde · 1 fazla dokunuş · %72", yön ipucu; Tekrar dene, Sıradaki / Turu bitir.
- Ses kapalıysa "Bu oyun metronomla oynanır; ses kapalı." + "Sesi aç".
- Çalarken çıkış onayı açılırsa deneme durur; "Devam et" aynı ritmi baştan başlatır.
- Görüntü: `ritmi-tut`, `ritmi-tut-ses-kapali`.

### E-08 Tur sonucu

- Kaynak: `screens/ResultScreen.tsx`, `ui/ScoreRing.tsx`, `ui/Stars.tsx`, `profile/RankCard.tsx`.
- Yıldızlar (animasyonlu), "Tur bitti · Harika iş!" (%90) / "Çok iyi!" (%70) / "Güzel gidiyorsun" (%50) /
  "Tekrarla, oturacak"; konu adı ("Sol Anahtarı Pratiği"…); Solfie balonu (yıldız ipucu ya da rekor).
- Doğruluk halkası (%, "7/10 doğru"), +XP, ortalama süre ("2,4 sn"; Ritmi Tut'ta "Ort. Sapma 38 ms").
- Ünvan kartı (kısa): "Bu turda +70 XP. Porte Gezgini ünvanına 230 XP kaldı."
- Ana düğme: "Hatalarını tekrar et · 3 soru" ya da "Yeni tur"; "Bitir".
- Görüntü: `sonuc` (Ritmi Tut sonucu cihazda dokunuş gerektirdiği için elle karşılaştırılır).

### E-09 Kutlama penceresi

- Kaynak: `components/Celebration.tsx`. Solfie (sevinç), satırlar (K-10), konfeti, "Devam". 6,5 sn sonra kapanır.
- Görüntü: `kutlama`.

### E-10 İlerleme

- Kaynak: `screens/ProgressScreen.tsx`, `progress/PathCard.tsx`, `progress/WeeklyReportCard.tsx`,
  `profile/RoundHistory.tsx`.
- Hiç soru yoksa: boş durum çizimi, "İstatistiklerin burada görünecek", "İlk tura başla" (Pratik'e götürür); üstte
  öğrenme yolu.
- Veri varsa sırayla: **Doğruluk** (Bu hafta / Bu ay / Tümü; bu hafta veri yoksa Tümü seçili açılır), **Bu hafta**
  (seri, dürtme metni, 7 gün şeridi, özet, "Öğretmenine haftalık rapor gönder"), **Sıradaki** (öğrenme yolu),
  **Konular** (satır: ad, çubuk, yüzde; ek çizgiler alt bilgi; dokununca o konuda tur), **Zorlandığın notalar**
  (3 sütun küçük porte, "Bu notaları çalış"), **Son turlar** (ilk 3, "Tümünü göster" ile 30).
- Kabul:
  - [ ] Bu hafta şeridinde dolu/yarım/boş/bugün (kesikli)/gelecek (silik) durumları aynı.
  - [ ] Rapor paylaşım menüsünde açılıyor; metin K-13 ile aynı.
- Görüntü: `ilerleme-bos`, `ilerleme`, `ilerleme-alt`.

### E-11 Profil

- Kaynak: `screens/profile/ProfileScreen.tsx`, `RankCard.tsx`, `LevelCard.tsx`, `ui/Avatar.tsx`.
- Başlık + Ayarlar düğmesi. Avatar, isim alanı (kesik çizgili), 6 renk seçimi, "… · 3 Kasım 2026'den beri".
- Ünvan kartı (15 basamak), seviye kartı (açıklamalı), üç kutu (Seri, Tamamlanan tur, Çözülen soru), düğmeler:
  Haftalık raporu öğretmenine gönder, Tüm ilerleme, Ayarlar.
- Görüntü: `profil`, `profil-alt`.

### E-12 Ayarlar

- Kaynak: `screens/SettingsScreen.tsx`, `components/NotesPicker.tsx`.
- Öğretmen kodu satırı → E-13. Çalışma: Günlük hedef (10/20/30/50 + açıklama), Seviye (değişince sayaç sıfır),
  Anahtar, Çalışılacak notalar (en az 3, hazır seçimler). Soru ekranı: Cevap yöntemi, Tuş isimlerini göster, Zaman
  yarışı. Ses ve görünüm: Ses, Titreşim, Tema. Hatırlatma: anahtar + saat (09, 12, 18, 20, 21); izin yoksa kırmızı
  uyarı. Tanıtımı tekrar göster. İlerlemeyi sıfırla (onay kutusu; ayarlar ve oyun kayıtları kalır). Gizlilik, Lisanslar.
  "Sürüm 1.0".
- Kabul:
  - [ ] Sıfırla: XP, seri, istatistikler, yıldızlar, son turlar siliniyor; ayarlar kalıyor; Pratik açılıyor.
  - [ ] Hatırlatma saati değişince bildirim yeni saate taşınıyor.
- Görüntü: `ayarlar`, `ayarlar-alt`, `ayarlar-sifirla`.

### E-13 Öğretmen kodu

- Kaynak: `screens/TeacherScreen.tsx`.
- Açıklama. **Öğrenci** kartı: kod alanı (büyük harf, en çok 7, "ABC-DEF"), Uygula; hata "Kod geçersiz. 6 karakteri
  kontrol et."; uygulanınca "Ayarların güncellendi (K7M-2QX)" + ayar listesi.
- **Öğretmen** kartı: konular (Hepsi + 7 konu; hiçbiri kalmazsa Hepsi), anahtar, seviye, notalar, hedef, tuş adları;
  canlı kod, kopyala/paylaş metni (`teacherShareText`).
- Görüntü: `ogretmen-kodu`, `ogretmen-kodu-alt`, `ogretmen-kodu-uygulandi`, `ogretmen-kodu-hata`.

### E-14 Gizlilik ve Lisanslar

- Kaynak: `screens/LegalScreen.tsx`, metinler `data/legal.ts`. Lisanslar: her biri için "Lisans metnini göster/gizle".
- Native'de lisans listesi değişir: React, Capacitor ve web paketleri çıkar; Outfit, JetBrains Mono, Bravura kalır.
  Metin değişikliği Ceren'in onayıyla (gizlilik metni mağazadakiyle aynı kalmalı).
- Görüntü: `gizlilik`, `lisanslar`.

### E-15 Çalışma

- Kaynak: `screens/study/StudyScreen.tsx`, `lessons.tsx`.
- Başlık, arama ("Konu ara: legato, Fa anahtarı…"; Türkçe harf ve aksan farkı yok sayılır, başlık/alt yazı/bölümde
  arar; temizle düğmesi), **Kaldığın yer** kartı (son ders, arama yokken), bölümler: Notalar, Ritim, Akorlar, Terimler
  (19 ders).
- Görüntü: `calisma`, `calisma-arama`, `calisma-kaldigin-yer`.

### E-16 Dersler

- Kaynak: `screens/study/LessonScreen.tsx` ve ders içerikleri:
  - Sol/Fa anahtarı notaları: ‹ › ile nota gezinme, porte + klavye, notayı çalma (`NotesStudy.tsx` `StaffStudy`).
  - Ezber cümleleri: renkli notalar, aynı renkte klavye, kart çevirme (`MnemonicsStudy`, `MemoCard`).
  - Diyez ve bemol (`StaffStudy mode="accidentals"`, `AccidentalMemo`).
  - Nota değerleri, sus işaretleri, noktalı notalar (`RhythmStudy.tsx`, `MemoVisuals.tsx`: nota ağacı, suslar,
    noktalı).
  - Majör ve minör nasıl kurulur (`ChordMemoVisual`, `KeyIntervals`); akor kartları 4 seviye (`ChordsStudy.tsx`,
    çevrilen kart, mini klavye, çalma, örnek diziler).
  - Terimler 6 grup (`TermsStudy.tsx`).
- Görüntü: `ders-<id>` her ders için (19).

### E-17 Oyunlar

- Kaynak: `screens/GamesScreen.tsx`, `GameResultScreen.tsx`, `ChordDuel.tsx`.
- **Liste**: Günün meydan okuması (durum: "Bugün henüz oynanmadı" / "Bugün oynandı · 7/10"), Arkadaşına meydan oku,
  Akor düellosu.
- **Günün meydan okuması**: numara, bugünün konusu, Oyna; oynandıysa sonuç, "Yarın yeni sorular gelecek. N gündür üst
  üste oynuyorsun.", Sonucu paylaş (🟩🟥 kareli metin).
- **Arkadaşına meydan oku**: konu seçimi + Başla; gelen kod alanı ("Kod geçersiz. 8 karakteri kontrol et."), Kabul et.
- **Oyun sonucu**: günlük (halka, süre, oyun serisi, paylaş); yeni meydan okuma (kod kutusu, "Kodu gönder" metni);
  karşılaştırma (iki sütun, "Kazandın!" / "Bu sefer o kazandı" / "Berabere!", "Sen de ona meydan oku"); Kapat.
- **Akor düellosu**: kurulum (iki isim, akor seviyesi, "Başlayalım"); oyun: ekran ikiye bölünür, üst yarı 180° ters,
  her yarıda akor (porte ya da tuşlar) ve şıklar; doğruya ilk basan puan alır, yanlış basan o soruda kilitlenir; ikisi
  de yanlışsa doğru gösterilir; 1,6 sn sonra sıradaki; 10 soru; sonuç (kazanan, Rövanş, Çık); çıkış onayı.
- Görüntü: `oyunlar`, `oyunlar-oynandi`, `gunun-oyunu`, `gunun-oyunu-oynandi`, `meydan-oku`, `meydan-oku-hata`,
  `oyun-sonucu-gunluk`, `oyun-sonucu-kod`, `duello-kurulum`, `duello-oyun`.

### E-18 Ortak pencereler ve parçalar

- Çıkış onayı (`ui/ExitConfirm.tsx`): "Turdan çıkılsın mı?" / "Bu turdaki cevapların kaydedilmeyecek." / Devam et /
  Çık.
- Kısa bildirim (`ui/Toast.tsx`): "Kopyalandı, mesaja yapıştırabilirsin", "Paylaşılamadı".
- Solfie (`components/Solfie.tsx`): pozlar idle, wave, cheer; konuşma balonu. Yalnız tanıtım, tur sonucu, kutlama.
- Diğer parçalar `src/ui/` (Button, Card, Chip, Segmented, StatTile, StatPill, ScoreRing, Stars, Avatar,
  ScreenHeader, BackButton, IconBadge, Choice) ve `src/components/` (Icons, Glyph, MusicalStaff, Notation,
  ChordStaffSvg, QuizPiano, MultiPiano, GoalStaff, Logo). 0.2'de tasarım sistemi olarak native'e aynı adlarla taşınır.

## C. Nota çizimi (0.4)

- **Notation dili** (`components/Notation.tsx`, sözdizimi dosyanın başında): nota/sus değerleri, bağlı gruplar
  (`ee`, `ssss`, `ess`, `sse`, `e.s`, `ses`, triole), sonekler (nokta, staccato, aksan, tenuto, fermata, adım, sap
  yönü, yanlış sap), ölçü işareti, ölçü çizgileri, süre bağı, legato, yazılar, dinamik, crescendo çatalı. Bankadaki
  her `score` ve `optionScores` dizisi native'de aynı çizilmeli.
- **Porte** (`MusicalStaff.tsx`): Sol/Fa anahtarı, nota konumu (y=40–80 çizgiler, 5 birim adım), ek çizgiler,
  diyez/bemol, doğru/yanlış renklendirme.
- **Akor portesi** (`ChordStaffSvg.tsx`), **günlük hedef portesi** (`GoalStaff.tsx`).
- **Klavye**: tek/çok oktav, siyah tuşlar, tuş adları, basılı/doğru/yanlış/ipucu görünümleri (`design/piano.ts` tek
  kaynak), çok tuşlu seçim.
- Yöntem (0.4): React bileşenleri sunucu tarafında SVG'ye dökülür ve parçalara ayrılır (`scripts/altin/cizim.ts` →
  `cizim.json`): çizgi, dikdörtgen, daire, yol, Bravura sembolü, yazı; sırası, konumu, rengi. Native yerleşim motoru
  (`SolvatoCore/Notation`) aynı listeyi üretir, `NotationTests` karşılaştırır. SwiftUI yalnız çizer
  (`Solvato/Notation/DrawingView.swift`).
- Kabul:
  - [x] Bankadaki her nota metni (`score`, `optionScores`), terim ve ritim gösterimleri, Ritmi Tut'un 30 ritmi ve
        kenar durumları (261 metin), her nota konumunun portesi (204), 94 akor × 3 renk, günlük hedef portesi, anahtar
        ikonları React'la parça parça aynı.
  - [ ] Ekranda React görüntüsüyle üst üste konduğunda aynı (Codemagic görüntüleri; yazıların taban çizgisi ve
        parıltı göz kontrolüyle).
  - [x] Klavye (tek ve çok tuşlu) React'la aynı: her nota sorusunun klavyedeki yeri ve klavye penceresi (564), soru
        klavyesinin 84 ve akor klavyesinin 16 durumunda her tuşun konumu, rengi, kenarlığı, gölgesi ve yazısı
        (`scripts/altin/piyano.ts` → `piyano.json`, `PianoTests`). Ekranda görünüşü Codemagic görüntüleriyle.

## D. Sistem entegrasyonları

| Konu               | Bugün (Capacitor)                       | Native                                                         | Kural                                                                                                       |
| ------------------ | --------------------------------------- | -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Günlük hatırlatma  | `@capacitor/local-notifications`        | `UNUserNotificationCenter`                                     | Kimlik 1001, her gün seçilen saatte :00, "Piyano zamanı 🎹" / "Serini kaybetme: bugün 5 dakika nota çalış." |
| Paylaşım           | `@capacitor/share`, yoksa pano          | `ShareLink` / `UIActivityViewController`                       | İptal sessiz; paylaşım yoksa panoya kopyala + bildirim                                                      |
| Titreşim           | `@capacitor/haptics`                    | `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator` | G-08                                                                                                        |
| Yön kilidi         | `@capacitor/screen-orientation`         | `supportedInterfaceOrientations`                               | G-02                                                                                                        |
| Durum çubuğu       | `@capacitor/status-bar`                 | SwiftUI `preferredColorScheme`                                 | G-04                                                                                                        |
| Kalıcı depolama    | `@capacitor/preferences` + localStorage | `UserDefaults`                                                 | G-09                                                                                                        |
| Ses oturumu        | `AppDelegate.swift`                     | `AVAudioSession` `.playback`, `.mixWithOthers`                 | G-07                                                                                                        |
| Gizlilik bildirimi | `PrivacyInfo.xcprivacy`                 | Aynı dosya, yalnız kullanılan API'ler                          | UserDefaults (CA92.1); izleme yok, veri toplama yok                                                         |

## Referans görüntüler

```bash
npm run build
node scripts/referans.mjs                  # hepsi: iPhone + iPad, koyu + açık
node scripts/referans.mjs --sadece soru    # adı "soru" ile başlayan senaryolar
```

- Çıktı `ekran/referans/<senaryo>-<iphone|ipad>-<koyu|acik>.png`. Senaryolar betiğin içinde; her ekranın **Görüntü**
  satırındaki adlarla aynı.
- Sabitler: tarih 18 Kasım 2026 Çarşamba 10:00, rastgelelik tohumlu, "Hareketi azalt" açık (animasyonlar son
  karesinde). Örnek istatistikler betikteki `ORNEK_STATS` (Orta seviye, 4 günlük seri, 1.270 XP, zorlanılan notalar,
  son turlar).
- 71 senaryo, 318 görüntü, 29 MB (1x). Görüntüler git'e girmez. Web kodu silinmeden önce (0.9) bir kez `docs/native/referans/`
  altına alınır.

## Altın tablolar

React kodundan bir betikle (`node scripts/altin.mjs`; `scripts/altin/uret.ts`'i esbuild ile paketleyip çalıştırır)
üretilen JSON dosyaları, `ios-native/SolvatoCore/Tests/SolvatoCoreTests/Fixtures/altin/`; native testler bunları okur.
Tarih, saat dilimi ve rastgelelik sabit. `seri` iki saat diliminde üretilir (`seri-Europe-Istanbul.json`,
`seri-America-New_York.json`; ikincisi yaz saati gecelerini de içerir). Akor turu ayrıca `akor-turu.json`
(K-17). Durum (22 Kasım): tablonun hepsi üretiliyor ve native testler geçiyor.

| Tablo                 | Girdi                                                         | Çıktı                                                 |
| --------------------- | ------------------------------------------------------------- | ----------------------------------------------------- |
| `soru-bankasi.json`   | —                                                             | 701 soru + seviyeleri (K-01, K-02)                    |
| `akorlar.json`        | —                                                             | 94 akor: ad, sembol, notalar, tuşlar, porte (K-17)    |
| `unvan.json`          | XP 0–25.000 (50'şer)                                          | `rankFromXp` (K-06)                                   |
| `yildiz.json`         | doğru/toplam 0–10                                             | `starsFor`, ipucu (K-09)                              |
| `seri.json`           | gün gün tur dizileri, hedef                                   | AppStats sonrası (K-07, K-08)                         |
| `seviye.json`         | tur sonuç dizileri                                            | seviye, sayaç (K-04)                                  |
| `tur-secimi.json`     | ayarlar + rastgele sayı dizisi                                | soru kimlikleri (K-03, K-05)                          |
| `ogretmen-kodu.json`  | ayar örneklemi + bozuk kodlar                                 | kod / çözüm / ret (K-15)                              |
| `oyun.json`           | tohum × kategori × seviye; 2026–2027 tarihleri; kod örnekleri | soru kimlikleri, şık sırası, günlük bilgi, kod (K-16) |
| `ritmi-tut.json`      | ritim × dokunuş dizisi × tempo × seviye                       | `gradeTaps` (K-18)                                    |
| `haftalik-rapor.json` | istatistik + tarih                                            | rapor metni (K-13)                                    |
| `donem.json`          | tarih × dönem × offset                                        | gün aralığı (K-14)                                    |
| `zayif-notalar.json`  | noteStats örnekleri                                           | `weakNotes` (K-12)                                    |

## Bilinen durumlar (birebir korunur, karar Ceren'in)

Kod okunurken fark edilenler. Native bunları **aynen** taşır; değişecekse Ceren karar verir ve "Bilinçli farklar"a
yazılır.

1. **Seri "dün"ü** şimdiden 24 saat çıkarılarak bulunuyor; yaz saati geçişi gecesinde nadiren bir günü atlayabilir.
   (Türkiye'de yaz saati yok; etkisi yalnız yurt dışında.)
2. **İlerlemeyi sıfırla** günün meydan okuması kayıtlarını (oyun serisi) silmiyor. Ceren: böyle kalsın (21 Kasım).

## Bilinçli farklar

(Ceren'in onayıyla eklenir.) 21 Kasım'da iki düzeltme React sürümünde de yapıldı, native aynısını taşır:

- İleri seviyede İleri ritim ve terim soruları geliyor (eski İleri listesindeki kimliklerin çoğu bankada yoktu).
- Ayarlar › Ses açıklaması: "Telefon sessiz moddayken de çalar." (Ses sessiz modda da çalıyor.)

- Bilgisayara özgü davranışlar taşınmaz: fareyle üzerine gelme renkleri, boşluk tuşuyla Ritmi Tut, masaüstünde telefon
  çerçevesi, Android geri tuşu.

## Kapsam dışı

- Analitik ve admin paneli (1.1, Paket 4).
- Android (dondurulmuş).
- Yeni özellik ya da yeniden tasarım: native sürüm yalnızca bugünkü uygulamanın aynısı.

## Etkilenen dosyalar

- Yeni: `ios-native/` (XcodeGen projesi, Swift paketi, UI testleri; 0.2'de kurulur), `scripts/referans.mjs`,
  `scripts/altin.mjs`.
- `src/` yalnızca okunur (başvuru). 0.9'da silinir.

## Gizlilik etkisi

Yok. Native sürüm de hiçbir yere veri göndermez; gizlilik bildirimi yalnız UserDefaults beyanını içerir.
