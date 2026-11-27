# Solvato çalışma sistemi

Claude Code ile Solvato üzerinde nasıl çalıştığımız. Kaynak: Anthropic'in
[Claude Code en iyi uygulamalar](https://code.claude.com/docs/en/best-practices) sayfası, bu projeye ve Ceren'in
çalışma biçimine (kod yok, Mac yok, bulut oturumu ve telefon) uyarlandı. Claude'un okuduğu kurallar `CLAUDE.md`'de.

## Temel fikir

Sayfanın ana mesajı: Claude koddan göremediği şeyi bilemez, bittiğini kontrol edemediği işi "bitti" sanır ve yazılı
bir kural olsa bile ara sıra atlayabilir. Bu yüzden sistem üç katmanlı:

| Katman                          | Ne işe yarar                               | Solvato'da                                              |
| ------------------------------- | ------------------------------------------ | ------------------------------------------------------- |
| **Bilgi** (Claude okur)         | Koddan çıkmayan kararlar, tuzaklar         | `CLAUDE.md` (kısa), `docs/URUN.md`, özellik dokümanları |
| **Prosedür** (gerekince açılır) | Uzun, adım adım işler                      | Beceriler: `ozellik`, `bitir`, `magaza-kontrol`         |
| **Zorunlu kural** (otomatik)    | İstisnası olmayan şeyler; Claude atlayamaz | Kancalar ve izin kuralları (`.claude/settings.json`)    |

## Otomatik çalışanlar

Bunları istemene gerek yok; her oturumda kendiliğinden çalışır.

- **Oturum açılınca:** doküman biçimleyicisi kurulu değilse kurulur (bulut oturumu her seferinde temiz başlar).
- **Claude bir doküman (.md) değiştirince:** dosya otomatik biçimlendirilir.
- **main'e gönderilince (GitHub Actions):** çekirdek testleri, güvenlik taraması, seçilen ekranların görüntüleri,
  performans ölçümü ve erişilebilirlik denetimi koşar; sonuçlar `ekranlar` dalında. Kırmızı olursa Claude düzeltir.
- **Engelli işlemler:** GitHub'a zorla push yapılamaz.

## Üç tür iş

### 1. Küçük düzeltme (tek ekran, tek anlam)

Doğrudan yaz. İyi bir istek üç şeyi söyler: **nerede**, **ne oluyor**, **ne olmalı**.

| Yerine                  | Şunu yaz                                                                                                                   |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| "Ritmi Tut bozuk"       | "Ritmi Tut'ta tura başlayıp geri düğmesine basınca onay sormadan çıkıyor. Akor turundaki gibi 'Turdan çık' onayı açılsın." |
| "Ayarlar güzel olsun"   | "Ayarlar'da Günlük hatırlatma açıkken saat düğmeleri iPhone SE'de iki satıra kırılıyor. Tek satıra sığsın."                |
| "İlerleme ekranına bak" | "İlerleme'de Zorlandığın notalar kartı hiç soru çözmemiş birinde boş görünüyor. Boşken kısa bir açıklama yazsın."          |

Ekran görüntüsü ekleyebilirsin; Claude onu da okur. Sadece fikir almak istiyorsan ("bu ekranda ne iyileşir?") genel
sormak da olur; Claude o zaman kod değiştirmeden önerir.

### 2. Yeni özellik ya da büyük değişiklik

1. **Konuş:** "Yeni bir özellik istiyorum: …" ya da `/ozellik` yaz. Claude sana çoktan seçmeli sorular sorar,
   sonra `docs/ozellikler/<ad>.md` dokümanını yazar. Kod yazılmaz.
2. **Onayla:** dokümanı oku; değiştirmek istediğini söyle.
3. **Yeni oturumda uygula:** "docs/ozellikler/<ad>.md'yi uygula" yaz. Temiz oturum, konuşmanın gürültüsü olmadan
   dokümandan çalışır.
4. **Bağımsız inceleme:** "inceleyici ile dokümana göre kontrol et" yaz. Kodu yazmamış bir ajan kabul ölçütlerini tek tek
   kontrol eder; yalnızca doğruluk sorunlarını bildirir.
5. **Önizlemede dene**, sonra "tamam" ya da düzeltme.

### 3. Mağazaya gönderim

`/magaza-kontrol` yaz. Claude Apple'ın güncel kurallarını web'den okur, sürüm numaralarını, gizlilik beyanını,
lisansları ve mağaza metinlerini kontrol eder, `docs/APP-STORE-KONTROL.md`'ye ekler ve sana yapacaklarını listeler.

## Her işin sonunda göreceklerin

Claude her kod değişikliğini `bitir` adımlarıyla kapatır. Sonunda şunlar olmalı; eksikse sor:

- Kısa Türkçe özet: ne değişti, ekranda ne göreceksin, senden beklenen bir karar var mı, atlanan adım var mı.
- Arayüz değiştiyse Claude'un baktığı ekran görüntüleri (`ekranlar` dalı; gerekirse sana gönderilir).
- Yeni TestFlight sürümü (numarası özette) ve GitHub'da Türkçe commit mesajlarıyla `main`.

"Testler geçti" demek tek başına yetmez; Claude komutun çıktısını ya da ekran görüntüsünü göstermeli.

## Oturum düzeni

- **Bir iş, bir oturum.** Birbiriyle ilgisiz iki işi aynı oturumda yapma; yeni bir oturum aç. Uzun oturum hem daha
  pahalı hem de eski konular yeni işe karışır.
- **İlk dakikayı izle.** Claude yanlış yöne gidiyorsa hemen durdur ve yönlendir.
- **İki düzeltmede olmadıysa üçüncüyü yazma.** Yeni bir oturum aç ve öğrendiklerini de içeren tek, net bir istek yaz.
  Üçüncü düzeltme çoğu zaman iki başarısız denemenin üstüne eklenir.
- **Aynı şeyi iki kez düzelttiysen** Claude'a "bunu CLAUDE.md'ye ekle" de. CLAUDE.md'ye yalnızca koddan anlaşılmayan,
  tekrar tekrar gereken şeyler girer; kısa kalması önemli.
- **Aynı anda iki oturum** açabilirsin ama farklı ekranlar üzerinde olsunlar. İkisi de `main`e gönderdiği için aynı
  dosyalara dokunurlarsa çakışır.

## Düşünme gücü (efor)

Varsayılan çoğu iş için yeterli. Zor ve sinsi işlerde (ör. Ritmi Tut zamanlaması, seviye hesabı hatası, nedenini
bilmediğimiz bir çökme) oturumu yüksek eforla aç. Basit metin ve renk düzeltmelerinde gerek yok.
"İyice düşün" gibi ifadeler işe yaramıyor; efor ayarı yarıyor.

## Dil

Claude seninle her zaman Türkçe konuşur. Kendi alt ajanlarına (ör. `inceleyici`) iş verirken ve onlardan rapor alırken
İngilizce kullanır; sonucu sana Türkçe aktarır.

## Claude'un sana sormadan yapmadıkları

- Veri gönderen, hesap ya da reklam ekleyen her şey (gizlilik beyanı değişir).
- Bir özelliği kaldırmak, iPad desteğini kapatmak gibi ürün kararları.
- `docs/URUN.md`'deki bir kararla çelişen istek: önce çelişkiyi söyler.
- Mağaza metinlerini ve gizlilik politikası dokümanını değiştirmek (öneri olarak işaretler).

## Komut özeti

| Yaz               | Ne olur                                              |
| ----------------- | ---------------------------------------------------- |
| `/ozellik`        | Sorular → özellik dokümanı (kod yok)                 |
| `/bitir`          | Bitirme adımları (genelde Claude kendisi çalıştırır) |
| `/magaza-kontrol` | Mağaza öncesi uygunluk kontrolü                      |
| `/code-review`    | Son değişikliğin hata incelemesi                     |
