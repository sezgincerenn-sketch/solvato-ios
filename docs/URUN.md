# Solfado: ürün kararları ve yol haritası

Son güncelleme: 25 Kasım 2026. Bu dosya alınan kararları ve sıradaki işleri tutar; kod ayrıntısı `README.md`'de.

## Ne

Piyano öğrencileri için günde birkaç dakikalık nota okuma, ritim, akor, kulak ve müzik terimleri pratiği.
iOS ve Android, Türkçe. Öğretmenle birlikte kullanılan bir araç: öğretmen 6 haneli kodla çalışılacak konuları
ayarlar, öğrenci haftalık raporunu paylaşım menüsüyle öğretmenine gönderir.

## Alınmış kararlar

| Konu          | Karar                                                                                                                                                                                                                                                                                                              |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Ad            | **Solfado** (28 Kasım; önceki adlar Solvato ve Notalık). Kod, depo ve klasör adları `Solvato` kalır; uygulama kimliği `com.solvato.app`.                                                                                                                                                                           |
| Logo          | Piyano tuşları, sarı tuşta anahtar deliği (delik büyütülmeyecek). Yazıda "Solf" beyaz, "ado" mor.                                                                                                                                                                                                                  |
| Maskot        | **Solfie**, sekizlik nota; pozlar idle / wave / cheer. Az görünür.                                                                                                                                                                                                                                                 |
| Gelir         | Yayında **reklamsız ve ücretsiz**. Sonra Solvato Plus, ardından ücretli öğretmen paneli. Ankette reklamdan bahseden herkes bırakma sebebi olarak yazdı.                                                                                                                                                            |
| Veri          | Sunucu ve hesap yok, veri toplanmıyor. Mağazada "Data Not Collected".                                                                                                                                                                                                                                              |
| Dil           | Arayüzde "öğretmen" (hoca değil), yüzde "%40", süre "0,4 sn".                                                                                                                                                                                                                                                      |
| Tasarım       | Mevcut koyu mor tasarım korunuyor. 3 alternatif (Klavye, Porte Defteri, Oyun Yolu) denendi; şu parçalar alındı: porte üzerinde günlük hedef, mini portelerde zorlanılan notalar, seri kartında hafta, Çalışma'da arama ve "Kaldığın yer". Öğrenme yolu haritası **alınmadı** (öğretmenin konu seçmesiyle çelişir). |
| Kaldırılanlar | İki Porte (iki notayı birlikte okuma) denendi, kaldırıldı. Ritmi Tut Oyunlar listesinden çıkarıldı (ana sayfada Ritim kartının altında). Ritim heceleri eklenmeyecek.                                                                                                                                              |
| Seri          | Kutlama 1. günden başlar.                                                                                                                                                                                                                                                                                          |
| Veri (1.1)    | Admin paneli için **anonim analitik**: isim/hesap yok, rastgele cihaz kimliği, Ayarlar'dan kapatılabilir, yalnızca kendi sunucumuz (Cloudflare). 1.0 veri toplamadan çıkar. Ayrıntı `docs/PLAN.md`.                                                                                                                |
| Hesap         | **1.0'a çekildi** (25 Kasım): Misafir, Apple ve Google ile giriş; e-posta yok. Misafir tam kullanır, ilerlemesi yalnız o cihazda kalır. "Sunucu ve hesap yok" kararı hesap açanlar için değişir; sunucu, gizlilik politikası ve mağaza beyanı yayından önce hazır olmalı. Ayrıntı `docs/ozellikler/hesap.md`.      |
| Sekmeler      | Ana sayfa · İlerleme · Öğren · Profil, yüzen kapsül alt menü (25 Kasım, revize R13).                                                                                                                                                                                                                               |
| Native iOS    | `solvato-ios` **Swift/SwiftUI ile native** yeniden yazılır; web görünümü ve üçüncü taraf kod yok, güvenlik ve performans tam optimize. **1. öncelik** (22 Kasım). Plan `docs/PLAN.md` Paket 0.                                                                                                                     |
| Platform      | Önce iOS (iPhone + iPad), Android App Store'dan sonra. Web sürümü yok; tarayıcı önizlemesi TestFlight çalışınca kalkar.                                                                                                                                                                                            |
| Instagram     | Yayından önce uygulamanın içeriği paylaşılmaz; genel nota ipuçları ve bilmeceler, sonunda "uygulama yolda, takipte kal".                                                                                                                                                                                           |

