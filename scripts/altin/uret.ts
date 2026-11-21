// Altın tabloları üretir: React mantığına sabit girdiler verip çıktılarını JSON'a yazar. Native Swift testleri
// (ios-native/SolvatoCore) aynı girdilerle aynı çıktıyı vermek zorunda. Doğrudan çalıştırılmaz: scripts/altin.mjs
// bunu esbuild ile paketler ve sabit saat dilimiyle çalıştırır. src/ yalnızca okunur.
import { writeFileSync, mkdirSync } from "node:fs"
import { cizim } from "./cizim"
import { join } from "node:path"
import { ALL_QUESTIONS, questionLevel } from "../../src/data/questions"
import { rankFromXp, todayKey } from "../../src/utils/level"
import { starsFor, nextStarHint } from "../../src/utils/stars"
import { periodRange, eachDay, type Period } from "../../src/utils/dates"
import {
  applyProgress,
  currentStreak,
  detectCelebration,
  recordLevelProgress,
  recordStars,
  recordTopics,
  topicOf,
} from "../../src/state/stats"
import { weakNotes } from "../../src/state/weakNotes"
import { encodeTeacher, decodeTeacher, TOPICS, GOALS, type TeacherSetup } from "../../src/utils/teacherCode"
import {
  buildGameQuestions,
  encodeChallenge,
  decodeChallenge,
  dailyInfo,
  GAME_CATS,
  catLabel,
  type GameCat,
} from "../../src/utils/games"
import { buildWeeklyReport, weeklyReportText } from "../../src/utils/weeklyReport"
import { accuracyFor } from "../../src/state/stats"
import { pickQuestions, getWeakQuestions, ROUND_LABELS } from "../../src/data/session"
import { buildEarQuestions } from "../../src/data/ear"
import { ALL_NOTES, getSettings, updateSettings, type Settings } from "../../src/utils/settings"
import { DEFAULT_STATS } from "../../src/types"
import {
  ALL_CHORDS,
  chordsUpTo,
  staffY,
  samePcs,
  progressionsFor,
  QUALITY_COLOR,
  type ChordLevel,
} from "../../src/data/chords"
import { distractors, shuffle as chordShuffle } from "../../src/data/chordQuiz"
import { fitsKeyboard, litKeys } from "../../src/components/piano/MultiPiano"
import {
  RHYTHM_PATTERNS,
  TEMPO,
  PASS,
  gradeTaps,
  onsets,
  parseRhythm,
  pickPatterns,
  type TapResult,
} from "../../src/data/rhythmTap"
import type { QuestionLevel } from "../../src/data/questions"
import type { AppStats, FilterCategory, Question, SessionResult, SpecialRound } from "../../src/types"

const OUT = process.argv[2]
const TZ = process.env.TZ
mkdirSync(OUT, { recursive: true })
const write = (name: string, data: unknown) => writeFileSync(join(OUT, name), JSON.stringify(data) + "\n")

// ─── Ortam: sahte saat, bellek içi localStorage, denetimli Math.random ─────────
const RealDate = Date
let NOW = 0
class FakeDate extends RealDate {
  constructor(...a: unknown[]) {
    if (a.length === 0) super(NOW)
    else super(...(a as [number]))
  }
  static now() {
    return NOW
  }
}
globalThis.Date = FakeDate as DateConstructor
const store = new Map<string, string>()
;(globalThis as { localStorage?: unknown }).localStorage = {
  getItem: (k: string) => store.get(k) ?? null,
  setItem: (k: string, v: string) => void store.set(k, String(v)),
  removeItem: (k: string) => void store.delete(k),
}

/** Native'deki SeededRandom ile aynı: games.ts'teki mulberry32 */
function mulberry(seed: number) {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}
// Girdileri üretmek için kendi rastgeleliğimiz (React'ın Math.random'ına karışmaz)
const gen = mulberry(20261118)
const int = (n: number) => Math.floor(gen() * n)
const pick = <T>(a: readonly T[]) => a[int(a.length)]

const DEFAULT_SETTINGS: Settings = { ...getSettings() }
const resetSettings = (patch: Partial<Settings> = {}) => updateSettings({ ...DEFAULT_SETTINGS, ...patch })

/** Yerel saatle tarih → ms (TZ ortam değişkenine göre) */
const at = (y: number, m: number, d: number, h = 10, min = 0) => new RealDate(y, m - 1, d, h, min).getTime()

