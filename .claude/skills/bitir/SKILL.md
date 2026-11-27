---
name: bitir
description: Solvato'da bir değişikliği bitirme adımları — testler, ekran görüntüleri, README, commit, main'e push ve TestFlight. Kod değiştiren her işin sonunda kullan.
---

# Değişikliği bitir

Sırayla yap; bir adım geçmezse düzelt, atlama. Atladığın adım olursa özette söyle.

1. **Çekirdek:** `cd ios-native/SolvatoCore && swift test` temiz geçmeli (Linux'ta da koşar). Puan, seviye, tarih, seri,
   kod gibi mantık değiştiyse önce testine bir örnek ekle.
2. **Güvenlik:** `python3 scripts/native-guvenlik.py` "sorun yok" demeli (ağ API'si, dış adres, bağımlılık, gizlilik
   bildirimi).
3. **Ekranlar (arayüz değiştiyse):** `ios-native/ui-testleri.txt`'e yalnız değişen ekranların testlerini yaz
   (`ScreenshotTests` adları ya da `Sınıf/test`). main'e gönderince GitHub Actions görüntüleri `ekranlar` dalına koyar;
   bitince görüntülere kendin bak (`git fetch origin ekranlar`). Taşan yazı, iki satıra kırılan düğme, okunmayan renk en
   sık hatalar. Performans tablosu aynı dalda `performans.md`.
4. **README ve dokümanlar:** ilgili bölümü güncelle; yeni kavram eklediysen "Önemli kavramlar"a bir madde. Gizlilik ve
   lisans metinleri `ios-native/SolvatoCore/Sources/SolvatoCore/Resources/hukuk.json`'da (uygulama ve site aynı
   dosyayı okur); yeni yazı tipi ya da kod parçası eklediysen `licenses`'a ekle. Markdown'ı `npx prettier --write` ile
   biçimle.
   4b. **Mağaza uygunluğu (yeni özellik geldiyse):** `magaza-kontrol` becerisinin 3, 4 ve 5. adımları. Sonucu
   `docs/APP-STORE-KONTROL.md`'nin sonundaki "Özellik kontrolleri" tablosuna bir satır ekle (tarih, özellik, sonuç).
5. **Commit ve push:** her mantıksal değişiklik ayrı commit; mesaj Türkçe ve ne değiştiğini söyler
   ("Ritmi Tut: çıkışta onay sor"). Oturumun çalışma dalına push et, sonra `git push origin HEAD:main`
   (main ileri sarılamıyorsa zorlamadan dur ve Ceren'e söyle).
6. **TestFlight (ios-native/Solvato değiştiyse):** push'tan sonra `testflight.yml`'i başlat
   (`mcp__github__actions_run_trigger`, ref `main`); ~5 dakikada biter, sürüm numarasını (2000 + koşu) özette söyle.
   Derleme hatası olursa düzelt.
7. **Özet (Türkçe, kısa):** ne değişti, Ceren ekranda ne görecek, kararı gereken bir şey var mı, atlanan adım.
