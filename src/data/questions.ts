// Soru bankası: nota, ritim, terim ve nota yazımı soruları; seviye ataması (questionLevel).
import type { Question } from "../types"
import {
  SHARP_NAMES,
  FLAT_NAMES,
  SYMBOL,
  LETTER,
  accKey,
  accLabel,
  blackKeyLabel,
  type Accidental,
} from "./accidentals"

// ─── Note name ordering ─────────────────────────────────────────────────────
const TR_NOTES = ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"] as const

// ─── Staff position data ─────────────────────────────────────────────────────
// SVG coordinate system: staff lines at y = 40, 50, 60, 70, 80
// Line 1 (bottom) = y=80, Line 5 (top) = y=40

interface StaffNoteData {
  name: string
  y: number
  ledger: number[]
  hint: string
}

const TREBLE_NOTES: StaffNoteData[] = [
  { name: "Do", y: 90, ledger: [90], hint: "Sol anahtarında Do (C4) — birinci ek çizgide. Orta Do olarak bilinir." },
  { name: "Re", y: 85, ledger: [], hint: "Sol anahtarında Re (D4) — birinci çizginin altındaki aralıkta." },
  { name: "Mi", y: 80, ledger: [], hint: "Sol anahtarında Mi (E4) — birinci çizgide." },
  { name: "Fa", y: 75, ledger: [], hint: "Sol anahtarında Fa (F4) — birinci ve ikinci çizgi arasındaki aralıkta." },
  {
    name: "Sol",
    y: 70,
    ledger: [],
    hint: "Sol anahtarında Sol (G4) — ikinci çizgide. Sol anahtarının sarmal noktası!",
  },
  { name: "La", y: 65, ledger: [], hint: "Sol anahtarında La (A4) — ikinci ve üçüncü çizgi arasındaki aralıkta." },
  { name: "Si", y: 60, ledger: [], hint: "Sol anahtarında Si (B4) — üçüncü (orta) çizgide." },
  { name: "Do", y: 55, ledger: [], hint: "Sol anahtarında Do (C5) — üçüncü ve dördüncü çizgi arasındaki aralıkta." },
  { name: "Re", y: 50, ledger: [], hint: "Sol anahtarında Re (D5) — dördüncü çizgide." },
  { name: "Mi", y: 45, ledger: [], hint: "Sol anahtarında Mi (E5) — dördüncü ve beşinci çizgi arasındaki aralıkta." },
  { name: "Fa", y: 40, ledger: [], hint: "Sol anahtarında Fa (F5) — beşinci (üst) çizgide." },
  { name: "Sol", y: 35, ledger: [], hint: "Sol anahtarında Sol (G5) — beşinci çizginin üstündeki aralıkta." },
  { name: "La", y: 30, ledger: [30], hint: "Sol anahtarında La (A5) — birinci ek çizgide (yukarıda)." },
]

const BASS_NOTES: StaffNoteData[] = [
  { name: "Mi", y: 90, ledger: [90], hint: "Fa anahtarında Mi (E2) — birinci ek çizgide (aşağıda)." },
  { name: "Fa", y: 85, ledger: [], hint: "Fa anahtarında Fa (F2) — birinci çizginin altındaki aralıkta." },
  { name: "Sol", y: 80, ledger: [], hint: "Fa anahtarında Sol (G2) — birinci çizgide." },
  { name: "La", y: 75, ledger: [], hint: "Fa anahtarında La (A2) — birinci ve ikinci çizgi arasındaki aralıkta." },
  { name: "Si", y: 70, ledger: [], hint: "Fa anahtarında Si (B2) — ikinci çizgide." },
  { name: "Do", y: 65, ledger: [], hint: "Fa anahtarında Do (C3) — ikinci ve üçüncü çizgi arasındaki aralıkta." },
  { name: "Re", y: 60, ledger: [], hint: "Fa anahtarında Re (D3) — üçüncü (orta) çizgide." },
  { name: "Mi", y: 55, ledger: [], hint: "Fa anahtarında Mi (E3) — üçüncü ve dördüncü çizgi arasındaki aralıkta." },
  {
    name: "Fa",
    y: 50,
    ledger: [],
    hint: "Fa anahtarında Fa (F3) — dördüncü çizgide. Fa anahtarının referans noktası!",
  },
  { name: "Sol", y: 45, ledger: [], hint: "Fa anahtarında Sol (G3) — dördüncü ve beşinci çizgi arasındaki aralıkta." },
  { name: "La", y: 40, ledger: [], hint: "Fa anahtarında La (A3) — beşinci (üst) çizgide." },
  { name: "Si", y: 35, ledger: [], hint: "Fa anahtarında Si (B3) — beşinci çizginin üstündeki aralıkta." },
  { name: "Do", y: 30, ledger: [30], hint: "Fa anahtarında Do (C4) — birinci ek çizgide (yukarıda). Orta Do!" },
]

// İleri seviye: portenin üstünde ve altında 2–3 ek çizgideki notalar
const TREBLE_EXTRA: StaffNoteData[] = [
  { name: "Fa", y: 110, ledger: [90, 100, 110], hint: "Sol anahtarında Fa (F3) — alttan üçüncü ek çizgide." },
  { name: "Sol", y: 105, ledger: [90, 100], hint: "Sol anahtarında Sol (G3) — alttan ikinci ek çizginin altında." },
  { name: "La", y: 100, ledger: [90, 100], hint: "Sol anahtarında La (A3) — alttan ikinci ek çizgide." },
  { name: "Si", y: 95, ledger: [90], hint: "Sol anahtarında Si (B3) — orta Do çizgisinin hemen altında." },
  { name: "Si", y: 25, ledger: [30], hint: "Sol anahtarında Si (B5) — üstteki ilk ek çizginin üstünde." },
  { name: "Do", y: 20, ledger: [30, 20], hint: "Sol anahtarında Do (C6) — üstten ikinci ek çizgide." },
  { name: "Re", y: 15, ledger: [30, 20], hint: "Sol anahtarında Re (D6) — üstten ikinci ek çizginin üstünde." },
  { name: "Mi", y: 10, ledger: [30, 20, 10], hint: "Sol anahtarında Mi (E6) — üstten üçüncü ek çizgide." },
]

const BASS_EXTRA: StaffNoteData[] = [
  { name: "La", y: 110, ledger: [90, 100, 110], hint: "Fa anahtarında La (A1) — alttan üçüncü ek çizgide." },
  { name: "Si", y: 105, ledger: [90, 100], hint: "Fa anahtarında Si (B1) — alttan ikinci ek çizginin altında." },
  { name: "Do", y: 100, ledger: [90, 100], hint: "Fa anahtarında Do (C2) — alttan ikinci ek çizgide." },
  { name: "Re", y: 95, ledger: [90], hint: "Fa anahtarında Re (D2) — ilk ek çizginin hemen altında." },
  { name: "Re", y: 25, ledger: [30], hint: "Fa anahtarında Re (D4) — orta Do çizgisinin hemen üstünde." },
  { name: "Mi", y: 20, ledger: [30, 20], hint: "Fa anahtarında Mi (E4) — üstten ikinci ek çizgide." },
  { name: "Fa", y: 15, ledger: [30, 20], hint: "Fa anahtarında Fa (F4) — üstten ikinci ek çizginin üstünde." },
  { name: "Sol", y: 10, ledger: [30, 20, 10], hint: "Fa anahtarında Sol (G4) — üstten üçüncü ek çizgide." },
]

