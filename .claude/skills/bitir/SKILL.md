---
name: bitir
description: Solvato'da bir değişikliği bitirme adımları — kontrol, ekran görüntüsü, README, native eşitleme, önizlemeyi yayınlama, commit ve main'e push. Kod değiştiren her işin sonunda kullan.
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
5. **Native:** `npm run sync` (ios/ repoda, eski kalmasın). `git status` ile değişen native dosyaları gör.
6. **Önizleme:** `npm run build:single`, sonra `dist-single/index.html`'i Artifact aracıyla
   https://claude.ai/artifact/AK45sA3bSP2kZX5TZacarf adresine yeniden yayınla (bu oturumda okumadıysan önce `read`).
   Kısa bir `label` ver ("Ritmi Tut: çıkış onayı"). TestFlight çalışmaya başlayınca bu adım kalkar.
   Ceren telefonda denemek isterse: `git tag testflight-<sürüm>-<kısa-ad> && git push origin <etiket>` (Codemagic derler).
7. **Commit ve push:** her mantıksal değişiklik ayrı commit; mesaj Türkçe ve ne değiştiğini söyler
   ("Ritmi Tut: çıkışta onay sor"). Oturumun çalışma dalına push et, sonra `git push origin HEAD:main`
   (main ileri sarılamıyorsa zorlamadan dur ve Ceren'e söyle).
8. **Özet (Türkçe, kısa):** ne değişti, Ceren ekranda ne görecek, kararı gereken bir şey var mı, atlanan adım.
