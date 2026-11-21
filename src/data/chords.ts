// Akor motoru: akorları kök + türden üretir, doğru yazımla (C# minör = Do# Mi Sol#)
// porte konumlarını ve piyano tuşlarını hesaplar.
//
// Seviyeler (piyano öğretmeninin önerisi):
//   1 Başlangıç: doğal köklü majör ve minör
//   2 Orta:      ara seslerin majör ve minörleri (Do# minör, Si♭ majör…)
//   3 İleri:     7'li akorlar (majör 7, dominant 7, minör 7)
//   4 Uzman:     dim, aug, m7♭5, dim7, sus2, sus4, 9'lu, 13'lü

export type ChordLevel = 1 | 2 | 3 | 4
export const CHORD_LEVEL_LABELS: Record<ChordLevel, string> = { 1: "Başlangıç", 2: "Orta", 3: "İleri", 4: "Uzman" }

const LETTERS = ["C", "D", "E", "F", "G", "A", "B"] as const
const LETTER_PC = [0, 2, 4, 5, 7, 9, 11]
const TR: Record<string, string> = { C: "Do", D: "Re", E: "Mi", F: "Fa", G: "Sol", A: "La", B: "Si" }
// Piyano klavyesindeki tuş adları (siyah tuşlar diyez adıyla)
export const PC_KEY = ["Do", "Do#", "Re", "Re#", "Mi", "Fa", "Fa#", "Sol", "Sol#", "La", "La#", "Si"]

const ACC_TXT: Record<number, string> = { [-2]: "♭♭", [-1]: "♭", 0: "", 1: "#", 2: "##" }

// Akor türü: aralıklar (yarım ses) ve harf adımları (üçlü = 2 harf, beşli = 4 …)
interface Quality {
  key: string
  tr: string // Türkçe ad
  sym: string // akor sembolü eki
  semis: number[]
  steps: number[]
  formula: string
  level: ChordLevel
}

const Q: Quality[] = [
  {
    key: "maj",
    tr: "majör",
    sym: "",
    semis: [0, 4, 7],
    steps: [0, 2, 4],
    formula: "Kök + büyük üçlü (4 yarım ses) + küçük üçlü (3 yarım ses)",
    level: 1,
  },
  {
    key: "min",
    tr: "minör",
    sym: "m",
    semis: [0, 3, 7],
    steps: [0, 2, 4],
    formula: "Kök + küçük üçlü (3 yarım ses) + büyük üçlü (4 yarım ses)",
    level: 1,
  },
  {
    key: "maj7",
    tr: "majör 7",
    sym: "maj7",
    semis: [0, 4, 7, 11],
    steps: [0, 2, 4, 6],
    formula: "Majör akor + büyük yedili (kökten 11 yarım ses)",
    level: 3,
  },
  {
    key: "7",
    tr: "dominant 7",
    sym: "7",
    semis: [0, 4, 7, 10],
    steps: [0, 2, 4, 6],
    formula: "Majör akor + küçük yedili (kökten 10 yarım ses)",
    level: 3,
  },
  {
    key: "m7",
    tr: "minör 7",
    sym: "m7",
    semis: [0, 3, 7, 10],
    steps: [0, 2, 4, 6],
    formula: "Minör akor + küçük yedili (kökten 10 yarım ses)",
    level: 3,
  },
  {
    key: "dim",
    tr: "eksik",
    sym: "dim",
    semis: [0, 3, 6],
    steps: [0, 2, 4],
    formula: "İki küçük üçlü üst üste (3 + 3 yarım ses)",
    level: 4,
  },
  {
    key: "aug",
    tr: "artık",
    sym: "aug",
    semis: [0, 4, 8],
    steps: [0, 2, 4],
    formula: "İki büyük üçlü üst üste (4 + 4 yarım ses)",
    level: 4,
  },
  {
    key: "m7b5",
    tr: "yarı eksik",
    sym: "m7♭5",
    semis: [0, 3, 6, 10],
    steps: [0, 2, 4, 6],
    formula: "Eksik akor + küçük yedili (kökten 10 yarım ses)",
    level: 4,
  },
  {
    key: "dim7",
    tr: "eksik 7",
    sym: "dim7",
    semis: [0, 3, 6, 9],
    steps: [0, 2, 4, 6],
    formula: "Dört küçük üçlü: her ses bir öncekinden 3 yarım ses yukarıda",
    level: 4,
  },
  {
    key: "sus2",
    tr: "sus2",
    sym: "sus2",
    semis: [0, 2, 7],
    steps: [0, 1, 4],
    formula: "Üçlü yerine ikili: kök + 2 yarım ses + 5 yarım ses",
    level: 4,
  },
  {
    key: "sus4",
    tr: "sus4",
    sym: "sus4",
    semis: [0, 5, 7],
    steps: [0, 3, 4],
    formula: "Üçlü yerine dörtlü: kök + 5 yarım ses + 2 yarım ses",
    level: 4,
  },
  {
    key: "9",
    tr: "9'lu",
    sym: "9",
    semis: [0, 4, 7, 10, 14],
    steps: [0, 2, 4, 6, 8],
    formula: "Dominant 7 + büyük dokuzlu (kökün bir oktav üstündeki ikili)",
    level: 4,
  },
  {
    key: "13",
    tr: "13'lü",
    sym: "13",
    semis: [0, 4, 10, 21],
    steps: [0, 2, 6, 12],
    formula: "Kök, üçlü, küçük yedili ve on üçlü (altılı); piyanoda genelde beşli ve dokuzlu atlanır",
    level: 4,
  },
]

