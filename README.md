# Solvato

Piyano öğrencileri için nota okuma, ritim, akor ve müzik terimleri pratiği. iPhone ve iPad uygulaması: **Swift +
SwiftUI** (`ios-native/`), yalnız Apple çatıları, üçüncü taraf kod yok. Sunucu yok, hesap yok; tüm ilerleme telefonda.

Uygulama 21–27 Kasım 2026'da React + Capacitor sürümünden birebir native'e taşındı (`docs/PLAN.md` Paket 0,
`docs/ozellikler/native-ios.md`). React kodu main'den silindi; son hâli **`web-arsiv`** dalında (Android işi başlayınca
oradan alınır; `solvato-android` dondurulmuş eski kopya). Kodda geçen "web `src/...`" ve `scripts/altin.mjs` gibi adlar o
dalda. Analitik sunucusu ve admin paneli `solvato-admin` reposunda (1.1).

Ürün kararları ve yol haritası: `docs/URUN.md`. Claude Code ile çalışma kuralları: `CLAUDE.md`,
çalışma sistemi (beceriler, kancalar, iş akışı): `docs/CALISMA-SISTEMI.md`.

## Ritmi Tut (ritim oyunu)

- Ekran `Solvato/Screens/RhythmTapScreen.swift`; ritimler ve puanlama `SolvatoCore/Logic/RhythmTap.swift`, akış
  `App/RhythmTapRound.swift`. Giriş: ana sayfada Ritim & Ölçü kartının altı. Tur 6 ritim; sonuç ortak tur sonucu ekranında.
- Her ritim tek ölçü 4/4, Notation dilinde yazılır; dokunulacak anlar aynı metinden hesaplanır (çizilen = ölçülen).
  Seviyeler: Başlangıç dörtlük/ikilik/sekizlik çifti; Orta + onaltılıklar ve noktalı dörtlük; İleri + noktalı
  sekizlik–onaltılık, senkop. Tempo 76/66/72. Yeni ritim eklerken toplam 4 vuruş olmalı.
- Zamanlama: metronom tıkları ve dinlerken notalar ses saatine (`Sound.now`) önceden zamanlanır, dokunuş aynı saatle
  ölçülür ve çıkış gecikmesi düşülür. Pencere: tam ±90 ms (başlangıçta ±110), yakın ±180 ms (±200). Dokunma alanı her
  parmağı ayrı sayar (`UI/TouchDownPad.swift`); VoiceOver açıkken de doğrudan dokunulur. %70 ve üstü "geçti".
- Gerçek telefonda test edilmeli: dokunuş gecikmesi cihaza göre değişir (kapalı test, `docs/KAPALI-TEST.md`).

## Marka

- Ad: **Solvato** (_solve_ "çöz" + müzikteki _-ato_ eki). Yazıda "Solv" kalın, "ato" mor (`UI/Logo.swift`).
- Logo: piyano tuşları; üçüncü (sarı) tuşta anahtar deliği. Aynı geometri açılış animasyonunda (`SplashScreen.swift`).
- Maskot: **Solfie** (sekizlik nota, amber bayrak), `UI/Solfie.swift`; `SolfieSays` konuşma balonuyla. Pozlar: `idle`,
  `wave`, `cheer`. Az görünür: tanıtım, tur sonucu, kutlama.
- Uygulama kimliği: `com.solvato.app`.
- Eski ad Notalık'tı. Depolama anahtarları **bilerek değiştirilmedi**: `pianote_settings_v1`, `notausta_stats_v1`,
  `notalik_rotate_hint_v1`, `notalik-daily` vb. Yeni anahtar `solvato_` önekiyle; eskileri yeniden adlandırmayın.

## Hızlı başlangıç

```bash
cd ios-native/SolvatoCore && swift test     # çekirdek testleri (Linux'ta da koşar)
python3 scripts/native-guvenlik.py          # güvenlik taraması
npm install && npx prettier --write docs/x.md   # dokümanları biçimle (tek npm bağımlılığı Prettier)
node scripts/site.mjs                       # gizlilik/destek sitesi → site/dist
```

