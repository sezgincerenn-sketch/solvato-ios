// Referans görüntüleri (native iOS geçişi, docs/ozellikler/native-ios.md): bugünkü React uygulamasının her ekranını
// ve durumunu iPhone ve iPad boyutunda, koyu ve açık temada çeker. Native UI testleri aynı adlarla görüntü üretir;
// ikisi yan yana karşılaştırılır.
// Kullanım (önce `npm run build`):
//   node scripts/referans.mjs                    # bütün senaryolar
//   node scripts/referans.mjs --sadece soru      # adı "soru" ile başlayanlar
//   node scripts/referans.mjs --olcek 2          # 2x çözünürlük
// Çıktı: ekran/referans/<senaryo>-<iphone|ipad|iphone-yatay>-<koyu|acik>.png (git'e girmez).
// Sabitler: tarih 18 Kasım 2026 Çarşamba 10:00 (İstanbul), tohumlu Math.random, "Hareketi azalt" açık.
import { createRequire } from "node:module"
import { mkdirSync } from "node:fs"
import { preview } from "vite"

const require = createRequire(import.meta.url)
const { chromium } = require("playwright") // bulut oturumunda genel kurulu Playwright

const args = process.argv.slice(2)
const opt = { sadece: "", olcek: 1 }
for (let i = 0; i < args.length; i++) {
  if (args[i] === "--sadece") opt.sadece = args[++i]
  else if (args[i] === "--olcek") opt.olcek = Number(args[++i])
  else throw new Error(`Bilinmeyen seçenek: ${args[i]}`)
}

const SIMDI = "2026-11-18T10:00:00+03:00"
const CIHAZLAR = { iphone: [390, 844], ipad: [1024, 1366], "iphone-yatay": [844, 390] }

// ─── Örnek veriler ───────────────────────────────────────────────────────────
const AYAR_TEMEL = { onboarded: true, coachDone: true, level: 2, joinedAt: "2026-11-03" }
const AYAR_ORNEK = {
  ...AYAR_TEMEL,
  name: "Deniz",
  avatarColor: "blue",
  dailyGoal: 20,
  levelProgress: { n: 31, c: 26 },
}
const gun = (d) => `2026-11-${String(d).padStart(2, "0")}`
const saat = (d, h) => new Date(`${gun(d)}T${String(h).padStart(2, "0")}:15:00+03:00`).getTime()
const ORNEK_STATS = {
  streak: 4,
  totalPoints: 1270,
  totalSessions: 13,
  lastPlayDate: "Tue Nov 17 2026",
  dailyLog: { [gun(13)]: 2, [gun(14)]: 2, [gun(15)]: 2, [gun(16)]: 2, [gun(17)]: 3, [gun(18)]: 1 },
  dailyQuestions: { [gun(13)]: 20, [gun(14)]: 20, [gun(15)]: 20, [gun(16)]: 20, [gun(17)]: 26, [gun(18)]: 8 },
  noteStats: {
    "treble:80": { correct: 9, total: 10 },
    "treble:70": { correct: 8, total: 9 },
    "treble:45": { correct: 1, total: 4 },
    "treble:30": { correct: 2, total: 5 },
    "bass:65": { correct: 1, total: 3 },
    "bass:50": { correct: 6, total: 7 },
    "treble:60:sharp": { correct: 2, total: 4 },
  },
  categoryAccuracy: {
    treble: { correct: 38, total: 46 },
    bass: { correct: 17, total: 24 },
    trebleLedger: { correct: 5, total: 9 },
    bassLedger: { correct: 1, total: 3 },
    rhythm: { correct: 14, total: 18 },
    terms: { correct: 7, total: 10 },
    chords: { correct: 6, total: 10 },
    writing: { correct: 0, total: 0 },
    ear: { correct: 4, total: 6 },
  },
  history: [
    { at: saat(18, 9), label: "Karışık", correct: 7, total: 8, sec: 41 },
    { at: saat(17, 19), label: "Akorlar", correct: 6, total: 10 },
    { at: saat(17, 18), label: "Fa Anahtarı", correct: 6, total: 10, sec: 52 },
    { at: saat(17, 17), label: "Karışık", correct: 5, total: 6, sec: 30 },
    { at: saat(16, 18), label: "Ritim", correct: 8, total: 10, sec: 61 },
    { at: saat(16, 17), label: "Sol Anahtarı", correct: 9, total: 10, sec: 38 },
    { at: saat(15, 18), label: "Kulak", correct: 4, total: 6, sec: 44 },
  ],
  dailyAccuracy: {
    [gun(13)]: { correct: 15, total: 20 },
    [gun(14)]: { correct: 16, total: 20 },
    [gun(15)]: { correct: 15, total: 20 },
    [gun(16)]: { correct: 17, total: 20 },
    [gun(17)]: { correct: 20, total: 26 },
    [gun(18)]: { correct: 7, total: 8 },
  },
  bestStars: { treble: 3, bass: 1, rhythm: 2, chords: 1, rhythmtap: 2, all: 2 },
  dailyTopics: {
    [gun(16)]: { treble: { correct: 9, total: 10 }, rhythm: { correct: 8, total: 10 } },
    [gun(17)]: { bass: { correct: 6, total: 10 }, chords: { correct: 6, total: 10 }, treble: { correct: 4, total: 6 } },
    [gun(18)]: {
      treble: { correct: 4, total: 4 },
      terms: { correct: 2, total: 3 },
      accidentals: { correct: 1, total: 1 },
    },
  },
}
const ORNEK_DAILY = { [gun(18)]: { date: gun(18), correct: 7, sec: 58, marks: "🟩🟩🟥🟩🟩🟩🟥🟩🟥🟩" } }