// ─── Distractor sets: 12 variants of 3 wrong answers per note ───────────────
const DIST: Record<string, string[][]> = {
  Do: [
    ["Re", "Mi", "Fa"],
    ["Re", "Mi", "Sol"],
    ["Re", "Mi", "La"],
    ["Re", "Mi", "Si"],
    ["Re", "Fa", "Sol"],
    ["Re", "Fa", "La"],
    ["Re", "Fa", "Si"],
    ["Re", "Sol", "La"],
    ["Re", "Sol", "Si"],
    ["Re", "La", "Si"],
    ["Mi", "Fa", "Sol"],
    ["Mi", "Fa", "La"],
  ],
  Re: [
    ["Do", "Mi", "Fa"],
    ["Do", "Mi", "Sol"],
    ["Do", "Mi", "La"],
    ["Do", "Mi", "Si"],
    ["Do", "Fa", "Sol"],
    ["Do", "Fa", "La"],
    ["Do", "Fa", "Si"],
    ["Do", "Sol", "La"],
    ["Do", "Sol", "Si"],
    ["Do", "La", "Si"],
    ["Mi", "Fa", "Sol"],
    ["Mi", "Fa", "La"],
  ],
  Mi: [
    ["Do", "Re", "Fa"],
    ["Do", "Re", "Sol"],
    ["Do", "Re", "La"],
    ["Do", "Re", "Si"],
    ["Do", "Fa", "Sol"],
    ["Do", "Fa", "La"],
    ["Do", "Fa", "Si"],
    ["Do", "Sol", "La"],
    ["Do", "Sol", "Si"],
    ["Do", "La", "Si"],
    ["Re", "Fa", "Sol"],
    ["Re", "Fa", "La"],
  ],
  Fa: [
    ["Do", "Re", "Mi"],
    ["Do", "Re", "Sol"],
    ["Do", "Re", "La"],
    ["Do", "Re", "Si"],
    ["Do", "Mi", "Sol"],
    ["Do", "Mi", "La"],
    ["Do", "Mi", "Si"],
    ["Do", "Sol", "La"],
    ["Do", "Sol", "Si"],
    ["Do", "La", "Si"],
    ["Re", "Mi", "Sol"],
    ["Re", "Mi", "La"],
  ],
  Sol: [
    ["Do", "Re", "Mi"],
    ["Do", "Re", "Fa"],
    ["Do", "Re", "La"],
    ["Do", "Re", "Si"],
    ["Do", "Mi", "Fa"],
    ["Do", "Mi", "La"],
    ["Do", "Mi", "Si"],
    ["Do", "Fa", "La"],
    ["Do", "Fa", "Si"],
    ["Do", "La", "Si"],
    ["Re", "Mi", "Fa"],
    ["Re", "Mi", "La"],
  ],
  La: [
    ["Do", "Re", "Mi"],
    ["Do", "Re", "Fa"],
    ["Do", "Re", "Sol"],
    ["Do", "Re", "Si"],
    ["Do", "Mi", "Fa"],
    ["Do", "Mi", "Sol"],
    ["Do", "Mi", "Si"],
    ["Do", "Fa", "Sol"],
    ["Do", "Fa", "Si"],
    ["Do", "Sol", "Si"],
    ["Re", "Mi", "Fa"],
    ["Re", "Mi", "Sol"],
  ],
  Si: [
    ["Do", "Re", "Mi"],
    ["Do", "Re", "Fa"],
    ["Do", "Re", "Sol"],
    ["Do", "Re", "La"],
    ["Do", "Mi", "Fa"],
    ["Do", "Mi", "Sol"],
    ["Do", "Mi", "La"],
    ["Do", "Fa", "Sol"],
    ["Do", "Fa", "La"],
    ["Do", "Sol", "La"],
    ["Re", "Mi", "Fa"],
    ["Re", "Mi", "Sol"],
  ],
}

const Q_TEXTS = [
  "Bu nota hangisi?",
  "Notanın adı nedir?",
  "Hangi nota bu?",
  "Bu notayı tanımlayın.",
  "Bu nota hangi perdedir?",
  "Notayı tespit edin.",
  "Bu nota ne?",
]

function buildNoteQuestions(noteArr: StaffNoteData[], clef: "treble" | "bass", startId: number): Question[] {
  const qs: Question[] = []
  let id = startId
  for (const n of noteArr) {
    const dists = DIST[n.name]
    for (let v = 0; v < 12; v++) {
      const d = dists[v]
      const opts = [n.name, d[0], d[1], d[2]]
      opts.sort((a, b) => TR_NOTES.indexOf(a as never) - TR_NOTES.indexOf(b as never))
      qs.push({
        id: id++,
        category: "note_identification",
        clef,
        noteName: n.name,
        noteY: n.y,
        ledgerLines: n.ledger,
        questionText: Q_TEXTS[v % Q_TEXTS.length],
        options: opts,
        correctAnswer: n.name,
        explanation: n.hint,
      })
    }
  }
  return qs
}

