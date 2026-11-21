# Solvato'yu kendi iPhone ve iPad'inde test etme rehberi

Mac olmadan: uygulama Codemagic'in bulut Mac'inde derlenir, TestFlight'a yüklenir, sen de telefonuna TestFlight
uygulamasıyla kurarsın. İlk kurulum bir kez yapılır (yaklaşık 1 saat). Sonrasında her yeni sürüm için Claude'a
"TestFlight'a gönder" demen yeterli.

Gerekenler: Apple Developer Program üyeliği (var), bir GitHub hesabı (var), bilgisayarda bir tarayıcı.
Dosya indirip yükleyeceğin adımlar var; bunları telefondan değil bilgisayardan yap.

Kısaltmalar: **Apple Developer** = https://developer.apple.com/account · **App Store Connect** =
https://appstoreconnect.apple.com · **Codemagic** = https://codemagic.io

---

## Bölüm A — Apple tarafı

### 1. Uygulama kimliğini kaydet (Bundle ID)

1. Apple Developer → **Certificates, Identifiers & Profiles** → **Identifiers** → mavi **+**.
2. **App IDs** → Continue → **App** → Continue.
3. Description: `Solvato`. Bundle ID: **Explicit**, `com.solvato.app`.
4. Capabilities listesinde hiçbir şeyi işaretleme (hatırlatma bildirimi yerel, ek yetki gerekmez).
5. Continue → Register.

### 2. App Store Connect'te uygulamayı oluştur

1. App Store Connect → **Apps** → **+** → **New App**.
2. Platforms: **iOS**. Name: `Solvato: Nota Okuma`. Primary Language: **Turkish**.
   Bundle ID: listeden `com.solvato.app`. SKU: `solvato-ios`. User Access: **Full Access**.
3. **Create**.

Ad başkası tarafından alınmışsa hata verir. O zaman `Solvato – Nota Okuma` gibi bir varyasyon dene ve bana söyle;
mağaza metinlerini ona göre güncellerim. Ad yayından önce değiştirilebilir.

### 3. Codemagic için API anahtarı oluştur

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API**.
   İlk kez giriyorsan önce **Request Access** çıkabilir; hesap sahibi olarak onayla.
2. **Team Keys** sekmesinde **+** (Generate API Key).
3. Name: `Codemagic`. Access: **App Manager**. **Generate**.
4. Listede yeni anahtarın yanında **Download API Key**'e bas. `.p8` dosyası iner. **Yalnızca bir kez indirilebilir**;
   güvenli bir yere kaydet ve kimseyle paylaşma (bana da gönderme).
5. Sayfanın üstündeki **Issuer ID**'yi ve anahtarın **Key ID**'sini bir kenara not et.

---

## Bölüm B — Codemagic tarafı

### 4. Hesap aç ve API anahtarını ekle

1. Codemagic → **Sign up** → **GitHub ile devam et**. **Kişisel hesap** kullan, takım (Team) oluşturma. Ücretsiz
   500 dakika yalnızca kişisel hesapta var.
2. GitHub izin ekranında `solvato-ios` reposuna erişim ver.
3. Hesap ayarları → **Integrations** → **Developer Portal** → **Manage keys** → **Add key**.
4. App Store Connect API key name: tam olarak **`Solvato`** yaz (derleme dosyası bu adı arıyor).
5. Issuer ID ve Key ID'yi gir, `.p8` dosyasını yükle → **Save**.

### 5. İmza sertifikası oluştur

1. Hesap ayarları → **codemagic.yaml settings** → **Code signing identities** → **iOS certificates**.
2. **Generate certificate**. Reference name: `solvato-dagitim`. Certificate type: **Apple Distribution**.
   API key: `Solvato`. **Create certificate**.
3. Codemagic sertifikayı indirmeni ister ve bir **şifre** gösterir. Dosyayı indir, şifreyi kaydet.
   **Yalnızca bir kez** gösterilir.
