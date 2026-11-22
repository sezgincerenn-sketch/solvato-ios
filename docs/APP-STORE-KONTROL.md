# App Store uygunluk kontrolü

Tarih: 21 Kasım 2026 · Sürüm 1.0 (build 1) · Capacitor 7.6 · iOS hedefi 14.0

İşaretler: **Engel** (bu haliyle reddedilir ya da gönderilemez) · **Risk** (incelemeciye göre reddedilebilir) · **Tamam**.
"Düzeltildi" yazan maddeler bu kontrolde koddan düzeltildi, her biri ayrı commit.

## Kaynaklar (21 Kasım 2026'da web'den kontrol edildi)

- App Review Guidelines, son güncelleme 16 Ekim 2026: https://developer.apple.com/app-store/review/guidelines/
- Upcoming Requirements: https://developer.apple.com/news/upcoming-requirements/
  - 28 Nisan 2026'dan beri yüklemeler **Xcode 26 ve iOS 26 SDK** ile derlenmeli.
  - 9 Eylül 2026'dan beri en düşük hedef **iOS 13**.
  - Yaş derecesi anketinin yeni soruları 31 Ocak 2026'dan beri zorunlu.
- Required reason API'leri: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- Capacitor privacy manifest rehberi: https://capacitorjs.com/docs/ios/privacy-manifest
- Ekran görüntüsü ölçüleri: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
- Yaş dereceleri: https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions

## Özet tablo

| #   | Konu                                         | Durum                                        |
| --- | -------------------------------------------- | -------------------------------------------- |
| 0   | Xcode 26 / iOS 26 SDK, en düşük iOS          | Engel: bulut derlemede ayarlanmalı (aşağıda) |
| 1   | 4.2 Minimum işlevsellik                      | Tamam (düşük risk)                           |
| 2a  | PrivacyInfo.xcprivacy                        | Engel → **düzeltildi**                       |
| 2b  | Required reason API beyanları                | Engel → **düzeltildi**                       |
| 2c  | "Data Not Collected" ile kod uyumu           | Tamam                                        |
| 2d  | Gizlilik politikası uygulama içinde          | Engel → **düzeltildi**                       |
| 2e  | Gizlilik politikası herkese açık bir adreste | Engel: Ceren                                 |
| 3a  | İzin metinleri                               | Tamam                                        |
| 3b  | ITSAppUsesNonExemptEncryption                | Risk → **düzeltildi**                        |
| 3c  | Geliştirme dili tr                           | Risk → **düzeltildi**                        |
| 3d  | Ekran yönleri                                | Tamam                                        |
| 3e  | iPad desteği ve iPad ekran görüntüleri       | Engel: karar gerekiyor                       |
| 4   | İkon ve açılış ekranı                        | Tamam                                        |
| 5a  | Çalışmayan düğme, "yakında", test verisi     | Tamam                                        |
| 5b  | Paylaşım menüsü iptal edilince ikinci menü   | Risk → **düzeltildi**                        |
| 5c  | Sessiz modda ses (Kulak, Ritmi Tut)          | Risk: karar gerekiyor                        |
| 5d  | Reklam kodu                                  | Tamam                                        |
| 6   | 2.3 Mağaza metinleri                         | Risk: köşeli parantezler temizlenmeli        |
| 7   | Yaş derecesi 4+, Kids yok                    | Tamam                                        |
| 8   | Lisanslar                                    | Risk → **düzeltildi**                        |
| 9   | Erişilebilirlik ve temel kalite              | Tamam (iyileştirme önerileri var)            |
| 10  | App Store Connect'te doldurulacaklar         | Ceren (liste en sonda)                       |

---

## 0. Derleme gereksinimleri — Engel (bulut serviste ayar)

- **Kural:** App Store Connect'e yüklenen her derleme Xcode 26 + iOS 26 SDK ile yapılmış olmalı. Eski Xcode ile
  alınan derleme yükleme sırasında reddedilir.
- **Kanıt:** `ios/App/App.xcodeproj/project.pbxproj` içinde `IPHONEOS_DEPLOYMENT_TARGET = 14.0` (iOS 13 kuralını
  karşılıyor), `ios/App/Podfile:3` `platform :ios, '14.0'`. Capacitor 7.6 Xcode 26 ile derleniyor.
