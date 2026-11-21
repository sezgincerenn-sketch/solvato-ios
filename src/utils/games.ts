// Oyunlar: günün meydan okuması ve kodla arkadaşa meydan okuma.
// Sunucu yok: aynı "tohum" (seed) iki telefonda aynı soruları üretir.
import { Capacitor } from "@capacitor/core"
import { ALL_QUESTIONS, questionLevel } from "../data/questions"
import type { Question, RoundAnswer } from "../types"

export const GAME_LENGTH = 10

export type GameCat = "all" | "treble" | "bass" | "rhythm" | "terms" | "writing"
export const GAME_CATS: { key: GameCat; label: string }[] = [
  { key: "all", label: "Karışık" },
  { key: "treble", label: "Sol anahtarı" },
  { key: "bass", label: "Fa anahtarı" },
  { key: "rhythm", label: "Ritim" },
  { key: "terms", label: "Terimler" },
  { key: "writing", label: "Nota yazımı" },
]
export const catLabel = (c: GameCat) => GAME_CATS.find((x) => x.key === c)?.label ?? ""

// ─── Tohumlu rastgelelik ─────────────────────────────────────────────────────
function rng(seed: number) {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}
function shuffleWith<T>(arr: T[], r: () => number): T[] {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(r() * (i + 1))
    ;[a[i], a[j]] = [a[j], a[i]]
  }
  return a
}

export function buildGameQuestions(cat: GameCat, level: number, seed: number): Question[] {
  const r = rng(seed)
  const ok = (q: Question) => questionLevel(q) <= level
  let pool = ALL_QUESTIONS.filter(ok)
  if (cat === "treble" || cat === "bass")
    pool = pool.filter((q) => q.category === "note_identification" && q.clef === cat)
  else if (cat === "rhythm") pool = pool.filter((q) => q.category === "rhythm")
  else if (cat === "terms") pool = pool.filter((q) => q.category === "musical_terms")
  else if (cat === "writing") pool = pool.filter((q) => q.category === "writing")
  else {
    // Karışık: yarısı nota, yarısı diğer konular
    const notes = shuffleWith(
      pool.filter((q) => q.category === "note_identification"),
      r,
    ).slice(0, 5)
    const other = shuffleWith(
      pool.filter((q) => q.category !== "note_identification"),
      r,
    ).slice(0, GAME_LENGTH - notes.length)
    pool = [...notes, ...other]
  }
  // Sıralama her iki telefonda aynı olsun diye önce id'ye göre diz
  pool = [...pool].sort((a, b) => a.id - b.id)
  return shuffleWith(pool, r)
    .slice(0, GAME_LENGTH)
    .map((q) =>
      q.category === "note_identification" || q.optionScores ? q : { ...q, options: shuffleWith(q.options, r) },
    )
}

// ─── Meydan okuma kodu ───────────────────────────────────────────────────────
// 40 bit → 8 karakter: kategori 3 · seviye 2 · tohum 16 · doğru 4 · süre(sn) 10 · kontrol 5
const ALPHA = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ" // 0/O, 1/I karışmasın
export type Challenge = { cat: GameCat; level: number; seed: number; correct: number; sec: number }

function checksum(n: number) {
  let s = 7
  let x = n
  while (x > 0) {
    s = (s * 31 + (x % 32)) % 32
    x = Math.floor(x / 32)
  }
  return s
}

export function encodeChallenge(c: Challenge): string {
  const ci = Math.max(
    0,
    GAME_CATS.findIndex((x) => x.key === c.cat),
  )
  let n = ci
  n = n * 4 + (c.level - 1)
  n = n * 65536 + (c.seed & 0xffff)
  n = n * 16 + Math.min(15, c.correct)
  n = n * 1024 + Math.min(1023, Math.round(c.sec))
  n = n * 32 + checksum(n)
  let out = ""
  for (let i = 0; i < 8; i++) {
    out = ALPHA[n % 32] + out
    n = Math.floor(n / 32)
  }
  return out.slice(0, 4) + "-" + out.slice(4)
}

