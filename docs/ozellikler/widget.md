# Ana ekran widget'ı

Durum: **taslak, Ceren'le kararlar alındı (25 Kasım 2026)**. Yalnız native iOS'a yazılır (`ios-native/`); React sürümüne
eklenmez. Yapılacaklar sayfasında Ceren "bunu şimdi yapalım" dedi; yayın sonrası değil, 1.0'a girer.

## Amaç

Öğrenci telefonun ana ekranında uygulamayı açmadan bugünkü hedefinde nerede olduğunu ve serisini görsün; akşam
henüz hedefini tutturmadıysa serisinin bozulacağını fark etsin. Hatırlatma bildirimini kapatan öğrenciye de sessiz bir
hatırlatıcı olur.

## Kullanıcı ne görür

Widget galerisinde ad: **"Solvato · Bugün"**, açıklama: **"Günlük hedefin ve serin."** İki boyut: Küçük ve Orta.

### Küçük widget (kare)

- Ortada **hedef halkası**: içinde büyük "12/20", altında küçük "soru". Halka çözülen soru oranında mor dolar.
- Altta **alev + seri**: "5 gün". Seri 0 ise alev soluk ve "Seri yok".
- **Hedef tamamsa**: halka tamamen dolar ve yeşile döner, içinde "20/20", altında "Hedef tamam".
- **Akşam uyarısı**: saat 18:00'den sonra, serisi 1 ya da daha fazla olan ve bugünkü hedefi henüz tamamlanmamış
  öğrencide alev turuncu ve parlak, alt satırda "5 gün · Serin bugün bitmesin". Bildirim değil, yalnız widget'taki
  yazı.