// ─── K-01, K-02: soru bankası ────────────────────────────────────────────────
function bank() {
  const levels: Record<number, number> = {}
  for (const q of ALL_QUESTIONS) levels[q.id] = questionLevel(q)
  return { count: ALL_QUESTIONS.length, questions: ALL_QUESTIONS, levels }
}

// ─── K-06 ünvan, K-09 yıldız, K-14 dönem ─────────────────────────────────────
function unvan() {
  const rows = []
  for (let xp = 0; xp <= 25000; xp += 50) rows.push({ xp, ...rankFromXp(xp) })
  for (const xp of [99, 101, 299, 21999, 22001]) rows.push({ xp, ...rankFromXp(xp) })
  return rows
}

function yildiz() {
  const rows = []
  for (let total = 0; total <= 10; total++)
    for (let correct = 0; correct <= total; correct++) rows.push({ correct, total, stars: starsFor(correct, total) })
  for (const [correct, total] of [
    [9, 10],
    [7, 10],
    [5, 10],
    [14, 20],
    [6, 6],
    [4, 6],
    [3, 6],
    [2, 3],
  ])
    rows.push({ correct, total, stars: starsFor(correct, total) })
  const hints = [0, 1, 2, 3].map((s) => nextStarHint(s))
  return { rows, hints }
}

function donem() {
  const rows = []
  const start = at(2026, 1, 1)
  for (let i = 0; i < 800; i += 3) {
    NOW = start + i * 86400000 + int(86400000)
    const now = new Date()
    for (const period of ["week", "month"] as Period[])
      for (const offset of [0, 1, 2]) {
        const { from, to } = periodRange(period, offset, now)
        rows.push({ now: NOW, period, offset, from: todayKey(from), to: todayKey(to), days: eachDay(from, to).length })
      }
  }
  return rows
}

// ─── K-04, K-07, K-08: tur sonu ──────────────────────────────────────────────
// App.tsx handleComplete / handleSpecialComplete'in istatistik kısmının birebir kopyası (src/ okunur, değiştirilmez).
type Round =
  | { kind: "quiz"; category: FilterCategory; label?: string; game?: GameCat; results: SessionResult[] }
  | { kind: "special"; special: SpecialRound; correct: boolean[] }

function completeQuiz(stats: AppStats, r: Extract<Round, { kind: "quiz" }>) {
  const results = r.results
  let pts = 0
  results.forEach((x) => {
    if (x.correct) pts += 10
  })
  const label = r.game ? `Oyun · ${catLabel(r.game)}` : (r.label ?? ROUND_LABELS[r.category])
  const newStats = applyProgress(stats, pts, results.length, {
    label,
    correct: results.filter((x) => x.correct).length,
    total: results.length,
    sec: Math.round(results.reduce((a, x) => a + x.timeMs, 0) / 1000),
  })
  results.forEach((x) => {
    if (x.category === "note_identification" && x.noteY !== undefined) {
      const key = `${x.clef}:${x.noteY}${x.accidental ? ":" + x.accidental : ""}`
      const cur = newStats.noteStats[key] ?? { correct: 0, total: 0 }
      newStats.noteStats[key] = { correct: cur.correct + (x.correct ? 1 : 0), total: cur.total + 1 }
    }
  })
  const acc = { ...newStats.categoryAccuracy }
  const add = (v: { correct: number; total: number } | undefined, ok: boolean) => ({
    correct: (v?.correct ?? 0) + (ok ? 1 : 0),
    total: (v?.total ?? 0) + 1,
  })
  results.forEach((x) => {
    if (x.category === "note_identification") {
      const isLedger = x.hasLedger ?? false
      if (x.clef === "treble") {
        acc.treble = add(acc.treble, x.correct)
        if (isLedger) acc.trebleLedger = add(acc.trebleLedger, x.correct)
      } else if (x.clef === "bass") {
        acc.bass = add(acc.bass, x.correct)
        if (isLedger) acc.bassLedger = add(acc.bassLedger, x.correct)
      }
    } else if (x.category === "ear") acc.ear = add(acc.ear, x.correct)
    else if (x.category === "writing") acc.writing = add(acc.writing, x.correct)
    else if (x.category === "rhythm") acc.rhythm = add(acc.rhythm, x.correct)
    else if (x.category === "musical_terms") acc.terms = add(acc.terms, x.correct)
  })
  newStats.categoryAccuracy = acc
  const stars = starsFor(results.filter((x) => x.correct).length, results.length)
  const best = !r.game && !r.label ? recordStars(newStats, r.category, stars) : null
  recordTopics(
    newStats,
    results.map((x) => ({ topic: topicOf(x), correct: x.correct ? 1 : 0, total: 1 })),
  )
  let cel: Record<string, unknown> | null = detectCelebration(stats, newStats)
  const unlocked = recordLevelProgress(results)
  if (unlocked) cel = { ...(cel ?? {}), unlocked }
  return { stats: newStats, stars, best, celebration: cel, points: pts }
}