// ─── Yardımcılar ─────────────────────────────────────────────────────────────
const bekle = (page, ms = 350) => page.waitForTimeout(ms)

/** Önce aria-label, yoksa tam metin; "css=" ile başlıyorsa seçici */
async function tikla(page, hedef) {
  let loc
  if (hedef.startsWith("css=")) loc = page.locator(hedef.slice(4))
  else {
    const etiket = page.locator(`[aria-label="${hedef}"]`)
    loc = (await etiket.count()) > 0 ? etiket : page.getByText(hedef, { exact: true })
  }
  await loc.first().click({ timeout: 5000 })
  await bekle(page)
}

const gorunur = async (page, metin) =>
  (await page.getByText(metin, { exact: false }).count()) > 0 &&
  (await page.getByText(metin, { exact: false }).first().isVisible())

/** Soru turunda bir cevap verir: klavye varsa tuş, yoksa son şık */
async function cevapVer(page, tus = "Do tuşu") {
  const k = page.locator(`[aria-label="${tus}"]`)
  if ((await k.count()) > 0) await k.first().click()
  else await page.locator("main button:enabled, #root button:enabled").last().click()
}

/** Yanlış cevap verilen ilk soruda durur */
async function yanlisaKadar(page) {
  for (let i = 0; i < 10; i++) {
    await cevapVer(page)
    await bekle(page, 300)
    if (await gorunur(page, "Doğru cevap:")) return
    await bekle(page, 700)
  }
}

/** Doğru cevap verilen ilk soruda durur (yanlışları geçer) */
async function dogruyaKadar(page) {
  for (let i = 0; i < 10; i++) {
    await cevapVer(page)
    await bekle(page, 150)
    if (!(await gorunur(page, "Doğru cevap:"))) return
    const sonraki = page.getByText(/^(Sıradaki|Turu bitir)$/)
    await sonraki.first().click()
    await bekle(page)
  }
}

