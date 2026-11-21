# Solvato

Piyano öğrencileri için nota okuma, ritim, akor ve müzik terimleri pratiği.
iPhone ve iPad uygulaması: **React 19 + TypeScript + Vite**, yerel kabuk **Capacitor 7**.
Bu repo **iOS** sürümüdür. Android sürümü dondurulmuş bir kopya olarak `solvato-android` reposunda; Android işi başlayınca
`src/` buradan oraya alınır. Analitik sunucusu ve admin paneli `solvato-admin` reposunda (1.1).
Sunucu yok; tüm ilerleme telefonda saklanır.

Ürün kararları ve yol haritası: `docs/URUN.md`. Claude Code ile çalışma kuralları: `CLAUDE.md`,
çalışma sistemi (beceriler, kancalar, iş akışı): `docs/CALISMA-SISTEMI.md`.

## Ritmi Tut (ritim oyunu)

- Ekran: `screens/RhythmTapSession.tsx`; ritimler ve puanlama: `data/rhythmTap.ts`. Giriş: ana sayfada Ritim & Ölçü kartının
  altı (Oyunlar listesinde yok). Tur 6 ritim; sonuç ortak `ResultScreen`de (`SpecialRound` `"rhythmtap"`, sapma "Ort. Sapma" ms).
- Her ritim tek ölçü 4/4, Notation dilinde yazılır; dokunulacak anlar aynı metinden hesaplanır (çizilen = ölçülen).
  Seviyeler: Başlangıç dörtlük/ikilik/sekizlik çifti; Orta + onaltılıklar (`ssss`, `ess`, `sse`) ve noktalı dörtlük;
  İleri + noktalı sekizlik–onaltılık (`e.s`), `ses`, senkop. Karışık bağlı gruplar tek kelime yazılır (`ess`, `e.s`).
  Tempo 76/66/72 (onaltılıklı seviyeler daha yavaş). Yeni ritim eklerken toplam 4 vuruş olmalı.
- Zamanlama: metronom tıkları `AudioContext` saatine önceden zamanlanır (`utils/audio.ts` `scheduleClick`), dokunuş da
  aynı saatle ölçülür ve ses çıkış gecikmesi (`audioLatency`) düşülür. Pencere: tam ±90 ms (başlangıçta ±110), yakın ±180 ms (±200);
  sık notalı ritimlerde pencere en kısa nota aralığının yarısına daralır (dokunuş komşu notaya sayılmasın).
  Fazla dokunuş puan düşürür; %70 ve üstü "geçti".
- Geri düğmesi ortak `ui/ExitConfirm` onayını açar (test ve akor ekranlarıyla aynı); çalarken açılırsa deneme durur,
  "Devam et" ile aynı ritim baştan başlar.
- Doğruluk Ritim konusuna yazılır, yıldızlar `rhythmtap` anahtarıyla. Ses kapalıysa oyun "Sesi aç" ister.
- Gerçek telefonda test edilmeli: dokunuş gecikmesi cihaza göre değişir; gerekirse `audioLatency`ye sabit düzeltme eklenir.

## Marka

- Ad: **Solvato** (_solve_ "çöz" + müzikteki _-ato_ eki). Yazıda "Solv" kalın, "ato" mor (`components/Logo.tsx`).
- Logo: piyano tuşları; üçüncü (sarı) tuşta anahtar deliği. Aynı geometri `Splash.tsx` animasyonunda.
- Maskot: **Solfie** (sekizlik nota, amber bayrak, kolları ve ayakları var), `components/Solfie.tsx`. `Solfie` tek başına,
  `SolfieSays` konuşma balonuyla. Pozlar duruma göre: `idle` (ipucu, tur sonucu), `wave` (tanıtımın ilk adımı, selam),
  `cheer` (rekor, kutlama penceresi, tanıtımın son adımı "Hazırsın"). Balon metni tek kısa cümle; her ekrana eklemeyin,
  az görünmesi değerini korur.
