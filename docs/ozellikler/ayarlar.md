# Ayarlar düzeni

Durum: **onaylandı, native'de uygulandı (26 Kasım 2026)**. Çekirdek ölçütleri testlerle doğrulandı; ekran ölçütleri
GitHub Actions simülatör görüntüleriyle (`ekranlar` dalı) kapanacak. Yalnız native iOS'a yazılır (`ios-native/`). Kapsadığı revize
(`docs/ozellikler/tasarim-revize.md`): R36.

**Başvuru:** taslak sayfası https://claude.ai/artifact/CZgUJ48uPbVufVhMFaMzKq, **Taslak 1 (tek sayfa)** seçildi
(Ceren, 26 Kasım). Taslak 2 ("Diğer" ayrı sayfada) alınmadı. Web'de bu düzen yok; native taslağı izler.

## Amaç

Ayarlar daha kısa ve düzenli olsun: dört net grup, her satırda o anki değer, az kullanılanlar en altta. Ayarların
kendisi ve kuralları değişmez; yalnız görünüm ve yerleri değişir.

## Kullanıcı ne görür

Başlık "Ayarlar" ve geri oku bugünkü gibi. Altında dört grup; her grup yuvarlak köşeli bir **kart**, kartın üstünde
mor, büyük harfli küçük grup adı. Kart içinde satırlar ince çizgiyle ayrılır.

Satır türleri:

- **Değerli satır:** solda başlık, sağda soluk renkte o anki değer ve "›" ("10 soru ›"). Dokununca alttan **seçim
  penceresi** açılır.
- **Anahtarlı satır:** solda başlık, sağda açma/kapama anahtarı (bugünkü mor anahtar).
- **Bağlantı satırı:** solda başlık, sağda "›"; başka ekran açar.

### 1. Çalışma

| Satır               | Sağda                      | Dokununca                                                             |
| ------------------- | -------------------------- | --------------------------------------------------------------------- |
| Günlük hedef        | "10 soru"                  | Seçim penceresi: 10 / 20 / 30 / 50 soru, her birinin yanında açıklama |
| Seviye              | "Orta" (+ alt yazı)        | Seçim penceresi: Başlangıç / Orta / İleri                             |
| Anahtar             | "Sol" / "Fa" / "İkisi de"  | Seçim penceresi: Sol / Fa / İkisi de                                  |
| Çalışılacak notalar | "Hepsi" ya da "Do Re Mi…"  | Yeni alt ekran "Çalışılacak notalar" (bugünkü nota seçici + açıklama) |

- Seviye satırının alt yazısı kalır: "Sonraki seviyeye: 31/50 soru · %84 doğru" / "Tüm sorular açık.".
- Günlük hedef açıklamaları pencerede: "rahat tempo", "düzenli çalışma", "hızlı ilerleme", "yoğun tempo".
- Notalar satırının değeri: hepsi seçiliyse "Hepsi", değilse seçili notalar ("Do Re Mi Sol"); sığmazsa sondan "…".

### 2. Sorular

| Satır                 | Sağda                 | Dokununca                                |
| --------------------- | --------------------- | ---------------------------------------- |
| Cevap yöntemi         | "Klavye" / "Şıklar"   | Seçim penceresi: Klavye / Şıklar         |
| Tuş isimlerini göster | anahtar               | açar/kapatır                             |
| Zaman yarışı          | anahtar               | açar/kapatır                             |

### 3. Ses ve bildirim

| Satır             | Sağda   | Dokununca                                                              |
| ----------------- | ------- | ---------------------------------------------------------------------- |
| Ses               | anahtar | açar/kapatır                                                           |
| Titreşim          | anahtar | açar/kapatır                                                           |
| Günlük hatırlatma | anahtar | açarken bildirim izni ister (bugünkü gibi)                             |
| Hatırlatma saati  | "19:00" | Saat çarkı (tanıtımdaki saat çarkının aynısı); yalnız hatırlatma açıkken görünür |

