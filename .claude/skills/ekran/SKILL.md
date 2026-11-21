---
name: ekran
description: Solvato'nun ekran görüntüsünü koyu ve açık temada, telefon / iPhone SE / iPad boyutunda alır; taşma, dış ağ isteği ve konsol hatası raporlar. Arayüzü kontrol ederken ya da mağaza görseli için ham ekran gerektiğinde kullan.
---

# Ekran görüntüsü

```bash
npm run build
node scripts/ekran.mjs --ad <ad> [--adim "<aria-label ya da tam metin>"]... [--kaydir] [--se] [--tablet] [--olcek 2]
```

- Uygulama tanıtımı geçmiş, Orta seviyede açılır; açılış animasyonu beklenir.
- `--adim` sırayla dokunur: önce `aria-label`, yoksa tam metin. Örnek: Ayarlar için `--adim Profil --adim Ayarlar`.
- Çıktı `ekran/<ad>-<telefon|se|tablet>-<koyu|acik>.png` (git'e girmez; Ceren uygulamada açabilir).
- Satır sonunda `⚠` varsa: YATAY TAŞMA, DIŞ İSTEK (uygulama hiçbir yere istek atmamalı, "Data Not Collected"),
  HATA (konsol). Çıkış kodu 1 olur; düzeltmeden bitirme.
- Görüntülere **Read ile kendin bak**; "✓" yalnızca ölçülebilen hataları yakalar.
- Ceren'e göstermek istediğin görüntüyü SendUserFile ile gönder; mağaza için `--olcek 2` ya da `--olcek 3` kullan.
- Belirli bir durumu (ör. seri 5 gün) görmek gerekiyorsa betiğe geçici `localStorage` eklemek yerine adımlarla
  oraya git; olmuyorsa betiğe yeni bir seçenek ekle ve README'de belirt.