Arayüz (SwiftUI) Mac gerektirir; Mac yok, GitHub Actions'ın Mac sunucusunda derlenir:

- **`native-ekranlar.yml`** (`main`e `ios-native/` gönderilince): uygulamayı derler, `ios-native/ui-testleri.txt`'te
  seçilen UI testlerini iPhone / küçük iPhone / iPad simülatöründe koşar (`scripts/native-ui-testleri.sh`). Küçültülmüş
  görüntüler, hata özetleri, `performans.md` tablosu ve erişilebilirlik denetimi **`ekranlar` dalında**; tam boy PNG'ler
  koşunun Artifacts bölümünde. Ayrı bir Linux işi güvenlik taramasını yapar.
- **`cekirdek-testleri.yml`**: her gönderimde Linux'ta `swift test`.
- **`testflight.yml`** (elle: Actions › TestFlight › Run workflow, ya da Claude başlatır): imzalar ve TestFlight'a yükler;
  build 2000 + koşu numarası; özette uygulama boyutu. Sırlar ve kurulum: `docs/IOS-TEST-REHBERI.md` Bölüm B2.
- Ses oturumu `.playback` + `.mixWithOthers`: sessiz düğme açıkken de ses çalar, arkadaki müzik durmaz.

## Uygulamanın yapısı

Uygulama `ios-native/` klasöründe:

```
ios-native/
  project.yml          Xcode projesinin tanımı (XcodeGen); .xcodeproj repoda yok, derlemede üretilir
  SolvatoCore/         arayüzden bağımsız Swift paketi (Linux'ta da derlenir): tasarım değerleri, tema tercihi;
                       Logic/ (soru bankası, seviye, ünvan, yıldız, seri, tur sonu, öğretmen ve meydan okuma kodu,
                       oyunlar, soru seçimi, kulak soruları, akorlar ve akor turu, Ritmi Tut puanlama, haftalık rapor, kalıcı depolama), Resources/soru-bankasi.json. Testler: `swift test`
                       Audio/Synth.swift (bütün sesler kodla: Sounds, web utils/audio.ts ile aynı dalga ve zarf; SynthMixer: örnek
                       doğruluğunda zamanlama ve ses saati),
                       Notation/ (nota çizimi yerleşimi: Notation dili, portesi, akor ve hedef portesi → çizim listesi;
                       Piano: klavye tuşları, durumları, renkleri; Diagrams: Çalışma'daki şema klavye), App/ (ScreenStack: gezinme kuralları;
                       AppModel: uygulama durumu ve tur akışı, web App.tsx; ScrollMemory: geri dönünce kaydırma konumu; HomeContent, QuizRound, ResultContent, TeacherFlow, StudyContent (dersler, terimler, arama), ChordStudyContent (akor kartları), NoteStudyContent (nota ve ezber dersleri), GameScreensContent (oyunlar), DuelGame (akor düellosu), RhythmTapRound (Ritmi Tut akışı): ekran içerikleri;
                       Legal: Gizlilik/Lisanslar metinleri, Resources/hukuk.json (tek kaynak, site de okur);
                       TestScenario: UI test senaryosu, bellekte depo),
                       Resources/smufl.json (Bravura sembol yolları, web'le aynı)
  Solvato/             SwiftUI uygulaması: Design/ (renk → Color, yazı tipleri, CSS gradyanı), UI/ (web src/ui ile
                       aynı adlarla: AppButton, AppCard, Icon, Logo, Chip, Segmented, ChoiceCard, IconBadge, Stars,
                       StatTile, StatPill, ScoreRing; Shell.swift: Avatar, BackButton, ScreenHeader, Toast, PlayChip,
                       TopicLink, ExitConfirm, NavBar (yüzen kapsül, iOS 26'da cam), TabletColumn; PercentRing.swift: yüzde halkası, GoalBar, TabTitle; FlowLayout; CodeField (kod girişi); SVG yolları Vector.swift ile çizilir), Notation/ (DrawingView: çizim listesini
                       Canvas'a çizer; NotationView, MusicalStaffView, ChordStaffView, GoalStaffView, ClefIconView; PianoViews: QuizPianoView,
                       MultiPianoView), Screens/, Audio.swift (AVAudioEngine çıkışı `Sound`, ses saati, titreşim `Haptics`),
                       UI/Motion.swift (sallanma, nabız, kayarak/büyüyerek belirme, seri alevi, nota zıplaması, "yan çevir" ipucu),
                       UI/ScrollMemoryProbe.swift (`.remembersScroll`: kaydırma alanının konumunu bildirir ve geri yükler),
                       Resources/Fonts (Outfit, JetBrains Mono TTF), PrivacyInfo.xcprivacy
  SolvatoUITests/      ekran görüntüsü testleri (ScreenshotTests), büyük yazı / iPad / erişilebilirlik denetimi
                       (AccessibilityTests), performans ölçümleri (PerformanceTests); ortak yardımcılar UITestSupport
```

