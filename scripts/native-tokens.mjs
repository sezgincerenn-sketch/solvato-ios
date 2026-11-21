// Web tasarım sisteminin değerlerini (src/design/tokens.ts + tokens.css) JSON'a döker. Native iOS'taki Swift testi
// (native/SolvatoCore) aynı değerleri bu dosyayla karşılaştırır: renk, ölçü ya da yazı değeri iki sürümde ayrışırsa test düşer.
// Kullanım: node scripts/native-tokens.mjs   (tokens.ts / tokens.css değişince yeniden çalıştırın)
import { readFileSync, writeFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const t = await import(join(root, "src/design/tokens.ts"))
const css = readFileSync(join(root, "src/design/tokens.css"), "utf8")
const out = join(root, "native/SolvatoCore/Tests/SolvatoCoreTests/Fixtures/tokens.json")

const hex2 = (n) => n.toString(16).padStart(2, "0").toUpperCase()

/** "#abc123", "#ABC12380" ya da "rgba(1, 2, 3, 0.5)" → "#RRGGBBAA"; renk değilse null */
function normColor(v) {
  v = v.trim()
  let m = v.match(/^#([0-9a-f]{6})([0-9a-f]{2})?$/i)
  if (m) return `#${m[1].toUpperCase()}${(m[2] ?? "FF").toUpperCase()}`
  m = v.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)$/)
  if (m) return `#${hex2(+m[1])}${hex2(+m[2])}${hex2(+m[3])}${hex2(Math.round((m[4] === undefined ? 1 : +m[4]) * 255))}`
  return null
}

/** tokens.css içinde bir seçicinin bloğundaki renk değişkenleri (gölge/filtre gibi renk olmayanlar atlanır) */
function cssColors(selector) {
  const start = css.indexOf(selector)
  const body = css.slice(css.indexOf("{", start) + 1, css.indexOf("}", start))
  const vars = {}
  for (const m of body.matchAll(/--([\w-]+):\s*([^;]+);/g)) {
    const c = normColor(m[2])
    if (c) vars[m[1]] = c
  }
  return vars
}

const cssVar = (v) => v.match(/^var\(--([\w-]+)\)$/)?.[1] ?? null
const gradientStops = (g) => [...g.matchAll(/#[0-9A-F]{6}/gi)].map((m) => normColor(m[0]))
const bezier = (s) => s.match(/cubic-bezier\(([^)]+)\)/)[1].split(",").map(Number)
function parseShadow(s) {
  const m = s.match(/^0 (\d+)px (\d+)px (rgba\([^)]+\))$/)
  return { y: +m[1], blur: +m[2], color: normColor(m[3]) }
}

const fixture = {
  palette: Object.fromEntries(Object.entries(t.palette).map(([k, v]) => [k, normColor(v)])),
  theme: { dark: cssColors(":root,"), light: cssColors(".theme-light") },
  colors: Object.fromEntries(
    Object.entries(t.colors).map(([k, v]) => [k, cssVar(v) ? { var: cssVar(v) } : { fixed: normColor(v) }]),
  ),
  brand: Object.fromEntries(Object.entries(t.brand).map(([k, v]) => [k, normColor(v)])),
  category: Object.fromEntries(
    Object.entries(t.category).map(([k, v]) => [
      k,
      { base: normColor(v.base), light: normColor(v.light), text: cssVar(v.text) },
    ]),
  ),
  gradient: Object.fromEntries(Object.entries(t.gradient).map(([k, v]) => [k, gradientStops(v)])),
  radius: t.radius,
  space: t.space,
  fontSize: t.font.size,
  fontWeight: t.font.weight,
  tracking: Object.fromEntries(Object.entries(t.font.tracking).map(([k, v]) => [k, parseFloat(v)])),
  shadow: { card: parseShadow(t.shadow.card), raised: parseShadow(t.shadow.raised) },
  glow: { y: 8, blur: 28, alpha38: normColor(t.shadow.glow("#000000").split(" ").pop()) },
  motion: {
    fast: parseFloat(t.motion.fast),
    base: parseFloat(t.motion.base),
    slow: parseFloat(t.motion.slow),
    ease: bezier(t.motion.ease),
    spring: bezier(t.motion.spring),
  },
  touchMin: t.touch.min,
}

writeFileSync(out, JSON.stringify(fixture, null, 2) + "\n")
console.log(`yazıldı: ${out.slice(root.length + 1)}`)
console.log(
  `palet ${Object.keys(fixture.palette).length}, koyu ${Object.keys(fixture.theme.dark).length}, açık ${Object.keys(fixture.theme.light).length} renk`,
)