// ─── Rhythm questions (100) ──────────────────────────────────────────────────
const RHYTHM_QUESTIONS: Question[] = [
  // --- Note values ---
  {
    id: 313,
    category: "rhythm",
    rhythmType: "whole",
    questionText: "Bu nota değeri nedir?",
    options: ["Birlik", "İkilik", "Dörtlük", "Sekizlik"],
    correctAnswer: "Birlik",
    explanation: "Birlik 4/4 ölçüde 4 vuruş sürer. İçi boş, sapsız oval şeklindedir.",
  },
  {
    id: 314,
    category: "rhythm",
    rhythmType: "half",
    questionText: "Bu nota değeri nedir?",
    options: ["Birlik", "İkilik", "Dörtlük", "Sekizlik"],
    correctAnswer: "İkilik",
    explanation: "İkilik 2 vuruş sürer. İçi boş ovalin sapı vardır.",
  },
  {
    id: 315,
    category: "rhythm",
    rhythmType: "quarter",
    questionText: "Bu nota değeri nedir?",
    options: ["İkilik", "Dörtlük", "Sekizlik", "Onaltılık"],
    correctAnswer: "Dörtlük",
    explanation: "Dörtlük 1 vuruş sürer. Dolu oval, tek sap.",
  },
  {
    id: 316,
    category: "rhythm",
    rhythmType: "eighth",
    questionText: "Bu nota değeri nedir?",
    options: ["Dörtlük", "Sekizlik", "Onaltılık", "İkilik"],
    correctAnswer: "Sekizlik",
    explanation: "Sekizlik yarım vuruş sürer. Dolu oval, sap ve bir kanca/bayrak.",
  },
  {
    id: 317,
    category: "rhythm",
    rhythmType: "sixteenth",
    questionText: "Bu nota değeri nedir?",
    options: ["Sekizlik", "Onaltılık", "Dörtlük", "İkilik"],
    correctAnswer: "Onaltılık",
    explanation: "Onaltılık çeyrek vuruş sürer. İki kanca/bayrak içerir.",
  },
  {
    id: 318,
    category: "rhythm",
    rhythmType: "whole",
    questionText: "Kaç vuruş sürer?",
    options: ["1 vuruş", "2 vuruş", "3 vuruş", "4 vuruş"],
    correctAnswer: "4 vuruş",
    explanation: "Birlik 4/4 ölçüde tam 4 vuruş boyunca sürer.",
  },
  {
    id: 319,
    category: "rhythm",
    rhythmType: "half",
    questionText: "Kaç vuruş sürer?",
    options: ["1 vuruş", "2 vuruş", "3 vuruş", "4 vuruş"],
    correctAnswer: "2 vuruş",
    explanation: "İkilik 2 vuruş sürer; birliğin yarısıdır.",
  },
  {
    id: 320,
    category: "rhythm",
    rhythmType: "quarter",
    questionText: "Kaç vuruş sürer?",
    options: ["1 vuruş", "2 vuruş", "Yarım vuruş", "Çeyrek vuruş"],
    correctAnswer: "1 vuruş",
    explanation: "Dörtlük 1 vuruş sürer; en yaygın nota değeridir.",
  },
  {
    id: 321,
    category: "rhythm",
    rhythmType: "eighth",
    questionText: "Kaç vuruş sürer?",
    options: ["1 vuruş", "Yarım vuruş", "Çeyrek vuruş", "2 vuruş"],
    correctAnswer: "Yarım vuruş",
    explanation: "Sekizlik yarım vuruş sürer.",
  },
  {
    id: 322,
    category: "rhythm",
    rhythmType: "sixteenth",
    questionText: "Kaç vuruş sürer?",
    options: ["Yarım vuruş", "Çeyrek vuruş", "1 vuruş", "2 vuruş"],
    correctAnswer: "Çeyrek vuruş",
    explanation: "Onaltılık çeyrek vuruş sürer.",
  },
  {
    id: 323,
    category: "rhythm",
    questionText: "1 birlik kaç dörtlüğe eşittir?",
    displayText: "𝅝 = ?♩",
    options: ["2 dörtlük", "3 dörtlük", "4 dörtlük", "8 dörtlük"],
    correctAnswer: "4 dörtlük",
    explanation: "Birlik = 4 dörtlük. Nota değerleri ikiye bölünerek küçülür.",
  },
  {
    id: 324,
    category: "rhythm",
    questionText: "1 ikilik kaç dörtlüğe eşittir?",
    displayText: "𝅗 = ?♩",
    options: ["1 dörtlük", "2 dörtlük", "4 dörtlük", "8 dörtlük"],
    correctAnswer: "2 dörtlük",
    explanation: "İkilik = 2 dörtlük. Birliğin yarısıdır.",
  },
  {
    id: 325,
    category: "rhythm",
    questionText: "1 dörtlük kaç sekizliğe eşittir?",
    displayText: "♩ = ?♪",
    options: ["1 sekizlik", "2 sekizlik", "4 sekizlik", "8 sekizlik"],
    correctAnswer: "2 sekizlik",
    explanation: "Dörtlük = 2 sekizlik.",
  },
  {
    id: 326,
    category: "rhythm",
    questionText: "1 sekizlik kaç onaltılığa eşittir?",
    displayText: "♪ = ?",
    options: ["1", "2", "4", "8"],
    correctAnswer: "2",
    explanation: "Sekizlik = 2 onaltılık.",
  },
  {
    id: 327,
    category: "rhythm",
    questionText: "3/4 ölçüde bir ölçüye kaç sekizlik sığar?",
    displayText: "3/4 = ? ♪",
    options: ["3", "4", "6", "8"],
    correctAnswer: "6",
    explanation: "3/4 ölçüde 3 dörtlük vuruş vardır; her dörtlük 2 sekizlik eder, yani 3 × 2 = 6 sekizlik.",
  },
  {
    id: 328,
    category: "rhythm",
    questionText: "2/4 ölçüde bir ölçüye kaç sekizlik sığar?",
    displayText: "2/4 = ? ♪",
    options: ["2", "3", "4", "6"],
    correctAnswer: "4",
    explanation: "2/4 ölçüde 2 dörtlük vuruş vardır; her dörtlük 2 sekizlik eder, yani 2 × 2 = 4 sekizlik.",
  },
  {
    id: 329,
    category: "rhythm",
    questionText: "2/4 ölçüde bir ölçüye kaç onaltılık sığar?",
    displayText: "2/4 = ? ♬",
    options: ["4", "6", "8", "16"],
    correctAnswer: "8",
    explanation: "2/4 ölçüde 2 dörtlük vuruş vardır; her dörtlük 4 onaltılık eder, yani 2 × 4 = 8 onaltılık.",
  },
  {
    id: 330,
    category: "rhythm",
    questionText: "6/8 ölçüde bir ölçüye kaç dörtlük sığar?",
    displayText: "6/8 = ? ♩",
    options: ["2", "3", "4", "6"],
    correctAnswer: "3",
    explanation: "6/8 ölçüde 6 sekizlik vardır; 2 sekizlik 1 dörtlük ettiği için 6 ÷ 2 = 3 dörtlük.",
  },
  {
    id: 331,
    category: "rhythm",
    questionText: "4/4 ölçüde birlik kaç vuruş sürer?",
    displayText: "4/4 + 𝅝",
    options: ["2 vuruş", "3 vuruş", "4 vuruş", "6 vuruş"],
    correctAnswer: "4 vuruş",
    explanation: "4/4 ölçüde birlik tüm ölçüyü doldurur (4 vuruş).",
  },
  // --- Rests ---
  {
    id: 333,
    category: "rhythm",
    rhythmType: "whole_rest",
    questionText: "Bu sus değeri nedir?",
    options: ["Birlik sus", "İkilik sus", "Dörtlük sus", "Sekizlik sus"],
    correctAnswer: "Birlik sus",
    explanation: "Birlik sus 4 vuruş sürer; porte çizgisinin altına asılı dörtgen şeklindedir.",
  },
  {
    id: 334,
    category: "rhythm",
    rhythmType: "half_rest",
    questionText: "Bu sus değeri nedir?",
    options: ["Birlik sus", "İkilik sus", "Dörtlük sus", "Sekizlik sus"],
    correctAnswer: "İkilik sus",
    explanation: "İkilik sus 2 vuruş sürer; porte çizgisinin üstünde duran şapka şeklindedir.",
  },
  {
    id: 335,
    category: "rhythm",
    rhythmType: "quarter_rest",
    questionText: "Bu sus değeri nedir?",
    options: ["İkilik sus", "Dörtlük sus", "Sekizlik sus", "Onaltılık sus"],
    correctAnswer: "Dörtlük sus",
    explanation: "Dörtlük sus 1 vuruş sürer; kıvrımlı çizgi şeklindedir.",
  },
  {
    id: 336,
    category: "rhythm",
    rhythmType: "eighth_rest",
    questionText: "Bu sus değeri nedir?",
    options: ["Dörtlük sus", "Sekizlik sus", "Onaltılık sus", "İkilik sus"],
    correctAnswer: "Sekizlik sus",
    explanation: "Sekizlik sus yarım vuruş sürer; eğri çizgi ve noktadan oluşur.",
  },
  {
    id: 337,
    category: "rhythm",
    rhythmType: "whole_rest",
    questionText: "Kaç vuruş sürer?",
    options: ["1", "2", "3", "4"],
    correctAnswer: "4",
    explanation: "Birlik sus 4 vuruş (tam bir ölçü) sürer.",
  },
  {
    id: 338,
    category: "rhythm",
    rhythmType: "half_rest",
    questionText: "Kaç vuruş sürer?",
    options: ["1", "2", "3", "4"],
    correctAnswer: "2",
    explanation: "İkilik sus 2 vuruş sürer.",
  },
  {
    id: 339,
    category: "rhythm",
    rhythmType: "quarter_rest",
    questionText: "Kaç vuruş sürer?",
    options: ["Yarım", "1", "2", "4"],
    correctAnswer: "1",
    explanation: "Dörtlük sus 1 vuruş sürer.",
  },
  {
    id: 340,
    category: "rhythm",
    rhythmType: "eighth_rest",
    questionText: "Kaç vuruş sürer?",
    options: ["Çeyrek", "Yarım", "1", "2"],
    correctAnswer: "Yarım",
    explanation: "Sekizlik sus yarım vuruş sürer.",
  },
  {
    id: 341,
    category: "rhythm",
    questionText: "Noktalı dörtlük kaç vuruş sürer?",
    displayText: "♩.",
    options: ["1", "1,5", "2", "2,5"],
    correctAnswer: "1,5",
    explanation: "Noktalı nota, notanın değerinin 1,5 katı kadar sürer. Noktalı dörtlük = 1 + 0,5 = 1,5 vuruş.",
  },
  {
    id: 342,
    category: "rhythm",
    questionText: "Noktalı ikilik kaç vuruş sürer?",
    displayText: "𝅗.",
    options: ["2", "2,5", "3", "3,5"],
    correctAnswer: "3",
    explanation: "Noktalı ikilik = 2 + 1 = 3 vuruş sürer.",
  },
  {
    id: 343,
    category: "rhythm",
    questionText: "4/4 ölçüde bir ikilik + iki dörtlük kaç vuruş tutar?",
    displayText: "𝅗 + ♩ + ♩",
    options: ["3 vuruş", "4 vuruş", "5 vuruş", "6 vuruş"],
    correctAnswer: "4 vuruş",
    explanation: "2 + 1 + 1 = 4 vuruş. Bu kombinasyon tam bir ölçüyü doldurur.",
  },
  {
    id: 344,
    category: "rhythm",
    questionText: "Hangi nota değeri, dörtlüğün iki katıdır?",
    displayText: "♩ × 2 = ?",
    options: ["Sekizlik", "Onaltılık", "İkilik", "Birlik"],
    correctAnswer: "İkilik",
    explanation: "İkilik, dörtlüğün iki katı kadar sürer (2 vuruş).",
  },
  {
    id: 345,
    category: "rhythm",
    questionText: "Hangi nota değeri, dörtlüğün yarısıdır?",
    displayText: "♩ ÷ 2 = ?",
    options: ["Onaltılık", "Sekizlik", "İkilik", "Birlik"],
    correctAnswer: "Sekizlik",
    explanation: "Sekizlik, dörtlüğün yarısı kadardır (0,5 vuruş).",
  },
  {
    id: 346,
    category: "rhythm",
    questionText: "4/4 ölçüde kaç sekizlik bir ölçüye sığar?",
    displayText: "4/4 = ? ♪",
    options: ["4", "6", "8", "16"],
    correctAnswer: "8",
    explanation: "4/4 ölçüde 8 sekizlik bulunabilir (4 vuruş × 2).",
  },
  {
    id: 347,
    category: "rhythm",
    questionText: "Ölçü işaretinde alttaki sayı neyi gösterir?",
    displayText: "4/4",
    options: ["Vuruş sayısı", "Nota değeri", "Tempo", "Ses seviyesi"],
    correctAnswer: "Nota değeri",
    explanation: "Ölçü işaretinde alttaki sayı, bir vuruşun hangi nota değerine eşit olduğunu gösterir. 4 = dörtlük.",
  },
  {
    id: 348,
    category: "rhythm",
    questionText: "Ölçü işaretinde üstteki sayı neyi gösterir?",
    displayText: "3/4",
    options: ["Tempo", "Vuruş sayısı", "Nota değeri", "Ölçü uzunluğu"],
    correctAnswer: "Vuruş sayısı",
    explanation: "Ölçü işaretinde üstteki sayı, her ölçüde kaç vuruş olduğunu gösterir.",
  },
  {
    id: 349,
    category: "rhythm",
    questionText: "6/8 ölçüde alt sayı neyi gösterir?",
    displayText: "6/8",
    options: ["Dörtlük", "Sekizlik", "İkilik", "Birlik"],
    correctAnswer: "Sekizlik",
    explanation:
      "6/8 ölçüde alt sayı 8 = sekizlik demektir. Yani ölçüdeki sayım birimi sekizliktir: her ölçüde 6 sekizlik vardır.",
  },
  {
    id: 350,
    category: "rhythm",
    questionText: "4/4 ölçüde 4 dörtlük yerine neyin yazılmasıyla aynı süre elde edilir?",
    displayText: "♩♩♩♩ = ?",
    options: ["2 ikilik", "1 birlik", "Her ikisi de", "3 ikilik"],
    correctAnswer: "Her ikisi de",
    explanation: "1 birlik = 2 ikilik = 4 dörtlük = 8 sekizlik; hepsi 4 vuruştur.",
  },
  {
    id: 351,
    category: "rhythm",
    questionText: "Bu ölçü işareti hangi ölçüyü gösterir?",
    displayText: "𝄴",
    options: ["2/4", "3/4", "4/4", "6/8"],
    correctAnswer: "4/4",
    explanation: "C işareti 4/4 ölçü demektir. En yaygın ölçüdür.",
  },
  {
    id: 352,
    category: "rhythm",
    questionText: "Bu ölçü işareti hangi ölçüyü gösterir?",
    displayText: "𝄵",
    options: ["2/2", "2/4", "4/4", "6/8"],
    correctAnswer: "2/2",
    explanation: "Çizgili C (alla breve) 2/2 ölçü demektir; her vuruş bir ikiliktir.",
  },
  {
    id: 354,
    category: "rhythm",
    questionText: "Farklı notaları kapsayan bu bağ ne anlama gelir?",
    displayText: "~ bağ",
    options: ["Notaları kesik kesik çal", "Notaları bağlı (legato) çal", "Notaları vurgula", "Notaları tekrarla"],
    correctAnswer: "Notaları bağlı (legato) çal",
    explanation: "Legato bağı farklı notaları bağlayarak düzgün (legato) çalmayı belirtir.",
  },
  {
    id: 355,
    category: "rhythm",
    questionText: "İki nota arasındaki bu bağ ne anlama gelir?",
    displayText: "⌒ tie",
    options: ["Legato çalış", "Aynı iki notanın birleştirilmesi", "Tempo artışı", "Dinamik değişim"],
    correctAnswer: "Aynı iki notanın birleştirilmesi",
    explanation:
      "Süre bağı aynı perdedeki iki notayı birleştirir; ikinci nota çalınmaz, sadece ilk notanın süresi uzar.",
  },
  // More rhythm questions
  {
    id: 357,
    category: "rhythm",
    questionText: "Fermata (durak) ne anlama gelir?",
    displayText: "𝄐",
    options: ["Notayı kısa tut", "Notayı belirtilenden uzun tut", "Sesi yükselt", "Notayı tekrarla"],
    correctAnswer: "Notayı belirtilenden uzun tut",
    explanation: "Fermata, notanın ya da susun belirlenen değerinden daha uzun tutulmasını gösterir.",
  },
  {
    id: 358,
    category: "rhythm",
    questionText: "Bu notalardan en uzun süren hangisi?",
    options: ["Birlik", "İkilik", "Dörtlük", "Sekizlik"],
    correctAnswer: "Birlik",
    explanation: "Birlik 4 vuruş sürer; ikilik 2, dörtlük 1, sekizlik yarım vuruş.",
  },
  {
    id: 360,
    category: "rhythm",
    questionText: "Bu çift çizgi neyi gösterir?",
    displayText: "‖",
    options: ["Ölçünün başı", "Parçanın sonu", "Tekrar işareti", "Tempo değişimi"],
    correctAnswer: "Parçanın sonu",
    explanation: "İnce ve kalın çift çizgi parçanın ya da bölümün bitişini gösterir.",
  },
  // Time signature recognition
  {
    id: 361,
    category: "rhythm",
    questionText: "4/4 ölçüde hangi nota bir vuruşu temsil eder?",
    displayText: "4/4",
    options: ["Sekizlik", "Dörtlük", "İkilik", "Birlik"],
    correctAnswer: "Dörtlük",
    explanation: "4/4 ölçüde alt sayı 4 = dörtlük. Bir dörtlük = bir vuruş.",
  },
  {
    id: 362,
    category: "rhythm",
    questionText: "6/8 ölçüde kaç ana vuruş hissedilir?",
    displayText: "6/8",
    options: ["2", "3", "6", "8"],
    correctAnswer: "2",
    explanation: "6/8 ölçüde 6 sekizlik birleşerek 2 ana vuruş (3+3) oluşturur.",
  },
  {
    id: 363,
    category: "rhythm",
    questionText: "Hangi nota değeri 6/8 ölçüde bir tam vuruşu temsil eder?",
    displayText: "6/8",
    options: ["Sekizlik", "Dörtlük", "Noktalı dörtlük", "İkilik"],
    correctAnswer: "Noktalı dörtlük",
    explanation: "6/8 ölçüde her ana vuruş 3 sekizlik = noktalı dörtlük kadar sürer.",
  },
  {
    id: 365,
    category: "rhythm",
    questionText: "9/8 ölçüde kaç ana vuruş hissedilir?",
    displayText: "9/8",
    options: ["2", "3", "4", "9"],
    correctAnswer: "3",
    explanation: "9/8 ölçüdeki 9 sekizlik, üçerli gruplanır (3+3+3); bu yüzden 3 ana vuruş hissedilir.",
  },
  {
    id: 367,
    category: "rhythm",
    questionText: "4/4 ölçüde bir ölçüye kaç onaltılık sığar?",
    displayText: "4/4 = ?",
    options: ["8", "16", "32", "4"],
    correctAnswer: "16",
    explanation: "4 dörtlük × 4 onaltılık = 16 onaltılık.",
  },
  // Additional rhythm questions
  {
    id: 371,
    category: "rhythm",
    questionText: "3/4 ölçüde bir ölçüyü tek başına dolduran nota hangisidir?",
    displayText: "3/4 = ?",
    options: ["İkilik", "Noktalı ikilik", "Birlik", "Noktalı dörtlük"],
    correctAnswer: "Noktalı ikilik",
    explanation: "3/4 ölçü 3 vuruştur. İkilik 2 vuruş, noktası yarısı kadar (1 vuruş) ekler: 2 + 1 = 3 vuruş.",
  },
  {
    id: 372,
    category: "rhythm",
    questionText: "3/4 ölçüde bir ölçüye kaç onaltılık sığar?",
    displayText: "3/4 = ? ♬",
    options: ["6", "8", "12", "16"],
    correctAnswer: "12",
    explanation: "3/4 ölçüde 3 dörtlük vuruş vardır; her dörtlük 4 onaltılık eder, yani 3 × 4 = 12 onaltılık.",
  },
  {
    id: 373,
    category: "rhythm",
    questionText: "Dört sekizlik kaç dörtlük eder?",
    displayText: "♪♪♪♪ = ?♩",
    options: ["1", "2", "3", "4"],
    correctAnswer: "2",
    explanation: "2 sekizlik = 1 dörtlük, dolayısıyla 4 sekizlik = 2 dörtlük.",
  },
  {
    id: 374,
    category: "rhythm",
    questionText: "Sekiz onaltılık kaç dörtlük eder?",
    displayText: "×8 onalt. = ?♩",
    options: ["1", "2", "3", "4"],
    correctAnswer: "2",
    explanation: "4 onaltılık = 1 dörtlük, dolayısıyla 8 onaltılık = 2 dörtlük.",
  },
  {
    id: 375,
    category: "rhythm",
    questionText: "Hangisi doğrudur?",
    displayText: "1 tam = ?",
    options: ["2 dörtlük", "4 ikilik", "2 ikilik", "8 ikilik"],
    correctAnswer: "2 ikilik",
    explanation: "1 birlik = 2 ikilik = 4 dörtlük = 8 sekizlik.",
  },
  {
    id: 376,
    category: "rhythm",
    questionText: "Notaları birbirine bağlayan kalın çizgi neyi gösterir?",
    displayText: "♬ bağlı notalar",
    options: ["Legato çal", "Staccato çal", "Sekizlik/onaltılık grubu", "Tempo artır"],
    correctAnswer: "Sekizlik/onaltılık grubu",
    explanation:
      "Kalın çizgiyle bağlanan notalar genellikle sekizlik veya daha küçük nota değerleridir ve ritimsel gruplamayı kolaylaştırır.",
  },
  {
    id: 377,
    category: "rhythm",
    questionText: "Triole (üçleme) nedir?",
    displayText: "3 üçleme",
    options: ["Üç vuruşluk nota", "İki vuruş yerine üç eşit nota", "Üç nota tekrarı", "Üç oktavlı aralık"],
    correctAnswer: "İki vuruş yerine üç eşit nota",
    explanation:
      "Triole, normalde iki eşit nota sığacak yere üç eşit nota yerleştirerek özel bir ritim etkisi yaratır.",
  },
  {
    id: 379,
    category: "rhythm",
    questionText: "Hangi nota ikiye bölündüğünde sekizlik elde edilir?",
    displayText: "? ÷ 2 = ♪",
    options: ["Birlik", "İkilik", "Dörtlük", "Onaltılık"],
    correctAnswer: "Dörtlük",
    explanation: "Dörtlük ÷ 2 = sekizlik.",
  },
  {
    id: 380,
    category: "rhythm",
    questionText: "Ritardando (rit.) ne anlama gelir?",
    displayText: "rit.",
    options: ["Hız artır", "Giderek yavaşla", "Ani dur", "Sabit hızda"],
    correctAnswer: "Giderek yavaşla",
    explanation: "Ritardando (rit. ya da ritard.), temponun kademeli olarak yavaşlamasını belirtir.",
  },
  {
    id: 381,
    category: "rhythm",
    questionText: "Accelerando (accel.) ne anlama gelir?",
    displayText: "accel.",
    options: ["Giderek yavaşla", "Giderek hızlan", "Sabit kal", "Ani dur"],
    correctAnswer: "Giderek hızlan",
    explanation: "Accelerando (accel.), temponun giderek artmasını (hızlanmasını) ifade eder.",
  },
  {
    id: 382,
    category: "rhythm",
    questionText: "A tempo ne anlama gelir?",
    displayText: "a tempo",
    options: ["Yeni bir tempo", "Önceki tempoya dön", "Çok hızlı", "Serbest tempo"],
    correctAnswer: "Önceki tempoya dön",
    explanation: "A tempo, rit. veya accel. işaretinin ardından orijinal tempoya geri dönüleceğini belirtir.",
  },
  {
    id: 385,
    category: "rhythm",
    questionText: "Parçanın ilk tam ölçüden önce başlayan bu kısa girişine ne denir?",
    displayText: "Upbeat ↑",
    options: ["Senkop", "Anakruz (ön vuruş)", "Fermata", "Triole"],
    correctAnswer: "Anakruz (ön vuruş)",
    explanation: "Anakruz, ölçünün güçlü birinci vuruşundan önce gelen zayıf başlangıç notasıdır.",
  },
  {
    id: 386,
    category: "rhythm",
    questionText: "4/4 ölçüde hangi vuruş en güçlüdür?",
    displayText: "4/4: 1-2-3-4",
    options: ["2. vuruş", "3. vuruş", "4. vuruş", "1. vuruş"],
    correctAnswer: "1. vuruş",
    explanation: "4/4 ölçüde 1. vuruş en güçlüdür; 3. vuruş ikinci derecede güçlüdür.",
  },
  {
    id: 387,
    category: "rhythm",
    questionText: "3/4 ölçüde hangi vuruş en güçlüdür?",
    displayText: "3/4: 1-2-3",
    options: ["1. vuruş", "2. vuruş", "3. vuruş", "Hepsi eşit"],
    correctAnswer: "1. vuruş",
    explanation: "3/4 ölçüde 1. vuruş (güçlü), 2. ve 3. vuruşlar zayıftır (güçlü-zayıf-zayıf).",
  },
  {
    id: 388,
    category: "rhythm",
    questionText: "Bağlı iki birlik kaç vuruş sürer?",
    displayText: "𝅝~ 𝅝",
    options: ["4", "6", "8", "10"],
    correctAnswer: "8",
    explanation: "Süre bağı ile bağlı iki birlik: 4+4 = 8 vuruş sürer.",
  },
  // fill to 100
  {
    id: 399,
    category: "rhythm",
    questionText: "12/8 ölçüde kaç ana vuruş hissedilir?",
    displayText: "12/8",
    options: ["3", "4", "6", "12"],
    correctAnswer: "4",
    explanation: "12/8 ölçüde 12 sekizlik, 4 gruba (3+3+3+3) bölünür; 4 ana vuruş hissedilir.",
  },
  {
    id: 400,
    category: "rhythm",
    questionText: "Noktalı ikilik + dörtlük = kaç vuruş?",
    displayText: "𝅗. + ♩",
    options: ["3", "4", "5", "6"],
    correctAnswer: "4",
    explanation: "Noktalı ikilik (3 vuruş) + dörtlük (1 vuruş) = 4 vuruş; tam bir 4/4 ölçüsü.",
  },
  {
    id: 403,
    category: "rhythm",
    questionText: "Hangi nota değeri bir sekizlikten daha kısa sürer?",
    displayText: "♪ > ?",
    options: ["Dörtlük", "İkilik", "Onaltılık", "Birlik"],
    correctAnswer: "Onaltılık",
    explanation: "Onaltılık (1/16), sekizliğin (1/8) yarısı kadar sürer.",
  },
  {
    id: 404,
    category: "rhythm",
    questionText: "4/4 ölçüde bir ölçüye kaç ikilik sığar?",
    displayText: "4/4 = ? 𝅗",
    options: ["1", "2", "3", "4"],
    correctAnswer: "2",
    explanation: "4/4 ölçüde 4 vuruş var; ikilik 2 vuruş sürer, dolayısıyla 2 ikilik sığar.",
  },
  {
    id: 409,
    category: "rhythm",
    questionText: "Notanın üstündeki/altındaki bu düz çizgi (tenuto) ne anlama gelir?",
    displayText: "Tenuto (-)",
    options: ["Kısa çal", "Tam değerinde tut", "Legato", "Vurgu yap"],
    correctAnswer: "Tam değerinde tut",
    explanation:
      "Tenuto çizgisi, notanın tam değerinde (hatta biraz daha uzun) tutulmasını ve hafifçe vurgulanmasını belirtir.",
  },
  {
    id: 410,
    category: "rhythm",
    questionText: "Notanın üstündeki/altındaki bu işaret (aksan) ne anlama gelir?",
    displayText: "> Accent",
    options: ["Daha yavaş", "Bu notayı vurgula", "Legato çal", "Nota değerini uzat"],
    correctAnswer: "Bu notayı vurgula",
    explanation: "Aksan işareti, o notanın diğerlerine göre daha güçlü çalınmasını belirtir.",
  },
]