4. Aynı sayfada **Upload certificate** sekmesine geç. İndirdiğin `.p12` dosyasını yükle, şifreyi gir, Reference name
   `solvato-dagitim` → **Add certificate**.

"You already have a current Distribution certificate" hatası alırsan Apple'da 3 dağıtım sertifikası sınırı dolmuş
demektir. Apple Developer → Certificates'ta kullanmadığın eskilerden birini sil (Revoke) ve tekrar dene.

### 6. Dağıtım profilini oluştur (Apple Developer)

1. Apple Developer → **Profiles** → **+**.
2. Distribution altında **App Store Connect** → Continue.
3. App ID: `Solvato (com.solvato.app)` → Continue.
4. Sertifika: bugün oluşturulan **Apple Distribution** sertifikası (tarihi bugünkü olan) → Continue.
5. Provisioning Profile Name: `Solvato App Store` → **Generate**. İndirmene gerek yok.

### 7. Profili Codemagic'e çek

1. Codemagic → **Code signing identities** → **iOS provisioning profiles** → **Fetch profiles**.
2. App Store profiles altında `Solvato App Store`'u seç, Reference name `solvato-appstore`.
3. Sayfanın altındaki **Download selected**'a bas.
4. Listede profilin **Certificate** sütununda yeşil tik görmelisin. Tik yoksa 5. adımdaki sertifika yüklenmemiş demektir.

### 8. Uygulamayı Codemagic'e ekle ve ilk derlemeyi başlat

1. Codemagic → **Applications** → **Add application** → GitHub → `solvato-ios` reposu.
2. Codemagic repodaki `codemagic.yaml` dosyasını bulur. Proje türü sorarsa **codemagic.yaml**'ı seç.
3. **Start new build** → Branch: `main` → Workflow: **iOS → TestFlight** → **Start new build**.
4. Derleme yaklaşık 15–20 dakika sürer. Adımlar tek tek yeşile döner. Kırmızı bir adım olursa aşağıdaki
   "Sorun çıkarsa" bölümüne bak.

---

## Bölüm C — TestFlight ve telefon

### 9. Kendini test grubuna ekle

1. App Store Connect → **Apps** → Solvato → **TestFlight** sekmesi.
2. Derleme listede önce **Processing** görünür (5–30 dk). Şifreleme sorusu otomatik cevaplandığı için ek bir adım çıkmaz.
3. Sol menüde **Internal Testing** yanındaki **+** → grup adı `Ekip` → Create.
4. Gruba **Testers** → **+** → kendi Apple ID'ni seç → Add.
5. **Builds** bölümünden derlemeyi gruba ekle (otomatik eklenmediyse).

İç test grubu (en fazla 100 kişi, App Store Connect kullanıcısı olmalı) beta incelemesi beklemez. Dış test kullanıcıları
(ankette e-posta bırakanlar) için daha sonra **External Testing** grubu açarız; ilk derlemede Apple'ın kısa beta
incelemesi gerekir.

### 10. iPhone ve iPad'e kur

1. iPhone'da App Store'dan **TestFlight** uygulamasını indir. Apple Developer hesabındaki Apple ID ile giriş yap.
2. Davet e-postasındaki **View in TestFlight**'a dokun ya da TestFlight'ı aç. Solvato orada görünür → **Install**.
3. iPad'de de aynı Apple ID ile TestFlight'ı kur; Solvato orada da çıkar.
4. TestFlight sürümünün simgesinin yanında turuncu bir nokta olur. Her derleme 90 gün geçerlidir.

### 11. Sonraki sürümler

- Codemagic'te **Start new build** → dal **main** → iş akışı **Native iOS → TestFlight** (native sürüm) ya da
  **iOS → TestFlight** (eski React sürümü). Bulut oturumundaki Claude git etiketi gönderemediği için derlemeyi
  etiketle başlatamaz.
- **Native iOS → testler ve ekranlar** TestFlight'a yüklemez ve imza istemez; `ios-native/` klasörü `main`e
  gönderilince kendiliğinden başlar. Ekran görüntüleri derleme sayfasında **Artifacts** › `native-ekranlar.zip`.
