# Native performans ölçümleri

GitHub Actions her `ios-native` gönderiminde iPhone simülatöründe ölçer (SolvatoUITests/PerformanceTests).
En yeni ölçüm en üstte; 🔴 sınırı aşan değer (iş kırmızı olur). Sınırlar: docs/ozellikler/erisilebilirlik-ipad.md.
Uygulama boyutu TestFlight koşusunun özetinde; kaydırma takılması ve Ritmi Tut dokunuş gecikmesi cihazda elle ölçülür.

| Tarih | Commit | Soğuk açılış | Sekme geçişi | Bellek (tur, tepe) |
| --- | --- | --- | --- | --- |
| Sınır | | 4 sn | 0,3 sn | 150 MB |
| 2026-11-28 19:56 | f43cc59 | 🔴 7,46 sn | — | — |
| 2026-11-28 18:36 | 347d62f | 🔴 4,14 sn | — | 73 MB |
| 2026-11-28 14:08 | 1851a6e | 3,33 sn | — | 71 MB |
| 2026-11-28 00:02 | 87239bf | 🔴 4,23 sn | — | 73 MB |
| 2026-11-27 21:36 | bd2e5b8 | 🔴 4,32 sn | 0,26 sn | — |
| 2026-11-27 19:45 | 97c68c6 | 🔴 4,04 sn | 0,28 sn | 73 MB |
| 2026-11-27 18:00 | 79abb28 | 🔴 4,35 sn | 0,2 sn | 72 MB |
| 2026-11-27 15:30 | 3f82e8e | 🔴 6,61 sn | 0,1 sn | — |
| 2026-11-27 14:55 | 7bfd203 | 🔴 4,48 sn | 0,08 sn | 56 MB |
| 2026-11-27 13:10 | 7bfd203 | 🔴 3,41 sn | 0,07 sn | 55 MB |