// ─── Musical Terms (100) ─────────────────────────────────────────────────────
const TERMS_QUESTIONS: Question[] = [
  // --- Dynamics ---
  {
    id: 413,
    category: "musical_terms",
    displayText: "p",
    questionText: "'p' (piano) ne anlama gelir?",
    options: ["Çok güçlü", "Güçlü", "Hafif/sessiz", "Çok hafif"],
    correctAnswer: "Hafif/sessiz",
    explanation: 'p = piano (İt. "hafif"). Sessizce, kısık sesle çalınmasını belirtir.',
  },
  {
    id: 414,
    category: "musical_terms",
    displayText: "f",
    questionText: "'f' (forte) ne anlama gelir?",
    options: ["Hafif", "Güçlü", "Çok güçlü", "Orta güçlü"],
    correctAnswer: "Güçlü",
    explanation: 'f = forte (İt. "güçlü"). Yüksek sesle çalınmasını belirtir.',
  },
  {
    id: 415,
    category: "musical_terms",
    displayText: "ff",
    questionText: "'ff' (fortissimo) ne anlama gelir?",
    options: ["Güçlü", "Çok güçlü", "Orta", "Hafif"],
    correctAnswer: "Çok güçlü",
    explanation: 'ff = fortissimo (İt. "çok güçlü"). Olabildiğince yüksek sesle çalınmasını belirtir.',
  },
  {
    id: 416,
    category: "musical_terms",
    displayText: "pp",
    questionText: "'pp' (pianissimo) ne anlama gelir?",
    options: ["Hafif", "Çok hafif", "Orta", "Güçlü"],
    correctAnswer: "Çok hafif",
    explanation: 'pp = pianissimo (İt. "çok hafif"). Olabildiğince sessiz çalınmasını belirtir.',
  },
  {
    id: 417,
    category: "musical_terms",
    displayText: "mf",
    questionText: "'mf' (mezzo forte) ne anlama gelir?",
    options: ["Orta güçlü", "Çok güçlü", "Orta hafif", "Güçlü"],
    correctAnswer: "Orta güçlü",
    explanation: 'mf = mezzo forte (İt. "orta güçlü"). mp ile f arasında bir dinamiktir.',
  },
  {
    id: 418,
    category: "musical_terms",
    displayText: "mp",
    questionText: "'mp' (mezzo piano) ne anlama gelir?",
    options: ["Orta hafif", "Çok hafif", "Orta güçlü", "Güçlü"],
    correctAnswer: "Orta hafif",
    explanation: 'mp = mezzo piano (İt. "orta hafif"). Piano ile mezzo forte arasındaki dinamiktir.',
  },
  {
    id: 419,
    category: "musical_terms",
    displayText: "cresc.",
    questionText: "'Crescendo' (cresc.) ne anlama gelir?",
    options: ["Giderek hafifle", "Giderek kuvvetlen", "Hızlı ve canlı", "Ani dur"],
    correctAnswer: "Giderek kuvvetlen",
    explanation: 'Crescendo (cresc., İt. "büyüyen"), sesin giderek artırılmasını belirtir.',
  },
  {
    id: 420,
    category: "musical_terms",
    displayText: "dim.",
    questionText: "'Diminuendo' (dim.) ne anlama gelir?",
    options: ["Giderek kuvvetlen", "Giderek hafifle", "Hız artır", "Tekrar"],
    correctAnswer: "Giderek hafifle",
    explanation: 'Diminuendo (dim. veya decresc., İt. "küçülen"), sesin giderek azalmasını belirtir.',
  },
  {
    id: 421,
    category: "musical_terms",
    displayText: "sfz",
    questionText: "'sforzando' (sfz) ne anlama gelir?",
    options: ["Giderek güçlen", "Ani kuvvetli vurgu", "Sessizce", "Orta güçte"],
    correctAnswer: "Ani kuvvetli vurgu",
    explanation: 'Sforzando (sfz, İt. "zorla"), tek bir notanın ya da akorun aniden çok güçlü çalınmasını belirtir.',
  },
  {
    id: 423,
    category: "musical_terms",
    displayText: "fff",
    questionText: "'fff' (forte fortissimo) ne anlama gelir?",
    options: ["Güçlü", "Çok güçlü", "Olası en yüksek ses", "Orta güçlü"],
    correctAnswer: "Olası en yüksek ses",
    explanation: "fff, mümkün olan en yüksek dinamik seviyeyi ifade eder; son derece güçlü çalınır.",
  },
  {
    id: 424,
    category: "musical_terms",
    displayText: "ppp",
    questionText: "'ppp' (pianississimo) ne anlama gelir?",
    options: ["Çok hafif", "Orta hafif", "Neredeyse duyulmaz", "Güçlü"],
    correctAnswer: "Neredeyse duyulmaz",
    explanation: "ppp, mümkün olan en sessiz dinamik seviyeyi ifade eder; neredeyse işitilmeyecek kadar kısık.",
  },
  // --- Tempo terms ---
  {
    id: 425,
    category: "musical_terms",
    displayText: "Allegro",
    questionText: "'Allegro' ne demektir?",
    options: ["Çok yavaş", "Yavaş ve ağır", "Hızlı ve canlı", "Orta hızda"],
    correctAnswer: "Hızlı ve canlı",
    explanation: "Allegro (İt. 'neşeli, hızlı'), ♩=120-168 BPM civarı hızlı bir tempodur.",
  },
  {
    id: 426,
    category: "musical_terms",
    displayText: "Andante",
    questionText: "'Andante' ne demektir?",
    options: ["Çok yavaş", "Yürüyüş hızında", "Hızlı", "Çok hızlı"],
    correctAnswer: "Yürüyüş hızında",
    explanation: "Andante (İt. 'yürüyen'), ♩=76-108 BPM civarı orta yavaş tempodur.",
  },
  {
    id: 427,
    category: "musical_terms",
    displayText: "Adagio",
    questionText: "'Adagio' ne demektir?",
    options: ["Hızlı ve canlı", "Yavaş ve ifadeli", "Orta hızda", "Çok hızlı"],
    correctAnswer: "Yavaş ve ifadeli",
    explanation: "Adagio (İt. 'rahat'), ♩=66-76 BPM civarı yavaş ve anlamlı tempodur.",
  },
  {
    id: 428,
    category: "musical_terms",
    displayText: "Presto",
    questionText: "'Presto' ne demektir?",
    options: ["Yavaş", "Orta", "Çok hızlı", "Hızlı"],
    correctAnswer: "Çok hızlı",
    explanation: "Presto (İt. 'çabuk'), ♩=168-200 BPM civarı çok hızlı tempodur.",
  },
  {
    id: 429,
    category: "musical_terms",
    displayText: "Moderato",
    questionText: "'Moderato' ne demektir?",
    options: ["Yavaş", "Orta hızda", "Hızlı", "Çok hızlı"],
    correctAnswer: "Orta hızda",
    explanation: "Moderato (İt. 'ılımlı'), ♩=108-120 BPM civarı orta tempodur.",
  },
  {
    id: 430,
    category: "musical_terms",
    displayText: "Vivace",
    questionText: "'Vivace' ne demektir?",
    options: ["Yavaş", "Orta", "Canlı ve hareketli", "Çok yavaş"],
    correctAnswer: "Canlı ve hareketli",
    explanation: "Vivace (İt. 'canlı'), ♩=156-176 BPM civarı hızlı ve enerjik tempodur.",
  },
  {
    id: 431,
    category: "musical_terms",
    displayText: "Largo",
    questionText: "'Largo' ne demektir?",
    options: ["Çok yavaş ve geniş", "Orta yavaş", "Hızlı", "Orta hızda"],
    correctAnswer: "Çok yavaş ve geniş",
    explanation: "Largo (İt. 'geniş'), ♩=40-60 BPM civarı çok yavaş ve ağır bir tempodur.",
  },
  {
    id: 432,
    category: "musical_terms",
    displayText: "Lento",
    questionText: "'Lento' ne demektir?",
    options: ["Hızlı", "Yavaş", "Çok hızlı", "Orta"],
    correctAnswer: "Yavaş",
    explanation: "Lento (İt. 'yavaş'), ♩=45-60 BPM civarı yavaş tempodur; Largo'ya yakındır.",
  },
  {
    id: 434,
    category: "musical_terms",
    displayText: "Allegretto",
    questionText: "'Allegretto' ne demektir?",
    options: ["Allegro'dan biraz yavaş", "Allegro'dan daha hızlı", "Çok yavaş", "Orta"],
    correctAnswer: "Allegro'dan biraz yavaş",
    explanation: "Allegretto, Allegro ile Moderato arasında bir tempodur (♩=112-120).",
  },
  // --- Articulation ---
  {
    id: 436,
    category: "musical_terms",
    displayText: "Legato",
    questionText: "'Legato' ne demektir?",
    options: ["Kısa ve kesik", "Düzgün ve bağlı", "Güçlü ve vurgulu", "Yavaşlayarak"],
    correctAnswer: "Düzgün ve bağlı",
    explanation: 'Legato (İt. "bağlı"), notaların kesintisiz ve pürüzsüz biçimde çalınmasını belirtir.',
  },
  {
    id: 437,
    category: "musical_terms",
    displayText: "Staccato",
    questionText: "'Staccato' ne demektir?",
    options: ["Bağlı", "Kısa ve kesik", "Yavaş", "Güçlü"],
    correctAnswer: "Kısa ve kesik",
    explanation:
      'Staccato (İt. "ayrılmış"), notanın tam değerinden daha kısa çalınmasını belirtir. Nota üzerinde nokta ile gösterilir.',
  },
  {
    id: 438,
    category: "musical_terms",
    displayText: "Tenuto",
    questionText: "'Tenuto' ne demektir?",
    options: ["Kısa tut", "Tam değerinde tut/hafif vurgula", "Çok güçlü", "Hızla çal"],
    correctAnswer: "Tam değerinde tut/hafif vurgula",
    explanation:
      'Tenuto (İt. "tutulmuş"), notanın tam değerinde tutulmasını ve hafifçe vurgulanmasını belirtir. (-) ile gösterilir.',
  },
  {
    id: 439,
    category: "musical_terms",
    displayText: "Marcato",
    questionText: "'Marcato' ne demektir?",
    options: ["Sessizce", "Belirgin ve vurgulu", "Yavaş", "Bağlı"],
    correctAnswer: "Belirgin ve vurgulu",
    explanation: 'Marcato (İt. "belirgin"), notanın özellikle vurgulanarak çalınmasını belirtir.',
  },
  // --- Expression terms ---
  {
    id: 442,
    category: "musical_terms",
    displayText: "Cantabile",
    questionText: "'Cantabile' ne demektir?",
    options: ["Hızlı ve teknik", "Şarkı söyler gibi", "Sessizce", "Kırık ritimle"],
    correctAnswer: "Şarkı söyler gibi",
    explanation: 'Cantabile (İt. "şarkı söyler gibi"), ifadeli ve akıcı bir çalış tarzını belirtir.',
  },
  {
    id: 443,
    category: "musical_terms",
    displayText: "Dolce",
    questionText: "'Dolce' ne demektir?",
    options: ["Güçlü", "Tatlı ve nazik", "Hızlı", "Kesik"],
    correctAnswer: "Tatlı ve nazik",
    explanation: 'Dolce (İt. "tatlı"), yumuşak ve nazik bir ton rengini belirtir.',
  },
  {
    id: 444,
    category: "musical_terms",
    displayText: "Espressivo",
    questionText: "'Espressivo' ne demektir?",
    options: ["Teknik ve soğuk", "İfadeli", "Çok hızlı", "Yavaşlayarak"],
    correctAnswer: "İfadeli",
    explanation: 'Espressivo (İt. "ifadeli, duygusal"), müziğin derin duyguyla yorumlanmasını belirtir.',
  },
  // --- Form & structure ---
  {
    id: 456,
    category: "musical_terms",
    displayText: "Da Capo (D.C.)",
    questionText: "'Da Capo' (D.C.) ne anlama gelir?",
    options: ["Başa dön", "Sona git", "Tekrarla", "Atla"],
    correctAnswer: "Başa dön",
    explanation: "Da Capo (İt. 'baştan'), parçanın en başından tekrar çalınmasını belirtir.",
  },
  {
    id: 457,
    category: "musical_terms",
    displayText: "Fine",
    questionText: "'Fine' ne anlama gelir?",
    options: ["Başlangıç", "Son/bitiş", "Tekrar", "Yavaşla"],
    correctAnswer: "Son/bitiş",
    explanation: "Fine (İt. 'son'), D.C. veya D.S. tekrarı sırasında parçanın nerede biteceğini gösterir.",
  },
  {
    id: 458,
    category: "musical_terms",
    displayText: "Coda",
    questionText: "'Coda' ne anlama gelir?",
    options: ["Başlangıç bölümü", "Bitiş bölümü", "Tekrar işareti", "Köprü bölümü"],
    correctAnswer: "Bitiş bölümü",
    explanation: "Coda (İt. 'kuyruk'), parçanın sonuna eklenen özel bitiş bölümüdür.",
  },
  // --- Additional terms ---
  {
    id: 465,
    category: "musical_terms",
    displayText: "Fermata",
    questionText: "'Fermata' ne demektir?",
    options: ["Kısa tut", "İstediğin kadar uzat", "Tekrar et", "Atlat"],
    correctAnswer: "İstediğin kadar uzat",
    explanation: "Fermata, nota veya susun kendi değerinden daha uzun tutulacağını gösterir.",
  },
  {
    id: 476,
    category: "musical_terms",
    displayText: "Poco",
    questionText: "'Poco' ne demektir?",
    options: ["Çok", "Az/biraz", "Orta", "Hiç"],
    correctAnswer: "Az/biraz",
    explanation: "Poco (İt. 'biraz'). Örn: 'poco a poco' = yavaş yavaş, giderek.",
  },
  {
    id: 477,
    category: "musical_terms",
    displayText: "Molto",
    questionText: "'Molto' ne demektir?",
    options: ["Az", "Çok", "Orta", "Bazen"],
    correctAnswer: "Çok",
    explanation: "Molto (İt. 'çok'). Örn: 'molto allegro' = çok hızlı, 'molto vivace'.",
  },
  {
    id: 486,
    category: "musical_terms",
    displayText: "Rallentando (rall.)",
    questionText: "'Rallentando' ne demektir?",
    options: ["Hızlan", "Giderek yavaşla", "Sabit kal", "Duraksama"],
    correctAnswer: "Giderek yavaşla",
    explanation: "Rallentando (rall.), ritardando ile eş anlamlıdır; tempo giderek yavaşlar.",
  },
]