function completeSpecial(stats: AppStats, r: Extract<Round, { kind: "special" }>) {
  const correct = r.correct.filter(Boolean).length
  const total = r.correct.length
  const pts = correct * 10
  const topic = r.special === "chords" ? "chords" : "rhythm"
  const next = applyProgress(stats, pts, total, {
    label: r.special === "chords" ? "Akorlar" : "Ritmi Tut",
    correct,
    total,
  })
  const prev = next.categoryAccuracy[topic] ?? { correct: 0, total: 0 }
  next.categoryAccuracy = {
    ...next.categoryAccuracy,
    [topic]: { correct: prev.correct + correct, total: prev.total + total },
  }
  recordTopics(next, [{ topic, correct, total }])
  const stars = starsFor(correct, total)
  const best = recordStars(next, r.special, stars)
  return { stats: next, stars, best, celebration: detectCelebration(stats, next), points: pts }
}

function resultFor(q: Question, correct: boolean): SessionResult {
  return {
    questionId: q.id,
    category: q.category,
    clef: q.clef,
    correct,
    timeMs: 400 + int(9000),
    hasLedger: (q.ledgerLines?.length ?? 0) > 0,
    noteY: q.noteY,
    accidental: q.accidental,
  }
}
const QUIZ_CATS: FilterCategory[] = ["all", "treble", "bass", "rhythm", "terms", "accidentals", "writing", "ear"]
function randomRound(accuracy: number): Round {
  const roll = int(20)
  if (roll === 0)
    return { kind: "special", special: "chords", correct: Array.from({ length: 10 }, () => gen() < accuracy) }
  if (roll === 1)
    return { kind: "special", special: "rhythmtap", correct: Array.from({ length: 6 }, () => gen() < accuracy) }
  const n = roll === 2 ? 1 + int(10) : 10
  const results: SessionResult[] = []
  for (let i = 0; i < n; i++) {
    if (gen() < 0.08) {
      // kulak sorusu: bankada yok
      results.push({ questionId: 900001 + i, category: "ear", correct: gen() < accuracy, timeMs: 1000 + int(5000) })
    } else results.push(resultFor(pick(ALL_QUESTIONS), gen() < accuracy))
  }
  const category = pick(QUIZ_CATS)
  const mode = int(10)
  if (mode === 0) return { kind: "quiz", category: "all", game: pick(GAME_CATS).key, results }
  if (mode === 1) return { kind: "quiz", category: "all", label: pick(["Zayıf notalar", "Hataların tekrarı"]), results }
  return { kind: "quiz", category, results }
}