- **Erişilebilirlik ve iPad (0.8, `docs/ozellikler/erisilebilirlik-ipad.md`):** yazılar telefonun yazı boyutuyla
  büyür (`Font.ui` ölçeklenir, büyümemesi gerekenler `Font.uiFixed`; sınır `AppTypeSize`: uygulama xxxLarge, turlar
  xxLarge). VoiceOver metinleri `SolvatoCore/App/AccessibilityText.swift`'te (testli; soru portesinde nota adı yok),
  duyurular `UI/Accessibility.swift` (`Announce`). iPad'de düzen pencere genişliğine bakar (Split View / Stage Manager).
  Her `ios-native` gönderiminde: `scripts/native-guvenlik.py` (ağ API'si, dış adres, bağımlılık, gizlilik bildirimi; kaynak
  ve derlenmiş paket), iPhone'da `PerformanceTests` → `ekranlar` dalında `performans.md` (sınır aşılırsa iş kırmızı),
  `AccessibilityTests` seçilirse büyük yazı, iPad dört yön ve otomatik erişilebilirlik denetimi (`denetim-<cihaz>.txt`).
  `ui-testleri.txt`'te `Sınıf/test` biçimi de olur.
- Kalıcı veriler web'le aynı anahtar adlarıyla Application Support/Solvato altında dosya (`Persistence.swift`; veri
  korumalı, son ders yedek dışı). UI testleri `-UITestTheme dark|light` ile temayı zorlar.
- Uygulama Pratik ile açılır (`AppRoot.swift`). Tasarım sistemi önizlemesi yalnız `-UITestDesignSystem` ile. UI testleri
  `SolvatoUITests/senaryolar.json` senaryolarını ortam değişkeniyle verir, uygulama o veriyle bellekte ve sabit tarihle
  açılır; görüntü adları `<senaryo>-<cihaz>-<koyu|acik>`.
