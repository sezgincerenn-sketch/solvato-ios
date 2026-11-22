// Herkese açık site (App Store'un istediği gizlilik ve destek adresleri): site/ayarlar.json + src/data/legal.ts
// PRIVACY metninden `site/dist/` altına üç sayfa üretir: index.html, gizlilik/index.html, destek/index.html.
// Gizlilik sayfası uygulamadaki Gizlilik ekranıyla aynı metni taşır (tek kaynak legal.ts); geliştirici adı ve iletişim
// e-postası ayarlar.json'dan. Cloudflare Pages `site/dist`'i yayınlar. Kullanım: node scripts/site.mjs
import { build } from "esbuild"
import { cpSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const out = join(root, "site/dist")
const cfg = JSON.parse(readFileSync(join(root, "site/ayarlar.json"), "utf8"))
const eksik = ["gelistirici", "eposta"].filter((k) => !cfg[k])
if (eksik.length) console.warn(`Uyarı: site/ayarlar.json'da boş alan: ${eksik.join(", ")} (sayfada yer tutucu görünür)`)
const ad = cfg.gelistirici || "[GELİŞTİRİCİ ADI]"
const eposta = cfg.eposta || "[E-POSTA ADRESİ]"

// legal.ts'i paketleyip PRIVACY'yi al (?raw lisans içe aktarmaları boş metin olur; burada gerekmez)
const tmp = join(root, "node_modules/.cache/site/legal.mjs")
await build({
  entryPoints: [join(root, "src/data/legal.ts")],
  bundle: true,
  platform: "node",
  format: "esm",
  outfile: tmp,
  logLevel: "warning",
  plugins: [
    {
      name: "raw",
      setup(b) {
        b.onResolve({ filter: /\?raw$/ }, (a) => ({ path: a.path, namespace: "raw" }))
        b.onLoad({ filter: /.*/, namespace: "raw" }, () => ({ contents: "export default ''", loader: "js" }))
      },
    },
  ],
})
const { PRIVACY } = await import(tmp)

const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
const mail = `<a href="mailto:${esc(eposta)}">${esc(eposta)}</a>`

// Outfit (uygulamanın yazı tipi): Latin + Türkçe harfler (latin-ext) iki dosya, fontsource'un unicode-range'leriyle
const LATIN =
  "U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD"
const LATIN_EXT =
  "U+0100-02BA,U+02BD-02C5,U+02C7-02CC,U+02CE-02D7,U+02DD-02FF,U+0304,U+0308,U+0329,U+1D00-1DBF,U+1E00-1E9F,U+1EF2-1EFF,U+2020,U+20A0-20AB,U+20AD-20C0,U+2113,U+2C60-2C7F,U+A720-A7FF"
const WEIGHTS = [400, 700, 800]
const fonts = WEIGHTS.flatMap((w) =>
  [
    ["latin", LATIN],
    ["latin-ext", LATIN_EXT],
  ].map(
    ([sub, range]) =>
      `@font-face{font-family:Outfit;font-weight:${w};font-display:swap;src:url(/fonts/outfit-${sub}-${w}.woff2) format("woff2");unicode-range:${range}}`,
  ),
).join("\n")

// Uygulamanın renkleri (src/design/tokens.css): koyu tema, sistem açıksa açık tema
const css = `
${fonts}
:root{--bg:#0f172a;--surface:#1e293b;--border:rgba(255,255,255,.08);--text:#f1f5f9;--muted:#94a3b8;--accent:#a78bfa}
@media (prefers-color-scheme: light){:root{--bg:#f8fafc;--surface:#fff;--border:rgba(15,23,42,.14);--text:#0f172a;--muted:#475569;--accent:#6d28d9}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);font-family:Outfit,system-ui,-apple-system,sans-serif;line-height:1.6}
main{max-width:680px;margin:0 auto;padding:40px 16px 64px}
.logo{font-size:32px;font-weight:800;letter-spacing:-.02em;text-decoration:none;color:var(--text)}
.logo span{color:#8b5cf6}
h1{font-size:24px;line-height:1.3;margin:28px 0 4px}
h2{font-size:18px;margin:28px 0 8px}
h3{font-size:16px;margin:18px 0 4px}
p{margin:0 0 10px;color:var(--text)}
.muted{color:var(--muted);font-size:14px}
a{color:var(--accent)}
.card{background:var(--surface);border:1px solid var(--border);border-radius:20px;padding:20px;margin-top:20px}
nav{display:flex;gap:16px;margin-top:40px;font-size:14px}
`
const page = (title, body) => `<!doctype html>
<html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title><meta name="robots" content="index,follow"><style>${css}</style></head>
<body><main><a class="logo" href="/">Solv<span>ato</span></a>
${body}
<nav><a href="/gizlilik/">Gizlilik</a><a href="/destek/">Destek</a></nav>
<p class="muted">© ${new Date().getFullYear()} ${esc(ad)}</p>
</main></body></html>
`

const gizlilik = page(
  "Solvato · Gizlilik Politikası",
  `<h1>Gizlilik Politikası</h1><p class="muted">Son güncelleme: ${esc(cfg.guncelleme)}</p>
${PRIVACY.map((s) => `<h2>${esc(s.title)}</h2>\n${s.body.map((p) => `<p>${esc(p)}</p>`).join("\n")}`).join("\n")}
<h2>İletişim</h2>
<p>Uygulamayı geliştiren: ${esc(ad)}. Gizlilikle ilgili her soru için: ${mail}</p>`,
)

const destek = page(
  "Solvato · Destek",
  `<h1>Destek</h1>
<p>Bir sorun mu var, ya da bir öneri? Bize e-postayla yaz.</p>
<div class="card"><p><strong>E-posta:</strong> ${mail}</p>
<p class="muted">Yazarken cihazını (ör. iPhone 15, iPad) ve iOS sürümünü eklersen daha hızlı yardımcı oluruz.</p></div>
<h2>Sık sorulanlar</h2>
<h3>İlerlemem nerede saklanıyor?</h3>
<p>Yalnızca kendi cihazında. Uygulamayı silersen ilerleme de silinir. Ayarlar › İlerlemeyi sıfırla ile istediğin zaman baştan başlayabilirsin.</p>
<h3>Öğretmen kodunu nereye girerim?</h3>
<p>Ayarlar › Öğretmen kodu. Öğretmeninin gönderdiği 6 haneli kodu girince çalışacağın notalar ve seviye öğretmeninin seçtiği gibi ayarlanır.</p>
<h3>Ses gelmiyor.</h3>
<p>Ayarlar › Ses açık mı, bak. Solvato telefonun sessiz düğmesi açıkken de çalar; ses yine gelmiyorsa cihazın ses düzeyini yükselt.</p>
<h3>Günlük hatırlatma gelmiyor.</h3>
<p>Ayarlar › Günlük hatırlatma açık olmalı ve iPhone Ayarlar › Bildirimler › Solvato'da bildirimlere izin verilmeli.</p>`,
)

const index = page(
  "Solvato",
  `<h1>Nota okuma ve müzik teorisi pratiği</h1>
<p>Solvato, piyano öğrencileri için günde birkaç dakikalık nota okuma, ritim, akor, kulak ve müzik terimleri pratiği. Öğretmenle birlikte kullanılır.</p>
<p class="muted">iPhone ve iPad için. Reklam yok, hesap gerekmez, veri toplanmaz.</p>`,
)

rmSync(out, { recursive: true, force: true })
for (const [p, html] of [
  ["index.html", index],
  ["gizlilik/index.html", gizlilik],
  ["destek/index.html", destek],
]) {
  mkdirSync(dirname(join(out, p)), { recursive: true })
  writeFileSync(join(out, p), html)
}
mkdirSync(join(out, "fonts"), { recursive: true })
for (const w of WEIGHTS)
  for (const sub of ["latin", "latin-ext"])
    cpSync(
      join(root, `node_modules/@fontsource/outfit/files/outfit-${sub}-${w}-normal.woff2`),
      join(out, `fonts/outfit-${sub}-${w}.woff2`),
    )
console.log(`site/dist: 3 sayfa (${ad}, ${eposta})`)