## Anket (17–20 Kasım, 12 yanıt: 7 eğitmen, 5 öğrenci)

- Eğitmenler öğrencisine önerir mi: **4,9/5**. Öğrencilere yararı: **4,4/5**.
- İki grubun da bir numaralı isteği **ilerlemeyi görmek**.
- Eğitmenler en çok ek çizgiler ve fa anahtarında, öğrenciler hızda ve iki eli birlikte okumada zorlanıyor.
- Ücretli eğitmen sürümüne 7 eğitmenden 5'i "evet" ya da "belki".
- Bir eğitmen: "Orta seviyede oktav farkı gözetmeden notayı buldurmak yanlış." (aşağıda açık iş)

## Açık işler

Önce yapılacaklar:

- [ ] **Telefonda oktav kontrolü**: telefonda piyano tek oktav gösterildiği için cevabın oktavı kontrol edilmiyor,
      geniş ekranda ediliyor. Orta ve İleri seviyede telefonda da oktavlı cevap düşünülmeli.
- [ ] **Ritmi Tut gerçek telefonda**: dokunuş gecikmesi cihaza göre değişir; gerekirse `audioLatency`ye düzeltme.
- [ ] Kapalı test: ses, bildirim, iPad, Ritmi Tut zamanlaması. Yüz yüze, yakın çevreyle; rehber `docs/KAPALI-TEST.md`.

Yayın sonrası adaylar:

- [ ] İki el / iki porte okuma (5 kişi istedi); kaldırılan sürümden daha basit bir yaklaşımla.
- [ ] Aralık ve kalıp okuma (notayı tek tek değil, çizgi ve boşluk ilişkisiyle).
- [ ] Sınav / konservatuvar hazırlık içeriği; metot kitabıyla uyumlu sıra.
- [ ] Solvato Plus ve öğretmen paneli.

Kod borcu:

- [ ] 6 dosyada kalan 23 Tailwind sınıfı → token + satır içi stil.

## Yayın planı

- Hedef yayın: ~~23 Aralık – 5 Ocak~~ → **Ocak sonu – Şubat ortası 2027** (native iOS kararıyla kaydı).
- Google Play kapalı testi: en az **12 test kullanıcısı, 14 gün**. Ankette 6 kişi test için e-posta bıraktı.
- Mac yok: iOS derlemesi bulut servisiyle (Capawesome, Capgo ya da Codemagic; Ionic Appflow kapanıyor).
- Mağaza ekran görüntüleri hazır (7 kare: ana sayfa, soru, tur sonucu, Ritmi Tut, arkadaşla yarış, öğretmen kodu,
  ilerleme). Arayüz değişirse yeniden çekilmeli.

## Ceren'in dokümanları (claude.ai, yalnızca Ceren ve paylaştığı kişiler açabilir)

| Doküman                                                                | Bağlantı                                          |
| ---------------------------------------------------------------------- | ------------------------------------------------- |
| Uygulama önizlemesi (tek dosyalık sürüm)                               | https://claude.ai/artifact/AK45sA3bSP2kZX5TZacarf |
| Mağaza metinleri (açıklamalar, gizlilik etiketi, veri güvenliği formu) | https://claude.ai/artifact/DPUzuXN5pS4ZB28BYkrgJd |
| Gizlilik politikası                                                    | https://claude.ai/artifact/DSSS7vsiYzhdbiZ9K6Jdro |
| Yayın planı tablosu (24 adım)                                          | https://claude.ai/artifact/7UwiAXdPwGsVrn3HfWPfTu |
| Solvato Tasarım Sistemi                                                | https://claude.ai/artifact/8JMKAcRX1hgxapisT4EUp9 |
| Anket analizi                                                          | https://claude.ai/artifact/MSbDVsT4FUmHBsHdgSaLcJ |
| UI alternatifleri tuvali                                               | https://claude.ai/artifact/DS6UyyLHT2W82avAaHpoY2 |
| Logo ve maskot tuvali                                                  | https://claude.ai/artifact/DiL9N6hfZ1JrNrEn5k5eXi |