- Uygulama kimliği: `com.solvato.app` (iOS ve Android'de aynı).
- Eski ad Notalık'tı; ad ve kimlik ilk mağaza yüklemesinden önce değişti. Depolama anahtarları **bilerek değiştirilmedi**
  (anlamları yok, değiştirmek yalnızca geçiş kodu gerektirir):
  `pianote_settings_v1`, `notausta_stats_v1`, `notalik_rotate_hint_v1`, `notalik-daily` vb. Yeni anahtar eklerken
  `solvato_` önekini kullanın, eskileri yeniden adlandırmayın.

## Hızlı başlangıç

```bash
npm install
npm run dev          # tarayıcıda geliştirme (http://localhost:5173)
npm run check        # tür kontrolü + biçim kontrolü (commit öncesi)
npm run format       # Prettier ile biçimlendir
```

| Komut                       | Ne yapar                                                                                        |
| --------------------------- | ----------------------------------------------------------------------------------------------- |
| `npm run build`             | `dist/` içine üretim derlemesi                                                                  |
| `npm run build:single`      | Tek dosyalık önizleme (`dist-single/index.html`), paylaşmak için                                |
| `npm run sync`              | Derle + `cap sync ios` (iOS projesini günceller)                                                |
| `npm run ios`               | Derle, eşitle, Xcode'u aç (Mac gerekir)                                                         |
| `node scripts/ekran.mjs`    | Ekran görüntüsü (koyu/açık, `--se`, `--tablet`), taşma ve dış istek raporu                      |
| `node scripts/referans.mjs` | Native geçişi için her ekranın referans görüntüsü (iPhone/iPad, koyu/açık, sabit tarih ve veri) |

## iOS derlemesi ve TestFlight

Mac yok: `codemagic.yaml` Codemagic'in bulut Mac'inde derler, imzalar ve TestFlight'a yükler (Xcode 26+ kontrolü,
`npm run check`, build numarası Codemagic sayacından). Başlatma: Codemagic'te "Start new build" ya da `testflight-*` git
etiketi. Kurulum ve cihaz testi listesi: `docs/IOS-TEST-REHBERI.md`. Ses oturumu `AppDelegate.swift`'te `playback` +
`mixWithOthers`: sessiz düğme açıkken de ses çalar, arkadaki müzik durmaz.

## Native iOS (Swift / SwiftUI, yapım aşamasında)

`docs/PLAN.md` Paket 0: uygulama native olarak yeniden yazılıyor; bugünkü React kodu başvuru kaynağı. Klasör `ios-native/`:

```
ios-native/
  project.yml          Xcode projesinin tanımı (XcodeGen); .xcodeproj repoda yok, derlemede üretilir
  SolvatoCore/         arayüzden bağımsız Swift paketi (Linux'ta da derlenir): tasarım değerleri, tema tercihi;
                       Logic/ (soru bankası, seviye, ünvan, yıldız, seri, tur sonu, öğretmen ve meydan okuma kodu,
                       oyunlar, soru seçimi, kulak soruları, akorlar ve akor turu, Ritmi Tut puanlama), Resources/soru-bankasi.json. Testler: `swift test`
  Solvato/             SwiftUI uygulaması: Design/ (renk → Color, yazı tipleri, CSS gradyanı), UI/ (web src/ui ile
                       aynı adlarla: AppButton, AppCard, Icon, Logo, Chip, Segmented, ChoiceCard, IconBadge, Stars,
                       StatTile, StatPill, ScoreRing; SVG yolları Vector.swift ile çizilir), Screens/,
                       Resources/Fonts (Outfit, JetBrains Mono TTF), PrivacyInfo.xcprivacy
  SolvatoUITests/      her ekranı koyu/açık açıp ekran görüntüsü alan testler
```