/** Seri ve tur senaryoları: günler boyunca turlar, her adımdan sonra AppStats ve seviye ayarı */
function seri() {
  const scenarios = []
  // Sabit, elle seçilmiş senaryolar + rastgele olanlar
  const plans: {
    name: string
    goal: number
    level: 1 | 2 | 3
    days: { gap: number; rounds: number; acc: number }[]
  }[] = [
    { name: "ardışık-günler", goal: 10, level: 1, days: [1, 1, 1, 1, 1].map((gap) => ({ gap, rounds: 1, acc: 0.8 })) },
    { name: "bir-gün-ara", goal: 20, level: 1, days: [1, 1, 2, 1, 3, 1].map((gap) => ({ gap, rounds: 2, acc: 0.7 })) },
    { name: "hedef-tutmayan", goal: 30, level: 2, days: [1, 1, 1, 1].map((gap) => ({ gap, rounds: 2, acc: 0.6 })) },
    {
      name: "hizli-seviye",
      goal: 10,
      level: 1,
      days: Array.from({ length: 8 }, () => ({ gap: 1, rounds: 3, acc: 0.95 })),
    },
    {
      name: "ileri-seviye",
      goal: 50,
      level: 3,
      days: Array.from({ length: 5 }, () => ({ gap: 1, rounds: 5, acc: 0.85 })),
    },
  ]
  for (let i = 0; i < 12; i++)
    plans.push({
      name: `rastgele-${i + 1}`,
      goal: pick(GOALS),
      level: (1 + int(3)) as 1 | 2 | 3,
      days: Array.from({ length: 4 + int(8) }, () => ({
        gap: pick([0, 1, 1, 1, 1, 2, 3, 70]),
        rounds: 1 + int(4),
        acc: 0.4 + gen() * 0.6,
      })),
    })

  for (const plan of plans) {
    resetSettings({ dailyGoal: plan.goal, level: plan.level, levelProgress: { n: 0, c: 0 } })
    let stats: AppStats = JSON.parse(JSON.stringify(DEFAULT_STATS))
    let t = at(2026, 3, 1 + int(20), 9)
    const steps = []
    for (const day of plan.days) {
      t += day.gap * 86400000
      // Günün içinde tur saatleri: sabah 08:00'den başlayıp birkaç saat arayla; bazen gece yarısına yakın
      let time = t
      for (let k = 0; k < day.rounds; k++) {
        time += (k === 0 ? 0 : 1 + int(4)) * 3600000 + int(3600000)
        NOW = time
        const settingsBefore = { level: getSettings().level, levelProgress: getSettings().levelProgress }
        const round = randomRound(day.acc)
        const out = round.kind === "quiz" ? completeQuiz(stats, round) : completeSpecial(stats, round)
        stats = out.stats
        steps.push({
          now: NOW,
          round,
          settingsBefore,
          settingsAfter: { level: getSettings().level, levelProgress: getSettings().levelProgress },
          stars: out.stars,
          best: out.best,
          points: out.points,
          celebration: out.celebration,
          stats: k === day.rounds - 1 ? JSON.parse(JSON.stringify(stats)) : undefined,
          streak: stats.streak,
          lastPlayDate: stats.lastPlayDate,
          totalPoints: stats.totalPoints,
          streakNow: currentStreak(stats),
        })
      }
      // Ertesi gün ve iki gün sonra gösterilen seri
      NOW = time + 86400000
      const tomorrow = currentStreak(stats)
      NOW = time + 2 * 86400000
      steps[steps.length - 1] = {
        ...steps[steps.length - 1],
        streakTomorrow: tomorrow,
        streakIn2Days: currentStreak(stats),
      }
      t = time
    }
    scenarios.push({ name: plan.name, goal: plan.goal, level: plan.level, steps })
  }
  // Yaz saati geçişi (ABD: 8 Mart 2026 ileri, 1 Kasım 2026 geri): "dün = şimdi − 24 saat" kuralı (Bilinen durum 1)
  // gece yarısından hemen sonra ya da 25 saatlik günün sonunda takvimdeki dünden farklı sonuç verir; aynen korunur.
  const dst: [string, number[]][] = [
    [
      "yaz-saati-ileri",
      [at(2026, 3, 6, 20), at(2026, 3, 7, 20), at(2026, 3, 8, 23, 50), at(2026, 3, 9, 0, 30), at(2026, 3, 10, 0, 20)],
    ],
    [
      "yaz-saati-geri",
      [at(2026, 10, 30, 20), at(2026, 10, 31, 23, 40), at(2026, 11, 1, 23, 30), at(2026, 11, 2, 23, 45)],
    ],
  ]
  for (const [name, times] of dst) {
    resetSettings({ dailyGoal: 10, level: 1, levelProgress: { n: 0, c: 0 } })
    let stats: AppStats = JSON.parse(JSON.stringify(DEFAULT_STATS))
    const steps = []
    for (const time of times) {
      NOW = time
      const settingsBefore = { level: getSettings().level, levelProgress: getSettings().levelProgress }
      const round: Round = {
        kind: "quiz",
        category: "treble",
        results: ALL_QUESTIONS.slice(0, 10).map((q) => resultFor(q, true)),
      }
      const out = completeQuiz(stats, round)
      stats = out.stats
      const probe = [1, 30, 23 * 60 + 30, 24 * 60 + 30].map((min) => {
        NOW = time + min * 60000
        return { now: NOW, streak: currentStreak(stats) }
      })
      steps.push({
        now: time,
        round,
        settingsBefore,
        settingsAfter: { level: getSettings().level, levelProgress: getSettings().levelProgress },
        stars: out.stars,
        best: out.best,
        points: out.points,
        celebration: out.celebration,
        stats: JSON.parse(JSON.stringify(stats)),
        streak: stats.streak,
        lastPlayDate: stats.lastPlayDate,
        totalPoints: stats.totalPoints,
        streakNow: ((NOW = time), currentStreak(stats)),
        probe,
      })
    }
    scenarios.push({ name, goal: 10, level: 1, steps })
  }
  return { tz: TZ, scenarios }
}

