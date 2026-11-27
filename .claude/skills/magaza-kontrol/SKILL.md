---
name: magaza-kontrol
description: App Store'a yeni sürüm göndermeden önce uygunluk kontrolü. Ceren /magaza-kontrol yazınca çalışır.
disable-model-invocation: true
---

# Mağaza öncesi kontrol

Ayrıntılı ilk kontrol `docs/APP-STORE-KONTROL.md`'de. Her sürümde şunlara bak, sonucu o dosyanın sonuna
"Sürüm X kontrolü" başlığıyla ekle (Engel / Risk / Tamam, kanıt dosya:satır):

1. **Apple'ın güncel kuralları:** https://developer.apple.com/news/upcoming-requirements/ sayfasını oku (tahmin etme);
   en düşük Xcode/SDK ve iOS hedefini `ios-native/project.yml` ve GitHub Actions'taki Xcode sürümüyle karşılaştır.
2. **Sürüm numarası:** `ios-native/project.yml` `MARKETING_VERSION` ile Ayarlar'daki "Sürüm" yazısı aynı olmalı; build
   numarasını `testflight.yml` verir (2000 + koşu).
3. **Gizlilik:** yeni bir Apple çatısı ya da API eklendiyse required reason API ara (`UserDefaults`, dosya tarihleri,
   `systemUptime`, disk alanı, klavye listesi) ve `ios-native/Solvato/PrivacyInfo.xcprivacy`'ye ekle;
   `scripts/native-guvenlik.py`'deki beklenen listeyi de güncelle. `python3 scripts/native-guvenlik.py` "sorun yok" demeli.
4. **Lisanslar:** yeni yazı tipi ya da kod parçası `hukuk.json` `licenses`'ta var mı.
5. **Tamamlık:** `grep -rniE "yakında|coming soon|lorem|todo|print\(" ios-native/Solvato ios-native/SolvatoCore/Sources`;
   reklam kodu yok (`grep -rniE "admob|interstitial|banner" ios-native` boş).
6. **Mağaza metinleri:** "Solvato Mağaza Metinleri" dokümanını (Claude Docs) oku, her iddiayı koddaki karşılığıyla
   eşleştir (tur uzunluğu, ünvan sayısı, oyunlar). Köşeli parantezli yer tutucu kalmamalı.
7. **Ekran görüntüleri:** arayüz değiştiyse hangi mağaza karesinin yeniden çekilmesi gerektiğini listele.
8. Ceren'e kısa özet: kaç engel, hangileri düzeltildi, mağaza panelinde onun yapacakları.