/** Turu sonuna kadar oynar (doğru/yanlış fark etmez) */
async function turuBitir(page) {
  for (let i = 0; i < 40; i++) {
    if (await gorunur(page, "Tur bitti")) return
    if ((await page.locator('[aria-label="Kutlama"]').count()) > 0) return
    if (await gorunur(page, "Meydan okuma kodu")) return
    if (await gorunur(page, "Günün meydan okuması #")) return
    const sonraki = page.getByText(/^(Sıradaki|Turu bitir)$/)
    if ((await sonraki.count()) > 0) await sonraki.first().click()
    else await cevapVer(page)
    await bekle(page, 900)
  }
}

async function kaydir(page) {
  await page.evaluate(() =>
    document.querySelectorAll("*").forEach((d) => {
      const s = getComputedStyle(d).overflowY
      if ((s === "auto" || s === "scroll") && d.scrollHeight > d.clientHeight) d.scrollTop = d.scrollHeight
    }),
  )
  await bekle(page)
}

const yolla =
  (...adimlar) =>
  async (page) => {
    for (const a of adimlar) await tikla(page, a)
  }

// ─── Senaryolar ──────────────────────────────────────────────────────────────
// ayar: pianote_settings_v1, stats: notausta_stats_v1, daily: notalik-daily, ders: solvato_last_lesson_v1
// cihazlar: varsayılan iPhone + iPad
const O = { ayar: AYAR_ORNEK, stats: ORNEK_STATS, daily: ORNEK_DAILY }
const DERSLER = [
  ["notes-treble", "Sol anahtarı notaları"],
  ["notes-bass", "Fa anahtarı notaları"],
  ["mnemonic-treble", "Ezber cümleleri: Sol anahtarı"],
  ["mnemonic-bass", "Ezber cümleleri: Fa anahtarı"],
  ["accidentals", "Diyez ve bemol"],
  ["rhythm-values", "Nota değerleri"],
  ["rhythm-rests", "Sus işaretleri"],
  ["rhythm-dotted", "Noktalı notalar"],
  ["chords-build", "Majör ve minör nasıl kurulur"],
  ["chords-1", "Akor kartları: Başlangıç"],
  ["chords-2", "Akor kartları: Orta"],
  ["chords-3", "Akor kartları: İleri"],
  ["chords-4", "Akor kartları: Uzman"],
  ["terms-Dinamikler", "Dinamikler"],
  ["terms-Tempo", "Tempo"],
  ["terms-Değişim işaretleri", "Değişim işaretleri"],
  ["terms-Artikülasyon", "Artikülasyon"],
  ["terms-İfade", "İfade"],
  ["terms-Yapısal İşaretler", "Yapısal İşaretler"],
]

