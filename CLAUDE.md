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
- **Native iOS'a geçiliyor (1. öncelik, `docs/PLAN.md` Paket 0):** Swift/SwiftUI, web görünümü ve üçüncü taraf kod yok.
  Bugünkü React kodu (`src/`) native sürüm aynı işlevlere ulaşana kadar başvuru kaynağı; ona yeni özellik ekleme.
- `solvato-android`: dondurulmuş kopya; Android işi başlayana kadar **kod yazma**. Başlayınca `src/` buradan alınır.
  Bu yüzden `src/` içindeki Android'e özel küçük parçaları (geri tuşu) silme.
- `solvato-admin`: analitik sunucusu, veritabanı ve admin paneli (1.1, `docs/PLAN.md`).
- **`solvato` reposu yedek: ona hiçbir şekilde dokunma** (commit, push, dal, etiket yok). Bugünkü React sürümünün
  çalışan kopyası olarak olduğu gibi kalır. Değişiklikler yalnızca `solvato-ios` ve `solvato-android`'de.
- **Birebir uyum:** native iOS (ve ileride Android) mevcut uygulamayla birebir aynı olmalı: aynı ekranlar ve akışlar,
  aynı metinler, renkler, yazı tipleri, ölçüler, animasyonlar ve aynı kurallar (puan, seviye, seri, kodlar). Yeniden
  tasarlama ya da "iyileştirme" yapma; fark gerekiyorsa önce Ceren'e sor. Başvuru kaynağı bu repodaki `src/` ve
  `node scripts/ekran.mjs` ile alınan ekran görüntüleri.

## Çalışma şekli

- Küçük, net istekleri doğrudan yap. Geri dönmesi zor ya da birden çok yoruma açık işlerde önce tek soru sor.
- Birden çok ekranı etkileyen ya da ürün kararı içeren isteklerde koda geçmeden **`ozellik`** becerisiyle özellik
  dokümanı yaz (`docs/ozellikler/`). Uygulama ayrı oturumda o dokümandan yapılır.
- Kod değiştiren her işi **`bitir`** becerisiyle bitir (kontrol, ekran, README, commit, push, TestFlight, özet).
- **Native iş akışı (26 Kasım):** web revize önizlemesi artık güncellenmez; değişiklik TestFlight'tan denenir.
  Çekirdek: `cd ios-native/SolvatoCore && swift test`. Ekranlar: `main`e gönderince GitHub Actions görüntüleri `ekranlar`
  dalına koyar (seçim `ios-native/ui-testleri.txt`, yalnız değişen ekranların testleri). TestFlight: GitHub Actions
  `testflight.yml` (`mcp__github__actions_run_trigger`, ref `main`); Codemagic kullanılmaz.
- Bir özellik bitince main'e göndermeden önce **`inceleyici`** ajanına dokümana göre inceletebilirsin; yalnız doğruluk
  bulgularını düzelt.
- Kanıtla konuş: "geçti" deme, komutu ve sonucunu ya da ekran görüntüsünü göster.

## Komutlar

```bash
npm run check          # tür kontrolü (noUnused açık) + Prettier kontrolü
npm run format         # biçim hatalarını düzeltir
node scripts/ekran.mjs --ad x --adim Profil --se   # ekran görüntüsü (önce npm run build); `ekran` becerisine bak
npm run build:single   # tek dosyalık önizleme: dist-single/index.html
npm run sync           # derle + cap sync ios (ios/ projesini günceller)
```

Kancalar (`.claude/settings.json`): oturum başında `node_modules` yoksa `npm install`; düzenlenen `src/` dosyası Prettier'dan
geçer; `src/` değişmişken iş bitirilmek istenirse `npm run check` koşar ve geçmezse durdurur.

## Kod kuralları

- **Ham renk ve sayı yok**: her şey `src/design/tokens.ts`. Yazı rengi `colors.*`, dolgu `palette.*` / `category.*`.
  Açık tema yalnızca token kullanılırsa çalışır. (Eski dosyalarda 16 ham hex ve 57 `rgba(` kaldı: bilinen borç, yenisini ekleme.)
- **Tekrar yok**: aynı parça iki yerde gerekiyorsa `src/ui/` (genel) ya da `src/components/` (müziğe özgü) altına
  çıkar. Örnekler: `ExitConfirm`, `PlayChip`, `TopicLink`, `GoalStaff`, `MusicalStaff`.
- Yeni bileşenlerde Tailwind sınıfı değil satır içi stil + token kullan (tasarım sistemi önizlemesi Tailwind'i
  yüklemez). Eski dosyalarda kalan Tailwind sınıfları bilinen borç.
- Dosyanın başına bir-iki satır Türkçe açıklama yaz: ne yapar, nerede kullanılır.
- Depolama anahtarlarını **yeniden adlandırma** (eski adlar bilerek korunuyor). Yeni anahtar `solvato_` önekiyle.
- Kullanıcıya görünen metin Türkçe. Yazım kuralları:
  - Yüzde önde: **%40** (40% değil). Süre: **0,4 sn** (`fmtSec`).
  - "Seviye" yalnızca Başlangıç / Orta / İleri için; XP basamakları "ünvan".
  - **"Öğretmen"** de, "hoca" deme.
  - Nota adları Do Re Mi Fa Sol La Si; oktavlı yazımda "Fa4".

## Tuzaklar

- `src/data/smufl.ts` otomatik üretildi; düzenleme izinlerle engelli.
- `ios/App/App.xcodeproj/project.pbxproj` elle (betikle) düzenlenir; `cap sync` ona dokunmaz. Yeni dosya eklerken
  PBXFileReference + PBXBuildFile + grup + Resources aşamasına dört kayıt gerekir (örnek: `PrivacyInfo.xcprivacy`).
- Yeni native eklenti → `ios/App/App/PrivacyInfo.xcprivacy` beyanını kontrol et. Yeni bağımlılık ya da yazı tipi →
  `src/data/legal.ts` `LICENSES`. Gizlilik politikası değişirse aynı dosyadaki `PRIVACY` metni de değişir.
- `utils/persist.ts` yalnızca üç anahtarı UserDefaults'a yansıtıyor; yeni kalıcı veri eklersen listeye ekle.
- Uygulama hiçbir yere ağ isteği göndermez ("Data Not Collected"). Bir şey gönderen özellik eklenecekse önce Ceren'e sor.

## Ürün ilkeleri (kısa)

- Uygulama **öğretmenle birlikte** kullanılan bir pratik aracı; dersin yerini almaz.
- Sunucu yok, hesap yok, veri toplanmaz (mağaza gizlilik beyanları buna dayanıyor).
- Yayında **reklam yok**. Önce büyüme, sonra Solvato Plus ve öğretmen paneli (`docs/URUN.md`).
- Solfie (maskot) az görünür: tanıtım, tur sonucu, kutlama. Her ekrana ekleme.
