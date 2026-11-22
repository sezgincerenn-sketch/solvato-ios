# Hesap ve cihazlar arası ilerleme

Durum: taslak, Ceren'le kararlar alındı (22 Kasım 2026). Sürüm: **1.1** (1.0 hesapsız çıkar). Native iOS'a yazılır
(`ios-native/`); React sürümüne eklenmez. Sunucu `solvato-admin` reposunda (Paket 4'teki Cloudflare altyapısı).

## Amaç

Öğrenci telefonda çalışıp iPad'e (ya da yeni telefona) geçtiğinde ilerlemesine kaldığı yerden devam edebilsin.
Hesap **isteğe bağlı**: uygulama hesapsız da bugünkü gibi tam çalışır. İleride öğretmen paneli ve Android aynı hesabı
kullanır.

## Değişen ürün kararları (`docs/URUN.md` güncellenecek)

- "Sunucu ve hesap yok, veri toplanmıyor" → **hesap açan kullanıcı için** e-posta (ya da Apple/Google kimliği), doğum
  yılı, ilerleme ve ayarlar sunucuda saklanır. Hesapsız kullanıcıdan hiçbir şey gönderilmez.
- Mağaza gizlilik beyanı "Data Not Collected"tan çıkar: **Contact Info (e-posta)** ve **User Content / Other (ilerleme)**,
  "Linked to you", amaç "App Functionality". İzleme (tracking) yok, reklam yok.
- "Üçüncü taraf kod yok" korunur: Apple ile giriş Apple'ın kendi çerçevesiyle (AuthenticationServices); Google ile giriş
  Google kütüphanesi olmadan, sistemin güvenli tarayıcı penceresiyle (ASWebAuthenticationSession, OAuth + PKCE).

## Kullanıcı ne görür

Görünüm Solvato tasarım sistemiyle (koyu mor, Outfit, mevcut düğmeler); örnek gösterilen "bookinclub" ekranı yalnızca
akış fikri içindir, renk ve logo alınmaz.

### 1. İlk açılış (tanıtımın sonunda)

Tanıtımın son adımından (günlük hatırlatma) sonra bir sayfa:

- Başlık: **"İlerlemen kaybolmasın"**
- Metin: "Hesap açarsan iPad'inde ya da yeni telefonunda kaldığın yerden devam edersin."
- Düğmeler (yukarıdan aşağı): **"Apple ile devam et"** (Apple'ın standart siyah/beyaz düğmesi), **"Google ile devam et"**,
  **"E-posta ile devam et"**, en altta metin düğmesi **"Şimdilik geç"**.
- "Şimdilik geç" Pratik'e götürür; bir daha bu sayfa kendiliğinden çıkmaz.

### 2. Profil

- Hesap yoksa Profil'in üstünde kart: **"Hesap aç"** + "İlerlemeni diğer cihazlarına taşı." → 1'deki seçenekler (ayrı ekran).
- Hesap varsa aynı yerde: e-posta (Apple "e-postamı gizle" seçildiyse "Apple ile giriş yapıldı"), son eşitleme ("Az önce
  eşitlendi" / "Çevrimdışı · bağlanınca eşitlenecek").

### 3. E-posta ile

- **Giriş** ekranı: E-posta, Şifre, **"Şifremi unuttum"**, **"Giriş yap"**; altta "Hesabın yok mu? **Kayıt ol**".
- **Kayıt ol**: E-posta, Şifre (en az 8 karakter), Doğum yılı (seçici), **"Hesap oluştur"**. Gizlilik metnine bağlantı.
- Kayıttan sonra e-postaya doğrulama bağlantısı gider; doğrulanana kadar Profil'de "E-postanı doğrula · Yeniden gönder".
  Doğrulamadan da eşitleme çalışır (kullanıcıyı bekletmeyiz), ama şifre sıfırlama yalnız doğrulanmış e-postaya.
- **Şifremi unuttum**: e-posta girilir → "Sıfırlama bağlantısını gönderdik." Bağlantı uygulamayı (ya da web sayfasını) açar,
  yeni şifre belirlenir.

### 4. Apple / Google ile

- Sistem penceresi açılır; dönüşte hesap yoksa oluşturulur, varsa giriş yapılır.
- İlk kez hesap açılıyorsa **Doğum yılı** sorulur (Apple/Google yaşı vermez).

### 5. Yaş (13 altı)

- Doğum yılına göre 13 yaşından küçükse: "Hesabını açmak için ebeveyninin onayı gerekiyor." + **Ebeveyn e-postası** alanı +
  **"Onay iste"**.
- Ebeveyne giden e-postada ne saklandığı kısaca yazar ve **"Onaylıyorum"** bağlantısı vardır.
- Onaylanana kadar Profil'de "Ebeveyn onayı bekleniyor · Yeniden gönder"; uygulama bu arada hesapsız gibi çalışır, hiçbir
  ilerleme gönderilmez. Onay gelince eşitleme başlar. 14 gün içinde onaylanmazsa bekleyen hesap silinir.

### 6. Hesaba ilk bağlanma (cihazdaki ilerleme)

- Hesap açılınca/giriş yapılınca cihazdaki ilerleme hesaba taşınır. Hesapta zaten ilerleme varsa **birleştirilir**
  (kurallar aşağıda); kullanıcıya bir şey sorulmaz. Sonunda kısa bildirim: "İlerlemen hesabına eklendi."

### 7. Ayarlar › Hesap

- **Çıkış yap**: onay penceresi "Çıkış yapılsın mı? Bu cihazdaki ilerleme silinir; hesabındaki ilerleme korunur." →
  **Çıkış yap** / **Vazgeç**. Çıkıştan sonra uygulama ilk kurulum gibi boş açılır (tanıtım gösterilmez).
- **Hesabı sil** (Apple zorunlu tutuyor): "Hesabın ve sunucudaki bütün ilerlemen kalıcı olarak silinir. Bu cihazdaki ilerleme
  kalır." → yazarak onay ("SİL") → silinir. Apple ile girişte Apple'daki bağlantı da kaldırılır.

## Kurallar ve sınır durumları

- **Ne eşitlenir:** istatistikler (`notausta_stats_v1`: XP, ünvan, seviye ilerlemesi, seri, yıldızlar, konu doğrulukları,
  son turlar), ayarlar (`pianote_settings_v1`: ad, renk, seviye, günlük hedef, anahtar, notalar, cevap yöntemi, ses, titreşim,
  öğretmen kodu ve konular), tema, günün meydan okuması kayıtları (`notalik-daily`).
- **Ne eşitlenmez:** günlük hatırlatma (bildirim izni cihaza özgü), "yan çevir" ipucu sayacı, Çalışma'daki son ders,
  ana sayfa ipuçlarının gösterilip gösterilmediği, tanıtımın görülmesi.
- **Birleştirme** (iki cihaz aynı anda ya da çevrimdışı çalıştıysa): günlük soru ve doğru sayıları gün gün en büyük değer
  (aynı tur iki kez sayılmasın diye toplama değil, her tur benzersiz kimlikle bir kez eklenir); XP ve ünvan turlardan yeniden
  hesaplanır; seri ve yıldızlarda en iyisi; son turlar listesi tarih sırasıyla birleşir; ayarlarda en son değiştirilen kazanır.
  Kurallar `SolvatoCore`'da, altın örneklerle testli.
- **Çevrimdışı:** uygulama her zaman cihazdaki veriyle çalışır; değişiklikler sıraya alınır, bağlanınca gönderilir. Hata
  kullanıcıyı durdurmaz; Profil'de "Çevrimdışı · bağlanınca eşitlenecek".
- **Ne zaman eşitlenir:** uygulama açılınca, tur bitince, ayar değişince, arka plana geçerken.
- **İlerlemeyi sıfırla** (Ayarlar): hesaplıysa "Bu, hesabındaki ilerlemeyi de sıfırlar." uyarısı.
- **Telefon/tablet:** ekranlar iPad'de ortada en çok 480 pt genişlikte; koyu ve açık temada aynı.
- **Ses/titreşim:** etkisi yok.
- **Güvenlik:** oturum anahtarı Keychain'de; şifre yalnızca sunucuda tuzlu karmayla (bcrypt/argon2); bütün istekler HTTPS;
  giriş denemelerine hız sınırı.

## Kabul ölçütleri

- [ ] Hesap açmadan uygulamanın her ekranı bugünkü gibi çalışıyor ve hiçbir ağ isteği gönderilmiyor.
- [ ] Tanıtımın sonunda hesap sayfası çıkıyor; "Şimdilik geç" Pratik'e götürüyor ve sayfa bir daha kendiliğinden çıkmıyor.
- [ ] Apple, Google ve e-posta ile hesap açılıyor ve giriş yapılıyor; Google girişi Google kütüphanesi olmadan çalışıyor.
- [ ] Telefonda 10 soru çözülüp iPad'de aynı hesapla giriş yapılınca XP, seri, yıldızlar, ad ve ayarlar aynı görünüyor.
- [ ] İki cihazda çevrimdışı çözülen turlar bağlanınca kaybolmadan ve iki kez sayılmadan birleşiyor (çekirdek testleri).
- [ ] 13 yaş altı kayıtta ebeveyn onayı istenmeden hiçbir veri sunucuya gitmiyor; onaydan sonra eşitleme başlıyor.
- [ ] "Şifremi unuttum" e-postası geliyor ve yeni şifreyle giriş yapılabiliyor.
- [ ] Hesabı sil sunucudaki bütün kayıtları siliyor; aynı e-postayla yeniden kayıt temiz başlıyor.
- [ ] Çıkış yapınca cihaz boş açılıyor; tekrar giriş yapınca ilerleme geri geliyor.
- [ ] Mağaza gizlilik beyanı ve uygulamadaki Gizlilik metni (`legal.ts` / `hukuk.json`) yeni duruma göre güncel;
      `PrivacyInfo.xcprivacy` toplanan veri türlerini içeriyor.

## Kapsam dışı

- Öğretmen paneli ve öğretmen hesabı (Solvato Plus ile, ayrı doküman).
- Android'de giriş (Android başlayınca; aynı sunucu).
- Arkadaş ekleme, sıralama tablosu, sosyal özellikler.
- Telefon numarasıyla giriş, şifresiz e-posta kodu.
- Anonim analitik (Paket 4, ayrı; hesapla birleştirilmez).

## Etkilenen dosyalar (tahmini)

- `solvato-admin` (yeni): Cloudflare Worker API (`/auth/apple`, `/auth/google`, `/auth/email`, `/auth/reset`,
  `/account`, `/sync`), D1 tabloları (kullanıcı, kimlik, ilerleme belgesi, ebeveyn onayı), e-posta gönderimi
  (doğrulama, şifre sıfırlama, ebeveyn onayı; Cloudflare uyumlu bir e-posta hizmeti, ör. Resend ya da MailChannels).
- `ios-native/SolvatoCore`: `Account` (oturum durumu), `Sync` (birleştirme kuralları, değişiklik sırası) + testler.
- `ios-native/Solvato`: `Screens/AccountScreens.swift` (giriş, kayıt, şifre sıfırlama, yaş/ebeveyn onayı), Profil kartı,
  Ayarlar › Hesap, tanıtımın son sayfası; Keychain; `Solvato.entitlements` (Sign in with Apple, ilişkili alan adı).
- `docs/URUN.md` (Veri kararı), `src/data/legal.ts` → `hukuk.json` (gizlilik metni), `PrivacyInfo.xcprivacy`,
  `docs/APP-STORE-KONTROL.md`.

## Gizlilik etkisi

Uygulama ilk kez dışarıya veri gönderir — yalnız hesap açan kullanıcı için ve yalnız kendi sunucumuza. Gönderilenler:
e-posta (ya da Apple/Google kimliği), doğum yılı, ebeveyn e-postası (13 altı), ilerleme ve ayarlar. Reklam, izleme ve
üçüncü taraf analitik yok. Yayından önce gerekenler: gizlilik politikasının yeniden yazılması (KVKK aydınlatma metni dahil),
mağaza beyanının güncellenmesi, Apple'da "Sign in with Apple" yeteneği, Google Cloud'da OAuth istemcisi (Ceren'in hesabıyla).

## Ceren'in yapacakları (uygulama oturumundan önce)

- Google Cloud Console'da proje ve iOS OAuth istemcisi (adımlar uygulama oturumunda verilecek).
- Apple Developer'da App ID'ye "Sign in with Apple" yeteneği.
- E-posta gönderimi için alan adı (ör. `solvato.app`): doğrulama e-postalarının spam'e düşmemesi için gerekli.
