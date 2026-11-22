// Ses altın tablosu (G-07): web'in seslerini (src/utils/audio.ts, kulak sorusu src/components/EarPrompt.tsx)
// Chromium'da OfflineAudioContext ile 48 kHz'de üretir, 5 ms'lik pencerelerin RMS düzeyini JSON'a yazar. Native
// SynthTests aynı sesleri SynthMixer'la üretip pencere pencere karşılaştırır (perde, süre, sıra, zarf).
// Kullanım: node scripts/altin-ses.mjs   (utils/audio.ts değişince yeniden çalıştırın)
import { build } from "esbuild"
import { createRequire } from "node:module"
import { readFileSync, writeFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

const require = createRequire(import.meta.url)
const { chromium } = require("playwright") // bulut oturumunda genel kurulu Playwright
const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const out = join(root, "ios-native/SolvatoCore/Tests/SolvatoCoreTests/Fixtures/ses.json")
const tmp = join(root, "node_modules/.cache/altin/ses.js")

// Web Audio yerine sesi dosyaya üreten bağlam: her ses kendi bağlamında, 0. saniyeden
const entry = `
import * as audio from "${join(root, "src/utils/audio.ts")}"
import { playEar } from "${join(root, "src/components/EarPrompt.tsx")}"
const SR = 48000
window.__ctx = null
window.AudioContext = class extends OfflineAudioContext {
  constructor() { super(1, SR * 4, SR); window.__ctx = this }
  resume() { return Promise.resolve() }
}
const SOUNDS = {
  "piyano-Do4": () => audio.playPianoNote("Do", 4),
  "piyano-La#5": () => audio.playPianoNote("La#", 5),
  "piyano-Sol3-akor": () => audio.playPianoNote("Sol", 3, 0.25, 0.24),
  "dogru": () => audio.playCorrectChime(),
  "yanlis": () => audio.playWrongBuzz(),
  "tur-sonu": () => audio.playSessionDone(),
  "hedef": () => audio.playGoalDone(),
  "seviye": () => audio.playLevelUp(),
  "seri": () => audio.playStreakUp(),
  "tik-vurgulu": () => audio.scheduleClick(0.1, true),
  "tik": () => audio.scheduleClick(0.1, false),
  "ritim-notasi": () => audio.scheduleBeat(0.1),
  "kulak-nota": () => playEar({ kind: "note", ref: { name: "Do", octave: 4 }, target: { name: "Sol", octave: 4 } }),
  "kulak-akor": () => playEar({ kind: "chord", notes: [{ name: "Do", octave: 4 }, { name: "Mi", octave: 4 }, { name: "Sol", octave: 4 }] }),
}
window.render = async () => {
  const res = {}
  for (const [name, play] of Object.entries(SOUNDS)) {
    window.__ctx = null
    const ms = play()
    const buf = await window.__ctx.startRendering()
    const d = buf.getChannelData(0)
    const W = SR / 200
    const rms = []
    for (let i = 0; i < d.length; i += W) {
      let s = 0
      for (let j = i; j < i + W; j++) s += d[j] * d[j]
      rms.push(Math.round(Math.sqrt(s / W) * 1e5) / 1e5)
    }
    while (rms.length && rms[rms.length - 1] === 0) rms.pop()
    res[name] = { rms, ...(typeof ms === "number" ? { ms } : {}) }
  }
  return res
}
`
await build({
  stdin: { contents: entry, resolveDir: root, loader: "tsx" },
  bundle: true,
  format: "iife",
  outfile: tmp,
  logLevel: "warning",
  jsx: "automatic",
  define: { "process.env.NODE_ENV": '"production"' },
})

const browser = await chromium.launch()
const page = await browser.newPage()
// localStorage çalışsın diye gerçek bir köken (ayarlar varsayılan: ses açık)
await page.route("http://altin.local/**", (r) =>
  r.fulfill({ contentType: "text/html", body: `<script>${readFileSync(tmp, "utf8")}</script>` }),
)
await page.goto("http://altin.local/")
const res = await page.evaluate(() => window.render())
await browser.close()
writeFileSync(out, JSON.stringify({ sampleRate: 48000, window: 240, sounds: res }) + "\n")
console.log(`ses.json: ${Object.keys(res).length} ses`)
