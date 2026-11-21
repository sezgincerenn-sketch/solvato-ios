export type ClefType = "treble" | "bass"
export type QuestionCategory = "note_identification" | "rhythm" | "musical_terms" | "writing" | "ear"
export type FilterCategory = "all" | "treble" | "bass" | "rhythm" | "terms" | "accidentals" | "writing" | "ear"

/** Kulak sorusunda çalınacak ses: tek nota (önce referans Do) ya da akor */
export type Pitch = { name: string; octave: number }
export type EarPrompt = { kind: "note"; ref: Pitch; target: Pitch } | { kind: "chord"; notes: Pitch[] }

export interface Question {
  id: number
  category: QuestionCategory
  clef?: ClefType
  noteName?: string
  noteY?: number
  ledgerLines?: number[]
  questionText: string
  displayText?: string
  options: string[]
  correctAnswer: string
  explanation: string
  rhythmType?: string
  score?: string // Notation bileşeninin çizeceği nota dizisi
  optionScores?: Record<string, string> // şıklar yazı yerine çizimse: şık → nota dizisi
  accidental?: "sharp" | "flat" // diyez / bemol sorusu
  keyName?: string // piyanodaki karşılığı, ör. 'Do#'
  /** Kulak sorusu: çalınacak sesler (data/ear.ts) */
  ear?: EarPrompt
}

/** Haftalık raporda ayrı sayılan konular */
export type TopicKey = "treble" | "bass" | "accidentals" | "rhythm" | "terms" | "writing" | "chords" | "ear"

/** Soru bankası dışındaki turlar: akor kartları ve Ritmi Tut oyunu (kendi ekranları, ortak sonuç ekranı) */
export type SpecialRound = "chords" | "rhythmtap"

/** Sonuç ekranının bir cevaptan ihtiyacı olan kadarı (akor turu da bunu üretir) */
export type RoundAnswer = Pick<SessionResult, "questionId" | "correct" | "timeMs">

export interface SessionResult {
  questionId: number
  category: QuestionCategory
  clef?: ClefType
  correct: boolean
  timeMs: number
  hasLedger?: boolean
  noteY?: number
  accidental?: "sharp" | "flat"
}

/** Tamamlanan bir tur (İlerleme › Son turlar) */
export interface RoundRecord {
  /** Bitiş zamanı (ms) */
  at: number
  /** Ekranda görünen ad: "Sol Anahtarı", "Akorlar", "Oyun · Ritim" */
  label: string
  correct: number
  total: number
  /** Toplam cevap süresi (sn); akor turunda yok */
  sec?: number
}

export interface AppStats {
  streak: number
  totalPoints: number
  totalSessions: number
  lastPlayDate: string
  // Gün bazlı (YYYY-MM-DD) tamamlanan seans sayısı: haftalık grafik için
  dailyLog: Record<string, number>
  // Gün bazlı (YYYY-MM-DD) çözülen soru sayısı: günlük hedef için
  dailyQuestions: Record<string, number>
  // Nota konumuna göre doğruluk (anahtar: 'treble:70'): zayıf nota tespiti için
  noteStats: Record<string, { correct: number; total: number }>
  categoryAccuracy: {
    treble: { correct: number; total: number }
    bass: { correct: number; total: number }
    trebleLedger: { correct: number; total: number }
    bassLedger: { correct: number; total: number }
    rhythm: { correct: number; total: number }
    terms: { correct: number; total: number }
    chords: { correct: number; total: number }
    writing?: { correct: number; total: number }
    ear?: { correct: number; total: number }
  }
  /** Son turlar, en yenisi başta (en çok 100) */
  history?: RoundRecord[]
  /** Gün bazlı doğruluk: haftalık / aylık doğruluk için */
  dailyAccuracy?: Record<string, { correct: number; total: number }>
  /** Konu başına en iyi tur yıldızı, 0–3 (anahtar: FilterCategory ya da "chords"); bkz. utils/stars.ts */
  bestStars?: Record<string, number>
  /** Gün bazlı, konuya göre doğruluk: haftalık rapor için (son 60 gün tutulur) */
  dailyTopics?: Record<string, Partial<Record<TopicKey, { correct: number; total: number }>>>
}

export const DEFAULT_STATS: AppStats = {
  streak: 0,
  totalPoints: 0,
  totalSessions: 0,
  lastPlayDate: "",
  dailyLog: {},
  dailyQuestions: {},
  noteStats: {},
  categoryAccuracy: {
    treble: { correct: 0, total: 0 },
    bass: { correct: 0, total: 0 },
    trebleLedger: { correct: 0, total: 0 },
    bassLedger: { correct: 0, total: 0 },
    rhythm: { correct: 0, total: 0 },
    terms: { correct: 0, total: 0 },
    chords: { correct: 0, total: 0 },
    writing: { correct: 0, total: 0 },
    ear: { correct: 0, total: 0 },
  },
}

// Gezinme
export type NavTab = "home" | "dashboard" | "study"
export type View =
  | NavTab
  | "quiz"
  | "result"
  | "chordquiz"
  | "rhythmtap"
  | "settings"
  | "duel"
  | "games"
  | "game-daily"
  | "game-challenge"
  | "gameresult"
  | "profile"
  | "lesson"
  | "teacher"
  | "privacy"
  | "licenses"
export type Theme = "dark" | "light"

// Bir sorunun cevap durumu
export type AnswerState = "pending" | "correct" | "wrong"