- **Gezinme revizesi (yalnız native, `docs/ozellikler/gezinme.md`):** dört sekme Ana sayfa · İlerleme · Öğren · Profil
  (Profil sekme oldu; öğretmen kodu kartı Profil'de). `ana-sayfa.json` ve `ilerleme.json` altın
  tabloları bu revizeye göre.
- **Tanıtım revizesi (yalnız native, `docs/ozellikler/tanitim.md`):** tanıtım giriş ekranıyla açılır, geri oku var,
  denemelerden sonra öğretmen sorusu (`teacherRole`: student / self / teacher). Adım sırası `SolvatoCore` `OnboardingFlow`;
  "Ben öğretmenim" seçilince tanıtım biter ve öğretmen kodu ekranı yalnız hazırlama bölümüyle açılır. Öğretmen kodu
  ekranının bölümü role göre (`TeacherSection`). Hatırlatma saati her yerde aynı saat satırı (`UI/TimeField.swift`, saat
  çarkı); yeni ayar `reminderMinute` (0–59). Ayarlar'daki alt yazı Türkçe eke uyar: "Her gün 07:45'te", "19:00'da".
- **Revizeler (yalnız native, 26 Kasım; `docs/ozellikler/tasarim-revize.md`):** tur noktaları doğru/yanlış renginde
  (R2, `RoundDots` → `UI/RoundDotsView`); turların sol üstünde hep çarpı (R16, `RoundCloseButton`); turlarda da kenardan
  kaydırınca ekran kayar, bırakınca çıkış onayı (R34, `AppRoot`); Ritmi Tut'ta güçlü titreşim (R22, `Haptics.beat`);
  kod kutusunda tire kendiliğinden (R31, `formatCodeInput`) ve "Kodu yapıştır" (R30, `codeFromPaste`: mesajın tamamından
  kodu bulur); paylaşım mesajlarında kod en üstte; Diyez-bemol dersinde bemol sekmesi korunur (R10); "Ezber cümleleri" →
  "Kolay hatırla" (R33; `calisma.json` altın tablosunda bu başlıklar elle değişti); tur sonunda bir kez "Serini koru" teklifi (R8, `ReminderOffer`, yeni ayar `reminderOffered`); paylaşım mesajlarının
  sonunda App Store bağlantısı (R32, `AppStoreLink`, Apple ID 6837820383; ekleme `AppButton` ve haftalık rapor
  düğmelerinde, altın tablolardaki metinler bağlantısız kalır).
- **0.9 karşılaştırması (27 Kasım):** dört `inceleyici` ile envantere göre ekran ekran bakıldı; düzeltilenler: sekmeye
  geçince sayfa yeniden kurulur (`SystemTabs` `.id`, web gibi en üstten ve güncel ayarla), ipucu turu katmanı bütün
  dokunuşları tutar, Ritmi Tut'ta çoklu dokunuş (`UI/TouchDownPad`) ve bitiş sesi kesilmez, akor şıkları 60 pt (iç boşluk
  dahil), süre sayacı başlangıca bağlı, tanıtım satır araları, yer tutucu rengi `textFaint`, açılış notalarının solması,
  Hareketi azalt'ta açılış anında kalkar, Sistem temasında pencere ayarı da güncellenir.
- **Ayarlar düzeni (yalnız native, `docs/ozellikler/ayarlar.md`):** dört kart (Çalışma · Sorular · Ses ve bildirim ·
  Diğer); satırda o anki değer, dokununca seçim penceresi (`UI/SettingsRows.swift`, değer yazıları `SettingsText`).
  Çalışılacak notalar ayrı ekran (`AppView.notes`). Hatırlatma saati Ayarlar'da satır ("19:00 ›"), tanıtımda büyük kutu.
- **Turdan çıkış (yalnız native, `docs/ozellikler/tur-ekranlari.md`):** ✕ ve kenardan kaydırma `AppModel.exitRound`'u
  çağırır: turda cevap verildiyse (`roundHasAnswers`, ekran `hasAnswers`'tan bildirir) onay açılır, yoksa sormadan geri
  dönülür. Akor düellosunda da ✕.

## Tasarım sistemi

Kural: **ham renk ya da sayı yazılmaz.** Değerler `SolvatoCore/Tokens.swift` ve `Colors.swift`'te (web `tokens.ts`'ten
birebir alındı, `TokensTests` doğrular); SwiftUI tarafı `Solvato/Design/` (`Theme.swift`, `Typography.swift`).