- **Son uyarı** (Ceren, 25 Kasım): saat 22:00'den sonra aynı koşulda widget kırmızıya döner (kırmızı kenar, kırmızı
  alev), alt satırda "Serini kaybedeceksin · 2 saat kaldı" (gece yarısına kalan tam saat; son saatte "1 saatten az
  kaldı").

### Solfie

Ceren'in isteğiyle (25 Kasım, tuval yorumu: "biraz sıkıcı olmuş") iki boyutta da sağ altta Solfie durur; çizim
uygulamadaki Solfie'nin aynısı, hareketsiz. Poz duruma göre (rastgele değil):

- **Normal** ve **seri 0**: sakin (idle).
- **Hedef tamam**: kutlama (cheer, kollar havada, parıltılar).
- **Akşam uyarısı**, **son uyarı** ve **ilk kullanım**: el sallar (wave).

Bu, "Solfie az görünür" kuralının (CLAUDE.md) bilinçli bir istisnasıdır: widget uygulamanın dışında, ana ekranda
durur ve Ceren onayladı.

### Orta widget (yatay)

- **Sol yarı**: küçük widget'ın içeriği (halka + seri, aynı durumlar).
- **Sağ yarı**: başlık "Bu hafta", altında Pt Sa Ça Pe Cu Ct Pz yedi daire ve en altta "3 gün çalıştın".
  Daire durumları İlerleme'deki "Bu hafta" şeridiyle aynı: hedefin tuttuğu gün dolu, çalışılıp hedefin tutmadığı gün
  yarım dolu, çalışılmayan gün boş, bugün kesikli halkalı, gelecek günler silik.

### İlk kullanım

Tanıtım bitmemişse ya da hiç soru çözülmemişse: boş halka "0/10" (ayarlardaki hedefle) ve altta "İlk turunu çöz".
Orta widget'ta hafta şeridi boş daireler.

### Dokununca

Uygulama açılır ve **Ana sayfa** sekmesi görünür (bugünkü adıyla Pratik). Tur kendiliğinden başlamaz. Uygulama başka
bir sekmede ya da bir turun içinde açık kaldıysa: tur açıksa olduğu yerde kalır (yarım tur kaybolmaz), değilse Ana
sayfaya geçer.

## Kurallar ve sınır durumları

- **Sayılar uygulamadakiyle aynı** kurallardan gelir: bugünkü soru sayısı `dailyQuestions[bugün]`, hedef ayardaki
  günlük hedef (10/20/30/50), gösterilen seri K-07 `currentStreak` (son seri günü bugün ya da dün değilse 0), hafta
  şeridi K-13 haftalık raporla aynı gün durumları. Widget kendisi hesap yapmaz; uygulamanın yazdığı küçük özeti
  bugünün tarihine göre okur.
- **Gece yarısı**: uygulama açılmasa da widget 00:00'da yeni güne geçer: halka "0/20", hafta şeridinde bugün bir
  sonraki gün. Dünkü hedef tutmadıysa ve önceki gün de seri günü değilse seri 0 görünür (K-07 ile aynı).
- **18:00 ve 22:00**: akşam uyarısı ve son uyarı uygulama açılmadan devreye girer; 22:00'den sonra kalan saat her saat
  başı güncellenir. Hedef tamamlanınca uyarı kalkar.
- **Güncelleme**: her tur bittiğinde (soru, akor, Ritmi Tut, oyun) ve uygulama arka plana geçtiğinde widget yenilenir.
  Ayarlarda günlük hedef değişince ya da "İlerlemeyi sıfırla" yapılınca da yenilenir.
- **Telefon kilitliyken**: uygulamanın kendi kayıt dosyaları kilitliyken okunamıyor (veri korumalı). Bu yüzden
  uygulama widget için ayrı, küçük bir özet yazar: yalnız sayılar (bugünkü soru, hedef, seri, son seri günü, haftanın
  7 günü). İsim, öğretmen kodu, cevaplar yazılmaz. Özet telefon açıldıktan sonra kilitliyken de okunabilir.
- **Tema**: telefonun açık/koyu moduna uyar (uygulamanın açık ve koyu temasındaki renkler). iOS'un renkli ve şeffaf
  widget görünümlerinde halka ve alev vurgu rengini alır, yazılar okunur kalır.
- **iPad**: aynı iki boyut, aynı içerik.
- **Ses, titreşim, hareket**: widget'ta yok (Solfie de hareketsiz).
- **Erişilebilirlik**: VoiceOver "Bugün 12/20 soru. Seri 5 gün." (uyarıda "Serin bugün bitmesin", son uyarıda "Serini kaybedeceksin, 2 saat kaldı" eklenir; hafta için
  "Bu hafta 3 gün çalıştın"). Dinamik Yazı büyüdüğünde yazılar kısalır, taşmaz.
- **Hesap (1.0)**: widget yalnız o telefondaki veriyi gösterir; misafir ve hesaplı kullanıcı için aynı.
- **Yazım**: "12/20 soru", "5 gün", "Hedef tamam", "Seri yok", "Serin bugün bitmesin", "Serini kaybedeceksin · 2 saat kaldı", "Bu hafta", "3 gün çalıştın",
  "İlk turunu çöz".

## Kabul ölçütleri

- [ ] Solfie'nin pozu: normal ve seri 0'da sakin, hedef tamamda kutlama, akşam uyarısında ve ilk kullanımda el
      sallıyor; çizim uygulamadakiyle aynı.
- [ ] Widget galerisinde "Solvato · Bugün" adıyla Küçük ve Orta boyut çıkıyor.
- [ ] Bugün 12 soru çözülmüş, hedef 20 iken halkada "12/20" ve %60 dolu mor halka.
- [ ] Hedef tamamlanınca halka yeşil ve tam dolu, altında "Hedef tamam"; bir tur bittikten sonra uygulamaya dönmeden
      ana ekranda güncel.
- [ ] Seri 0 iken soluk alev ve "Seri yok"; seri 5 iken "5 gün".
- [ ] 18:00'den sonra seri ≥1 ve hedef tamamlanmamışsa "Serin bugün bitmesin"; hedef tamamsa ya da seri 0 ise yok;
      18:00'den önce yok.
- [ ] 22:00'den sonra aynı koşulda kırmızı görünüm ve "Serini kaybedeceksin · N saat kaldı"; 23:00'te "1 saatten az
      kaldı"; hedef tamamlanınca kalkıyor.
- [ ] Uygulama açılmadan gece yarısı geçince halka "0/hedef" ve seri K-07'ye göre (dün seri günüyse aynı sayı, değilse 0).
- [ ] Orta widget'ta hafta şeridinin dolu/yarım/boş/bugün/gelecek durumları İlerleme'deki şeritle aynı gün için aynı.
- [ ] Tanıtım bitmemişken "0/10" ve "İlk turunu çöz".
- [ ] Dokununca uygulama Ana sayfada açılıyor; açık bir tur varsa tur kaybolmuyor.
- [ ] Telefon açık ve koyu modda, iOS renkli ve şeffaf widget görünümünde yazılar okunuyor (ekran görüntüleri).
- [ ] VoiceOver metni yukarıdaki gibi.
- [ ] Widget hiçbir ağ isteği yapmıyor; özette sayılardan başka veri yok.
- [ ] Çekirdekte widget özetini hesaplayan kısım testli: aynı istatistik ve saat için halka, seri, uyarı ve hafta
      şeridi sonuçları (gece yarısı, 17:59 / 18:00, 21:59 / 22:00 / 23:00, hedef tam, seri 0, boş veri senaryoları).

## Kapsam dışı

- Kilit ekranı widget'ı, StandBy, Apple Watch, Büyük boyut.
- Widget'tan tur başlatma, etkileşimli düğmeler.
- Widget'ta sıradaki konu, XP/ünvan, öğretmen bilgisi. Solfie'nin hareketli hâli (widget'ta animasyon yok).
- Android widget'ı (Android işi başlayınca ayrıca).
- React (web) sürümü.

## Etkilenen dosyalar (tahmini)

- `ios-native/project.yml`: yeni hedef `SolvatoWidget` (widget uzantısı, `com.solvato.app.widget`), iki hedefe App
  Group yetkisi (`group.com.solvato.app`), uygulama hedefine uzantının gömülmesi.
- `ios-native/SolvatoWidget/` (yeni): widget tanımı, zaman çizelgesi (00:00, 18:00, 22:00, 23:00 girişleri), Küçük ve Orta
  görünümler, `PrivacyInfo.xcprivacy`, Info.plist.
- `ios-native/SolvatoCore/Sources/SolvatoCore/App/WidgetSnapshot.swift` (yeni): özetin biçimi ve "şu tarih ve saatte ne
  gösterilir" hesabı; testleri `Tests/SolvatoCoreTests/WidgetSnapshotTests.swift`.
- `AppModel.swift`: kayıttan sonra özeti App Group'a yazma ve widget'ı yenileme.
- `AppRoot.swift`: widget'tan açılınca Ana sayfaya geçiş.
- Renk ve yazı: mevcut `Tokens.swift` / tasarım sistemi (widget hedefine de eklenir; ham renk yok).
- `codemagic.yaml`: imzalama widget uzantısını da kapsamalı. **Ceren için olası adım:** App Group ve uzantının
  kimliği Apple Developer'da otomatik oluşmazsa bir kez elle eklenmesi gerekebilir; gerekirse adım adım yazılır.
- `docs/ozellikler/native-ios.md` (D. Sistem entegrasyonları), `README.md`, `ios-native/SolvatoUITests` senaryoları
  (widget görüntüsü için önizleme).

## Gizlilik etkisi

Ağ isteği yok; veri telefondan çıkmaz. Widget için yazılan özet yalnız sayılar içerir ve uygulamayla widget'ın ortak
klasöründe durur. Mağaza gizlilik beyanını değiştirmez. Widget uzantısının `PrivacyInfo.xcprivacy` dosyasında ortak
klasör kullanımının nedeni beyan edilir.