const SENARYOLAR = [
  // Açılış ve tanıtım
  { ad: "acilis", ayar: { onboarded: true, coachDone: true }, splash: true },
  { ad: "tanitim-1-merhaba", ayar: {} },
  { ad: "tanitim-2-deneme", ayar: {}, eylem: yolla("Devam") },
  { ad: "tanitim-2-yanlis", ayar: {}, eylem: yolla("Devam", "Re tuşu") },
  { ad: "tanitim-2-dogru", ayar: {}, eylem: yolla("Devam", "Do tuşu") },
  { ad: "tanitim-4-anahtar", ayar: {}, eylem: yolla("Devam", "Do tuşu", "Devam", "Sol tuşu", "Devam") },
  {
    ad: "tanitim-5-seviye",
    ayar: {},
    eylem: yolla("Devam", "Do tuşu", "Devam", "Sol tuşu", "Devam", "Devam"),
  },
  {
    ad: "tanitim-6-hatirlatma",
    ayar: {},
    eylem: yolla("Devam", "Do tuşu", "Devam", "Sol tuşu", "Devam", "Devam", "Devam"),
  },
  {
    ad: "tanitim-7-hazir",
    ayar: {},
    eylem: yolla("Devam", "Do tuşu", "Devam", "Sol tuşu", "Devam", "Devam", "Devam", "Şimdi değil", "Devam"),
  },
  { ad: "pratik-ipucu-1", ayar: { onboarded: true } },
  { ad: "pratik-ipucu-5", ayar: { onboarded: true }, eylem: yolla("Sıradaki", "Sıradaki", "Sıradaki", "Sıradaki") },

  // Pratik
  { ad: "pratik-yeni", ayar: AYAR_TEMEL },
  { ad: "pratik", ...O },
  { ad: "pratik-alt", ...O, eylem: kaydir },
  { ad: "pratik-ogretmen", ...O, ayar: { ...AYAR_ORNEK, topics: ["treble", "rhythm"], teacherCode: "K7M-2QX" } },
  {
    ad: "pratik-hedef-tamam",
    ...O,
    stats: { ...ORNEK_STATS, streak: 5, lastPlayDate: "Wed Nov 18 2026", dailyQuestions: { [gun(18)]: 20 } },
  },

  // Soru turu
  { ad: "soru-nota", ...O, eylem: yolla("Sol Anahtarı") },
  { ad: "soru-nota-ipucu", ...O, eylem: yolla("Sol Anahtarı", "İpucu") },
  { ad: "soru-nota-dogru", ...O, eylem: async (p) => (await yolla("Sol Anahtarı")(p), dogruyaKadar(p)) },
  { ad: "soru-nota-yanlis", ...O, eylem: async (p) => (await yolla("Sol Anahtarı")(p), yanlisaKadar(p)) },
  { ad: "soru-nota-siklar", ...O, ayar: { ...AYAR_ORNEK, inputMode: "choice" }, eylem: yolla("Fa Anahtarı") },
  { ad: "soru-nota-yatay", ...O, cihazlar: ["iphone-yatay"], eylem: yolla("Sol Anahtarı") },
  { ad: "soru-diyez", ...O, eylem: yolla("Diyez & Bemol") },
  { ad: "soru-ritim", ...O, eylem: yolla("Ritim & Ölçü") },
  { ad: "soru-terim", ...O, eylem: yolla("Müzik Terimleri") },
  { ad: "soru-yazim", ...O, eylem: yolla("Nota Yazımı") },
  { ad: "soru-kulak", ...O, eylem: yolla("Kulak") },
  { ad: "soru-sure", ...O, ayar: { ...AYAR_ORNEK, timer: true }, eylem: yolla("Sol Anahtarı") },
  { ad: "soru-cikis", ...O, eylem: yolla("Sol Anahtarı", "Çık") },

  // Akor turu ve Ritmi Tut
  { ad: "akor", ...O, eylem: yolla("Akor") },
  { ad: "ritmi-tut", ...O, eylem: yolla("Ritmi Tut") },
  { ad: "ritmi-tut-ses-kapali", ...O, ayar: { ...AYAR_ORNEK, soundKeys: false }, eylem: yolla("Ritmi Tut") },

  // Tur sonucu ve kutlama (günlük hedefe 12 soru kalmışken 10 soruluk tur: kutlama çıkmaz; 2 kalmışken çıkar)
  { ad: "sonuc", ...O, eylem: async (p) => (await tikla(p, 'css=[data-coach="today"]'), turuBitir(p)) },
  {
    ad: "kutlama",
    ...O,
    stats: { ...ORNEK_STATS, dailyQuestions: { ...ORNEK_STATS.dailyQuestions, [gun(18)]: 18 } },
    eylem: async (p) => (await tikla(p, 'css=[data-coach="today"]'), turuBitir(p)),
  },

  // İlerleme, Profil, Ayarlar
  { ad: "ilerleme-bos", ayar: AYAR_TEMEL, eylem: yolla("İlerleme") },
  { ad: "ilerleme", ...O, eylem: yolla("İlerleme") },
  { ad: "ilerleme-alt", ...O, eylem: async (p) => (await yolla("İlerleme")(p), kaydir(p)) },
  { ad: "profil", ...O, eylem: yolla("Profil") },
  { ad: "profil-alt", ...O, eylem: async (p) => (await yolla("Profil")(p), kaydir(p)) },
  { ad: "ayarlar", ...O, eylem: yolla("Profil", "Ayarlar") },
  { ad: "ayarlar-alt", ...O, eylem: async (p) => (await yolla("Profil", "Ayarlar")(p), kaydir(p)) },
  {
    ad: "ayarlar-sifirla",
    ...O,
    eylem: async (p) => (
      await yolla("Profil", "Ayarlar")(p),
      await kaydir(p),
      await tikla(p, "İlerlemeyi sıfırla"),
      kaydir(p)
    ),
  },
  { ad: "ogretmen-kodu", ...O, eylem: yolla("Profil", "Ayarlar", "Öğretmen kodu") },
  {
    ad: "ogretmen-kodu-alt",
    ...O,
    eylem: async (p) => (await yolla("Profil", "Ayarlar", "Öğretmen kodu")(p), kaydir(p)),
  },
  {
    ad: "ogretmen-kodu-hata",
    ...O,
    eylem: async (p) => {
      await yolla("Profil", "Ayarlar", "Öğretmen kodu")(p)
      await p.locator('[aria-label="Öğretmen kodu"]').fill("ABC-DEF")
      await tikla(p, "Uygula")
    },
  },
  {
    ad: "ogretmen-kodu-uygulandi",
    ...O,
    eylem: async (p) => {
      await yolla("Profil", "Ayarlar", "Öğretmen kodu")(p)
      const kod = await p
        .getByText(/^[2-9A-Z]{3}-[2-9A-Z]{3}$/)
        .first()
        .textContent()
      await p.locator('[aria-label="Öğretmen kodu"]').fill(kod.trim())
      await tikla(p, "Uygula")
    },
  },
  {
    ad: "gizlilik",
    ...O,
    eylem: async (p) => (await yolla("Profil", "Ayarlar")(p), await kaydir(p), tikla(p, "Gizlilik")),
  },
  {
    ad: "lisanslar",
    ...O,
    eylem: async (p) => (await yolla("Profil", "Ayarlar")(p), await kaydir(p), tikla(p, "Lisanslar")),
  },

  // Çalışma
  { ad: "calisma", ...O, eylem: yolla("Çalışma") },
  {
    ad: "calisma-arama",
    ...O,
    eylem: async (p) => (
      await yolla("Çalışma")(p),
      await p.locator('[aria-label="Konu ara"]').fill("legato"),
      bekle(p)
    ),
  },
  { ad: "calisma-kaldigin-yer", ...O, ders: "mnemonic-treble", eylem: yolla("Çalışma") },
  ...DERSLER.map(([id, baslik]) => ({ ad: `ders-${id}`, ...O, eylem: yolla("Çalışma", baslik) })),

  // Oyunlar
  { ad: "oyunlar", ...O, daily: {}, eylem: yolla("Oyunlar") },
  { ad: "oyunlar-oynandi", ...O, eylem: yolla("Oyunlar") },
  { ad: "gunun-oyunu", ...O, daily: {}, eylem: yolla("Oyunlar", "Günün meydan okuması") },
  { ad: "gunun-oyunu-oynandi", ...O, eylem: yolla("Oyunlar", "Günün meydan okuması") },
  { ad: "meydan-oku", ...O, eylem: yolla("Oyunlar", "Arkadaşına meydan oku") },
  {
    ad: "meydan-oku-hata",
    ...O,
    eylem: async (p) => {
      await yolla("Oyunlar", "Arkadaşına meydan oku")(p)
      await p.locator('[aria-label="Meydan okuma kodu"]').fill("ABCD-EFGH")
      await tikla(p, "Kabul et")
    },
  },
  {
    ad: "oyun-sonucu-gunluk",
    ...O,
    daily: {},
    eylem: async (p) => (await yolla("Oyunlar", "Günün meydan okuması", "Oyna")(p), turuBitir(p)),
  },
  {
    ad: "oyun-sonucu-kod",
    ...O,
    eylem: async (p) => (await yolla("Oyunlar", "Arkadaşına meydan oku", "Başla")(p), turuBitir(p)),
  },
  { ad: "duello-kurulum", ...O, eylem: yolla("Oyunlar", "Akor düellosu") },
  { ad: "duello-oyun", ...O, eylem: yolla("Oyunlar", "Akor düellosu", "Başlayalım") },
]