- İzin verilmezse bugünkü kırmızı uyarı ("Bildirim izni verilmedi. iPhone Ayarlar → Solvato → Bildirimler bölümünden
  açabilirsin.") kartın hemen altında çıkar.
- Saat değişince bildirim yeni saate taşınır (bugünkü gibi).

### 4. Diğer

| Satır                  | Sağda                         | Dokununca                                |
| ---------------------- | ----------------------------- | ---------------------------------------- |
| Tema                   | "Sistem" / "Koyu" / "Açık"    | Seçim penceresi: Sistem / Koyu / Açık    |
| Tanıtımı tekrar göster | ›                             | Tanıtımı açar (bugünkü gibi)             |
| Gizlilik               | ›                             | Gizlilik ekranı                          |
| Lisanslar              | ›                             | Lisanslar ekranı                         |

### En altta

- Kartın dışında, ortalı kırmızı yazı **"İlerlemeyi sıfırla"**. Dokununca bugünkü onay alanı açılır ("XP, seri ve tüm
  istatistiklerin silinecek. Bu geri alınamaz." · Vazgeç · Sıfırla); davranış aynı.
- Altında soluk "Sürüm 1.0".

### Seçim penceresi

- Alttan kısa bir sayfa: üstte tutma çizgisi ve satırın başlığı ("Günlük hedef"), altında seçenek kartları; seçili
  olan mor çerçeveli ve "✓"li.
- Seçeneğe dokununca ayar hemen değişir, pencere kapanır, satırdaki değer güncellenir. Aşağı kaydırınca değişmeden
  kapanır.
- iPad'de satırın yanında küçük açılır pencere.

## Kurallar ve sınır durumları

- **Kalkan alt yazılar (kısalık için):** "Ses" altındaki "Telefon sessiz moddayken de çalar.", "Zaman yarışı"
  altındaki "Her soru için süre verilir.", hatırlatmanın "Her gün 19:00'da" alt yazısı (saat artık kendi satırında),
  günlük hedefin satır altı açıklaması (pencereye taşındı), notaların uzun açıklaması (notalar ekranına taşındı).
- **Seviye değişince** seviye sayacı sıfırlanır (bugünkü kural). Aynı seviye seçilirse sıfırlanmaz.
- **Notalar ekranı:** en az 3 nota kuralı, hazır seçimler (Do Re Mi · Do – Sol · Hepsi) ve açıklama metni bugünkü gibi.
  Geri oku ve kenardan kaydırma Ayarlar'a döner; Ayarlar kalınan yerden açılır.
- **Ayarlar kaydedilme biçimi ve depolama anahtarları değişmez**; eski kayıtlar olduğu gibi açılır.
- **Öğretmen kodu** Profil'de kalır; Ayarlar'a dönmez.
- **Koyu/açık tema:** kartlar, çizgiler, değerler tasarım değerleriyle; ham renk yok.
- **iPhone SE:** uzun satır başlıkları ve değerler taşmaz; değer sığmazsa kısalır, başlık iki satıra inebilir.
- **iPad:** sayfa bugünkü gibi ortada dar sütunda.
- **VoiceOver:** değerli satır "Günlük hedef, 10 soru, düğme"; anahtarlı satır açık/kapalı durumunu okur; grup adları
  başlık olarak okunur.
- **Hareketi azalt:** pencere sistemin kendi geçişiyle açılır; ek hareket yok.

## Kabul ölçütleri

- [ ] Ayarlar dört kartla açılıyor: Çalışma, Sorular, Ses ve bildirim, Diğer; sıra ve satırlar bu dokümandaki gibi.
- [ ] Değerli satırlar sağda o anki değeri gösteriyor; dokununca seçim penceresi açılıyor, seçim hemen uygulanıp
      pencere kapanıyor.
- [x] Seviye penceresinde farklı seviye seçilince sayaç sıfırlanıyor, aynı seviyede sıfırlanmıyor.
- [x] "Çalışılacak notalar" ayrı ekranda; en az 3 nota kuralı çalışıyor; satır değeri "Hepsi" ya da seçili notalar.
- [ ] "Hatırlatma saati" yalnız hatırlatma açıkken görünüyor, saat çarkıyla değişiyor, bildirim yeni saate taşınıyor.
- [ ] İzin reddedilince kırmızı uyarı Ses ve bildirim kartının altında.
- [x] "İlerlemeyi sıfırla" kartların altında kırmızı; onay alanı ve sıfırlama bugünkü gibi.
- [ ] Koyu ve açık temada, iPhone SE ve iPad'de taşma yok (görüntüler: `ayarlar`, `ayarlar-alt`, `ayarlar-pencere`,
      `ayarlar-notalar`, `ayarlar-sifirla`).
- [x] Çekirdek testleri: satır değer yazıları (hedef, seviye, anahtar, notalar, cevap yöntemi, tema), notalar
      değerinin kısaltılması, seviye değişiminde sayaç kuralı.

## Kapsam dışı

- Yeni ayar eklemek ya da bir ayarı kaldırmak.
- Profil ekranı ve öğretmen kodu kartı.
- Taslak 2 (ayrı "Diğer" sayfası).
- Web ve Android sürümü.

## Etkilenen dosyalar (tahmini)

- `SolvatoCore/App/ProfileSettingsContent.swift` (satır değer yazıları, notalar kısaltması), `SolvatoCore/App/ScreenStack.swift`
  (yeni alt ekran: çalışılacak notalar); testleri.
- `Solvato/Screens/SettingsScreen.swift` (yeniden düzen), yeni `Solvato/Screens/NotesSettingsScreen.swift`,
  yeni parça: ayar kartı, satır ve seçim penceresi (`Solvato/UI/`); `Solvato/AppRoot.swift` (yeni ekran).
- `SolvatoUITests/ScreenshotTests.swift` (`testProfilAyarlar`), `ui-testleri.txt`.
- `docs/ozellikler/native-ios.md` (E-12), `README.md`; `tasarim-revize.md` R36 durumu.

## Gizlilik etkisi

Yok. Ayarlar yalnız telefonda saklanır; ağ isteği yok.