export interface ChordNote {
  letter: number // 0..6 (C..B)
  acc: number // -2..2
  octave: number
  pc: number
}

export interface Chord {
  id: string
  level: ChordLevel
  root: string // 'C#'
  quality: string
  name: string // 'Do# minör'
  symbol: string // 'C#m'
  label: string // 'Do# minör (C#m)'
  notes: ChordNote[]
  noteNames: string[] // ['Do#', 'Mi', 'Sol#']
  pcs: number[]
  semis: number[] // kökten yarım ses uzaklıkları
  rootPc: number
  keys: string[] // piyano tuşları
  formula: string
}

function spell(letterIdx: number, acc: number, q: Quality, octave: number): ChordNote[] {
  const rootPc = (LETTER_PC[letterIdx] + acc + 12) % 12
  return q.semis.map((semi, i) => {
    const stepAbs = letterIdx + q.steps[i]
    const l = stepAbs % 7
    const oct = octave + Math.floor(stepAbs / 7)
    const targetAbs = LETTER_PC[letterIdx] + acc + semi // kökten mutlak yarım ses
    const natAbs = LETTER_PC[l] + 12 * Math.floor(stepAbs / 7)
    let a = targetAbs - natAbs
    while (a > 6) a -= 12
    while (a < -6) a += 12
    return { letter: l, acc: a, octave: oct, pc: (rootPc + semi) % 12 }
  })
}

export function noteName(n: { letter: number; acc: number }) {
  return TR[LETTERS[n.letter]] + ACC_TXT[n.acc]
}
function make(root: string, qKey: string, level: ChordLevel): Chord {
  const q = Q.find((x) => x.key === qKey)!
  const letterIdx = LETTERS.indexOf(root[0] as (typeof LETTERS)[number])
  const acc = root.includes("#") ? 1 : root.includes("b") ? -1 : 0
  // Porteye sığsın: yüksek köklerde bir oktav aşağıdan başla
  const octave = letterIdx >= 4 && q.semis[q.semis.length - 1] > 12 ? 3 : 4
  const notes = spell(letterIdx, acc, q, octave)
  const rootTr = TR[root[0]] + (acc === 1 ? "#" : acc === -1 ? "♭" : "")
  const rootSym = root[0] + (acc === 1 ? "#" : acc === -1 ? "♭" : "")
  const name = `${rootTr} ${q.tr}`
  const symbol = rootSym + q.sym
  const pcs = notes.map((n) => n.pc)
  return {
    id: root + qKey,
    level,
    root,
    quality: qKey,
    name,
    symbol,
    label: `${name} (${symbol})`,
    notes,
    noteNames: notes.map(noteName),
    pcs,
    semis: q.semis,
    rootPc: notes[0].pc,
    keys: [...new Set(pcs)].map((p) => PC_KEY[p]),
    formula: q.formula,
  }
}

const NATURALS = ["C", "D", "E", "F", "G", "A", "B"]