// ─── Soruların nota çizimleri (Notation bileşeni) ────────────────────────────
const SCORES: Record<number, string> = {
  323: "w = ? q",
  324: "h = ? q",
  325: "q = ? e",
  326: "e = ? s",
  327: "ts:3/4 = ? e",
  328: "ts:2/4 = ? e",
  329: "ts:2/4 = ? s",
  330: "ts:6/8 = ? q",
  331: "ts:4/4 w ||",
  341: "q.",
  342: "h.",
  343: "ts:4/4 h q q ||",
  344: "q + q = ?",
  345: "q t:÷2 = ?",
  346: "ts:4/4 = ? e",
  347: "ts:4/4 q q q q ||",
  348: "ts:3/4 q q q ||",
  349: "ts:6/8",
  350: "ts:4/4 q q q q = ?",
  351: "ts:C",
  352: "ts:¢",
  354: "(q q@1 q@2 q@3)",
  355: "h ~ h",
  357: "q q h^ ||",
  358: "h q w e",
  362: "ts:6/8 eee eee ||",
  360: "q q q q ||",
  361: "ts:4/4 ? ? ? ? ||",
  363: "ts:6/8 ? ||",
  365: "ts:9/8",
  367: "ts:4/4 = ? s",
  371: "ts:3/4 ? ||",
  372: "ts:3/4 = ? s",
  373: "ee ee = ? q",
  374: "ssss ssss = ? q",
  375: "w = ?",
  376: "ee ee ssss",
  377: "3eee q",
  379: "? t:÷2 = e",
  380: "tx:rit. q q q q",
  381: "tx:accel. q q q q",
  382: "tx:a_tempo q q q q",
  385: "ts:4/4 q | q q q q ||",
  386: "ts:4/4 q q q q ||",
  387: "ts:3/4 q q q ||",
  388: "w ~ w",
  399: "ts:12/8",
  400: "h. + q",
  403: "e t:> ?",
  404: "ts:4/4 = ? h",
  409: "q- q- q- q-",
  410: "q> q> q> q>",
}
for (const q of RHYTHM_QUESTIONS) if (SCORES[q.id]) q.score = SCORES[q.id]

