# Benchmark: nota okuma ve kulak eğitimi uygulamaları

Ceren'in Figma dosyası "Piyano Benchmark" (25 Kasım 2026 itibarıyla 315 ekran görüntüsü, IMG_2187–IMG_2514) incelendi.
Bu doküman bulguları tutar; Solvato'ya uygulanabilecek öneriler `docs/ozellikler/tasarim-revize.md`'de taslak revize
olarak duruyor. Görüntü numaraları Figma'daki katman adlarıdır (ör. `IMG_2201`).

## İncelenen uygulamalar

| #   | Uygulama                                   | Görüntüler | Odak                                | Görünüm                        | Gelir modeli                          |
| --- | ------------------------------------------ | ---------- | ----------------------------------- | ------------------------------ | ------------------------------------- |
| 1   | Clefs: Note Reading Trainer                | 2187–2211  | Nota okuma, kurs + serbest pratik   | Açık, adaçayı yeşili, sade     | Premium (kilitli dersler)             |
| 2   | Note Rush                                  | 2212–2229  | Oyun tarzı nota okuma, ritim, kulak | Koyu, neon, arcade             | Tek seferlik tam erişim               |
| 3   | Lumba Dore (Türkçe)                        | 2233–2241  | Müzik oyunları, görevler, sıralama  | Açık, kalabalık üst bant       | Hesaplı, ücretsiz                     |
| 4   | Perfect Ear                                | 2242–2260  | Kulak, ritim, teori, kurslar        | Açık, zeytin yeşili            | Tek seferlik 799,99 TL                |
| 5   | Solfexa (Türkçe)                           | 2261–2268  | Kulak, ritim, solfej modülleri      | Koyu + krem, tırnaklı yazı     | Abonelik 2.499,99 TL/ay, günlük limit |
| 6   | Adı görünmeyen koyu mavi uygulama (Türkçe) | 2269–2282  | Ders + alıştırma, XP, görevler      | Koyu lacivert, renkli simgeler | Aylık / ömür boyu                     |
| 7   | Pianotype: Nota Pratiği                    | 2283–2307  | Mikrofonla piyanoda nota okuma      | Beyaz + parlak mavi            | Abonelik, 7 gün deneme, süre limiti   |
| 8   | Piano Sight Reading                        | 2309–2321  | Nota tanıma, parçalar               | Açık lavanta                   | Üyelik                                |
| 9   | Notevision                                 | 2326–2334  | Nota, akor, tonalite (yatay)        | Açık, sıkışık                  | Bilinmiyor                            |
| 10  | MuseScore                                  | 2335–2345  | Nota kütüphanesi (yalnız tanıtım)   | Beyaz + mor                    | Abonelik                              |
| 11  | Notahop (Türkçe)                           | 2346–2376  | Nota okuma, şarkı defteri, maskot   | Açık, yeşil, kurbağa maskot    | Ücretsiz tur limiti + Pro             |
| 12  | Müzik Prova (Türkçe)                       | 2377–2396  | BİLSEM / GSL / konservatuvar sınavı | Krem + lacivert                | İlk seviyeler ücretsiz + Premium      |
| 13  | Tomplay                                    | 2397–2409  | Partisyon kütüphanesi, dersler      | Beyaz + pembe, fotoğraflı      | Abonelik, 14 gün deneme               |
| 14  | Pitch Trainer                              | 2410–2477  | Kulak eğitimi, dersler, ligler      | Beyaz + turuncu/mavi           | Haftalık abonelik, 7 gün deneme       |
| 15  | Notaforte                                  | 2478–2513  | Nota okuma yolu, "landmark" yöntemi | Pastel geçişli, renkli karolar | Yıllık / ömür boyu                    |
| 16  | Solfy (Fransızca)                          | 2514       | Yalnız açılış ekranı                | Mor                            | —                                     |

## Ortak kalıplar

### 1. İlk açılış (tanıtım)

- **Uzun soru dizileri yaygın**: Pianotype, MuseScore, Pitch Trainer ve Notaforte 6–12 soru soruyor (enstrüman, yaş,
  hedef, deneyim, günlük süre, seni ne zorluyor). Çoğu soru kişiselleştirmeden çok satış hunisi işi görüyor (yaş,
  tür, "potansiyelin" grafiği).