- **Yapılacak:** Bulut serviste Xcode sürümünü **26.x** seç. Codemagic kullanılırsa `codemagic.yaml`:

  ```yaml
  workflows:
    ios-release:
      environment:
        xcode: 26.1 # 26 ile başlayan herhangi bir sürüm
        node: 22
        ios_signing:
          distribution_type: app_store
          bundle_identifier: com.solvato.app
      scripts:
        - npm ci
        - npm run build
        - npx cap sync ios
        - cd ios/App && pod install
        - xcode-project use-profiles
        - xcode-project build-ipa --workspace ios/App/App.xcworkspace --scheme App
      publishing:
        app_store_connect:
          auth: integration
  ```

  Capawesome Cloud ve Capgo'da da derleme ayarlarında "Xcode version" / "stack" alanından 26 seçilir.
  İmzalama (`DEVELOPMENT_TEAM`, sertifika, profil) projede bilerek boş; servis kendi ekler.

- **Gelecek:** Apple, iOS 27 SDK ile (2027 baharı) UIKit uygulamalarından "UIScene" yaşam döngüsü isteyecek.
  `ios/App/App/AppDelegate.swift` eski düzende. Bu yayın için sorun değil; 2027'de Capacitor 8'e geçerken çözülür.

## 1. 4.2 Minimum işlevsellik — Tamam (düşük risk)

Kural: uygulama "yeniden paketlenmiş bir web sitesinin" ötesine geçen özellik, içerik ve arayüz sunmalı.