// ─── Diyez / bemol soruları ───────────────────────────────────────────────────
const ALL_ACC_OPTIONS: { label: string; key: string }[] = [
  ...SHARP_NAMES.map((n) => ({ label: accLabel(n, "sharp"), key: accKey(n, "sharp") })),
  ...FLAT_NAMES.map((n) => ({ label: accLabel(n, "flat"), key: accKey(n, "flat") })),
]

function buildAccidentalQuestions(noteArr: StaffNoteData[], clef: "treble" | "bass", startId: number): Question[] {
  const qs: Question[] = []
  let id = startId
  let rot = 0
  for (const acc of ["sharp", "flat"] as Accidental[]) {
    const names = acc === "sharp" ? SHARP_NAMES : FLAT_NAMES
    for (const n of noteArr) {
      if (!names.includes(n.name)) continue
      const key = accKey(n.name, acc)
      const label = accLabel(n.name, acc)
      // Aynı siyah tuşa giden (eş sesli) seçenek yanlış cevap olarak konmaz
      const pool = ALL_ACC_OPTIONS.filter((o) => o.key !== key)
      const picks: string[] = []
      for (let i = 0; picks.length < 3 && i < pool.length * 2; i++) {
        const o = pool[(rot * 3 + i * 2) % pool.length]
        if (!picks.includes(o.label)) picks.push(o.label)
      }
      rot++
      const oct = n.hint.match(/\(([A-G])(\d)\)/)?.[2] ?? "4"
      const sym = SYMBOL[acc]
      const options = [label, ...picks].sort(
        (a, b) => ((a.length + a.charCodeAt(0)) % 7) - ((b.length + b.charCodeAt(0)) % 7),
      )
      qs.push({
        id: id++,
        category: "note_identification",
        clef,
        noteName: n.name,
        noteY: n.y,
        ledgerLines: n.ledger,
        accidental: acc,
        keyName: key,
        questionText: "Nota işaretine dikkat: bu nota hangisi?",
        options,
        correctAnswer: label,
        explanation: `${label} (${LETTER[n.name]}${sym}${oct}): ${n.name} notasını ${acc === "sharp" ? "yarım ses yükseltir" : "yarım ses alçaltır"}. Piyanoda ${blackKeyLabel(key)} siyah tuşudur.`,
      })
    }
  }
  return qs
}