/** K-04: yalnızca seviye ilerlemesi, uzun diziler */
function seviye() {
  const rows = []
  for (let i = 0; i < 60; i++) {
    const level = (1 + int(3)) as 1 | 2 | 3
    const start = { n: int(60), c: 0 }
    start.c = int(start.n + 1)
    resetSettings({ level, levelProgress: start })
    const acc = 0.5 + gen() * 0.5
    const steps = []
    for (let k = 0; k < 15; k++) {
      const n = pick([1, 3, 10, 10, 10, 20])
      const correct = Array.from({ length: n }, () => gen() < acc)
      const results = correct.map((c) => resultFor(pick(ALL_QUESTIONS), c))
      const unlocked = recordLevelProgress(results)
      steps.push({ correct, unlocked, level: getSettings().level, levelProgress: getSettings().levelProgress })
    }
    rows.push({ level, start, steps })
  }
  return rows
}

// ─── K-12 zorlandığın notalar ────────────────────────────────────────────────
function zayif() {
  const keys = [
    ...new Set(
      ALL_QUESTIONS.filter((q) => q.category === "note_identification").map(
        (q) => `${q.clef}:${q.noteY}${q.accidental ? ":" + q.accidental : ""}`,
      ),
    ),
  ]
  const rows = []
  for (let i = 0; i < 80; i++) {
    const noteStats: Record<string, { correct: number; total: number }> = {}
    const n = int(30)
    for (let k = 0; k < n; k++) {
      const total = int(12)
      noteStats[pick(keys)] = { correct: int(total + 1), total }
    }
    const stats = { ...DEFAULT_STATS, noteStats }
    rows.push({ noteStats, six: weakNotes(stats), four: weakNotes(stats, 4) })
  }
  return { keys, rows }
}

// ─── K-15 öğretmen kodu ──────────────────────────────────────────────────────
function ogretmen() {
  const clefs = ["treble", "bass", "both"] as const
  const valid = []
  for (let i = 0; i < 1500; i++) {
    const notes = ALL_NOTES.filter(() => gen() < 0.6)
    const topicMode = int(3)
    const topics = topicMode === 0 ? [] : TOPICS.filter(() => gen() < 0.5).map((t) => t.key as string)
    const setup: TeacherSetup = {
      notes,
      clef: pick(clefs),
      level: (1 + int(3)) as 1 | 2 | 3,
      dailyGoal: pick(GOALS),
      keyLabels: gen() < 0.5,
      topics,
    }
    const code = encodeTeacher(setup)
    valid.push({ setup, code, decoded: decodeTeacher(code) })
  }
  // Bütün 6 karakterlik kodların bir örneklemi: hangileri çözülüyor
  const ALPHA = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
  const random = []
  for (let i = 0; i < 2000; i++) {
    const code = Array.from({ length: 6 }, () => ALPHA[int(32)]).join("")
    random.push({ code, decoded: decodeTeacher(code) })
  }
  // Giriş düzeltmeleri ve bozuk kodlar
  const sample = valid[0].code
  const odd = [
    sample.toLowerCase(),
    sample.replace("-", " "),
    ` ${sample} `,
    sample.replace("-", ""),
    "K7M-2QX",
    "k7m2qx",
    "O0OI1I",
    "OOO-III",
    "ABCDEF",
    "ABC-DEFG",
    "AB",
    "",
    "!!!!!!",
    "ÇĞŞÜÖİ",
    valid[1].code.slice(0, 6),
    valid[2].code + "2",
    encodeChallenge({ cat: "all", level: 2, seed: 1234, correct: 7, sec: 42 }),
    ...valid.slice(3, 40).map((v) => v.code.replace(/.$/, (c) => (c === "2" ? "3" : "2"))),
  ].map((code) => ({ code, decoded: decodeTeacher(code) }))
  return { valid, random, odd }
}

// ─── K-16 oyunlar ────────────────────────────────────────────────────────────
/** FNV-1a (32 bit) onaltılık: büyük tabloyu küçük tutmak için */
function fnv(s: string) {
  let h = 2166136261
  for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 16777619)
  return (h >>> 0).toString(16).padStart(8, "0")
}
/** Soru listesinin kısa izi: "id:şık|şık|…;id:…" */
const trace = (qs: Question[]) => qs.map((q) => `${q.id}:${q.options.join("|")}`).join(";")