- **Uzak web sitesi yok.** Tüm uygulama pakette (`capacitor.config.ts`'de `server.url` yok); açık bir web sitesinin
  kopyası değil. Derlenmiş uygulamayı tarayıcıda açıp tüm ekranları gezdim: **dışarıya tek bir istek bile gitmedi**.
- **Native özellikler kullanılıyor:**
  - Yerel bildirim (günlük hatırlatma): `src/utils/reminder.ts`
  - Titreşim: `src/utils/haptics.ts`
  - Paylaşım menüsü (öğretmen kodu, haftalık rapor, meydan okuma): `src/utils/games.ts` `shareText`
  - Ekran yönü kilidi (sorularda yatay, diğer ekranlar dikey; iPad'de serbest): `src/utils/orientation.ts`
  - Durum çubuğu temaya göre: `src/state/theme.ts`
  - Kalıcı yerel depolama (UserDefaults): `src/utils/persist.ts`
  - Çevrimdışı çalışma, Web Audio ile sentezlenen piyano ve metronom sesi (`src/utils/audio.ts`)
- **Etkileşimli içerik:** porte okuma soruları, dokunmatik piyano, Ritmi Tut (metronomla dokunma), kulak soruları,
  akor turu, oyunlar, seviye ve ünvan sistemi, öğretmen kodu.
- **Daha da güçlendirmek istersek (ürün kararı, şart değil):** ana ekran simgesine basılı tutunca kısayollar
  ("Bugünün çalışması", "Ritmi Tut"), ana ekran widget'ı (bugünkü hedef ve seri), haftalık raporu görsel olarak paylaşma.
- **İnceleme notunda** native özellikleri bir cümleyle saymak incelemeciyi doğru yöne çeker (aşağıda hazır metin var).

## 2. Gizlilik

### 2a–2b. PrivacyInfo.xcprivacy ve required reason API — Engel → düzeltildi

- **Sorun:** `ios/App/App/` altında gizlilik bildirimi yoktu. `@capacitor/preferences` iOS'ta `UserDefaults` kullanıyor
  (`node_modules/@capacitor/preferences/ios/Sources/PreferencesPlugin/Preferences.swift:19`) ve eklenti kendi bildirimini
  getirmiyor. `UserDefaults` Apple'ın "required reason API" listesinde; beyan edilmezse yükleme ITMS-91053 ile reddedilir.
- **Diğer eklentiler tarandı:** dosya tarihi, açılış süresi, disk alanı, klavye listesi API'lerinden hiçbiri kullanılmıyor.
  Capacitor çekirdeği kendi boş bildirimini getiriyor (`node_modules/@capacitor/ios/Capacitor/Capacitor/PrivacyInfo.xcprivacy`).
- **Düzeltme:** `ios/App/App/PrivacyInfo.xcprivacy` eklendi ve Xcode projesine kaynak olarak bağlandı (Xcode açmadan,
  `project.pbxproj` üzerinden). İçerik: takip yok, toplanan veri yok, `NSPrivacyAccessedAPICategoryUserDefaults` →
  `CA92.1` (yalnızca uygulamanın kendi verisini okuyup yazma).

### 2c. "Data Not Collected" — Tamam

- Kodda `fetch`, `XMLHttpRequest`, `WebSocket`, `sendBeacon`, analitik, Firebase, Sentry, reklam SDK'sı **yok**.
- Yazı tipleri CDN'den değil, paketten geliyor (`src/main.tsx:4-13`, `@fontsource/*`).
- Paylaşım düğmeleri telefonun kendi menüsünü açıyor; metni kişi kendisi seçip gönderiyor. Apple'ın tanımında bu "toplama"
  değil (veri geliştiriciye ulaşmıyor).
- Bildirimler yerel; push sunucusu yok.

### 2d. Gizlilik politikası uygulama içinde — Engel → düzeltildi

- **Kural (5.1.1):** gizlilik politikası hem App Store Connect'te hem de **uygulama içinde kolay erişilebilir** olmalı.
- **Sorun:** Ayarlar'da gizlilik bağlantısı ya da metni yoktu (`src/screens/SettingsScreen.tsx`).
- **Düzeltme:** Ayarlar'ın sonuna **Hakkında** bölümü: "Gizlilik" sayfası politikanın içeriğini internetsiz gösteriyor
  (`src/screens/LegalScreen.tsx`, metin `src/data/legal.ts`). Politika değişirse bu metin de güncellenmeli.

### 2e. Gizlilik politikası herkese açık bir adreste — Engel (Ceren)

- "Solvato Gizlilik Politikası" dokümanı şu an yalnızca senin açabildiğin bir claude.ai sayfası. App Store Connect'e
  **herkesin giriş yapmadan açabildiği** bir adres girilmeli.
- Dokümanda iki boşluk var: `[GELİŞTİRİCİ ADI]` ve `[E-POSTA ADRESİ]`. Bunlar doldurulmadan yayınlanırsa 2.1 ve 5.1.1'e
  takılır.
- Seçenekler: GitHub Pages (bu repoda `docs/` klasöründen tek sayfa, ücretsiz), Notion "web'de yayınla", Google Sites.
  İstersen GitHub Pages sayfasını ben hazırlarım; yalnızca ad ve e-posta lazım.
- **22 Kasım:** sayfalar hazır: `node scripts/site.mjs` → `site/dist/` (ana sayfa, `/gizlilik/`, `/destek/`). Gizlilik
  metni uygulamadaki `legal.ts` `PRIVACY`'den üretilir (tek kaynak). Kalan: `site/ayarlar.json`'a geliştirici adı ve
  iletişim e-postası, alan adı (Cloudflare) ve Cloudflare Pages'te yayın.

## 3. Info.plist (`ios/App/App/Info.plist`)

### 3a. İzin metinleri — Tamam

- Kullanılan izin yalnızca bildirim; iOS bildirim izni için Info.plist metni istemiyor, sistem penceresi kendi metnini
  gösteriyor. İzin yalnızca kişi hatırlatmayı açınca isteniyor (`src/screens/Onboarding.tsx:436`,
  `src/screens/SettingsScreen.tsx:172`), reddedilince Türkçe yönlendirme çıkıyor (`SettingsScreen.tsx:177`).
- Kamera, mikrofon, konum, fotoğraf kullanılmıyor; bunlar için metin gerekmiyor.

### 3b. ITSAppUsesNonExemptEncryption — Risk → düzeltildi

- Yoktu; her yüklemede App Store Connect şifreleme sorusunu sorar ve cevaplanana kadar derleme TestFlight'a çıkmaz.
- `ITSAppUsesNonExemptEncryption = false` eklendi. Uygulama şifreleme kullanmıyor (HTTPS bile yok).

### 3c. Geliştirme dili — Risk → düzeltildi

- `CFBundleDevelopmentRegion` `en` idi. Bu yüzden paylaşım menüsü gibi sistem pencereleri Türkçe telefonda bile
  İngilizce açılabilir ve App Store dil satırında yanlış dil görünebilir (2.3 metadata).
- Düzeltme: `CFBundleDevelopmentRegion = tr`, `CFBundleLocalizations = [tr]`, Xcode projesinde `developmentRegion = tr` ve
  `tr.lproj/InfoPlist.strings` (uygulama adı "Solvato").

### 3d. Ekran yönleri — Tamam

- iPhone: dikey + iki yatay; uygulama soru ekranları dışında dikeye kilitliyor (`src/utils/orientation.ts`).
  iPad: dört yön, kilit yok. Bu, iPad'de çoklu görev (Split View) için Apple'ın beklediği ayar.
- `UIRequiredDeviceCapabilities` `armv7` (Capacitor şablonu). Yayındaki Capacitor uygulamalarında da böyle; dokunmaya gerek yok.

### 3e. iPad desteği — Engel (karar gerekiyor)

- `project.pbxproj` `TARGETED_DEVICE_FAMILY = "1,2"` → uygulama iPad'de de yayınlanacak. Mağaza açıklamasında da
  "iPhone ve iPad'de" yazıyor ve uygulamada iPad düzeni var (`src/ui/TabletColumn.tsx`, `useTablet`).
- **Kural:** iPad destekleniyorsa **13 inç iPad ekran görüntüsü zorunlu** (2064×2752 ya da 2048×2732). Elimizde yalnızca
  iPhone görüntüleri (1290×2796) var; bu haliyle "İncelemeye gönder" düğmesi açılmaz.
- **İki yol:**
  1. iPad'i koru: 13 inç görüntüleri hazırla (ham ekranları ben Playwright ile 2048×2732 çekebilirim, sen çerçeveye
     koyarsın). Kapalı testte iPad'de bir tur denenmeli; incelemeciler uygulamayı iPad'de de açar.
  2. Yalnız iPhone: `TARGETED_DEVICE_FAMILY = 1` (tek satır) ve mağaza metninden "iPad" çıkar. iPad kullanıcıları
     uygulamayı yine iPhone uygulaması olarak kurabilir.

## 4. İkon ve açılış ekranı — Tamam

- `ios/App/App/Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png`: 1024×1024, RGB, **saydamlık yok**.
- Xcode 14'ten beri tek 1024'lük "universal" ikon yeterli; diğer boyutları Xcode kendisi üretiyor
  (`AppIcon.appiconset/Contents.json`).
- Açılış ekranı `Base.lproj/LaunchScreen.storyboard` düz koyu zemin (#0F172A), ardından uygulamanın kendi açılış
  animasyonu geliyor. `Splash.imageset` kullanılmıyor ama zararı yok.

## 5. 2.1 Tamamlık

### 5a. Çalışmayan düğme, "yakında", test verisi — Tamam

- `src` içinde "yakında", "coming soon", "lorem", `TODO`, `console.log` yok.
- Tüm Ayarlar, Oyunlar, Çalışma ve Profil girişlerinin bir ekranı var. Sürüm yazısı (`Sürüm 1.0`) proje sürümüyle aynı.
- İlk açılışta boş ekran yok: tanıtım ve iki deneme sorusuyla başlıyor.

### 5b. Paylaşım iptali — Risk → düzeltildi

- Telefonda paylaşım menüsü kapatılınca hata yakalanıp tarayıcının paylaşım menüsü **ikinci kez** açılıyordu
  (`src/utils/games.ts` `shareText`). İncelemeci bunu "bozuk" diye not edebilirdi. Artık iptal sessizce kapanıyor,
  "Paylaşılamadı" uyarısı da çıkmıyor.

### 5c. Sessiz modda ses — Risk (karar gerekiyor)

- Ses Web Audio ile çalıyor; iPhone'un yan düğmesi sessizdeyse **hiç ses gelmez**. Kulak soruları ve Ritmi Tut sese
  dayanıyor. İncelemeci telefonu sessizde tutuyorsa "Kulak çalışmıyor" diye reddedebilir. Ayarlar'da "Telefon
  sessizdeyse ses gelmeyebilir" uyarısı var ama soru ekranında yok.
- **Önerim:** `AppDelegate.swift`'e iki satır: ses oturumu `playback` + `mixWithOthers`. Sonuç: sessiz modda da ses gelir
  (müzik uygulamalarında beklenen davranış), arkada çalan müzik durmaz. Davranış değiştiği için sana soruyorum.
- Ayrıca inceleme notuna "Kulak ve Ritmi Tut için telefon sessizde olmamalı" yazılabilir.

### 5d. Reklam — Tamam

- Reklam kodu 21 Kasım'da tamamen silindi (`utils/ads.ts` ve ana sayfadaki boş banner alanı). Reklam SDK'sı yok, ağ isteği yok.

## 6. 2.3 Mağaza metinleri — Risk

"Solvato Mağaza Metinleri" dokümanı okundu ve uygulamayla karşılaştırıldı.

- **Uyuyor:** "Her tur 10 soru" (`src/data/session.ts:8`), "15 ünvan" (`src/utils/level.ts` `RANKS`), kulakta majör/minör/
  eksik/artık, Günün meydan okuması / Arkadaşına meydan oku / Akor düellosu (`src/screens/GamesScreen.tsx`), öğretmen kodu,
  haftalık rapor, günlük hatırlatıcı, "internet olmadan çalışır", "hesap gerekmez". Ad 19, alt başlık 27 karakter (sınır 30).
- **Düzeltilmeli:**
  - Açıklamadaki `[Reklamsız kalacaksa: Reklam yok.]` köşeli parantezi. Karar verildi (reklamsız), "Reklam yok." olarak bırak.
    Köşeli parantezli metin yer tutucu sayılır (2.1, 2.3).
  - "iPhone ve iPad'de" cümlesi 3e'deki karara göre kalır ya da çıkar.
  - Tanıtım metnindeki "Yeni:" ilk sürümde biraz garip durur ama kural ihlali değil.
- **Ekran görüntüleri:** 1290×2796, iPhone 6,9 inç grubunda kabul edilen bir ölçü. Arayüz değiştiği için (Ayarlar'a
  Hakkında eklendi) mevcut 7 karede etkilenen yok.

## 7. Yaş derecesi ve Kids — Tamam

- Beklenen sonuç **4+**. Yeni ankette (2025'te yenilendi) hepsine "Hayır / Yok":
  şiddet, korku, cinsellik, küfür, alkol-tütün, kumar, tıbbi içerik, **sınırsız web erişimi**, **kullanıcılar arası
  mesajlaşma**, **kullanıcı içeriği**, reklam, ebeveyn denetimi, yaş doğrulama.
- **Paylaşım menüsü 4+ için sorun değil:** uygulama içinde sohbet ya da kullanıcı içeriği yok; menü iOS'un kendi penceresi
  ve kişinin kendi seçtiği uygulamaya gidiyor. Uygulamada dış bağlantı (web adresi) yok.
- **Kids kategorisi seçilmiyor:** Kids'te (1.3) uygulamadan dışarı çıkan her adım ebeveyn kapısı ister; paylaşım menüsü
  buna takılırdı. Kids dışında 4+ uygulama çocuklara yine açık. Mağaza metninde "çocuklar için" ifadesi kullanılmamalı
  (2.3.8: bu ifade Kids kategorisine ayrılmış); şu anki metinde yok.

## 8. Lisanslar — Risk → düzeltildi

- **Bravura, Outfit, JetBrains Mono: SIL OFL 1.1.** OFL, yazı tipi yazılımla dağıtılırken telif satırı ve lisans
  metninin birlikte verilmesini istiyor. Lisans metni repoda vardı (`src/data/BRAVURA-LICENSE.txt`) ama uygulamaya
  girmiyordu. Bravura'nın "Reserved Font Name" koşulu bizi etkilemiyor (yazı tipini yeniden adlandırıp dağıtmıyoruz).
- **React, Capacitor ve eklentileri: MIT.** Telif satırı ve izin metni dağıtımda bulunmalı.
- **Düzeltme:** Ayarlar › Hakkında › **Lisanslar** sayfası. Font lisansları paketlerin kendi `LICENSE` dosyalarından
  derleme sırasında alınıyor (`src/data/legal.ts`), elle kopyalanmadı. Apple bu sayfayı istemiyor; lisanslar istiyor.

## 9. Erişilebilirlik ve temel kalite — Tamam (iyileştirme önerileri)

- **VoiceOver:** piyano tuşları ("Do tuşu", "Orta Do tuşu"), geri düğmesi, yıldızlar, skor halkası, diyaloglar
  etiketli (`src/components/piano/QuizPiano.tsx:89,165`, `src/ui/Stars.tsx`, `src/ui/ScoreRing.tsx`,
  `src/ui/ExitConfirm.tsx`). Porte "Müzik portesi" olarak okunuyor; notayı söylemiyor (soruyu çözmüş olurdu).
- **Dinamik yazı boyutu:** web görünümü iOS'un yazı boyutu ayarını izlemiyor ve yakınlaştırma kapalı
  (`index.html:7` `user-scalable=no`). Ret sebebi değil. App Store Connect'teki isteğe bağlı "Accessibility Nutrition
  Labels" bölümünde **Larger Text işaretleme**; yalnızca test ettiğimiz şeyleri işaretle (önerim: şimdilik boş bırak).
- **iPhone SE (375×667):** ana sayfa, Ayarlar, Gizlilik ve Lisanslar koyu ve açık temada açıldı; yatay taşma yok,
  düğmeler tek satır.
- **Çevrimdışı:** derlenmiş uygulama hiçbir dış adrese istek atmadı; yazı tipleri ve sesler pakette.
- **Gerçek cihazda bakılacak (kapalı test):** bildirimin gelmesi, Ritmi Tut gecikmesi, iPad, sessiz mod.

## 10. App Store Connect'te Ceren'in yapacakları

1. **Gizlilik politikası URL'si:** politikayı ad ve e-postayla doldurup herkese açık bir adreste yayınla (2e).
2. **Destek URL'si (zorunlu):** e-posta değil, bir web adresi. İçinde iletişim e-postası olan tek sayfa yeter
   (gizlilik sayfasıyla aynı sitede olabilir).
3. **App Privacy formu:** "Data Not Collected" (Veri toplanmıyor). Takip: Hayır.
4. **Yaş derecesi anketi:** her soruya "Hayır / Yok" (7. madde) → 4+. Kids kategorisini seçme.
5. **Export compliance:** Info.plist'teki anahtar sayesinde sorulmayacak; sorulursa "Hayır, şifreleme kullanmıyor".
6. **Fiyat:** Ücretsiz. Uygulama içi satın alma yok.
7. **Ekran görüntüleri:** iPhone 6,9 inç (1290×2796) mevcut. iPad'i koruyacaksak 13 inç iPad (2048×2732) da.
8. **Telif hakkı alanı:** "2026 [adın]".
9. **Kategori:** Eğitim, ikincil Müzik.
10. **İnceleme notu** (App Review Information › Notes), hazır metin:

    > Solvato is a piano note-reading practice app for students (Turkish UI). No account or login is needed; all
    > data stays on the device and nothing is sent to a server.
    >
    > Native features: daily local reminder notification (Settings › Günlük hatırlatma), haptics, iOS share sheet
    > (teacher code, weekly report, challenge codes), orientation lock, full offline use.
    >
    > To try the teacher code: Settings › Öğretmen kodu, enter **367-GJ3**. It sets treble clef, beginner level,
    > a 10-question daily goal and the topics "Treble clef" and "Rhythm".
    >
    > The ear-training questions and the "Ritmi Tut" rhythm game use sound: please make sure the device is not in
    > silent mode.

    "Sign-in required" kutusunu **işaretleme**. İletişim bilgisi olarak adın, telefonun ve e-postan istenecek.

## Karar bekleyenler

1. **iPad:** koruyup 13 inç görüntü mü hazırlayalım, yoksa yalnız iPhone mu? (3e)
2. **Sessiz mod:** sessizde de ses gelsin mi? (5c)
3. **Gizlilik sayfasının adresi:** GitHub Pages'i ben kurayım mı? (2e)

## Özellik kontrolleri

Her yeni özellik ya da bağımlılıktan sonra kısa kontrol (`bitir` becerisi, adım 4b). Tam kontrol her sürümde `/magaza-kontrol`.

| Tarih      | Değişiklik                                | Sonuç                                                                 |
| ---------- | ----------------------------------------- | --------------------------------------------------------------------- |
| 21.11.2026 | Sessiz modda ses (AppDelegate)            | Tamam: yeni izin yok, ağ isteği yok. 5c kapandı; cihazda doğrulanacak |
| 21.11.2026 | Codemagic derlemesi, Android'in ayrılması | Tamam: Xcode 26+ derlemede kontrol ediliyor (madde 0)                 |