// ─── Generate all questions ──────────────────────────────────────────────────
const trebleQuestions = buildNoteQuestions(TREBLE_NOTES, "treble", 1) // IDs 1-156
const bassQuestions = buildNoteQuestions(BASS_NOTES, "bass", 157) // IDs 157-312

const trebleAccidentals = buildAccidentalQuestions(TREBLE_NOTES, "treble", 601)
const bassAccidentals = buildAccidentalQuestions(BASS_NOTES, "bass", 701)

const trebleExtra = buildNoteQuestions(TREBLE_EXTRA, "treble", 1001)
const bassExtra = buildNoteQuestions(BASS_EXTRA, "bass", 1201)
const trebleExtraAcc = buildAccidentalQuestions(TREBLE_EXTRA, "treble", 1401)
const bassExtraAcc = buildAccidentalQuestions(BASS_EXTRA, "bass", 1501)

export const ALL_QUESTIONS: Question[] = [
  ...trebleQuestions,
  ...bassQuestions,
  ...trebleExtra,
  ...bassExtra,
  ...trebleAccidentals,
  ...bassAccidentals,
  ...trebleExtraAcc,
  ...bassExtraAcc,
  ...RHYTHM_QUESTIONS,
  ...TERMS_QUESTIONS,
]

export { trebleQuestions, bassQuestions }