- Her derleme 500 aylık ücretsiz dakikanın yaklaşık 15–20'sini kullanır (ayda ~25 derleme). Her küçük değişiklik için
  değil, denemeye değer bir grup değişiklik birikince gönder.
- Yeni derleme işlenince TestFlight bildirim gönderir; **Update** ile güncellenir, ilerleme silinmez.

---

## Ne test edilecek (kontrol listesi)

Tarayıcı önizlemesinde görülemeyen, yalnızca gerçek cihazda anlaşılan şeyler:

- [ ] **Ses, sessiz düğme açıkken:** Kulak sorusu ve Ritmi Tut ses çalıyor mu?
- [ ] **Ses, arkada müzik çalarken:** Spotify / Apple Music çalarken Solvato'da ses çal; müzik durmamalı.
- [ ] **Ritmi Tut zamanlaması:** tam vuruşta dokununca "tam" sayılıyor mu, hep geç ya da hep erken mi?
- [ ] **Hatırlatma:** Ayarlar'da hatırlatmayı aç, izin penceresi Türkçe mi, izin verince bir sonraki saatte bildirim geliyor mu?
      (İzni reddedip tekrar açmayı da dene: Türkçe yönlendirme çıkmalı.)
- [ ] **Titreşim:** doğru ve yanlış cevapta hissediliyor mu, Ayarlar'dan kapatınca duruyor mu?
- [ ] **Paylaşım:** haftalık rapor ve öğretmen kodunda paylaşım menüsü Türkçe açılıyor mu; menüyü kapatınca ikinci menü çıkmamalı.
- [ ] **Ekran yönü (iPhone):** soru ekranında telefonu yan çevirince iki sütun oluyor mu, diğer ekranlar dikey kalıyor mu?
- [ ] **iPad:** tüm ekranlar dikey ve yatayda; Split View'da (iki uygulama yan yana) dar pencerede taşma var mı?
- [ ] **Kalıcılık:** birkaç tur çöz, uygulamayı tamamen kapat (yukarı kaydır), aç: ilerleme ve seri duruyor mu?
- [ ] **Çevrimdışı:** uçak modunda uygulamayı aç; her şey çalışmalı.
- [ ] **Tema:** Ayarlar'da Sistem seçiliyken telefonu koyu/açık moda alınca uygulama da değişiyor mu, durum çubuğu okunuyor mu?
- [ ] **Çentik ve alt çubuk:** üstte saat/pil, altta ana ekran çizgisi hiçbir düğmenin üstüne binmiyor mu?

Bulduğun her sorunu ekran görüntüsüyle Claude'a yaz: hangi cihaz (iPhone/iPad), hangi ekran, ne oldu, ne bekliyordun.

---

## Sorun çıkarsa

Codemagic'te kırmızı adıma tıkla, son 30–40 satırı kopyalayıp Claude'a yapıştır. Sık görülenler:

| Hata (log'da)                                         | Sebep ve çözüm                                                                                |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `No matching profiles found` / `use-profiles` kırmızı | 6–7. adım eksik ya da profil yanlış sertifikayla oluşturuldu                                  |
| `Xcode ... App Store Connect Xcode 26+ istiyor`       | Codemagic'te Xcode 26 yok; Claude `xcode:` satırını günceller                                 |
| `npm run check` kırmızı                               | Kodda hata var; log'u Claude'a ver                                                            |
| `Integration "Solvato" not found`                     | 4. adımda anahtarın adı tam `Solvato` değil                                                   |
| Yayınlama adımında `No suitable application records`  | 2. adım yapılmamış ya da Bundle ID farklı                                                     |
| `The bundle version must be higher`                   | Build numarası eski; Claude düzeltir                                                          |
| Derleme TestFlight'ta görünmüyor                      | Apple işliyor (30 dk'ya kadar) ya da e-postana Apple'dan uyarı geldi; e-postayı Claude'a ilet |
