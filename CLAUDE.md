# CLAUDE.md

Claude Code'un bu repoda nasıl çalışacağı. Kodun yapısı `README.md`'de, ürün kararları ve yol haritası `docs/URUN.md`'de,
çalışma sisteminin Ceren'e anlatılmış hali `docs/CALISMA-SISTEMI.md`'de.

## Kiminle çalışıyorsun

- Proje sahibi **Ceren**. Kod yazmıyor; ürünü, tasarımı ve yayını o yönetiyor. Kodu ileride bir geliştirici arkadaşı
  devralacak.
- **Her zaman Türkçe yanıt ver.** Teknik terimleri gerektiği kadar kullan, ne değiştiğini ekranda göreceği haliyle anlat
  ("Pratik sayfasındaki Bugün kartı…"), dosya ve fonksiyon adlarını yalnızca gerekirse an.
- **Ajanlarla İngilizce:** alt ajanlara (subagent, `inceleyici` dahil) verdiğin görevleri İngilizce yaz; raporlarını da
  İngilizce iste. Ceren'e aktarırken Türkçeye çevir. Ceren'le her zaman Türkçe.
- Ceren'in bilgisayarında git, IDE ve Mac yok; bulut oturumlarından ve telefondan çalışıyor. Commit ve push'u sen
  yaparsın; o sonucu GitHub'da ve TestFlight'ta görür. iOS derlemesi bulut serviste alınır: Xcode'da elle yapılacak bir
  ayar gerekiyorsa onu proje dosyasından yap ya da nasıl yapılacağını göster.

## Repolar

- **Bu repo (`solvato-ios`)**: aktif geliştirme, iPhone + iPad. Değişiklikler buraya, `main`e.
- **Uygulama native (Swift/SwiftUI, `ios-native/`)**; web görünümü ve üçüncü taraf kod yok. React web kodu (`src/`,
  Capacitor `ios/`) 27 Kasım'da main'den silindi; son hâli **`web-arsiv`** dalında. Kodda ve dokümanlarda geçen
  `src/...`, `scripts/altin.mjs`, `scripts/referans.mjs` gibi adlar o dalda. `web-arsiv` dalına commit atma.