// ─── Soru seviyeleri ─────────────────────────────────────────────────────────
// 1 = Başlangıç, 2 = Orta, 3 = İleri. Yeni başlayan biri sadece 1. seviyeyi görür.
export type QuestionLevel = 1 | 2 | 3
export const LEVEL_LABELS: Record<QuestionLevel, string> = { 1: "Başlangıç", 2: "Orta", 3: "İleri" }

const ids = (s: string) =>
  new Set(
    s
      .split(/[\s,]+/)
      .filter(Boolean)
      .map(Number),
  )

const RHYTHM_L1 = ids(
  "313 314 315 318 319 320 323 324 331 332 333 334 335 337 338 339 343 344 347 348 357 358 360 361 370 375 386 387",
)
// İleri: bileşik ölçüler (6/8, 9/8, 12/8), alla breve, onaltılık hesapları, triole, ön vuruş, bağlı birlikler
const RHYTHM_L3 = ids("327 329 330 349 352 362 363 365 372 374 377 385 388 399")
const TERMS_L1 = ids("413 414 415 416 417 418 419 420 425 426 427 428 429 431 432 436 437 443 456 457 465")
// İleri: sfz, fff/ppp, tenuto, espressivo, coda, poco/molto, rallentando
const TERMS_L3 = ids("421 423 424 438 444 458 476 477 486")

export function questionLevel(q: Question): QuestionLevel {
  if (q.category === "note_identification") {
    const y = q.noteY ?? 60
    // 2–3 ek çizgideki notalar (diyezli/bemollüler dahil) ileri
    if ((q.ledgerLines?.length ?? 0) >= 2 || y > 95 || y < 25) return 3
    if (q.accidental) return 2
    // Porte içi ve hemen üstü/altı + orta Do başlangıç; diğer ek çizgiler orta
    const middleC = (q.clef === "treble" && y === 90) || (q.clef === "bass" && y === 30)
    return (y >= 35 && y <= 85) || middleC ? 1 : 2
  }
  if (q.category === "rhythm") return RHYTHM_L1.has(q.id) ? 1 : RHYTHM_L3.has(q.id) ? 3 : 2
  if (q.category === "musical_terms") return TERMS_L1.has(q.id) ? 1 : TERMS_L3.has(q.id) ? 3 : 2
  if (q.category === "writing") return q.id >= 1801 ? 2 : 1
  return 1
}

// ─── Nota yazım kuralları ("Hangisi doğru yazılmış?") ─────────────────────────
// Şıklar yazı değil, çizim: optionScores her şıkkın nota dizisini tutar.
const WRITING_LETTERS = ["A", "B", "C", "D"]
function writingQ(
  id: number,
  questionText: string,
  correct: string,
  wrongs: string[],
  explanation: string,
  rot: number,
): Question {
  // Doğru şıkkın yeri soruya göre değişsin
  const all = [...wrongs]
  all.splice(rot % 4, 0, correct)
  const optionScores: Record<string, string> = {}
  all.forEach((sc, i) => (optionScores[WRITING_LETTERS[i]] = sc))
  return {
    id,
    category: "writing",
    questionText,
    options: [...WRITING_LETTERS],
    correctAnswer: WRITING_LETTERS[rot % 4],
    explanation,
    optionScores,
  }
}

const WRITING_QUESTIONS: Question[] = []
{
  let id = 1601
  let rot = 0
  // Sap yönü: orta çizginin altı → sap sağda, yukarı
  for (const off of [-3, -2, -1, 0]) {
    for (const v of ["q", "h"]) {
      WRITING_QUESTIONS.push(
        writingQ(
          id++,
          "Hangisi doğru yazılmış?",
          `${v}@${off}`,
          [`${v}d@${off}`, `${v}x@${off}`, `${v}dx@${off}`],
          "Orta çizginin altındaki notaların sapı notanın sağından yukarı doğru çizilir.",
          rot++,
        ),
      )
    }
  }
  // Sap yönü: orta çizginin üstü → sap solda, aşağı
  for (const off of [2, 3, 4]) {
    for (const v of ["q", "h"]) {
      WRITING_QUESTIONS.push(
        writingQ(
          id++,
          "Hangisi doğru yazılmış?",
          `${v}d@${off}`,
          [`${v}@${off}`, `${v}dx@${off}`, `${v}x@${off}`],
          "Orta çizginin üstündeki notaların sapı notanın solundan aşağı doğru çizilir.",
          rot++,
        ),
      )
    }
  }
  // Sekizlik: kanca sapın ucunda ve sağa doğru
  for (const off of [-3, -1, 2, 4]) {
    const up = off < 1
    const ok = up ? `e@${off}` : `ed@${off}`
    const bad = up ? [`ed@${off}`, `ex@${off}`, `edx@${off}`] : [`e@${off}`, `edx@${off}`, `ex@${off}`]
    WRITING_QUESTIONS.push(
      writingQ(
        id++,
        "Hangi sekizlik doğru yazılmış?",
        ok,
        bad,
        up
          ? "Orta çizginin altındaki sekizliğin sapı sağda ve yukarı, kancası sapın ucunda sağa doğrudur."
          : "Orta çizginin üstündeki sekizliğin sapı solda ve aşağıdır.",
        rot++,
      ),
    )
  }

  // Ölçü toplamı: hangi ölçü doğru doldurulmuş?
  id = 1701
  const MEASURES: [string, string, string[], string][] = [
    ["4/4", "h q q", ["h h q", "q q q", "w q"], "İkilik (2) + dörtlük (1) + dörtlük (1) = 4 vuruş."],
    ["4/4", "q q q q", ["q q q", "h h h", "w h"], "Dört dörtlük = 4 vuruş."],
    ["4/4", "h. q", ["h. h", "h q", "w q"], "Noktalı ikilik (3) + dörtlük (1) = 4 vuruş."],
    ["4/4", "h ee q", ["h ee", "h h ee", "w ee"], "İkilik (2) + iki sekizlik (1) + dörtlük (1) = 4 vuruş."],
    ["3/4", "h q", ["h h", "q q", "w"], "3/4 ölçü 3 vuruştur: ikilik (2) + dörtlük (1) = 3."],
    ["3/4", "h.", ["w", "h", "h h"], "Noktalı ikilik 3 vuruştur ve 3/4 ölçüyü tek başına doldurur."],
    ["3/4", "q q q", ["q q q q", "q q", "h h"], "Üç dörtlük = 3 vuruş."],
    ["2/4", "q q", ["h q", "q", "w"], "2/4 ölçü 2 vuruştur: iki dörtlük = 2."],
    ["2/4", "ee q", ["ee h", "h h", "ee"], "İki sekizlik (1) + dörtlük (1) = 2 vuruş."],
  ]
  for (const [ts, ok, bad, ex] of MEASURES) {
    WRITING_QUESTIONS.push(
      writingQ(
        id++,
        `Hangi ${ts} ölçüsü doğru doldurulmuş?`,
        `ts:${ts} ${ok} ||`,
        bad.map((b) => `ts:${ts} ${b} ||`),
        ex,
        rot++,
      ),
    )
  }

  // Diyez / bemol notanın önüne yazılır
  id = 1801
  for (const [acc, off] of [
    ["#", -2],
    ["b", 0],
    ["#", 2],
    ["b", 4],
    ["#", -1],
    ["b", 3],
  ] as [string, number][]) {
    const d = off > 0 ? "d" : ""
    const dw = off > 0 ? "" : "d" // yanlış sap yönü
    WRITING_QUESTIONS.push(
      writingQ(
        id++,
        acc === "#" ? "Diyez hangisinde doğru yazılmış?" : "Bemol hangisinde doğru yazılmış?",
        `${acc}q${d}@${off}`,
        [`q${d}${acc}@${off}`, `${acc}q${dw}@${off}`, `q${dw}${acc}@${off}`],
        "Diyez ve bemol notanın soluna, notayla aynı çizgi ya da aralığa yazılır. Sap yönü kuralı da geçerlidir.",
        rot++,
      ),
    )
  }
}
ALL_QUESTIONS.push(...WRITING_QUESTIONS)