function oyun() {
  const cats = GAME_CATS.map((c) => c.key)
  const seeds = new Set([0, 1, 2, 65535])
  while (seeds.size < 1000) seeds.add(int(65536))
  const full = []
  const hashes: Record<string, string> = {}
  for (const seed of seeds)
    for (const cat of cats)
      for (const level of [1, 2, 3]) {
        const qs = buildGameQuestions(cat, level, seed)
        const key = `${cat}/${level}/${seed}`
        hashes[key] = fnv(trace(qs))
        if (full.length < 300)
          full.push({ cat, level, seed, ids: qs.map((q) => q.id), options: qs.map((q) => q.options) })
      }
  const daily = []
  for (
    let d = new RealDate(Date.UTC(2026, 0, 1));
    d.getUTCFullYear() < 2028;
    d = new RealDate(d.getTime() + 86400000)
  ) {
    const date = d.toISOString().slice(0, 10)
    daily.push(dailyInfo(date))
  }
  const codes = []
  for (let i = 0; i < 1000; i++) {
    const c = {
      cat: pick(cats),
      level: 1 + int(3),
      seed: int(65536),
      correct: int(11),
      sec: pick([0, 1, 59, 60, 1023, 1500, int(400)]),
    }
    const code = encodeChallenge(c)
    codes.push({ input: c, code, decoded: decodeChallenge(code) })
  }
  const ALPHA = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
  const random = []
  for (let i = 0; i < 2000; i++) {
    const code = Array.from({ length: 8 }, () => ALPHA[int(32)]).join("")
    random.push({ code, decoded: decodeChallenge(code) })
  }
  const odd = [
    codes[0].code.toLowerCase(),
    codes[1].code.replace("-", ""),
    ` ${codes[2].code}  `,
    "OOOO-IIII",
    "ABCD-EFG",
    "",
    encodeTeacher({ notes: ALL_NOTES, clef: "both", level: 1, dailyGoal: 10, keyLabels: false, topics: [] }),
  ].map((code) => ({ code, decoded: decodeChallenge(code) }))
  return { full, hashes, daily, codes, random, odd }
}

// ─── K-03, K-05 tur seçimi (Math.random dışarıdan verilen dizi) ──────────────
function turSecimi() {
  const realRandom = Math.random
  const cats: FilterCategory[] = ["all", "treble", "bass", "rhythm", "terms", "accidentals", "writing"]
  const rows = []
  for (let i = 0; i < 600; i++) {
    const limited = gen() < 0.35
    const notes = limited ? ALL_NOTES.filter(() => gen() < 0.5) : ALL_NOTES
    const settings = {
      level: (1 + int(3)) as 1 | 2 | 3,
      clef: pick(["treble", "bass", "both"] as const),
      notes: notes.length ? notes : ALL_NOTES,
      topics: gen() < 0.3 ? TOPICS.filter(() => gen() < 0.4).map((t) => t.key as string) : [],
    }
    resetSettings(settings)
    const seed = int(2 ** 31)
    Math.random = mulberry(seed)
    const category = i % 8 === 7 ? "ear" : pick(cats)
    const qs = category === "ear" ? buildEarQuestions() : pickQuestions(category)
    rows.push({
      settings,
      seed,
      category,
      questions: category === "ear" ? qs : qs.map((q) => ({ id: q.id, options: q.options })),
    })
  }
  const weak = []
  const weakKeys = zayif().keys
  for (let i = 0; i < 50; i++) {
    const keys = weakKeys.filter(() => gen() < 0.1)
    const seed = int(2 ** 31)
    Math.random = mulberry(seed)
    weak.push({ keys, seed, ids: getWeakQuestions(keys).map((q) => q.id) })
  }
  Math.random = realRandom
  return { rows, weak }
}

// ─── K-17 akor motoru ve akor turu ───────────────────────────────────────────
function akorlar() {
  const chords = ALL_CHORDS.map((c) => ({
    ...c,
    staffY: c.notes.map(staffY),
    lit: [...litKeys(c)],
    fits: fitsKeyboard(c),
    progressions: progressionsFor(c),
  }))
  const same: string[][] = []
  for (const a of ALL_CHORDS) for (const b of ALL_CHORDS) if (a.id < b.id && samePcs(a, b)) same.push([a.id, b.id])
  const upTo = [1, 2, 3, 4].map((lv) => chordsUpTo(lv as ChordLevel).map((c) => c.id))
  return { chords, same, upTo, colors: QUALITY_COLOR }
}

