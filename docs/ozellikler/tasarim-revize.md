# Tasarım revizeleri

Ceren'in tasarım revizelerinin listesi. Her revize numaralanır (R1, R2…), önce netleştirilir ve onaylanır, sonra küçük
gruplar hâlinde **yalnız native sürüme** (`ios-native/`) uygulanır; her grup TestFlight'la telefonda denenir.
Native sürüm bugünkü uygulamanın birebir kopyası olarak yazıldı; buradaki her madde o kopyadan **bilerek** yapılan bir
farktır (CLAUDE.md "Birebir uyum": fark ancak Ceren onayıyla). Uygulanınca `docs/ozellikler/native-ios.md`'deki ilgili
ekran ve kabul ölçütleri de güncellenir.

Uygulama sırası: Aralık'taki ilk TestFlight (native sürümün bugünkü hâli telefonda doğrulandıktan) sonra. Küçük ve
bağımsız maddeler daha erken girebilir.

## Durumlar

- **taslak**: Ceren anlattı, sorular açık
- **onaylandı**: ne yapılacağı net, uygulanabilir
- **uygulandı**: kodda, TestFlight bekliyor (derleme numarası)
- **tamam**: telefonda denendi

## Revizeler

| No  | Ekran(lar) | Ne değişiyor                                                                                             | Durum  | Not                                                   |
| --- | ---------- | -------------------------------------------------------------------------------------------------------- | ------ | ----------------------------------------------------- |
| R1  | Soru turu  | Yanlışta açıklama kartı "Senin cevabın: Fa · Doğru cevap: Sol" der; nota sorusunda ikisi de dinlenebilir | taslak | Benchmark: Pitch Trainer, Clefs                       |
| R2  | Soru turu  | Üstteki 10 nokta cevaplanınca yeşil (doğru) ya da kırmızı (yanlış) olur                                  | taslak | Benchmark: Notahop                                    |
| R3  | Pratik     | Bugün kartı ne çalışılacağını ve süresini söyler: "Sol Anahtarı · 10 soru · ~3 dk"                       | taslak | Kaydırmayı azaltma önerisiyle birlikte ele alınabilir |
| R4  | Tanıtım    | Seviye adımına isteğe bağlı kısa yerleştirme denemesi ("Bilmiyorum" seçenekli), sonuçta seviye önerisi   | taslak | Benchmark: Clefs, Notahop, Pitch Trainer; ürün kararı |
| R5  | Tanıtım    | Yeni adım: "Öğretmenle mi çalışıyorsun?" Evet derse öğretmen kodu alanı                                  | taslak | Benchmark: Notaforte, Tomplay                         |
| R6  | İlerleme   | Anahtar başına "Okuman" portesi: her nota üç renkte (eminsin / öğreniyorsun / henüz değil)               | taslak | Benchmark: Notahop; anketin 1 numaralı isteği         |
| R7  | İlerleme   | Boş ekranda 3 adımlı başlangıç listesi (ilk tur, ilk hedef, 2 gün üst üste)                              | taslak | Benchmark: Pitch Trainer                              |
| R8  | Tur sonucu | Hatırlatma kapalıyken ilk seri günü "Serini koru, hatırlatayım mı?" kartı                                | taslak | Benchmark: Clefs                                      |

<!-- Örnek satır:
| R1 | Pratik | "Bugün" kartı kısalır, porte küçülür | taslak | Soru: hedef yazısı kartta kalsın mı? |
-->

## Ayrıntılar

Her revize için: ekran görüntüsü ya da tarif, kararlar, açık sorular, etkilenen dosyalar, kabul ölçütü.

R1–R8, Ceren'in benchmark dosyasından (25 Kasım, `docs/benchmark.md`) çıkan **öneriler**; hiçbiri onaylı değil.
Görüntü numaraları Figma'daki "Piyano Benchmark" dosyasının katman adları (IMG_xxxx).

### R1 Yanlış cevapta "senin cevabın" ve dinleme

- **Örnek:** Pitch Trainer IMG_2444 ("Senin seçtiğin: Fa ▶ / Doğru cevap: Do ▶"), Clefs IMG_2200 (yanlış tuş kırmızı
  ve çizgili, doğru tuş yeşil).
- **Bugün:** klavyede seçilen tuş kırmızı, doğru tuş yeşil oluyor; alttaki kart yalnız "Doğru cevap: Sol" + açıklama.
  Şıklarla cevapta doğru şık yeşil ✓.
- **Öneri:** kartın ilk satırı "Senin cevabın: **Fa** · Doğru cevap: **Sol**". Nota sorularında iki adın yanında
  küçük ▶ düğmesi; ikisi dinlenip fark duyulur. Yanlış tuşa kırmızının yanında ince çizgili desen (renk ayırt
  edemeyenler için).
