// Herkese açık site (App Store'un istediği gizlilik ve destek adresleri): site/ayarlar.json + uygulamanın gizlilik
// metninden (ios-native/SolvatoCore/Sources/SolvatoCore/Resources/hukuk.json) `site/dist/` altına üç sayfa üretir:
// index.html, gizlilik/index.html, destek/index.html. Gizlilik sayfası uygulamadaki Gizlilik ekranıyla aynı metni taşır
// (tek kaynak hukuk.json); geliştirici adı ve iletişim e-postası ayarlar.json'dan. Bağımlılığı yok (yalnız Node).
// Cloudflare Pages `site/dist`'i yayınlar. Kullanım: node scripts/site.mjs
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

// Gizlilik metni uygulamanın kendi dosyasından (Ayarlar › Gizlilik ekranı da bunu gösterir)
const PRIVACY = JSON.parse(
  readFileSync(join(root, "ios-native/SolvatoCore/Sources/SolvatoCore/Resources/hukuk.json"), "utf8"),
).privacy

const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
const mail = `<a href="mailto:${esc(eposta)}">${esc(eposta)}</a>`

// Outfit (uygulamanın yazı tipi): uygulamanın kendi TTF dosyaları
const WEIGHTS = [
  [400, "Regular"],
  [700, "Bold"],
  [800, "ExtraBold"],
]
const fonts = WEIGHTS.map(
  ([w]) =>
    `@font-face{font-family:Outfit;font-weight:${w};font-display:swap;src:url(/fonts/outfit-${w}.ttf) format("truetype")}`,
).join("\n")

// Uygulamanın renkleri (SolvatoCore Tokens.swift): koyu tema, sistem açıksa açık tema
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
<p>Yalnızca kendi cihazında. Uygulamayı silersen ilerleme de silinir. Profil › Ayarlar › İlerlemeyi sıfırla ile istediğin zaman baştan başlayabilirsin.</p>
<h3>Öğretmen kodunu nereye girerim?</h3>
<p>Profil › Öğretmen kodu. Öğretmeninin gönderdiği 6 haneli kodu girince çalışacağın notalar ve seviye öğretmeninin seçtiği gibi ayarlanır.</p>
<h3>Ses gelmiyor.</h3>
<p>Profil › Ayarlar › Ses açık mı, bak. Solvato telefonun sessiz düğmesi açıkken de çalar; ses yine gelmiyorsa cihazın ses düzeyini yükselt.</p>
<h3>Günlük hatırlatma gelmiyor.</h3>
<p>Profil › Ayarlar › Günlük hatırlatma açık olmalı ve iPhone Ayarlar › Bildirimler › Solvato'da bildirimlere izin verilmeli.</p>`,
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
for (const [w, name] of WEIGHTS)
  cpSync(join(root, `ios-native/Solvato/Resources/Fonts/Outfit_${w}${name}.ttf`), join(out, `fonts/outfit-${w}.ttf`))
console.log(`site/dist: 3 sayfa (${ad}, ${eposta})`)