// ChordQuizSession.tsx buildQuestions'ın birebir kopyası (ekran dosyasında, dışa aktarılmıyor)
function buildChordQuestions(level: ChordLevel) {
  const SESSION = 10
  type QType = "staff" | "keys" | "build"
  const pool = chordsUpTo(level)
  const current = chordShuffle(pool.filter((c) => c.level === level))
  const earlier = chordShuffle(pool.filter((c) => c.level < level))
  const nCur = earlier.length ? Math.min(5, current.length) : Math.min(SESSION, current.length)
  let picked = [...current.slice(0, nCur), ...earlier.slice(0, SESSION - nCur)]
  if (picked.length < SESSION) picked = [...picked, ...chordShuffle(pool)].slice(0, SESSION)
  const types: QType[] = chordShuffle(
    Array.from({ length: SESSION }, (_, i) => (["staff", "keys", "build"] as QType[])[i % 3]),
  )
  const distractorPool = level === 1 ? chordsUpTo(1) : pool
  return chordShuffle(picked).map((chord, i) => ({
    chord,
    type: types[i] === "keys" && !fitsKeyboard(chord) ? "staff" : types[i],
    options: chordShuffle([chord, ...distractors(chord, distractorPool)]),
  }))
}

function akorTuru() {
  const realRandom = Math.random
  const rounds = []
  for (let i = 0; i < 300; i++) {
    const level = (1 + (i % 3)) as ChordLevel
    const seed = int(2 ** 31)
    Math.random = mulberry(seed)
    const qs = buildChordQuestions(level)
    rounds.push({
      level,
      seed,
      questions: qs.map((q) => ({ id: q.chord.id, type: q.type, options: q.options.map((o) => o.id) })),
    })
  }
  const dist = []
  for (let i = 0; i < 200; i++) {
    const level = (1 + (i % 4)) as ChordLevel
    const pool = chordsUpTo(level)
    const chord = pick(pool)
    const seed = int(2 ** 31)
    Math.random = mulberry(seed)
    dist.push({ level, chord: chord.id, seed, ids: distractors(chord, pool).map((c) => c.id) })
  }
  Math.random = realRandom
  return { rounds, distractors: dist }
}

// ─── K-18 Ritmi Tut ──────────────────────────────────────────────────────────
// RhythmTapSession.tsx'teki erken/geç uyarısının birebir kopyası (ekran dosyasında)
function biasText(result: TapResult) {
  const passed = result.score >= PASS
  const hits = result.notes.filter((n) => n.grade !== "miss").length
  return hits >= 2 && Math.abs(result.biasMs) > 45
    ? `${passed ? "Güzel; " : ""}${
        result.biasMs < 0
          ? "biraz erken dokunuyorsun, metronomu dinle."
          : "biraz geç dokunuyorsun, vuruşla birlikte dokun."
      }`.replace(/^b/, passed ? "b" : "B")
    : null
}

function ritmiTut() {
  const levels: QuestionLevel[] = [1, 2, 3]
  const patterns = levels.flatMap((lv) =>
    RHYTHM_PATTERNS[lv].map((score) => ({ level: lv, score, parsed: parseRhythm(score), onsets: onsets(score) })),
  )
  // Elle yazılmış ve hatalı metinler de ayrıştırılır (bilinmeyen parça atlanır)
  for (const score of ["w", "hr h", "q. q. q", "x q q", "  q   q  ", "eee q", "ssssss q"])
    patterns.push({ level: 1, score, parsed: parseRhythm(score), onsets: onsets(score) })
  const cases = []
  for (let i = 0; i < 1500; i++) {
    const level = pick(levels)
    const score = pick(RHYTHM_PATTERNS[pick(levels)])
    const bpm = gen() < 0.8 ? TEMPO[level] : 50 + int(90)
    const beatSec = 60 / bpm
    const style = int(6)
    const spread = [0.005, 0.03, 0.07, 0.12, 0.2, 0.05][style] // saniye
    const bias = style === 5 ? (gen() < 0.5 ? -0.07 : 0.07) : 0
    const taps: number[] = []
    for (const b of onsets(score)) {
      if (gen() < [0, 0.05, 0.1, 0.15, 0.25, 0.05][style]) continue // atlanan nota
      taps.push(b * beatSec + bias + (gen() * 2 - 1) * spread)
    }
    const extra = int(4) === 0 ? 1 + int(3) : 0
    for (let k = 0; k < extra; k++) taps.push(gen() * 4 * beatSec)
    if (gen() < 0.3) taps.reverse() // sırasız gelse de sıralanır
    const result = gradeTaps(score, taps, bpm, level)
    cases.push({ score, taps, bpm, level, result, passed: result.score >= PASS, bias: biasText(result) })
  }
  for (const level of levels) {
    const score = RHYTHM_PATTERNS[level][0]
    cases.push({
      score,
      taps: [],
      bpm: TEMPO[level],
      level,
      result: gradeTaps(score, [], TEMPO[level], level),
      passed: false,
      bias: null,
    })
  }
  // Elle: iki dokunuş bir notaya tam eşit uzaklıkta (ilk gelen sayılır), pencere sınırında, hepsi fazla
  const hand: [string, number[], number, QuestionLevel][] = [
    ["q q q q", [-0.05, 0.05, 0.95, 1.05, 2, 3], 60, 1],
    ["q q q q", [0.25, -0.25, 1, 2, 3], 60, 2],
    ["q q h", [0.2, 1.2, 2.2], 60, 1],
    ["q q h", [0.18, 1.18, 2.18], 60, 2],
    ["q q h", [0.11, 1.09, 2.09], 60, 1],
    ["ee ee q q", [0, 0.25, 0.5, 0.75, 1, 1.5, 2, 3], 60, 1],
    ["q q q q", [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5], 60, 1],
  ]
  for (const [score, taps, bpm, level] of hand) {
    const result = gradeTaps(score, taps, bpm, level)
    cases.push({ score, taps, bpm, level, result, passed: result.score >= PASS, bias: biasText(result) })
  }
  const picks = []
  for (let i = 0; i < 300; i++) {
    const level = levels[i % 3]
    const seed = int(2 ** 31)
    picks.push({ level, seed, patterns: pickPatterns(level, mulberry(seed)) })
  }
  return { tempo: TEMPO, pass: PASS, patterns, cases, picks }
}

