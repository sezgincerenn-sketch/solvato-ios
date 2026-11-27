# Kapalı test (0.9): yüz yüze, yakın çevreyle

Native Solvato'nun yayından önceki son denemesi (`docs/PLAN.md` 0.9). Ceren testi yakın çevresiyle **yüz yüze** yapar;
geri bildirim konuşarak ve not alarak toplanır, uygulama içinde form yok (uygulama hiçbir yere veri göndermez).
Notlar sonra Claude'a yapıştırılır; bulgular sınıflanıp düzeltilir.

## Kimlerle

5–6 kişi çoğu sorunu bulmaya yeter. Karışık olsun:

- 2 başlangıç öğrencisi (piyanoya yeni başlamış, nota okumayı öğreniyor)
- 1–2 orta / ileri öğrenci
- 1 öğretmen (öğretmen kodunu hazırlasın)
- 1 nota bilmeyen biri (tanıtımın tek başına anlaşılıp anlaşılmadığını en iyi o gösterir)

Kişi başı 20–25 dakika.

## Hazırlık

**Hangi cihaz:** En kolayı testi kendi iPhone'unda (ve iPad'inde) yaptırmak. Kişinin kendi telefonunda denemek
istersen onu App Store Connect'e kullanıcı olarak eklemen gerekir (Users and Access → **+** → e-posta, rol
"Customer Support", Solvato'ya erişim), sonra TestFlight › Internal Testing › **Ekip** grubuna ekle. Davet e-postasını
kabul edip TestFlight'tan kurar.

**Son sürüm:** TestFlight'ta en yeni derleme (şu an **2011**). Teste başlamadan güncelle.

**Her kişiden önce sıfırdan başlat** (ilk açılış da denensin):

1. Uygulamayı sil, TestFlight'tan yeniden kur. Bu, kendi ilerlemeni de siler; kendi kaydını korumak istiyorsan testi
   iPad'de ya da ikinci bir cihazda yap.
2. Ses açık, telefon sessiz modda değil (ses görevi ayrıca var). Ekran parlaklığı yüksek.

**TestFlight "What to Test" notu** (App Store Connect › TestFlight › derleme › Test Details; iç testte görünür):

> Solvato'nun yeni (native) sürümü. Tanıtımı baştan sona yap, bir tur bitir, Ritmi Tut'u dene. Takıldığın,
> yanlış gördüğün ya da sesin geç geldiği her yeri söyle.

## Oturum

Başta tek cümle: "Uygulamayı deniyoruz, seni değil. Aklından geçeni sesli söyle; nasıl yapılacağını ben söylemeyeceğim."
Görevi oku, sonra sus ve izle. Takılınca 30 saniye bekle; hâlâ takılıysa "Nerede arardın?" diye sor, cevabı not et.

### Görevler (sırayla; hepsini yetiştirmek gerekmez)

| #   | Görev (kişiye böyle söyle)                                                          | Neye bak                                                                    |
| --- | ----------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| 1   | "Uygulamayı ilk kez açıyorsun, başla."                                              | Tanıtım anlaşılıyor mu, deneme sorusunda tuşu buluyor mu, öğretmen sorusu   |
| 2   | "Bugünün çalışmasını yap, turu bitir."                                              | Klavyeyi mi şıkları mı seçiyor, yanlışta açıklamayı okuyor mu, sonuç ekranı |
| 3   | "Sadece Fa anahtarı çalışmak istiyorsun."                                           | Konu kartını buluyor mu                                                     |
| 4   | Soru turunda: "Telefonu yan çevir."                                                 | Klavye 3 oktav oluyor mu, tur kaldığı yerden sürüyor mu                     |
| 5   | "Ritmi Tut'u bul, bir ritmi dinle, sonra çal."                                      | Dokunuş ile tık aynı anda mı hissediliyor; "erken/geç" sonucu adil mi       |
| 6   | "Akor turunda bir akoru tuşlara basarak kur."                                       | Seçilen tuşlar anlaşılıyor mu, Kontrol Et                                   |
| 7   | "Öğren'de Sol anahtarı notaları dersini aç, notalarda gez."                         | Oklar / klavye ile gezme                                                    |
| 8   | "En çok zorlandığın notayı bul."                                                    | İlerleme'yi buluyor mu, Zorlandığın notalar                                 |
| 9   | "Bir arkadaşına meydan okuma kodu hazırla." (Gönderme, paylaşım ekranı açılsın.)    | Oyunlar kartı, kodun anlaşılması                                            |
| 10  | Öğretmene: "Öğrencin için kod hazırla." Öğrenciye: "Öğretmeninin kodunu gir."       | Profil › Öğretmen kodu; yapıştırma, tire, kodun uygulanması                 |
| 11  | "Her gün akşam 8'de hatırlatma istiyorsun."                                         | İzin sorusu, saat seçimi; ertesi gün bildirim geldi mi (sen kontrol et)     |
| 12  | "Telefonu sessiz moda al, bir soru cevapla."                                        | Ses geliyor mu (gelmeli; Ayarlar'da yazıyor)                                |
| 13  | iPad varsa: "Aynı turu iPad'de yatay yap." Sonra başka bir uygulamayla yan yana aç. | İki sütun, 2–3 oktav; dar pencerede iPhone düzeni                           |

### Son sorular (2–3 dakika)

1. Sence bu uygulama ne işe yarıyor, kimin için?
2. En çok neyi sevdin?
3. Nerede zorlandın ya da sinirlendin?
4. Öğretmeninle (ya da öğrencinle) kullanır mısın? Nasıl?
5. Haftada kaç kez açarsın? Neden?

## Not şablonu (kişi başı)

```
Kişi: (ad ya da takma ad) · rol: öğrenci başlangıç / orta-ileri / öğretmen / nota bilmiyor
Cihaz: iPhone ... / iPad ... · iOS ... · Solvato derleme 2011
Görevler: 1 ✓  2 ✓  3 takıldı  4 ✓ ...

Bulgular (her satır bir şey):
- [ekran] ne oldu · kişi ne dedi · ciddiyet: engel / can sıkıcı / küçük
- ...

Son sorular:
1. ...
```

**Ciddiyet:** _engel_ = görevi tamamlayamadı ya da uygulama çöktü; _can sıkıcı_ = tamamladı ama zorlandı, yanlış
anladı; _küçük_ = yazı, renk, öneri.

Çökme olursa: Ayarlar › Gizlilik ve Güvenlik › Analiz ve İyileştirmeler › Analiz Verileri'nde "Solvato" ile başlayan
kayıt; ekran görüntüsünü al. TestFlight'ın kendi çökme raporu da App Store Connect › TestFlight › Crashes'e düşer.

## Sonra

Bütün notları bu oturuma (ya da yeni bir oturuma) yapıştır. Claude bulguları ekrana göre gruplar, hangisinin hata,
hangisinin tasarım kararı olduğunu ayırır; kararı gerekenleri sana sorar, hataları düzeltir. Testten çıkan karar ve
düzeltmeler bu dosyanın sonuna "Bulgular" başlığıyla eklenir.

Testte ayrıca bakılacaklar (kapalı testten önce açıkta kalanlar, `docs/URUN.md`, `docs/APP-STORE-KONTROL.md`): ses,
bildirimin gelmesi, iPad, Ritmi Tut zamanlaması, sessiz mod; telefonda oktav kontrolü (Orta/İleri seviyede cevabın
oktavı telefonda sorulmuyor; kimse yadırgıyor mu).