export function decodeChallenge(code: string): Challenge | null {
  const s = code
    .toUpperCase()
    .replace(/[^0-9A-Z]/g, "")
    .replace(/O/g, "0")
    .replace(/I/g, "1")
  if (s.length !== 8) return null
  let n = 0
  for (const ch of s) {
    const v = ALPHA.indexOf(ch)
    if (v < 0) return null
    n = n * 32 + v
  }
  const ck = n % 32
  n = Math.floor(n / 32)
  if (checksum(n) !== ck) return null
  const sec = n % 1024
  n = Math.floor(n / 1024)
  const correct = n % 16
  n = Math.floor(n / 16)
  const seed = n % 65536
  n = Math.floor(n / 65536)
  const level = (n % 4) + 1
  const ci = Math.floor(n / 4)
  if (ci >= GAME_CATS.length || level > 3 || correct > GAME_LENGTH) return null
  return { cat: GAME_CATS[ci].key, level, seed, correct, sec }
}

export const newSeed = () => Math.floor(Math.random() * 65536)

// ─── Günün meydan okuması ────────────────────────────────────────────────────
const DAILY_ORDER: GameCat[] = ["all", "treble", "bass", "rhythm", "all", "terms", "writing"]

export function todayStr(d = new Date()) {
  const p = (n: number) => String(n).padStart(2, "0")
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
}
export function dailyInfo(date = todayStr()) {
  const [y, m, d] = date.split("-").map(Number)
  const dayNo = Math.floor(Date.UTC(y, m - 1, d) / 86400000)
  let h = 2166136261
  for (const ch of date) h = Math.imul(h ^ ch.charCodeAt(0), 16777619)
  return { date, cat: DAILY_ORDER[dayNo % DAILY_ORDER.length], seed: (h >>> 0) & 0xffff, no: dayNo - 20774 }
}

export type DailyRecord = { date: string; correct: number; sec: number; marks: string }
const DAILY_KEY = "notalik-daily"
export function loadDaily(): Record<string, DailyRecord> {
  try {
    return JSON.parse(localStorage.getItem(DAILY_KEY) || "{}")
  } catch {
    return {}
  }
}
export function saveDaily(rec: DailyRecord) {
  try {
    const all = loadDaily()
    if (all[rec.date]) return // ilk deneme sayılır
    all[rec.date] = rec
    localStorage.setItem(DAILY_KEY, JSON.stringify(all))
  } catch {
    /* ignore */
  }
}
export function dailyStreak(): number {
  const all = loadDaily()
  let n = 0
  const d = new Date()
  if (!all[todayStr(d)]) d.setDate(d.getDate() - 1)
  while (all[todayStr(d)]) {
    n++
    d.setDate(d.getDate() - 1)
  }
  return n
}

export function summarize(results: RoundAnswer[]) {
  const correct = results.filter((r) => r.correct).length
  const sec = Math.round(results.reduce((s, r) => s + r.timeMs, 0) / 1000)
  const marks = results.map((r) => (r.correct ? "🟩" : "🟥")).join("")
  return { correct, sec, marks }
}

export function fmtSec(sec: number) {
  return sec >= 60 ? `${Math.floor(sec / 60)} dk ${sec % 60} sn` : `${sec} sn`
}

// ─── Paylaş ──────────────────────────────────────────────────────────────────
export async function shareText(text: string): Promise<"shared" | "copied" | "cancelled" | "failed"> {
  if (Capacitor.isNativePlatform()) {
    try {
      const { Share } = await import("@capacitor/share")
      await Share.share({ text })
      return "shared"
    } catch (e) {
      // Kullanıcı menüyü kapattıysa sessizce dön (eskiden ardından ikinci bir paylaşım menüsü açılıyordu)
      if (/cancel/i.test(String((e as Error)?.message ?? e))) return "cancelled"
      try {
        await navigator.clipboard.writeText(text)
        return "copied"
      } catch {
        return "failed"
      }
    }
  }
  try {
    if (navigator.share) {
      await navigator.share({ text })
      return "shared"
    }
  } catch (e) {
    if ((e as Error)?.name === "AbortError") return "cancelled"
  }
  try {
    await navigator.clipboard.writeText(text)
    return "copied"
  } catch {
    return "failed"
  }
}
