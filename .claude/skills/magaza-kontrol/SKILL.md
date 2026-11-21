---
name: magaza-kontrol
description: App Store / Google Play'e yeni sürüm göndermeden önce uygunluk kontrolü. Ceren /magaza-kontrol yazınca çalışır.
disable-model-invocation: true
---

# Mağaza öncesi kontrol

Ayrıntılı ilk kontrol `docs/APP-STORE-KONTROL.md`'de. Her sürümde şunlara bak, sonucu o dosyanın sonuna
"Sürüm X kontrolü" başlığıyla ekle (Engel / Risk / Tamam, kanıt dosya:satır):

1. **Apple'ın güncel kuralları:** https://developer.apple.com/news/upcoming-requirements/ sayfasını oku (tahmin etme);
   en düşük Xcode/SDK ve iOS hedefini `ios/App/App.xcodeproj/project.pbxproj` ve bulut derleme ayarıyla karşılaştır.
2. **Sürüm numarası:** `MARKETING_VERSION` ve `CURRENT_PROJECT_VERSION` (pbxproj, iki yer; build numarasını Codemagic verir), Ayarlar'daki "Sürüm" yazısı aynı olmalı; build numarası her yüklemede artar.
3. **Gizlilik:** yeni native eklenti eklendiyse kaynağında required reason API ara
   (`UserDefaults`, dosya tarihleri, `systemUptime`, disk alanı, klavye listesi) ve `ios/App/App/PrivacyInfo.xcprivacy`'ye ekle.
   `node scripts/ekran.mjs` birkaç ekranda DIŞ İSTEK raporlamamalı.
4. **Lisanslar:** yeni bağımlılık ya da yazı tipi `src/data/legal.ts` `LICENSES`'ta var mı.
5. **Tamamlık:** `grep -rniE "yakında|coming soon|lorem|todo|console\.log" src`; reklam kodu yok (`grep -rniE "admob|interstitial|banner" src` boş).
6. **Mağaza metinleri:** "Solvato Mağaza Metinleri" dokümanını (Claude Docs) oku, her iddiayı koddaki karşılığıyla
   eşleştir (tur uzunluğu, ünvan sayısı, oyunlar). Köşeli parantezli yer tutucu kalmamalı.
7. **Ekran görüntüleri:** arayüz değiştiyse hangi mağaza karesinin yeniden çekilmesi gerektiğini listele.
8. Ceren'e kısa özet: kaç engel, hangileri düzeltildi, mağaza panelinde onun yapacakları.