- **Açık sorular:** Ses kapalıyken ▶ düğmeleri gizlensin mi? Ritim, terim ve yazım sorularında da "Senin cevabın"
  yazsın mı (orada dinleme yok)? Çizgili desen istenir mi?
- **Etkilenen:** E-05 Soru turu (açıklama kartı, klavye tuş durumu).
- **Kabul (taslak):** yanlış nota sorusunda kartta iki ad ve iki ▶; ▶ ilgili notayı çalıyor; doğru cevapta kart
  değişmiyor.

### R2 Tur içi noktalar doğru/yanlış renginde

- **Örnek:** Notahop IMG_2359 (her soru bir parça, doğru yeşil, yanlış kırmızı).
- **Bugün:** üstteki 10 nokta geçilen soruda mor, şimdiki soruda uzun mor, kalanlar gri. Doğru sayısı sağda "✓ 4".
- **Öneri:** cevaplanan noktalar yeşil ya da kırmızı; şimdiki ve kalanlar bugünkü gibi.
- **Açık sorular:** Kırmızı nokta motivasyonu düşürür mü (özellikle Başlangıç)? Yalnız yeşil/gri mi olsun?
- **Etkilenen:** E-05 Soru turu, E-06 Akor turu (aynı noktalar), oyun turları.
- **Kabul (taslak):** 10 soruluk turda nokta renkleri cevap sırasıyla birebir; tur sonucu sayısıyla tutarlı.

### R3 Bugün kartında ne ve ne kadar

- **Örnek:** Clefs IMG_2204 ("Günlük çalışman hazır! Sol anahtarı · 6 soru [Başla]"), Pitch Trainer IMG_2447
  ("~5 dk · +10 yeni"), bitince IMG_2468 ("Bugün için hepsi tamam ✓").
- **Bugün:** Bugün kartı "12/20 soru", hedef portesi, alt yazı ("… soru kaldı"), mor düğme "Bugünün çalışması / Devam
  et / Bir tur daha".