export const ALL_CHORDS: Chord[] = [
  // 1 · Başlangıç
  ...NATURALS.map((r) => make(r, "maj", 1)),
  ...NATURALS.map((r) => make(r, "min", 1)),
  // 2 · Orta: ara sesler
  ...["Db", "Eb", "F#", "Ab", "Bb"].map((r) => make(r, "maj", 2)),
  ...["C#", "Eb", "F#", "G#", "Bb"].map((r) => make(r, "min", 2)),
  // 3 · İleri: 7'liler
  ...["C", "D", "E", "F", "G", "A", "Bb", "Eb"].map((r) => make(r, "maj7", 3)),
  ...["C", "D", "E", "F", "G", "A", "B", "Bb"].map((r) => make(r, "7", 3)),
  ...["C", "D", "E", "F", "G", "A", "B"].map((r) => make(r, "m7", 3)),
  // 4 · Uzman
  ...["C", "D", "E", "F#", "G", "A", "B"].map((r) => make(r, "dim", 4)),
  ...["C", "D", "E", "F", "G", "A"].map((r) => make(r, "aug", 4)),
  ...["C", "D", "E", "F#", "G", "A", "B"].map((r) => make(r, "m7b5", 4)),
  ...["C", "D", "E", "G", "A", "B"].map((r) => make(r, "dim7", 4)),
  ...["C", "D", "E", "F", "G", "A"].map((r) => make(r, "sus2", 4)),
  ...["C", "D", "E", "F", "G", "A"].map((r) => make(r, "sus4", 4)),
  ...["C", "D", "F", "G", "A"].map((r) => make(r, "9", 4)),
  ...["C", "D", "F", "G"].map((r) => make(r, "13", 4)),
]

export function chordsUpTo(level: ChordLevel) {
  return ALL_CHORDS.filter((c) => c.level <= level)
}

// Porte konumu: sol anahtarında Do4 = y 90, her harf adımı 5 birim yukarı
export function staffY(n: ChordNote) {
  return 90 - (n.octave * 7 + n.letter - 28) * 5
}

// Aynı tuş kümesine sahip ama farklı adlı akorlar (ör. C6 / Am7) yanlış şık olmasın
export function samePcs(a: Chord, b: Chord) {
  const x = [...new Set(a.pcs)].sort().join()
  const y = [...new Set(b.pcs)].sort().join()
  return x === y
}

// Akor sembolünü yarım ses numarasından yaz (diyezli ya da bemollü)
const SHARP_SYM = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
const FLAT_SYM = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
function symAt(c: Chord, semi: number) {
  const flat = c.root.includes("b") || c.root === "F" || (c.quality === "min" && ["D", "G", "C", "F"].includes(c.root))
  return (flat ? FLAT_SYM : SHARP_SYM)[(c.rootPc + semi + 12) % 12]
}

// Akorun sık geçtiği kısa dizi (örnek)
export function progressionsFor(c: Chord): string[] {
  const r = (s: number, suf = "") => symAt(c, s) + suf
  switch (c.quality) {
    case "maj":
      return [`${r(0)} – ${r(7)} – ${r(9, "m")} – ${r(5)}`, `${r(0)} – ${r(5)} – ${r(7)} – ${r(0)}`]
    case "min":
      return [`${r(0, "m")} – ${r(8)} – ${r(3)} – ${r(10)}`, `${r(0, "m")} – ${r(5, "m")} – ${r(7)} – ${r(0, "m")}`]
    case "maj7":
      return [`${r(0, "maj7")} – ${r(9, "m7")} – ${r(2, "m7")} – ${r(7, "7")}`]
    case "7":
      return [`${r(0, "7")} → ${r(5)}  (dominant çözülür)`, `${r(-5, "m7")} – ${r(0, "7")} – ${r(5, "maj7")}`]
    case "m7":
      return [`${r(0, "m7")} – ${r(5, "7")} – ${r(10, "maj7")}  (ii–V–I)`]
    case "dim":
      return [`${r(0, "dim")} → ${r(1)}  (yarım ses yukarı çözülür)`]
    case "m7b5":
      return [`${r(0, "m7♭5")} – ${r(5, "7")} – ${r(10, "m")}  (minör ii–V–i)`]
    case "sus4":
      return [`${r(0, "sus4")} → ${r(0)}  (dörtlü üçlüye iner)`]
    case "sus2":
      return [`${r(0, "sus2")} → ${r(0)}`]
    default:
      return []
  }
}

export const QUALITY_COLOR: Record<string, string> = {
  maj: "#8B5CF6",
  min: "#F87171",
  maj7: "#60A5FA",
  "7": "#F59E0B",
  m7: "#34D399",
  dim: "#FB923C",
  aug: "#EC4899",
  m7b5: "#A78BFA",
  dim7: "#F97316",
  sus2: "#22D3EE",
  sus4: "#2DD4BF",
  "9": "#FBBF24",
  "13": "#C084FC",
}
