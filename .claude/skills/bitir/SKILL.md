---
name: bitir
description: Solvato'da bir değişikliği bitirme adımları — kontrol, ekran görüntüsü, README, native eşitleme, commit, main'e push ve TestFlight. Kod değiştiren her işin sonunda kullan.
---

# Değişikliği bitir

Sırayla yap; bir adım geçmezse düzelt, atlama. Atladığın adım olursa özette söyle.

1. **Kontrol:** `npm run check` temiz geçmeli (Stop kancası da bunu zorlar).
2. **Ekran (arayüz değiştiyse):** `ekran` becerisini uygula. Değişen ekranı koyu ve açık temada aç, görüntülere
   kendin bak. Taşan yazı, iki satıra kırılan düğme, okunmayan renk en sık hatalar.
3. **Mantık (puan, seviye, tarih, seri, öğretmen kodu değiştiyse):** küçük bir örnekle çalıştır, sonucu yaz.
   TS dosyasını çalıştırmak için: `node_modules/.bin/esbuild dosya.ts --bundle --platform=node --format=esm --outfile=/tmp/x.mjs && node /tmp/x.mjs`
   (geçici dosyaları repoya koyma).
4. **README:** ilgili bölümü güncelle; yeni kavram eklediysen "Önemli kavramlar"a bir madde.
   Gizlilik metni (`src/data/legal.ts`) ile mağazadaki gizlilik politikası aynı kalmalı; yeni bağımlılık ya da yazı tipi
   eklediysen `LICENSES` listesine ekle, yeni native eklenti eklediysen `magaza-kontrol` becerisindeki gizlilik adımına bak.
   4b. **Mağaza uygunluğu (yeni özellik ya da yeni bağımlılık geldiyse):** `magaza-kontrol` becerisinin 3, 4 ve 5. adımları
   (gizlilik beyanı, lisanslar, yer tutucu/"yakında" taraması) ve `ekran` raporunda DIŞ İSTEK olmaması. Sonucu
   `docs/APP-STORE-KONTROL.md`'nin sonundaki "Özellik kontrolleri" tablosuna bir satır ekle (tarih, özellik, sonuç).
5. **Capacitor (yalnız src/ değiştiyse):** `npm run sync` (ios/ repoda, eski kalmasın). `git status` ile değişen native dosyaları gör.
6. **Native (ios-native/ değiştiyse):** `swift test` geçmeli; `ios-native/ui-testleri.txt`'e yalnız değişen ekranların
   testlerini yaz. Web revize önizlemesi artık güncellenmez (Ceren, 26 Kasım).
7. **Commit ve push:** her mantıksal değişiklik ayrı commit; mesaj Türkçe ve ne değiştiğini söyler
   ("Ritmi Tut: çıkışta onay sor"). Oturumun çalışma dalına push et, sonra `git push origin HEAD:main`
   (main ileri sarılamıyorsa zorlamadan dur ve Ceren'e söyle).
7b. **TestFlight (native değiştiyse):** push'tan sonra `testflight.yml`'i başlat (`mcp__github__actions_run_trigger`,
   ref `main`); ~5 dakikada biter, sürüm numarasını (2000 + koşu) özette söyle. Derleme hatası olursa düzelt.
8. **Özet (Türkçe, kısa):** ne değişti, Ceren ekranda ne görecek, kararı gereken bir şey var mı, atlanan adım.