- **Web ile birebir değerler:** `node scripts/native-tokens.mjs` web'in `tokens.ts` + `tokens.css` değerlerini
  `SolvatoCore/Tests/.../Fixtures/tokens.json`'a, ikon ve yıldız yollarını `icons.json`'a döker; `TokensTests` Swift değerlerini bununla karşılaştırır. Web
  tasarım değeri değişirse betiği çalıştırın ve Swift tarafını eşitleyin.
- **Mantık web ile birebir (altın tablolar):** `node scripts/altin.mjs` React mantığını sabit tarih, saat dilimi ve
  rastgelelikle çalıştırıp girdi/çıktıları `Fixtures/altin/`'e yazar ve soru bankasını `Resources/soru-bankasi.json`'a
  döker; Swift testleri aynı girdiyle aynı çıktıyı bekler. `src/` mantığı ya da soruları değişirse betiği çalıştırın.
  Rastgelelik dışarıdan verilir (`RandomSource`; oyunlarda web'le aynı tohumlu üreteç). İstatistik JSON'u kendi küçük
  okuyucusuyla (`JSON.swift`) okunur, çünkü sözlüklerin ekleme sırası ekranda görünür (eşit yüzdeli zorlandığın notalar).
  Swift bulut oturumunda: `download.swift.org`'dan `/opt/swift`'e kurulur.
- **Derleme (Codemagic, iki iş akışı):**
  - `ios-native-test`, imzasız: `swift test`, `xcodegen generate`, iPhone / küçük iPhone / iPad simülatörlerinde UI
    testleri ve ekran görüntüleri (`native-ekranlar.zip`, adlar web referanslarıyla aynı:
    `<senaryo>-<cihaz>-<koyu|acik>.png`). main'e `ios-native/` değişikliği gönderilince kendiliğinden başlar.
  - `ios-native-testflight`: aynı adımlar + imzalı derleme ve TestFlight; elle başlatılır. Build numarası 1000 +
    Codemagic sayacı (React derlemeleriyle çakışmaz). Aynı uygulama kaydı (`com.solvato.app`).
- Tema tercihi web'le aynı anahtarda (`pianote_theme_v1`, UserDefaults). UI testleri `-UITestTheme dark|light` ile
  temayı zorlar.
- Henüz tek ekran var: tasarım sistemi önizlemesi. Gerçek ekranlar aşama 0.5'te.

## Klasör yapısı

```
src/
  main.tsx              giriş: yazı tipleri, kalıcı depolama, React kökü
  App.tsx               kabuk: ekranlar arası gezinme, tema, istatistik güncelleme, kaydırarak geri
  types.ts              ortak tipler (Question, AppStats, View, AnswerState…)

  design/               TASARIM SİSTEMİ — renk, ölçü, yazı (aşağıya bakın)
    tokens.ts           tüm değerler: palette, colors, category, radius, space, font, shadow, gradient
    tokens.css          temaya göre değişen CSS değişkenleri (koyu / açık)
    piano.ts            piyano tuşu görünümleri (tek kaynak)

  ui/                   genel arayüz parçaları: Button, Card, Chip, IconBadge, ScoreRing,
                        StatTile, ScreenHeader, BackButton, NavBar, useToast
  components/           müziğe özgü parçalar: Notation (partisyon dili), MusicalStaff, ChordStaffSvg,
                        Glyph (Bravura), piano/QuizPiano, piano/MultiPiano, MemoVisuals, Icons, Logo…
  screens/              ekranlar
    HomeScreen          Pratik (ana sayfa)
    QuizSession         soru turu (nota, ritim, terim, nota yazımı)
    ChordQuizSession    akor turu
    ResultScreen        tur sonu
    ProgressScreen      İlerleme sekmesi (+ progress/PathCard, progress/ProfileHeader)
    study/              Çalışma sekmesi (Notalar, Ritim, Akorlar, Terimler)
    GamesScreen         Oyunlar; GameResultScreen; ChordDuel
    SettingsScreen, Onboarding, Splash
    LegalScreen         Ayarlar › Gizlilik ve Lisanslar (metinler data/legal.ts)

  data/                 soru bankası (questions.ts), akorlar (chords.ts), tur seçimi (session.ts),
                        Bravura sembol yolları (smufl.ts — otomatik üretildi, elle düzenlemeyin)
  state/                istatistikler (stats.ts), tema (theme.ts)
  utils/                ayarlar, ses, titreşim, bildirim, oyun kodları, yön (yatay/tablet), kaydırarak geri
```

## Tasarım sistemi

Kural: **bileşenlerde ham renk ya da sayı yazılmaz.** Her şey `src/design/tokens.ts` üzerinden gelir.

```tsx
import { colors, palette, category, radius, space, font, alpha } from "../design/tokens"
import { Button, Card } from "../ui"

;<Card tone={category.rhythm.base}>
  <p style={{ fontSize: font.size.md, color: colors.text }}>Ritim</p>
  <p style={{ fontSize: font.size.sm, color: colors.textMuted }}>Nota değerleri</p>
  <Button onClick={start}>Başla</Button>
</Card>
```

| Grup          | Ne zaman                                                                                                                                                |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `colors.*`    | Metin, zemin, kenarlık ve vurgu metinleri. **Temaya duyarlı** (CSS değişkeni). Açık tema bunlarla çalışır.                                              |
| `palette.*`   | Temadan bağımsız sabit renkler: dolgu, gradyan, gölge. `alpha(palette.violet500, 0.12)` ile saydamlaştırılır.                                           |
| `category.*`  | Konu renkleri (treble, bass, accidentals, rhythm, writing, terms, chords, games). Ana sayfa kartı, soru etiketi ve ilerleme çubuğu aynı rengi kullanır. |
| `radius`      | `xs 4 · sm 8 · md 12 · lg 20 · pill`                                                                                                                    |
| `space`       | 4'ün katları: `space[1]=4 … space[6]=24`                                                                                                                |
| `font.size`   | `xs 12 · sm 14 · md 16 · lg 20 · xl 24 · xxl 32`                                                                                                        |
| `font.weight` | `regular 400 · medium 500 · semibold 600 · bold 700 · heavy 800`                                                                                        |

Önemli ayrım: **yazı rengi** için `colors.*Text` kullanın (ör. `colors.greenText`); koyu temada açık yeşil,
açık temada okunur koyu yeşil olur. **Dolgu/kenarlık** için `palette.*` ya da `category.*.base`.

Yeni bir renk gerekiyorsa önce `palette`'e, temaya göre değişmesi gerekiyorsa `tokens.css` (iki tema) +
`colors`'a ekleyin. Görsel referans: Solvato Tasarım Sistemi sayfası.

## Önemli kavramlar

- **Nota yazımı dili (`components/Notation.tsx`)**: `"ts:4/4 q q h ||"` gibi kısa bir dizgeyi
  Bravura sembolleriyle partisyona çevirir. Ritim ve nota yazımı soruları bunu kullanır; sözdizimi dosyanın başında.
- **Seviyeler**: `questionLevel(q)` her soruya 1–3 seviye verir (Başlangıç / Orta / İleri). 50 soruda %80
  doğrulukla seviye atlanır (`state/stats.ts`).
- **Öğretmen kodu**: öğretmenin seçtiği anahtar, seviye, notalar, günlük hedef ve tuş adları 6 karakterlik bir
  koda girer (`utils/teacherCode.ts`, ekran `screens/TeacherScreen.tsx`). Sunucu yok. Son 7 bit öğretmenin seçtiği konular
  (`TOPICS`, 0 = hepsi; eski kodlarda bu alan boş olduğu için "hepsi" açılır). Kodda artık boş bit yok.
- **Haftalık rapor**: bu takvim haftasının (Pzt–Paz, `utils/dates.ts`) özeti öğretmene düz metin olarak gider (`utils/weeklyReport.ts`; kart
  `screens/progress/WeeklyReportCard.tsx`, Profil'de de düğme). Konu bazlı veri `stats.dailyTopics`'te, son 60 gün tutulur.
  Kartın başında seri ve "bugün X soru daha, seri Y olsun" dürtmesi var. Rapor zorlanılan notaları da içerdiği için
  "Zorlandığın notalar" kartında ayrıca gönder düğmesi yok.
- **Günlük hedef portesi (`components/GoalStaff.tsx`)**: Pratik › Bugün kartında ilerleme çubuğu yerine. Hedefin her
  parçası portede bir nota (Re4'ten yukarı dizi); hedef 10'dan büyükse 10 nota çizilir.
- **Zorlandığın notalar (`state/weakNotes.ts`)**: en az 3 kez sorulup %70'in altında bilinen nota konumları. Her biri
  `MusicalStaff` ile kendi anahtarında küçük portede gösterilir (konum, ek çizgi ve diyez/bemol soru bankasından gelir).
- **Çalışma araması**: başlık, alt yazı ve bölüm adında arar; Türkçe harf ve aksan farkını yok sayar. Son açılan ders
  "Kaldığın yer" kartında çıkar (`solvato_last_lesson_v1`, yalnızca bu cihazda, yedeklenmez).
- **Tur yıldızları**: yalnızca doğruluk, %50/%70/%90 → 1/2/3 yıldız (`utils/stars.ts`). Konu başına en iyisi
  `stats.bestStars`'ta; oyun, karma günlük tur ve hata tekrarı sayılmaz.
- **Kulak**: soru bankası yok, her tur `data/ear.ts` üretir (önce Do + soru notası; akor türü). Her soruda 4 şık; akorda
  Majör/Minör/Eksik/Artık (Başlangıçta yalnız majör/minör çalınır, şıklar yine 4). Sesi
  `components/EarPrompt.tsx` çalar; ses kapalıysa soru dinlenemez, aynı yerde "Sesi aç" çıkar.
- **Ünvanlar**: seviyeden ayrı, XP ile kazanılan 15 basamak (Yeni Başlayan → Usta), `utils/level.ts` `RANKS`.
  Arayüzde "seviye" kelimesi yalnızca Başlangıç/Orta/İleri için kullanılır; XP basamakları her yerde "ünvan".
- **Kaydırarak geri (`utils/swipeBack.tsx`)**: ekranın sol kenarından kaydırınca önceki ekran altta görünür.
  Ekranların geri düğmesi `data-back` ile işaretlenir; Android geri tuşu da onu kullanır (iOS'ta etkisiz; `src/` Android'e aynen taşınabilsin diye duruyor).
- **Gizlilik ve Lisanslar (`screens/LegalScreen.tsx`, `data/legal.ts`)**: Ayarlar › Hakkında. Gizlilik metni mağazadaki
  gizlilik politikasıyla aynı içerikte tutulur (App Store 5.1.1 politikayı uygulama içinde de ister); politika değişirse
  ikisi birlikte güncellenir. Font lisansları (SIL OFL) paketlerin kendi `LICENSE` dosyalarından `?raw` ile alınır;
  yeni bir yazı tipi ya da kütüphane eklenirse `LICENSES` listesine de eklenmeli.
- **Oyunlar (`utils/games.ts`)**: sunucusuz. Aynı tohum (seed) iki telefonda aynı soruları üretir;
  meydan okuma kodu 40 bitlik bir sayıdır (kategori, seviye, tohum, doğru, süre, kontrol).
- **Depolama**: `localStorage` + `utils/persist.ts` ile telefonun kalıcı depolaması (Capacitor Preferences).

## Lisanslar

Müzik sembolleri: Bravura (SIL Open Font License), `src/data/BRAVURA-LICENSE.txt`.