// ─── K-13 haftalık rapor, K-14 doğruluk dönemleri ───────────────────────────
function haftalikRapor() {
  const cases = []
  const fixedNows = [
    at(2026, 11, 18, 10),
    at(2026, 11, 30, 9),
    at(2026, 12, 2, 21),
    at(2027, 1, 3, 23, 30),
    at(2026, 3, 1, 8),
  ]
  for (let i = 0; i < 70; i++) {
    const settings = {
      name: pick(["", "Ada", "  Deniz Su  ", "Çağrı"]),
      level: (1 + int(3)) as 1 | 2 | 3,
      dailyGoal: pick(GOALS),
      teacherCode: gen() < 0.3 ? "K7M-2QX" : "",
      levelProgress: { n: 0, c: 0 },
    }
    resetSettings(settings)
    let stats: AppStats = JSON.parse(JSON.stringify(DEFAULT_STATS))
    const end = i < fixedNows.length ? fixedNows[i] : at(2026, 1 + int(12), 1 + int(28), 8 + int(14))
    // Rapordan önceki ~3 hafta; bazı durumlarda bu hafta hiç çalışılmamış
    const quiet = i % 9 === 4
    const days = i === 0 ? 0 : 3 + int(18)
    const times = Array.from({ length: days }, () => end - int(21) * 86400000 - int(12) * 3600000)
      .filter((t) => !(quiet && t > end - 8 * 86400000))
      .sort((a, b) => a - b)
    for (const t of times) {
      NOW = Math.min(end, t)
      const round = randomRound(0.5 + gen() * 0.5)
      stats = (round.kind === "quiz" ? completeQuiz(stats, round) : completeSpecial(stats, round)).stats
    }
    NOW = end
    const s = getSettings()
    const r = buildWeeklyReport(stats, s, new Date(end))
    const acc = {
      all: accuracyFor(stats),
      week: [0, 1, 2].map((o) => accuracyFor(stats, "week", o)),
      month: [0, 1].map((o) => accuracyFor(stats, "month", o)),
    }
    cases.push({
      now: end,
      settings: { name: s.name, level: s.level, dailyGoal: s.dailyGoal, teacherCode: s.teacherCode },
      stats,
      report: { ...r, days: r.days.map(({ date: _d, ...rest }) => rest) },
      text: weeklyReportText(r),
      acc,
    })
  }
  return cases
}

// ─── Çalıştır ────────────────────────────────────────────────────────────────
const only = process.argv[3]
if (only === "seri") write(`seri-${TZ!.replace("/", "-")}.json`, seri())
else {
  const b = bank()
  write("soru-bankasi.json", b)
  write("unvan.json", unvan())
  write("yildiz.json", yildiz())
  write("donem.json", donem())
  write("seviye.json", seviye())
  write("zayif-notalar.json", zayif())
  write("ogretmen-kodu.json", ogretmen())
  write("oyun.json", oyun())
  write("tur-secimi.json", turSecimi())
  write("akorlar.json", akorlar())
  write("akor-turu.json", akorTuru())
  write("ritmi-tut.json", ritmiTut())
  write("haftalik-rapor.json", haftalikRapor())
  write("cizim.json", cizim())
  write("seri-" + TZ!.replace("/", "-") + ".json", seri())
}
