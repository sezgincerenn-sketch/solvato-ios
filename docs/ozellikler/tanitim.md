# Tanıtım ve öğretmen kodu ekranı

Durum: **onaylandı, native'de uygulandı (26 Kasım 2026)**. Çekirdek ölçütleri testlerle doğrulandı; ekran ölçütleri
GitHub Actions simülatör görüntüleriyle (`ekranlar` dalı) kapanacak. Yalnız native iOS'a yazılır (`ios-native/`). Kapsadığı revizeler
(`docs/ozellikler/tasarim-revize.md`): R5 (tanıtımdaki soru adımı), R9, R12, R27, R28 ve R35 (öğretmen kodu ekranı
role göre). R5'in Profil tarafı (kart başlıkları) `gezinme.md`'de yapıldı.

**Başvuru:** web revize önizlemesi (https://claude.ai/artifact/LpuacK4CoaKn3vT7gmNQzm; kod `revize-onizleme` dalı, 4. grup kaydı `src/screens/Onboarding.tsx`, `src/ui/TimeField.tsx`). Native, önizlemedeki metin ve ölçüleri izler;
farklar bu dokümanda yazılı (öğretmen yolu, saat seçici, öğretmen kodu ekranı).

## Amaç

Yeni kullanıcı ilk ekranda uygulamanın ne olduğunu anlasın, adımlar arasında geri dönebilsin, öğretmen mi öğrenci mi
olduğunu söylesin. Öğretmen gereksiz adımlardan geçmeden doğrudan öğrenci kodu hazırlamaya gitsin; öğrenci de öğretmen
kodu ekranında yalnız kodu girdiği bölümü görsün.

## Kullanıcı ne görür

### Tanıtım adımları

Sıra: **Giriş → Merhaba (ad) → Deneme 1 → Deneme 2 → Öğretmen sorusu → Anahtar → Seviye ve hedef → Hatırlatma →
Hazırsın.** Üstte solda geri oku, ortada adım noktaları, sağda "Atla" (son adımda yok).

- **Giriş (R27), yeni ilk adım:** logo (48 pt); büyük başlık **"Her gün birkaç dakika, nota okumak kolaylaşsın"**;
  altında "Solvato, piyano öğrencileri için kısa pratik turları: nota, ritim, akor ve kulak. Ne kadar ilerlediğini de
  gösterir."; 2×2 küçük kutular: 𝄞 Nota okuma · ♩ Ritim · ♬ Akor · ◉ Kulak (renkleri önizlemedeki gibi). Altta
  **"Başlayalım"** düğmesi.
- **Geri oku (R28):** ikinci adımdan itibaren sol üstte (Ayarlar'daki geri düğmesinin aynısı, 44 pt). Bir önceki
  adıma döner; o adımdaki seçimler (ad, anahtar, seviye, hedef, saat) korunur. İlk adımda görünmez ama yeri boş kalır
  (noktalar kaymaz). Adım noktaları önizlemedeki gibi küçülür: 6 pt, açık adım 18 pt.
- **Öğretmen sorusu (R5), denemelerden sonra:** başlık **"Bir öğretmenle mi çalışıyorsun?"**, üç seçenek kartı
  (varsayılan ilki seçili):
  - **"Evet, öğretmenim var"** · "Öğretmeninle birlikte çalışıyorsun"
  - **"Hayır, kendi kendime"** · "Anahtar ve seviyeyi birlikte seçelim"
  - **"Ben öğretmenim"** · "Öğrencilerim için kullanacağım"
  - Altta **"Devam"**. Kod istenmez.
- **Öğretmen yolu (Ceren'in kararı):** "Ben öğretmenim" ile "Devam" deyince anahtar, seviye, hatırlatma ve "Hazırsın"
  adımları **atlanır**; tanıtım biter ve doğrudan **öğretmen kodu ekranı** (öğrenci kodu hazırlama bölümü) açılır.
  Oradan geri dönünce Profil sekmesi açılır.
- **Öğrenci ve "kendi kendime" yolu:** anahtar → seviye ve hedef → hatırlatma → Hazırsın, bugünkü gibi.
- **Hatırlatma (R9):** "Evet, hatırlat" seçiliyken saat çipleri (17–21) yerine **saat satırı**: büyük "19:00"
  (önizlemedeki gibi ortalı, kalın, dolgulu kutu). Dokununca iPhone'un saat çarkı açılır (Alarm uygulamasındaki gibi);
  **bütün saatler ve dakikalar** seçilebilir. Varsayılan 19:00.
- **Tanıtım bitince (R12):** Ana sayfa **en üstten** açılır (Hazırsın'dan "Başlayalım" ya da herhangi bir adımda
  "Atla").

### Ayarlar › Hatırlatma (R9)

- Saat çipleri (09, 12, 18, 20, 21) kalkar; yerine tanıtımdakiyle **aynı saat satırı** (dokununca saat çarkı).
  Saat değişince bildirim yeni saate taşınır. Alt yazı "Her gün 19:30'da" gibi dakikalı.
- (Ayarlar'ın genel düzeni ayrı bir dokümanda yeniden ele alınacak, R36; bu doküman yalnız saat seçiciyi değiştirir.)

### Öğretmen kodu ekranı (R35)

Ekran, tanıtımdaki seçime (`teacherRole`) göre açılır:

| Seçim                   | Başlık                 | Görünen bölüm           | Altta geçiş bağlantısı                      |
| ----------------------- | ---------------------- | ----------------------- | ------------------------------------------- |
| Evet, öğretmenim var    | "Öğretmen kodunu gir"  | Yalnız kod girme        | "Öğretmen misin? Öğrencin için kod hazırla" |
| Ben öğretmenim          | "Öğrenci kodu hazırla" | Yalnız kod hazırlama    | "Öğrenci misin? Öğretmeninin kodunu gir"    |
| Kendi kendime / atlandı | "Öğretmen kodu"        | İkisi de (bugünkü gibi) | yok                                         |

- Başlık Profil'deki öğretmen kodu kartının başlığıyla aynı.
- Üstteki açıklama metni bölüme göre:
  - Kod girme: "Öğretmenin hangi notaları ve hangi seviyede çalışacağını bir kodla gönderir. Kodu girince uygulaman o
    ayarlarla kurulur." (bugünkü metin)
  - Kod hazırlama: "Öğrencin için konu, seviye, hedef ve notaları seç; kodu WhatsApp ya da mesajla gönder."
  - İkisi de: bugünkü metin.
- **Geçiş bağlantısı** (mor, küçük yazı, kartların altında): dokununca ekran diğer bölüme döner ve **seçim kalıcı
  değişir** (Ceren'in kararı): `teacherRole` öğrenci ↔ öğretmen olur; Profil kartının başlığı ve ekranın bir sonraki
  açılışı yeni seçimi gösterir. Kaydırma en üste döner.
- Bölümlerin içi (kod alanı, "Uygula", kod hazırlama seçimleri, paylaşım) değişmez.

## Kurallar ve sınır durumları

- **Yeni ayar:** `reminderMinute` (0–59, varsayılan 0; ayar nesnesinde, depolama anahtarı değişmez). Eski kayıtlarda
  yoksa 0. `teacherRole` gezinme işinde eklendi; burada tanıtım yazar, öğretmen kodu ekranındaki bağlantı değiştirir.
- **Atla:** öğretmen sorusundan önce "Atla" denirse `teacherRole` boş kalır ("Öğretmen kodu", iki bölüm). Soru
  cevaplandıktan sonra "Atla" denirse seçim kaydedilmiş olur.
- **Geri ile öğretmen sorusuna dönüp seçimi değiştirmek:** son "Devam"daki seçim geçerli.
- **Tanıtımı tekrar göster (Ayarlar):** aynı akış; soru önceki seçim işaretli açılır. Öğretmen yolunda tanıtım bitince
  yine öğretmen kodu ekranı açılır.
- **Hatırlatma izni verilmezse:** bugünkü gibi kapalı kalır (Ayarlar'daki uyarı metni aynı).
- **Saat 24 saat biçiminde** ("09:05"); cihaz 12 saat biçimindeyse de çark 24 saat gösterir (uygulama Türkçe).
- **iPad:** tanıtım bugünkü gibi en fazla 600 pt genişlikte ortada; saat çarkı küçük açılır pencerede.
- **Koyu/açık tema:** giriş kutuları ve saat satırı tasarım değerleriyle; ham renk yok.
- **VoiceOver:** geri oku "Geri"; saat satırı "Hatırlatma saati, 19:00"; giriş kutuları tek tek okunur.
- **Hareketi azalt:** adım geçişi bugünkü kısa solma; ek hareket yok.

## Kabul ölçütleri

- [ ] Tanıtım "Her gün birkaç dakika, nota okumak kolaylaşsın" ekranıyla açılıyor; "Başlayalım" Merhaba adımına geçiyor.
- [ ] İkinci adımdan itibaren sol üstte geri oku var; geri dönünce girilen ad ve seçimler duruyor; ilk adımda ok yok.
- [x] Öğretmen sorusunda üç seçenek; seçim `teacherRole`'e kaydediliyor (student / self / teacher).
- [ ] "Ben öğretmenim" → Devam: anahtar/seviye/hatırlatma adımları gelmiyor, öğretmen kodu ekranı "Öğrenci kodu
      hazırla" başlığıyla yalnız hazırlama bölümüyle açılıyor; geri dönünce Profil.
- [ ] "Evet, öğretmenim var" ve "Kendi kendime": anahtar → seviye → hatırlatma → Hazırsın sırası bugünkü gibi.
- [ ] Tanıtım (bitince ya da Atla ile) Ana sayfayı en üstten açıyor.
- [ ] Hatırlatma saati tanıtımda ve Ayarlar'da aynı saat satırı; 07:45 gibi her saat seçilebiliyor; bildirim o saatte.
- [x] Ayarlar'daki alt yazı dakikalı: "Her gün 07:45'te".
- [ ] Öğretmen kodu ekranı: öğrenci yalnız kod girmeyi, öğretmen yalnız hazırlamayı, diğerleri ikisini görüyor.
- [ ] Geçiş bağlantısı bölümü değiştiriyor; Profil kartının başlığı ve ekranın sonraki açılışı yeni rolü gösteriyor.
- [ ] Koyu ve açık temada, iPhone SE ve iPad'de taşma yok (ekran görüntüleri: tanıtım giriş, öğretmen sorusu,
      hatırlatma; öğretmen kodu ekranının üç hâli).
- [x] Çekirdek testleri: adım sırası (öğretmen yolu dahil), geri, rol ve ekran bölümü seçimi, saat alt yazısı,
      `reminderMinute` varsayılanı.

## Kapsam dışı

- Tanıtımda kod girme (Ceren: "tanıtımda kod istemeyelim").
- İpucu turu sırası (R29, taslak), kod yapıştırma ve otomatik tire (R30, R31), paylaşım bağlantısı (R32).
- Ayarlar'ın genel düzeni (R36, ayrı doküman).
- Seviye yerleştirme denemesi (R4, beklemede).
- Android ve web sürümü.

## Etkilenen dosyalar (tahmini)

- `SolvatoCore/Logic/Settings.swift` (`reminderMinute`), `SolvatoCore/App/ProfileSettingsContent.swift` (saat alt yazısı),
  `SolvatoCore/App/TeacherContent.swift` (rol → başlık, bölüm, açıklama, bağlantı), yeni küçük tanıtım akışı
  (adım sırası, geri) çekirdekte; testleri.
- `Solvato/Screens/OnboardingScreen.swift`, `TeacherScreen.swift`, `SettingsScreen.swift`, `Solvato/Reminder.swift`
  (dakikalı bildirim), `Solvato/AppRoot.swift` (tanıtım sonrası öğretmen kodu ekranı, Ana sayfa en üstte);
  yeni parça: saat satırı.
- Widget'ın son uyarı saati hatırlatma saatine bağlıysa dakika da hesaba katılır (kontrol edilecek).
- `docs/ozellikler/native-ios.md` (E-02, E-12, E-13), `README.md`, UI test senaryoları.

## Gizlilik etkisi

Yok. Seçimler ve saat yalnız telefondaki ayarlara yazılır; bildirim cihazda kurulur, ağ isteği yok.
