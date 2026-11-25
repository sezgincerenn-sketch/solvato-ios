// Öğretmen kodu: öğretmen öğrencisinin çalışma ayarlarını 6 karakterlik bir koda koyar
// (ör. "K7M-2QX"), WhatsApp'tan gönderir; öğrenci kodu girince ayarları kurulur. Sunucu yok.
//
// 30 bit → 6 karakter: işaret 4 · notalar 7 · anahtar 2 · seviye 2 · hedef 2 · tuş adları 1 · konular 7 · kontrol 5
// Konular 0 = hepsi; bu alan eskiden boştu, eski kodlar "tüm konular" olarak açılır.
// İşaret ve kontrolün başlangıç değeri meydan okuma kodundan farklı; iki kod birbirine karışmaz.
// Gövde karıştırılır (scramble), böylece benzer ayarlar bile farklı görünen kodlar verir.
import { ALL_NOTES, type Settings } from "./settings"
import { LEVEL_LABELS } from "../data/questions"

const ALPHA = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ" // games.ts ile aynı: 0/O, 1/I yok
const MARK = 0b1011
const CLEFS = ["treble", "bass", "both"] as const
export const GOALS = [10, 20, 30, 50] as const
export const MIN_NOTES = 3

export type TeacherSetup = Pick<Settings, "notes" | "clef" | "level" | "dailyGoal" | "keyLabels" | "topics">

/** Öğretmenin seçebildiği konular, koddaki bit sırasıyla (sıra değişmez!) */
export const TOPICS = [
  { key: "treble", label: "Sol anahtarı" },
  { key: "bass", label: "Fa anahtarı" },
  { key: "rhythm", label: "Ritim" },
  { key: "terms", label: "Müzik terimleri" },
  { key: "writing", label: "Nota yazımı" },
  { key: "ear", label: "Kulak" },
  { key: "chords", label: "Akorlar" },
] as const
export const allTopics = (topics: string[]) => topics.length === 0 || topics.length >= TOPICS.length

// Karıştırma: farklı ayarların kodları birbirine benzemesin (ör. hepsi "Q5J-" ile başlamasın).
// 25 bitlik gövde tek sayıyla çarpılır, sonra kendi üst bitleriyle XOR'lanır; ikisi de geri alınabilir.
const BITS = 25
const MOD = 2 ** BITS
const MUL = 30647735 // tek sayı
const MUL_INV = 4016135 // MUL * MUL_INV ≡ 1 (mod 2^25)
const ADD = 0x0abcde
function scramble(x: number) {
  x = (x * MUL + ADD) % MOD
  return x ^ Math.floor(x / 4096) // x ^ (x >> 12)
}
function unscramble(y: number) {
  const x = y ^ Math.floor(y / 4096) ^ Math.floor(y / 2 ** 24) // xorshift'in tersi
  return (((x - ADD + MOD) % MOD) * MUL_INV) % MOD
}

function checksum(n: number) {
  let s = 13
  let x = n
  while (x > 0) {
    s = (s * 29 + (x % 32)) % 32
    x = Math.floor(x / 32)
  }
  return s
}

export function encodeTeacher(t: TeacherSetup): string {
  const notesMask = ALL_NOTES.reduce((m, n, i) => (t.notes.includes(n) ? m | (1 << i) : m), 0)
  let n = MARK
  n = n * 128 + notesMask
  n = n * 4 + Math.max(0, CLEFS.indexOf(t.clef))
  n = n * 4 + (t.level - 1)
  n = n * 4 + Math.max(0, GOALS.indexOf(t.dailyGoal as (typeof GOALS)[number]))
  n = n * 2 + (t.keyLabels ? 1 : 0)
  const topicsMask = allTopics(t.topics)
    ? 0
    : TOPICS.reduce((m, x, i) => (t.topics.includes(x.key) ? m | (1 << i) : m), 0)
  n = n * 128 + topicsMask
  n = scramble(n)
  n = n * 32 + checksum(n)
  let out = ""
  for (let i = 0; i < 6; i++) {
    out = ALPHA[n % 32] + out
    n = Math.floor(n / 32)
  }
  return out.slice(0, 3) + "-" + out.slice(3)
}

export function decodeTeacher(code: string): TeacherSetup | null {
  const s = code
    .toUpperCase()
    .replace(/[^0-9A-Z]/g, "")
    .replace(/O/g, "0")
    .replace(/I/g, "1")
  if (s.length !== 6) return null
  let n = 0
  for (const ch of s) {
    const v = ALPHA.indexOf(ch)
    if (v < 0) return null
    n = n * 32 + v
  }
  const ck = n % 32
  n = Math.floor(n / 32)
  if (checksum(n) !== ck) return null
  n = unscramble(n)
  const topicsMask = n % 128
  n = Math.floor(n / 128)
  const keyLabels = n % 2 === 1
  n = Math.floor(n / 2)
  const goal = n % 4
  n = Math.floor(n / 4)
  const level = (n % 4) + 1
  n = Math.floor(n / 4)
  const clef = n % 4
  n = Math.floor(n / 4)
  const notesMask = n % 128
  const mark = Math.floor(n / 128)
  const notes = ALL_NOTES.filter((_, i) => notesMask & (1 << i))
  if (mark !== MARK || level > 3 || clef > 2 || notes.length < MIN_NOTES) return null
  const topics = topicsMask === 0 ? [] : TOPICS.filter((_, i) => topicsMask & (1 << i)).map((x) => x.key as string)
  return { notes, clef: CLEFS[clef], level: level as 1 | 2 | 3, dailyGoal: GOALS[goal], keyLabels, topics }
}

const CLEF_LABEL = { treble: "Sol anahtarı", bass: "Fa anahtarı", both: "Sol ve fa anahtarı" } as const

/** Kodun içeriğini okunur satırlara çevirir (öğrenciye gösterilir, paylaşım metnine girer) */
export function describeTeacher(t: TeacherSetup): string[] {
  return [
    allTopics(t.topics)
      ? "Tüm konular"
      : `Konular: ${TOPICS.filter((x) => t.topics.includes(x.key))
          .map((x) => x.label)
          .join(", ")}`,
    CLEF_LABEL[t.clef],
    `${LEVEL_LABELS[t.level]} seviye`,
    t.notes.length >= ALL_NOTES.length ? "Tüm notalar" : `Notalar: ${t.notes.join(" ")}`,
    `Günde ${t.dailyGoal} soru`,
    t.keyLabels ? "Tuşlarda nota adları görünür" : "Tuşlarda nota adları gizli",
  ]
}

export function teacherShareText(code: string, t: TeacherSetup) {
  // Revize R30/R32: kod tek başına ilk satırda (uzun basınca yalnız kod seçilir), en altta indirme satırı
  return [
    code,
    "",
    "Solvato öğretmen kodu. Uygulamada Profil › Öğretmen kodu'na yapıştır.",
    ...describeTeacher(t).map((l) => `• ${l}`),
    "",
    'Uygulamayı indir: App Store\'da "Solvato" diye arat.',
  ].join("\n")
}