- `solvato-android`: dondurulmuş kopya; Android işi başlayana kadar **kod yazma**. Başlayınca web kodu `web-arsiv`
  dalından alınır (Android'e özel parçalar, ör. geri tuşu, orada duruyor).
- `solvato-admin`: analitik sunucusu, veritabanı ve admin paneli (1.1, `docs/PLAN.md`).
- **`solvato` reposu yedek: ona hiçbir şekilde dokunma** (commit, push, dal, etiket yok). Bugünkü React sürümünün
  çalışan kopyası olarak olduğu gibi kalır. Değişiklikler yalnızca `solvato-ios` ve `solvato-android`'de.
- **Birebir uyum:** native sürüm React sürümüyle birebir aynı yazıldı (aynı ekranlar, metinler, renkler, ölçüler,
  animasyonlar ve kurallar; `docs/ozellikler/native-ios.md`). Bilinçli farklar o dokümanın "Bilinçli farklar"
  bölümünde; yeni bir fark gerekiyorsa önce Ceren'e sor. Eski davranışa bakmak için `web-arsiv` dalı ve altın tablolar
  (`ios-native/SolvatoCore/Tests/SolvatoCoreTests/Fixtures/`).

## Çalışma şekli

- Küçük, net istekleri doğrudan yap. Geri dönmesi zor ya da birden çok yoruma açık işlerde önce tek soru sor.
- Birden çok ekranı etkileyen ya da ürün kararı içeren isteklerde koda geçmeden **`ozellik`** becerisiyle özellik
  dokümanı yaz (`docs/ozellikler/`). Uygulama ayrı oturumda o dokümandan yapılır.
- Kod değiştiren her işi **`bitir`** becerisiyle bitir (testler, ekranlar, README, commit, push, TestFlight, özet).
- **İş akışı:** değişiklik TestFlight'tan denenir. Çekirdek: `cd ios-native/SolvatoCore && swift test`. Ekranlar:
  `main`e gönderince GitHub Actions görüntüleri, performans tablosunu ve erişilebilirlik denetimini `ekranlar` dalına
  koyar (seçim `ios-native/ui-testleri.txt`, yalnız değişen ekranların testleri). TestFlight: GitHub Actions
  `testflight.yml` (`mcp__github__actions_run_trigger`, ref `main`). Codemagic kullanılmaz.
- Bir özellik bitince main'e göndermeden önce **`inceleyici`** ajanına dokümana göre inceletebilirsin; yalnız doğruluk
  bulgularını düzelt.
- Kanıtla konuş: "geçti" deme, komutu ve sonucunu ya da ekran görüntüsünü göster.

## Komutlar

```bash
cd ios-native/SolvatoCore && swift test     # çekirdek testleri (mantık, metinler, çizim, sesler; Linux'ta da koşar)
python3 scripts/native-guvenlik.py          # ağ API'si, dış adres, bağımlılık, gizlilik bildirimi taraması
npx prettier --write README.md docs/x.md    # dokümanları biçimle
node scripts/site.mjs                       # gizlilik/destek sitesi (site/dist), metin hukuk.json'dan
```

Arayüz (SwiftUI) burada derlenmez; GitHub Actions'ın Mac sunucusunda derlenir (`native-ekranlar.yml`, `testflight.yml`).
Kancalar (`.claude/settings.json`): oturum başında `node_modules` yoksa Prettier kurulur; düzenlenen `.md` dosyası
Prettier'dan geçer.

## Kod kuralları

- **Ham renk ve sayı yok**: tasarım değerleri `SolvatoCore` `Tokens.swift` / `Colors.swift` (`ThemeColor`,
  `PaletteColor`, `CategoryColor`, `FontSize`, `Space`, `Radius`). Açık tema yalnızca token kullanılırsa çalışır.
  Okunan yazıda `textFaint` kullanma (kontrast); yalnız yer tutucu ve süs.
- **Yazı:** `Font.ui` / `.mono` / `.term` (Dinamik Yazı ile büyür); büyümemesi gereken yerde (klavye, halka, rozet,
  porte) `…Fixed`. Sınırlar `AppTypeSize`.
- **Tekrar yok**: aynı parça iki yerde gerekiyorsa `ios-native/Solvato/UI/` altına çıkar. Örnekler: `ExitConfirm`,
  `PlayChip`, `TopicLink`, `RoundCloseButton`, `MusicalStaffView`.
- Mantık ve kullanıcıya görünen metinler test edilebilsin diye `SolvatoCore`'da (testiyle); SwiftUI dosyası yalnız çizer.
  VoiceOver metinleri `SolvatoCore/App/AccessibilityText.swift`.
- Dosyanın başına bir-iki satır Türkçe açıklama yaz: ne yapar, nerede kullanılır.
- Depolama anahtarlarını **yeniden adlandırma** (eski adlar bilerek korunuyor). Yeni anahtar `solvato_` önekiyle.
- Kullanıcıya görünen metin Türkçe. Yazım kuralları:
  - Yüzde önde: **%40** (40% değil). Süre: **0,4 sn**.
  - "Seviye" yalnızca Başlangıç / Orta / İleri için; XP basamakları "ünvan".
  - **"Öğretmen"** de, "hoca" deme.
  - Nota adları Do Re Mi Fa Sol La Si; oktavlı yazımda "Fa4".

## Tuzaklar

- Xcode projesi (`.xcodeproj`) repoda yok; `ios-native/project.yml`'den XcodeGen üretir. Yeni Swift dosyasını klasöre
  koymak yeter.
- Yeni Apple API'si → `ios-native/Solvato/PrivacyInfo.xcprivacy` beyanı ve `scripts/native-guvenlik.py`'deki beklenen
  liste. Yeni yazı tipi ya da kod parçası → `hukuk.json` `licenses`. Gizlilik politikası değişirse `hukuk.json`
  `privacy` (uygulama ve site aynı metni gösterir).
- Altın tablolar (`Fixtures/altin/`), `soru-bankasi.json`, `smufl.json`, `senaryolar.json` React'tan döküldü; üreten
  betikler `web-arsiv` dalında. Artık elle düzenlenir; testleri de birlikte güncelle.
- Uygulama hiçbir yere ağ isteği göndermez ("Data Not Collected"). Bir şey gönderen özellik eklenecekse önce Ceren'e sor.

## Ürün ilkeleri (kısa)

- Uygulama **öğretmenle birlikte** kullanılan bir pratik aracı; dersin yerini almaz.
- Sunucu yok, hesap yok, veri toplanmaz (mağaza gizlilik beyanları buna dayanıyor).
- Yayında **reklam yok**. Önce büyüme, sonra Solvato Plus ve öğretmen paneli (`docs/URUN.md`).
- Solfie (maskot) az görünür: tanıtım, tur sonucu, kutlama. Her ekrana ekleme.