- **İyi örnekler kısa ve işe yarar**:
  - Clefs (2187–2192): "Daha önce nota okudun mu?" (3 seçenek), "Hangi anahtarları okuyabiliyorsun?", sonra kısa
    bir **yerleştirme denemesi** ("Bilmiyorum" seçeneğiyle) ve "Şuradan başlıyoruz" özeti.
  - Notahop (2346–2360): her sorunun altında neden sorulduğu yazıyor ("Kısa bir seviye belirleme turu bunu bir
    dakikada ayarlar"), en sonda **seçimlerin özeti** ("Planın hazır": anahtar, nota adları, hedef, hatırlatma saati).
  - Pitch Trainer (2421–2446): "Bir hızlı seviye kontrolü: bildiğini söyle, iddia ettiğini kanıtla, bildiğini atla.
    Yaklaşık iki dakika." + "Atla, yeni başlıyorum" bağlantısı. Yanlışta "Sorun değil, en baştan başlarız" diyor.
  - Notaforte (2483): "Seni en iyi ne anlatır?" sorusunda **"Öğretmenle öğreniyorum"** ve **"Müzik öğretmeniyim"**
    seçenekleri var; Tomplay seviye seçiminde "I am a Teacher".
- **Cevaba göre ekran**: Notaforte "En çok ne zorluyor?" sorusuna "Çizgi saymak" denince sonraki ekran o soruna
  çözümünü anlatıyor ("Artık çizgi saymak yok", 2486). Soru boşa sorulmuyor.
- **Bildirim izni bağlamla isteniyor**: Pianotype "Ritmi koruyun!" (Bildirimleri aç / Şimdi değil), Notahop saat
  seçimi, MuseScore "her gün aynı saatte 17 dk". Clefs ise izni tanıtımda değil, **ilk seri başladığında** tur
  sonunda istiyor ("Serini koru: kaybetmeden önce haber verelim mi? Şimdi değil / Hatırlat", 2201).

### 2. Ana sayfa

- **Tek bir "bugün" eylemi en üstte**: Clefs "Günlük çalışman hazır! Sol anahtarı · 6 soru [Başla]" (2204), Pitch
  Trainer "Bugünün çalışması · ~5 dk · +10 yeni [Başla]" (2447), Notahop "Seviye 1/7 · Seviye 2 için 12 doğru nota
  daha [Alıştırma turu oyna]" (2364), Piano Sight Reading "Today's practice · Bugünün hedefi 1/3 [Devam]" (2313).
  Kart neyin, kaç soruluk, ne kadar sürede yapılacağını söylüyor.
- **Bitince karşılayan durum**: Pitch Trainer "Bugün için hepsi tamam ✓ · Tekrar listende bir şey kalmadı" (2468).
- **Haftanın günleri şeridi** üstte (Pitch Trainer, Solfexa): bugün halkalı, geçmiş günler işaretli.
- **Kalabalık üst bant kötü örnek**: Lumba Dore'de 5 rozet (seri, seviye, yıldız, bildirim, avatar) yan yana (2234).
- **Kaydırma**: Clefs, Pitch Trainer ve Notahop'ta ilk ekran tek kart + kısa liste; uzun bölümler alt sekmelere
  dağıtılmış. Koyu mavi uygulama (2269–2282) ve Perfect Ear uzun kaydırmalı.

### 3. Soru / tur ekranı

- **Yanlış cevapta iki taraf birlikte gösteriliyor**:
  - Clefs (2200): klavyede yanlış basılan tuş **kırmızı ve çizgili**, doğru tuş **yeşil**, ikisinin üstünde nota adı.
    Çizgili desen rengi ayırt edemeyenler için de çalışıyor.
  - Pitch Trainer (2444): "Tam değil. Bu Do." altında **"Senin seçtiğin: Fa ▶"** ve **"Doğru cevap: Do ▶"** kutuları,
    ikisi de dinlenebiliyor; ardından "Anladım".
- **Tur içi ilerleme çubuğu doğru/yanlışı gösteriyor**: Notahop (2359) her soru için bir parça; doğru yeşil, yanlış
  kırmızı. Tur bitmeden nasıl gittiğin görülüyor.
- **"Bilmiyorum" seçeneği**: Clefs, Notahop ("Bunu henüz bilmiyorum"), Pitch Trainer ("Bilmiyor musun? Atla").
  Tahmin yerine dürüst cevap; yerleştirmede ve yeni notada işe yarıyor.
- **Cevap yöntemi seçimi turun başında**: Clefs (2198) nota çemberi / klavye / kaydırmalı klavye; Notaforte (2504)
  dairesel klavye / piyano klavyesi.
- **Notaforte "landmark" renkleri** (2502–2504): portede referans notaların çizgisi renkli bantla işaretleniyor,
  öğrenci diğer notaları bunlardan sayıyor. Ayarlardan kapatılabiliyor.
- **Çıkış onayı** her uygulamada var; Notahop ücretsiz tur hakkının yanacağını söylüyor (2367).

### 4. Tur sonu ve kutlama

- Clefs (2201): büyük yüzde (%95), "Seri başladı!", puan + ortalama süre (1,32 sn), "Yeni rekor!".
- Pitch Trainer (2465–2467): 1–3 yıldız, "İlk denemede doğru %40", ayrı bir **seri penceresi** (haftanın günleri,
  kaçırılan gün ✕, bugün ✓, "Devam et").
- Notahop (2360, 2363): "Okuman: seviye 1, turlar oradan başlar" + maskot kıyafeti ödülü; "2 dakika önce başladın,
  şimdi bir melodi okuyorsun" (okunan notalar tanıdık bir melodiye dönüşüp çalınıyor).
- Pianotype ve Pitch Trainer'da konfeti ve büyük başlık; Solvato'nun kutlama penceresiyle aynı yoğunlukta.

### 5. İlerleme ve istatistik

- **Notahop "Okuman" kartı** (2372): her anahtar için bir porte, notalar ustalık durumuna göre üç renkte (Artık
  eminim / Öğreniyorsun / Henüz değil) ve "Zor notalar: Fa". İlerleme tek bakışta portenin üstünde görünüyor.
- **Boş ilerleme ekranı yerine yapılacaklar listesi**: Pitch Trainer "İlerlemeni 3 adımda aç: Nasıl çalıştığını
  öğren ✓, Bir etkinlik tamamla ✓, 2 gün üst üste çalış" (2472). Müzik Prova'da "Henüz veri yok" boş durumu (2390).
- **Haftalık karşılaştırma**: Piano Sight Reading "Bu hafta %94 ortalama doğruluk · geçen haftaya göre"; Tomplay
  takvim + "ritmini kur" (2405).
- **Rozetler / kilometre taşları**: Tomplay "1/22 rozet", "3/7/12 hafta üst üste" (2407); Piano Sight Reading "Seri",
  "Doğruluk ası, en iyi %99", "Hızlanıyorsun".
- Konu bazlı seviye listeleri (Müzik Prova "Tek Ses 0/15, Çift Ses 0/46…") bilgi dolu ama kuru.

### 6. Seri, hedef, hatırlatma

- **Seri dondurma**: Clefs "1 dondurma hakkın var · Sonraki 6 gün sonra" (2206–2207); seriye bağlı uygulama simgesi
  ödülleri (30 / 100 gün).
- **Hedef süreyle**: Pitch Trainer "Günde 8 dk tatlı nokta", Notaforte "Günde 10 dakika: birkaç dakika her gün, haftada
  bir uzun oturumdan iyidir" (2490). Solvato hedefi soru sayısıyla tutuyor.
- **Hatırlatma günleri**: Tomplay hafta günü çipleri + saat (2406); Müzik Prova "Otomatik: çalıştığın saate göre".

### 7. Ders / teori içeriği

- Kısa kartlar halinde, her kartta tek fikir ve hemen dinleme: Pitch Trainer "Öğren · 1/5" kartları, "Bildiğin
  şarkılarla hatırla" (2452–2461); Müzik Prova metnin içinde "▶ Kalın ses · ▶ İnce ses" düğmeleri (2393–2394).
- Clefs ve Perfect Ear'da uzun düz metin sayfaları (2193–2197): okunması zor, kaydırma çok.
- Notaforte ders kartında hedef kuralı açıkça yazıyor: "Pratik bölümlerinde sonrakine geçmeden %90 doğru yap" (2502).

### 8. Ayarlar

- **Nota adı sistemleri örnekle**: Perfect Ear (2257) ve Pianotype (2303) her seçeneğin altında örnek dizi gösteriyor
  ("Solfej · Do Re Mi Fa Sol La Si", "Almanca · C D E F G A H").
- **"Hazırım düğmesi"** (Müzik Prova, 2395): kulak sorusunda cevap süresi kendiliğinden başlamıyor.
- **"Cevap ipuçları"** (Pitch Trainer): yanlıştan sonra seçtiğinle doğruyu karşılaştır.
- Tema "Sistem / Açık / Koyu" üçlü seçim (Müzik Prova).

### 9. Ücretlendirme ve satış

- Neredeyse hepsi tanıtım sonunda ödeme duvarı gösteriyor; çoğu deneme süreli abonelik (Pitch Trainer haftalık).
- Ücretsiz kullanımı **süreyle ya da tur sayısıyla kısıtlama** yaygın: Solfexa "Günlük 5 egzersiz hakkın doldu",
  Pianotype "Bir sonraki egzersiz 44:47 içinde", Notahop "Sonraki ücretsiz tura kalan 5:58:40".
- Sahte yükleme ve tahmin ekranları: "Kişiselleştirilmiş plan oluşturuluyor %47", "Piyano akort ediliyor…",
  "Kulakların 7 gün sonra çok gelişecek" grafiği.

## Solvato ile karşılaştırma

**Solvato'nun önde olduğu yerler**

- **Öğretmen bağı**: öğretmen kodu ve haftalık rapor incelenen uygulamaların hiçbirinde yok. En yakını Notaforte ve
  Tomplay'in tanıtımdaki "öğretmenim / öğretmenle öğreniyorum" seçeneği; ikisi de bunu sonradan kullanmıyor.
- **Reklamsız, hesapsız, veri toplamıyor**: rakiplerin çoğu hesap, analitik, ödeme duvarı ve süre limiti kullanıyor.
- **Türkçe ve konu genişliği**: nota + ritim + akor + kulak + terim aynı uygulamada; Türkçe rakipler (Notahop, Müzik
  Prova, Solfexa) ya tek konuya ya sınava odaklı.
- **Çalışılacak notaları seçmek**: Notaforte ve Piano Sight Reading'de aralık seçimi var, ama öğretmenin
  belirleyebildiği bir kısıt yok.

**Solvato'da eksik ya da zayıf görünenler** (öneriler revize dokümanında)

- Yanlışta klavye seçilen tuşu ve doğru tuşu zaten işaretliyor, ama alttaki açıklama kartı yalnız "Doğru cevap: Sol"
  yazıyor; öğrencinin ne seçtiği yazmıyor ve iki nota dinlenip karşılaştırılamıyor.
- Tur sırasında doğru/yanlış dağılımının görünmemesi (üstteki 10 nokta yalnızca kaçıncı soruda olunduğunu gösteriyor).
- İlerlemenin portenin üstünde, nota nota gösterilmemesi (anket: iki grubun da 1 numaralı isteği "ilerlemeyi görmek").
- Seviyenin yalnız beyanla seçilmesi; kısa bir yerleştirme denemesi yok.
- Tanıtımda öğretmen sorulmuyor; öğretmen kodu ancak Ayarlar'dan bulunuyor.
- Boş İlerleme ekranının ilk günlerde yol göstermemesi.

## Alınmaması gerekenler

- **Uzun satış amaçlı tanıtım soruları** (yaş, müzik türü, "potansiyelin" grafiği) ve **sahte yükleme ekranları**.
- **Süreyle ya da tur sayısıyla kısıtlama**, geri sayım sayaçları, haftalık abonelik. Solvato yayında ücretsiz.
- **Ülke sıralaması ve ligler** (Notahop, Pitch Trainer): sunucu ve hesap ister; Solvato'nun "veri toplanmaz"
  ilkesiyle çelişir. Arkadaşla yarış zaten meydan okuma koduyla çözülmüş.
- **Öğrenme yolu haritası** (Notaforte, Lumba Dore, Müzik Prova): daha önce denenip alınmadı; öğretmenin konu seçmesiyle
  çelişiyor (`docs/URUN.md`).
- **Maskotu her yere koymak** (Notahop'ta her ekranda kurbağa, kıyafet ödülleri): Solfie az görünür kalmalı.
- **Kalabalık üst bant** (Lumba Dore): Solvato'nun üç hapı (seri, XP, avatar) yeterli.

## Sonraya not (yayın sonrası adaylarla bağlantılı)

- **Aralık ve kalıp okuma** (`docs/URUN.md` açık iş): Notaforte'nin "landmark" yöntemi (referans notalar renkli bant,
  üçlüler, oktav kontrolü, ters nota, eşleştirme) iyi bir başvuru (2487–2511).
- **Sınav / konservatuvar hazırlık** (açık iş): Müzik Prova BİLSEM, Güzel Sanatlar Lisesi ve konservatuvar için
  etiketli egzersiz listesi ve sınav provası kuruyor (2377–2396).
- **Okunan notaların melodiye dönüşmesi** (Notahop "Gizemli melodi", "Şarkı defteri"): tur sonunda tanıdık bir
  melodinin çalınması güçlü bir ödül; içerik ve ses işi gerektirir.
- **Seri dondurma** (Clefs): seri kuralını değiştirir, ürün kararı.
