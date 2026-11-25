// Çalışma dersleri: Çalışma listesi bu kayıttan çizilir, her ders kendi ekranında açılır.
// Yeni bir ders eklemek için buraya bir satır eklemek yeterli.
import type { ReactNode } from "react"
import { DottedCard, NoteTree, RestsCard, ChordMemoVisual } from "../../components/MemoVisuals"
import { CHORD_LEVEL_LABELS } from "../../data/chords"
import { category } from "../../design/tokens"
import type { IconName } from "../../components/Icons"
import { AccidentalMemo, MnemonicsStudy, StaffStudy } from "./NotesStudy"
import { RhythmMemo } from "./RhythmStudy"
import { ChordsStudy, LEVEL_HELP } from "./ChordsStudy"
import { TERM_GROUPS, TermsStudy } from "./TermsStudy"

export type Lesson = {
  id: string
  section: "Notalar" | "Ritim" | "Akorlar" | "Terimler"
  title: string
  sub: string
  icon: IconName
  color: string
  render: () => ReactNode
}

const col = { gap: 16, display: "flex", flexDirection: "column" } as const

export const LESSONS: Lesson[] = [
  // ── Notalar
  {
    id: "notes-treble",
    section: "Notalar",
    title: "Sol anahtarı notaları",
    sub: "Portedeki yeri, piyanodaki tuşu",
    icon: "note",
    color: category.treble.base,
    render: () => <StaffStudy clef="treble" />,
  },
  {
    id: "notes-bass",
    section: "Notalar",
    title: "Fa anahtarı notaları",
    sub: "Sol el notaları, portede ve piyanoda",
    icon: "note",
    color: category.bass.base,
    render: () => <StaffStudy clef="bass" />,
  },
  {
    id: "mnemonic-treble",
    section: "Notalar",
    title: "Kolay hatırla: Sol anahtarı",
    sub: "Misafir Sola Silgiyi Reçele Fırlattı",
    icon: "bookmark",
    color: category.treble.base,
    render: () => <MnemonicsStudy clef="treble" />,
  },
  {
    id: "mnemonic-bass",
    section: "Notalar",
    title: "Kolay hatırla: Fa anahtarı",
    sub: "Solucan Simit, Reçel, Fasulye, Lahana yedi",
    icon: "bookmark",
    color: category.bass.base,
    render: () => <MnemonicsStudy clef="bass" />,
  },
  {
    id: "accidentals",
    section: "Notalar",
    title: "Diyez ve bemol",
    sub: "Siyah tuşlar, ♯ ve ♭ sırası",
    icon: "piano",
    color: category.accidentals.base,
    render: () => (
      <div style={col}>
        <StaffStudy clef="treble" mode="accidentals" />
        <AccidentalMemo />
      </div>
    ),
  },
  // ── Ritim
  {
    id: "rhythm-values",
    section: "Ritim",
    title: "Nota değerleri",
    sub: "Birlik, ikilik, dörtlük… kaç vuruş?",
    icon: "waves",
    color: category.rhythm.base,
    render: () => (
      <div style={col}>
        <RhythmMemo part="learn" />
        <NoteTree />
      </div>
    ),
  },
  {
    id: "rhythm-rests",
    section: "Ritim",
    title: "Sus işaretleri",
    sub: "Her notanın aynı süren bir susu var",
    icon: "waves",
    color: category.rhythm.base,
    render: () => <RestsCard />,
  },
  {
    id: "rhythm-dotted",
    section: "Ritim",
    title: "Noktalı notalar",
    sub: "Nokta, notaya yarısı kadar süre ekler",
    icon: "waves",
    color: category.rhythm.base,
    render: () => <DottedCard />,
  },
  // ── Akorlar
  {
    id: "chords-build",
    section: "Akorlar",
    title: "Majör ve minör nasıl kurulur",
    sub: "Yarım ses sayarak akor formülleri",
    icon: "piano",
    color: category.chords.base,
    render: () => <ChordMemoVisual />,
  },
  ...([1, 2, 3, 4] as const).map((l): Lesson => ({
    id: `chords-${l}`,
    section: "Akorlar",
    title: `Akor kartları: ${CHORD_LEVEL_LABELS[l]}`,
    sub: LEVEL_HELP[l],
    icon: "piano",
    color: category.chords.base,
    render: () => <ChordsStudy level={l} />,
  })),
  // ── Terimler
  ...TERM_GROUPS.map((g): Lesson => ({
    id: `terms-${g.group}`,
    section: "Terimler",
    title: g.group,
    sub: g.sample,
    icon: "type",
    color: category.terms.base,
    render: () => <TermsStudy group={g.group} />,
  })),
]

export const lessonById = (id: string) => LESSONS.find((l) => l.id === id)