// ─── Çalıştır ────────────────────────────────────────────────────────────────
const secilen = SENARYOLAR.filter((s) => s.ad.startsWith(opt.sadece))
if (!secilen.length) throw new Error(`"${opt.sadece}" ile başlayan senaryo yok`)
mkdirSync("ekran/referans", { recursive: true })
const server = await preview({ preview: { port: 4180, strictPort: false }, logLevel: "silent" })
const base = server.resolvedUrls.local[0]
const browser = await chromium.launch()
let sorun = 0

for (const s of secilen) {
  for (const cihaz of s.cihazlar ?? ["iphone", "ipad"]) {
    const [width, height] = CIHAZLAR[cihaz]
    for (const tema of ["dark", "light"]) {
      const dosya = `ekran/referans/${s.ad}-${cihaz}-${tema === "dark" ? "koyu" : "acik"}.png`
      const ctx = await browser.newContext({
        viewport: { width, height },
        deviceScaleFactor: opt.olcek,
        hasTouch: true,
        locale: "tr-TR",
        timezoneId: "Europe/Istanbul",
        reducedMotion: "reduce",
        colorScheme: tema,
      })
      await ctx.addInitScript(
        ({ ayar, stats, daily, ders, tema }) => {
          // Tohumlu rastgelelik: aynı senaryo her seferinde aynı soruları verir
          let a = 20261118
          Math.random = () => {
            a = (a + 0x6d2b79f5) >>> 0
            let t = Math.imul(a ^ (a >>> 15), a | 1)
            t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
            return ((t ^ (t >>> 14)) >>> 0) / 4294967296
          }
          if (sessionStorage.getItem("referans_hazir")) return
          sessionStorage.setItem("referans_hazir", "1")
          localStorage.clear()
          localStorage.setItem("pianote_settings_v1", JSON.stringify(ayar))
          localStorage.setItem("pianote_theme_v1", tema)
          localStorage.setItem("notalik_rotate_hint_v1", "99")
          if (stats) localStorage.setItem("notausta_stats_v1", JSON.stringify(stats))
          if (daily) localStorage.setItem("notalik-daily", JSON.stringify(daily))
          if (ders) localStorage.setItem("solvato_last_lesson_v1", ders)
        },
        { ayar: s.ayar ?? AYAR_TEMEL, stats: s.stats ?? null, daily: s.daily ?? null, ders: s.ders ?? null, tema },
      )
      const page = await ctx.newPage()
      await page.clock.setSystemTime(new Date(SIMDI))
      const hatalar = []
      page.on("pageerror", (e) => hatalar.push(e.message))
      try {
        await page.goto(base)
        // Açılış: "Hareketi azalt" açıkken son karesinde durur, 2 sn sonra söner
        await bekle(page, s.splash ? 1200 : 2800)
        if (s.eylem) await s.eylem(page)
        await bekle(page, 400)
        await page.screenshot({ path: dosya })
        console.log(`${dosya}${hatalar.length ? "  ⚠ HATA: " + hatalar.join(" | ") : ""}`)
        if (hatalar.length) sorun++
      } catch (e) {
        sorun++
        console.log(`${dosya}  ⚠ ALINAMADI: ${String(e.message).split("\n")[0]}`)
      }
      await ctx.close()
    }
  }
}

await browser.close()
await server.close()
console.log(sorun ? `${sorun} görüntüde sorun var` : "Hepsi alındı")
process.exit(sorun ? 1 : 0)
