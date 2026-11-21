// Altın tabloları üretir (docs/ozellikler/native-ios.md "Altın tablolar"): scripts/altin/uret.ts'i esbuild ile
// paketler, sabit saat dilimiyle çalıştırır ve JSON'ları native testlerin okuduğu klasöre yazar.
// Soru bankası ayrıca native paketin kaynaklarına kopyalanır (uygulama soruları oradan okur).
// Kullanım: node scripts/altin.mjs   (src/ içindeki mantık ya da soru bankası değişince yeniden çalıştırın)
import { build } from "esbuild"
import { execFileSync } from "node:child_process"
import { mkdirSync, readFileSync, writeFileSync, rmSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const out = join(root, "ios-native/SolvatoCore/Tests/SolvatoCoreTests/Fixtures/altin")
const bankOut = join(root, "ios-native/SolvatoCore/Sources/SolvatoCore/Resources/soru-bankasi.json")
const tmp = join(root, "node_modules/.cache/altin/uret.mjs")

await build({
  entryPoints: [join(root, "scripts/altin/uret.ts")],
  bundle: true,
  platform: "node",
  format: "esm",
  outfile: tmp,
  logLevel: "warning",
  jsx: "automatic",
  // react-dom/server CommonJS: Node modüllerini require ile ister
  banner: { js: "import { createRequire } from 'node:module'; const require = createRequire(import.meta.url);" },
  define: { "process.env.NODE_ENV": '"production"' },
})

rmSync(out, { recursive: true, force: true })
const run = (tz, ...args) =>
  execFileSync(process.execPath, [tmp, out, ...args], { env: { ...process.env, TZ: tz }, stdio: "inherit" })
run("Europe/Istanbul")
// Seri "dün = şimdi − 24 saat" kuralı yaz saati olan bir yerde de aynı sonucu vermeli
run("America/New_York", "seri")

// Uygulamanın okuduğu banka: yalnızca sorular (seviyeler native'de hesaplanır, testte karşılaştırılır)
const bank = JSON.parse(readFileSync(join(out, "soru-bankasi.json"), "utf8"))
mkdirSync(dirname(bankOut), { recursive: true })
writeFileSync(bankOut, JSON.stringify(bank.questions) + "\n")
const fixture = { count: bank.count, levels: bank.levels }
writeFileSync(join(out, "soru-bankasi.json"), JSON.stringify(fixture) + "\n")

// Bravura sembol yolları (src/data/smufl.ts): native nota çizimi aynı yolları kullanır
const { SMUFL } = await import(join(root, "src/data/smufl.ts"))
writeFileSync(join(dirname(bankOut), "smufl.json"), JSON.stringify(SMUFL) + "\n")

execFileSync("du", ["-sh", out, bankOut], { stdio: "inherit" })