| Grup                 | Ne zaman                                                                                                     |
| -------------------- | ------------------------------------------------------------------------------------------------------------ |
| `ThemeColor.*`       | Metin, zemin, kenarlık ve vurgu metinleri; **temaya duyarlı** (koyu/açık). Açık tema bunlarla çalışır.       |
| `PaletteColor.*`     | Temadan bağımsız sabit renkler: dolgu, gradyan, gölge. `.opacity(0.12)` ile saydamlaştırılır.                |
| `CategoryColor.*`    | Konu renkleri (treble, bass, accidentals, rhythm, writing, terms, chords, ear); `.base` dolgu, `.text` yazı. |
| `Radius`, `Space`    | `xs 4 · sm 8 · md 12 · lg 20`; 4'ün katları                                                                  |
| `FontSize`, `.ui(…)` | `xs 12 · sm 14 · md 16 · lg 20 · xl 24 · xxl 32`; `Font.ui` / `.mono` / `.term`, büyümeyen yerde `…Fixed`    |

Yazı rengi için `ThemeColor.*Text` (ör. `greenText`): koyu temada açık, açık temada okunur koyu ton. Okunan yazıda
`textFaint` kullanmayın (kontrast; yalnız yer tutucu ve süs).

## Önemli kavramlar

- **Nota yazımı dili (`SolvatoCore/Notation/Notation.swift`)**: `"ts:4/4 q q h ||"` gibi kısa bir dizgeyi Bravura
  sembolleriyle partisyona çevirir; çizim listesi `Notation/Drawing.swift`, ekranda `Notation/DrawingView.swift`.
- **Seviyeler**: her soru 1–3 seviyede (Başlangıç / Orta / İleri). 50 soruda %80 doğrulukla seviye atlanır
  (`Logic/Progress.swift`).
- **Öğretmen kodu**: anahtar, seviye, notalar, günlük hedef, tuş adları ve konular 6 karakterlik koda girer
  (`Logic/Codes.swift`, ekran `TeacherScreen.swift`). Sunucu yok; bozuk girdi testleri `InputFuzzTests`.
- **Haftalık rapor**: bu takvim haftasının özeti öğretmene düz metin (`Logic/WeeklyReport.swift`).
- **Zorlandığın notalar**: en az 3 kez sorulup %70'in altında bilinen nota konumları (`App/ProgressContent.swift`).
- **Tur yıldızları**: yalnızca doğruluk, %50/%70/%90 → 1/2/3 yıldız; konu başına en iyisi saklanır.
- **Kulak**: soru bankası yok, her tur üretilir (önce Do + soru notası; akor türü); sesler `Audio/Synth.swift`.
- **Ünvanlar**: seviyeden ayrı, XP ile kazanılan 15 basamak (`Logic/Rank.swift`). "Seviye" yalnız Başlangıç/Orta/İleri.
- **Kaydırarak geri (`AppRoot.swift`)**: sol kenardan kaydırınca önceki ekran altta görünür; turlarda çıkış onayı.
- **Gizlilik ve Lisanslar**: metinler `Resources/hukuk.json` (uygulamanın Gizlilik/Lisanslar ekranları ve
  `scripts/site.mjs` aynı dosyayı okur). Politika değişirse burada değişir; yeni yazı tipi ya da kod `licenses`'a.
- **Oyunlar (`Logic/Games.swift`)**: sunucusuz; aynı tohum iki telefonda aynı soruları üretir, meydan okuma kodu 40 bit.
- **Erişilebilirlik**: Dinamik Yazı (xSmall–xxxLarge, turlarda xxLarge), VoiceOver metinleri
  `App/AccessibilityText.swift`, Hareketi azalt `UI/Motion.swift` (`docs/ozellikler/erisilebilirlik-ipad.md`).
- **Web'den dökülen veriler**: altın tablolar (`Tests/.../Fixtures/`), `soru-bankasi.json`, `smufl.json`, `senaryolar.json`
  React sürümünden döküldü; üreten betikler `web-arsiv` dalında. Bundan sonra elle düzenlenir, testlerle birlikte.

## Lisanslar

Müzik sembolleri: Bravura; yazı tipleri: Outfit, JetBrains Mono (hepsi SIL Open Font License). Metinler `hukuk.json`.