- **Öneri:** düğmenin üstünde tek satır: sıradaki turun konusu, soru sayısı ve yaklaşık süre ("Sol Anahtarı · 10 soru ·
  ~3 dk"). Süre son turların ortalama cevap süresinden ya da sabit tahminden.
- **Açık sorular:** Süre tahmini gösterilsin mi, yoksa yalnız konu + soru sayısı mı? "Kaydırmayı azaltmak" önerisi
  için Pratik'in ilk ekranına sığacak şekilde mi düşünelim?
- **Etkilenen:** E-04 Pratik (Bugün kartı).
- **Kabul (taslak):** öğretmen konusu seçiliyken satır öğretmenin konusunu gösteriyor; hedef tamamken "Bir tur daha"
  satırı da doğru konu ve sayıyı veriyor.

### R4 Tanıtımda kısa yerleştirme denemesi

- **Örnek:** Clefs IMG_2189–2191 (anahtar seç → porte + nota çemberi + "Bilmiyorum" → "Şuradan başlıyoruz"), Notahop
  IMG_2358–2360 ("Bunu henüz bilmiyorum", "Okuman: seviye 1"), Pitch Trainer IMG_2439–2446 ("Yaklaşık iki dakika",
  "Atla, yeni başlıyorum", yanlışta "Sorun değil, en baştan başlarız").
- **Bugün:** E-02'de iki deneme sorusu (Do4, Sol4) var; seviye "Yeni başladım / Bir süredir / Uzun süredir" diye
  beyanla seçiliyor.
- **Öneri:** Seviye adımında "Bir süredir" ya da "Uzun süredir" seçilirse isteğe bağlı "2 dakikalık kontrol" (ör. 8
  nota, ek çizgili ve diyezli notalar dahil, "Bilmiyorum" düğmesiyle). Sonuçta "Önerimiz: Orta" ve değiştirme imkânı.
  "Atla" her zaman var.
- **Açık sorular:** Bu, seviye kuralını (K-04) değiştirmeden yalnız başlangıç seviyesini önermek mi olsun? Öğretmen
  kodu varsa deneme hiç gösterilmesin mi? Birden çok ekranı etkilediği için önce `ozellik` dokümanı gerekir.
- **Etkilenen:** E-02 Tanıtım, K-04 Seviye.
- **Kabul (taslak):** onaylanınca özellik dokümanında yazılacak.

### R5 Tanıtımda öğretmen sorusu

- **Örnek:** Notaforte IMG_2483 ("Öğretmenle öğreniyorum", "Müzik öğretmeniyim"), Tomplay IMG_2408 ("I am a
  Teacher").
- **Bugün:** öğretmen kodu tanıtımda geçmiyor; Ayarlar'ın en üstünden bulunuyor.
- **Öneri:** Anahtar adımından önce tek soru: "Bir öğretmenle mi çalışıyorsun?" Evet → "Öğretmeninden aldığın kodu
  gir" alanı (boş geçilebilir, "Kodum yok" bağlantısı). Kod girilirse anahtar, seviye ve hedef adımları atlanır
  (kod bunları zaten ayarlıyor). "Öğretmenim" seçeneği öğretmeni E-13'teki kod oluşturma bölümüne götürür.
- **Açık sorular:** Öğretmen seçeneği tanıtımda olsun mu, yoksa yalnız öğrenci tarafı mı? Kodla atlanan adımlar
  doğru mu?
- **Etkilenen:** E-02 Tanıtım, E-13 Öğretmen kodu. Birden çok ekran: önce `ozellik` dokümanı.
- **Kabul (taslak):** onaylanınca özellik dokümanında yazılacak.

### R6 İlerleme'de "Okuman" portesi

- **Örnek:** Notahop IMG_2372–2373 (Sol ve Fa anahtarı için birer porte; notalar "Artık eminim / Öğreniyorsun /
  Henüz değil" renklerinde; "Zor notalar: Fa").
- **Bugün:** İlerleme'de konu çubukları ve "Zorlandığın notalar" (en çok 6 küçük porte, %70 altı).
- **Öneri:** Konular'ın üstünde anahtar başına tek porte; o anahtarın çalışılan bütün nota konumları sırayla dizili,
  her nota üç renkte: %85+ ve en az 5 kez sorulmuş → eminsin (yeşil), daha az → öğreniyorsun (amber), hiç sorulmamış
  ya da %50 altı → henüz değil (gri/kırmızı). Veri zaten var (`noteStats`). Haftalık rapora da kısa hali girebilir.
- **Açık sorular:** "Zorlandığın notalar" kartı kalsın mı, bununla mı birleşsin? Eşikler (85 / 5 / 50) uygun mu?
  Diyezli konumlar aynı portede mi, ayrı mı?
- **Etkilenen:** E-10 İlerleme, K-12 Zorlandığın notalar (belki K-13 Haftalık rapor).
- **Kabul (taslak):** aynı `noteStats` için renkler eşiklere göre doğru; iPhone SE'de porte taşmadan sığıyor.

### R7 Boş İlerleme'de başlangıç listesi

- **Örnek:** Pitch Trainer IMG_2472 ("İlerlemeni 3 adımda aç · 2/3 tamam").
- **Bugün:** hiç soru yoksa boş durum çizimi, "İstatistiklerin burada görünecek", "İlk tura başla".
- **Öneri:** çizimin altında üç maddelik liste: "İlk turunu bitir", "Günlük hedefini tamamla", "2 gün üst üste çalış";
  tamamlananlar ✓. Üçü de bitene kadar İlerleme'nin üstünde küçük kart olarak kalır.
- **Açık sorular:** Liste yalnız boş durumda mı, yoksa ilk günlerde veri varken de mi görünsün?
- **Etkilenen:** E-10 İlerleme.
- **Kabul (taslak):** her madde ilgili kural (K-07 seri, K-08 tur sayısı) gerçekleşince işaretleniyor.

### R8 İlk seri günü hatırlatma teklifi

- **Örnek:** Clefs IMG_2201 (tur sonu: "Seri başladı!" altında "Serini koru: kaybetmeden önce haber verelim mi? Şimdi
  değil / Hatırlat").
- **Bugün:** hatırlatma tanıtımın 6. adımında soruluyor; "Şimdi değil" denirse yalnız Ayarlar'dan açılıyor.
- **Öneri:** hatırlatma kapalıysa ve seri ilk kez 1 olduysa tur sonucu ekranında tek seferlik küçük kart: "Serini
  koru. Yarın bu saatte hatırlatayım mı?" (Hatırlat / Şimdi değil). Hatırlat → bildirim izni + saat şimdiki saate en
  yakın seçenek. Bir kez gösterilir.
- **Açık sorular:** Kutlama penceresiyle çakışmasın diye pencere kapandıktan sonra mı görünsün? Saat seçimi kartta mı?
- **Etkilenen:** E-08 Tur sonucu, E-12 Ayarlar (hatırlatma).
- **Kabul (taslak):** yalnız bir kez gösteriliyor; izin reddedilirse hatırlatma kapalı kalıyor.

## Bekleyen öneriler

- Kaydırmayı azaltmak (Ceren, 22 Kasım): hangi ekranlarda uzun kaydırmanın rahatsız ettiği netleşecek.
- Benchmark'tan, revize değil yeni özellik sayılacaklar (`docs/benchmark.md` "Sonraya not"): aralık ve kalıp okuma
  için Notaforte'nin referans nota ("landmark") yöntemi, sınav hazırlık için Müzik Prova, tur sonunda okunan notaların
  tanıdık bir melodiye dönüşmesi (Notahop), seri dondurma (Clefs). Her biri ürün kararı; `ozellik` dokümanıyla.
