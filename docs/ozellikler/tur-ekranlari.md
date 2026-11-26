# Tur ekranları: çıkış, kaydırma, noktalar, titreşim

Durum: **onaylandı (Ceren'in cevapları), native'de uygulandı (26 Kasım 2026)**. R2, R16, R22 ve R34'ün temeli başka
bir oturumda yazıldı (`RoundDots`, `RoundCloseButton`, `Haptics.beat`, kaydırma); bu dokümanın getirdiği farklar:
cevapsız turda sormadan çıkış (`AppModel.exitRound`, ekranlar `hasAnswers` bildirir) ve düelloda "Bitir" yerine ✕.
Çekirdek ölçütleri testlerle doğrulandı; ekran ölçütleri GitHub Actions simülatör görüntüleriyle kapanacak. Yalnız native iOS'a yazılır
(`ios-native/`). Kapsadığı revizeler (`docs/ozellikler/tasarim-revize.md`): R2, R16, R22, R34.

**Başvuru:** R2, R16, R22 web revize önizlemesinde (https://claude.ai/artifact/LpuacK4CoaKn3vT7gmNQzm; kod
`revize-onizleme` dalı, 3. grup kaydı: `QuizSession.tsx`, `ChordQuizSession.tsx`, `RhythmTapSession.tsx`,
`utils/haptics.ts`). R34'ün web karşılığı yok; davranış bu dokümanda.

## Amaç

Bütün turlarda (soru, akor, Ritmi Tut, akor düellosu) çıkış aynı yerden ve aynı biçimde olsun; kenardan kaydırma
uygulamanın geri kalanıyla tutarlı olsun. Öğrenci turda nasıl gittiğini üstteki noktalardan görsün.

## Kullanıcı ne görür

### Çıkış düğmesi (R16)

- Soru turu, oyun turları (günün meydan okuması, kodla meydan okuma), akor turu, Ritmi Tut ve akor düellosunda sol
  üstte **✕** (geri oku yerine). Erişilebilirlik adı "Turdan çık".
- Akor düellosu: ortadaki şeritte soldaki "Bitir" yazısı kalkar, yerine aynı **✕** gelir. Düellonun kurulum ekranı
  (isimler, seviye) bir tur değil; orada bugünkü geri oku kalır.

### Kenardan kaydırma (R34)

- Turlarda da sol kenardan sağa kaydırınca **ekran parmağı izler**, altında önceki ekran görünür (diğer alt ekranlar
  gibi). Turlardaki mor ok kalkar.
- **Bırakınca** (ekranın %35'ini geçtiyse ya da hızlı kaydırdıysa):
  - Turda en az bir cevap verildiyse ekran **yerine geri oturur** ve "Turdan çıkılsın mı?" penceresi açılır
    (düelloda "Düellodan çıkılsın mı?" ve skor). "Çık" önceki ekrana döner, "Devam et" turda kalır.
  - Henüz hiç cevap yoksa ekran **kayıp gider**, sormadan önceki ekrana dönülür.
- Az kaydırıp bırakınca ekran yerine döner, bir şey olmaz.
- Onay penceresi açıkken kaydırmak "Devam et" gibi pencereyi kapatır (bugünkü gibi).

### Çıkış kuralı (✕ ve kaydırma aynı)

- Cevap verilmişse onay sorulur; hiç cevap yoksa sormadan çıkılır.
- "Cevap verildi" sayılır: soru ve akor turunda bir soru cevaplandı (ya da süresi doldu); Ritmi Tut'ta bir ritim
  denendi; düelloda bir oyuncu bir şıkka bastı. Düellonun sonuç ekranında soru sorulmaz.

### Üstteki noktalar (R2)

- Soru turunda ve akor turunda geçilen sorular: doğru cevap **yeşil**, yanlış (ya da süresi dolan) **kırmızı**. Şimdiki
  soru ve kalanlar bugünkü gibi (uzun mor ve gri).
- Ritmi Tut'un bölümleri zaten renkli (yeşil / amber); değişmez.

### Ritmi Tut titreşimi (R22)

- Dokunma alanına her dokunuşta daha güçlü titreşim (hafif yerine sert). Ayarlar › Titreşim kapalıysa yok.

## Kurallar ve sınır durumları

- Tur bitince (sonuç ekranı) kaydırma bugünkü gibi sonuç ekranından geri döner.
- Ritmi Tut çalarken onay açılırsa deneme ve sesler durur (bugünkü gibi); "Devam et" ile ritim baştan denenir.
- Kutlama ya da açılış açıkken kaydırma çalışmaz (bugünkü gibi).
- Telefon yan çevrilmişken (soru ve akor turu) kaydırma aynı.
- Koyu/açık tema: yeşil ve kırmızı noktalar tasarım değerleriyle (`green500`, `red500`).
- VoiceOver: ✕ "Turdan çık"; noktalar tek öğe olarak "3. soru, 10 sorudan" okunur.
- Hareketi azalt: kaydırma parmağı izler, geri oturma kısa.

## Kabul ölçütleri

- [ ] Dört tur ekranında sol üstte ✕ var; düelloda "Bitir" yok.
- [ ] Turda kaydırınca ekran parmağı izliyor, altta önceki ekran görünüyor; mor ok yok.
- [ ] Cevap verilmiş turda kaydırıp bırakınca ekran geri oturuyor ve onay açılıyor; ✕ de aynı onayı açıyor.
- [ ] Hiç cevap yokken ✕ ve kaydırma sormadan çıkıyor.
- [ ] Soru ve akor turunda geçilen noktalar doğruysa yeşil, yanlışsa kırmızı; sayısı tur sonucuyla aynı.
- [ ] Ritmi Tut'ta dokunuş titreşimi daha güçlü.
- [ ] Koyu ve açık temada, iPhone SE ve iPad'de görüntüler (`soru-nota-yanlis`, `soru-cikis`, `akor`, `ritmi-tut`,
      `duello-oyun`).
- [x] Çekirdek testleri: nokta durumları (soru ve akor), "cevap verildi" kuralı (dört tur), çıkış isteği (onay ya da
      doğrudan geri), turlarda kaydırmanın açık olması.

## Kapsam dışı

- Yanlış cevapta "senin cevabın" ve dinleme (R1, beklemede).
- Sonuç ekranındaki seri hatırlatma kartı (R8, ayrı iş).
- Web ve Android.

## Etkilenen dosyalar (tahmini)

- `SolvatoCore/App/AppModel.swift` (çıkış onayı ve "cevap verildi" durumu), `ScreenStack.swift` (turlarda kaydırma),
  `QuizRound.swift`, `ChordRound.swift`, `RhythmTapRound.swift`, `DuelGame.swift` (`hasAnswers`, nokta durumu); testleri.
- `Solvato/AppRoot.swift` (kaydırma; mor ok kalkar), `Screens/QuizScreen.swift`, `ChordQuizScreen.swift`,
  `RhythmTapScreen.swift`, `ChordDuelScreen.swift`, `Audio.swift` (orta titreşim).
- `docs/ozellikler/native-ios.md` (E-05, E-06, ritim ve düello bölümleri), `README.md`, UI testleri.

## Gizlilik etkisi

Yok.
