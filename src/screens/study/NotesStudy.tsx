// Çalışma › Notalar: porte üstünde notalar, ezber kartları, diyez/bemol
import { Segmented } from "../../ui"
import { pianoColors } from "../../design/piano"
import { useState } from "react"
import MusicalStaff from "../../components/MusicalStaff"
import { playPianoNote } from "../../utils/audio"
import Icon from "../../components/Icons"
import Glyph from "../../components/Glyph"
import { SHARP_NAMES, FLAT_NAMES, SYMBOL, accKey, LETTER, blackKeyLabel, type Accidental } from "../../data/accidentals"

import { alpha, colors, font, palette, radius } from "../../design/tokens"
import { BASS_OCTAVES, BLACK_AFTER, MiniPiano, NOTE_COLORS, PIANO_ORDER, TREBLE_OCTAVES } from "./shared"

// ─── Staff note reference data ─────────────────────────────────────────────────
const TREBLE_REF = [
  {
    name: "Do",
    y: 90,
    ledger: [90],
    label: "Do (C4)",
    desc: "Alttaki 1. ek çizgi — Orta Do",
  },
  { name: "Re", y: 85, ledger: [], label: "Re (D4)", desc: "1. çizgi altı" },
  { name: "Mi", y: 80, ledger: [], label: "Mi (E4)", desc: "1. çizgi" },
  {
    name: "Fa",
    y: 75,
    ledger: [],
    label: "Fa (F4)",
    desc: "1.–2. çizgi arası",
  },
  {
    name: "Sol",
    y: 70,
    ledger: [],
    label: "Sol (G4)",
    desc: "2. çizgi — Anahtar çizgisi",
  },
  {
    name: "La",
    y: 65,
    ledger: [],
    label: "La (A4)",
    desc: "2.–3. çizgi arası",
  },
  { name: "Si", y: 60, ledger: [], label: "Si (B4)", desc: "3. (orta) çizgi" },
  {
    name: "Do",
    y: 55,
    ledger: [],
    label: "Do (C5)",
    desc: "3.–4. çizgi arası",
  },
  { name: "Re", y: 50, ledger: [], label: "Re (D5)", desc: "4. çizgi" },
  {
    name: "Mi",
    y: 45,
    ledger: [],
    label: "Mi (E5)",
    desc: "4.–5. çizgi arası",
  },
  { name: "Fa", y: 40, ledger: [], label: "Fa (F5)", desc: "5. çizgi" },
  { name: "Sol", y: 35, ledger: [], label: "Sol (G5)", desc: "5. çizgi üstü" },
  {
    name: "La",
    y: 30,
    ledger: [30],
    label: "La (A5)",
    desc: "Üstteki 1. ek çizgi",
  },
]

const BASS_REF = [
  {
    name: "Mi",
    y: 90,
    ledger: [90],
    label: "Mi (E2)",
    desc: "Alttaki 1. ek çizgi",
  },
  { name: "Fa", y: 85, ledger: [], label: "Fa (F2)", desc: "1. çizgi altı" },
  { name: "Sol", y: 80, ledger: [], label: "Sol (G2)", desc: "1. çizgi" },
  {
    name: "La",
    y: 75,
    ledger: [],
    label: "La (A2)",
    desc: "1.–2. çizgi arası",
  },
  { name: "Si", y: 70, ledger: [], label: "Si (B2)", desc: "2. çizgi" },
  {
    name: "Do",
    y: 65,
    ledger: [],
    label: "Do (C3)",
    desc: "2.–3. çizgi arası",
  },
  { name: "Re", y: 60, ledger: [], label: "Re (D3)", desc: "3. (orta) çizgi" },
  {
    name: "Mi",
    y: 55,
    ledger: [],
    label: "Mi (E3)",
    desc: "3.–4. çizgi arası",
  },
  { name: "Fa", y: 50, ledger: [], label: "Fa (F3)", desc: "4. çizgi" },
  {
    name: "Sol",
    y: 45,
    ledger: [],
    label: "Sol (G3)",
    desc: "4.–5. çizgi arası",
  },
  { name: "La", y: 40, ledger: [], label: "La (A3)", desc: "5. çizgi" },
  { name: "Si", y: 35, ledger: [], label: "Si (B3)", desc: "5. çizgi üstü" },
  {
    name: "Do",
    y: 30,
    ledger: [30],
    label: "Do (C4)",
    desc: "Üstteki 1. ek çizgi — Orta Do",
  },
]

// ─── Notaları keşfet: tek anahtar, ‹ › ile gezinme, porte + piyano ─────────────
/**
 * Bir anahtarın notalarını tek tek gösterir.
 * mode "natural": doğal notalar · mode "accidentals": ♯ / ♭ seçimiyle diyezli ya da bemollü notalar
 */
export function StaffStudy({ clef, mode = "natural" }: { clef: "treble" | "bass"; mode?: "natural" | "accidentals" }) {
  const [acc, setAcc] = useState<Accidental | null>(mode === "accidentals" ? "sharp" : null)
  const notes = clef === "treble" ? TREBLE_REF : BASS_REF
  const octaves = clef === "treble" ? TREBLE_OCTAVES : BASS_OCTAVES
  const list = notes
    .map((n, i) => ({ ...n, origIdx: i }))
    .filter((n) => (acc === null ? true : (acc === "sharp" ? SHARP_NAMES : FLAT_NAMES).includes(n.name)))
  const [selectedIdx, setSelectedIdx] = useState<number | null>(list[0]?.origIdx ?? 0)
  const selectedNote = selectedIdx !== null ? notes[selectedIdx] : null
  const pos = Math.max(
    0,
    list.findIndex((n) => n.origIdx === selectedIdx),
  )

  function go(delta: number) {
    const next = list[(pos + delta + list.length) % list.length]
    setSelectedIdx(next.origIdx)
    playPianoNote(acc ? accKey(next.name, acc) : next.name, octaves[next.origIdx])
  }

  const arrow = {
    width: 48,
    height: 48,
    flexShrink: 0,
    borderRadius: radius.md,
    border: `1px solid ${colors.border}`,
    background: colors.fillStrong,
    color: colors.textSecondary,
    fontSize: font.size.xl,
    cursor: "pointer",
  } as const

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
      {/* Diyez / bemol dersinde tek seçici */}
      {mode === "accidentals" && (
        <Segmented
          size="sm"
          value={acc ?? "sharp"}
          options={
            [
              ["sharp", "♯ Diyez"],
              ["flat", "♭ Bemol"],
            ] as const
          }
          onChange={(k: Accidental) => {
            setAcc(k)
            const l = notes.filter((n) => (k === "sharp" ? SHARP_NAMES : FLAT_NAMES).includes(n.name))
            setSelectedIdx(notes.indexOf(l[0]))
          }}
        />
      )}

      {/* Gezinme: ‹ Nota › */}
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <button onClick={() => go(-1)} aria-label="Önceki nota" style={arrow}>
          ‹
        </button>
        <div style={{ flex: 1, textAlign: "center", fontFamily: font.family.ui }}>
          <p style={{ fontSize: font.size.xs, color: colors.textSubtle, fontFamily: font.family.mono }}>
            {pos + 1}/{list.length}
          </p>
          <p style={{ fontSize: font.size.sm, color: colors.textMuted }}>Oklarla ya da piyanoda bir tuşa basarak gez</p>
        </div>
        <button onClick={() => go(1)} aria-label="Sonraki nota" style={arrow}>
          ›
        </button>
      </div>

      {/* Detail card with staff + info */}
      {selectedNote ? (
        <div
          style={{
            background: colors.surface,
            borderRadius: radius.lg,
            padding: 20,
            border: `1px solid ${colors.border}`,
            display: "flex",
            flexDirection: "column",
            gap: 16,
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div
              style={{
                width: 44,
                height: 44,
                borderRadius: radius.md,
                background: `${NOTE_COLORS[selectedNote.name] ?? palette.violet600}22`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: font.size.lg,
                fontWeight: font.weight.heavy,
                color: NOTE_COLORS[selectedNote.name] ?? colors.violetText,
                fontFamily: font.family.ui,
              }}
            >
              {selectedNote.name}
              {acc ? SYMBOL[acc] : ""}
            </div>
            <div>
              <div
                style={{
                  color: colors.textSoft,
                  fontWeight: font.weight.bold,
                  fontSize: font.size.md,
                  fontFamily: font.family.ui,
                }}
              >
                {acc
                  ? `${selectedNote.name}${SYMBOL[acc]} (${LETTER[selectedNote.name]}${SYMBOL[acc]}${octaves[selectedIdx!]})`
                  : selectedNote.label}
              </div>
              <div
                style={{
                  color: colors.textMuted,
                  fontSize: font.size.sm,
                  fontFamily: font.family.ui,
                  marginTop: 2,
                }}
              >
                {acc
                  ? `${selectedNote.name} notasının yarım ses ${acc === "sharp" ? "üstü (yükseltir)" : "altı (alçaltır)"}. Piyanoda siyah tuştur: ${acc === "sharp" ? "" : ""}${blackKeyLabel(accKey(selectedNote.name, acc))}.`
                  : selectedNote.desc}
              </div>
            </div>
          </div>

          {/* Mini staff SVG */}
          <div
            style={{
              background: colors.staffPanel,
              border: `1px solid ${colors.border}`,
              borderRadius: radius.md,
              overflow: "hidden",
            }}
          >
            <MusicalStaff
              clef={clef}
              noteY={selectedNote.y}
              ledgerLines={selectedNote.ledger}
              noteName={selectedNote.name}
              accidental={acc ?? undefined}
              showLabel={false}
            />
          </div>

          {/* Piyano üzerinde göster */}
          <MiniPiano
            name={selectedNote.name}
            octave={octaves[selectedIdx!]}
            acc={acc}
            color={NOTE_COLORS[selectedNote.name] ?? palette.violet400}
            // Klavye anahtarın porte aralığını sabit gösterir: Sol Do4–Si5, Fa Do2–Do4
            startOctave={clef === "treble" ? 4 : 2}
            whites={clef === "treble" ? 14 : 15}
            available={(n, o, sharp) =>
              notes.some(
                (x, k) =>
                  x.name === n && octaves[k] === o && (mode === "natural" ? !sharp : sharp && SHARP_NAMES.includes(n)),
              )
            }
            dimBlack={mode === "accidentals"}
            hint={
              mode === "natural"
                ? "Bir beyaz tuşa bas: o nota portede gösterilir. Siyah tuşlar Diyez ve bemol dersinde."
                : "Bir siyah tuşa bas: o nota portede gösterilir."
            }
            onPick={(n, o, sharp) => {
              const i = notes.findIndex((x, k) => x.name === n && octaves[k] === o)
              if (i < 0) return
              // Revize R10: bemol sekmesindeyken siyah tuş sekmeyi diyeze çevirmesin
              if (sharp && !acc) setAcc("sharp")
              setSelectedIdx(i)
            }}
          />
        </div>
      ) : (
        <div
          style={{
            background: colors.surface,
            borderRadius: radius.lg,
            padding: 24,
            border: `1px solid ${colors.border}`,
            textAlign: "center",
            color: colors.textMuted,
            fontSize: font.size.sm,
            fontFamily: font.family.ui,
          }}
        >
          Bir nota seç — sesi çalınır ve porte üzerinde gösterilir
        </div>
      )}
    </div>
  )
}

// ─── Ezber kartı: porte + renkli notalar + aynı renkte klavye ─────────────────
interface FlipCardData {
  title: string
  notes: string
  letters: string[]
  letterColors: string[]
  mnemonic: string
  words: string[][] // [vurgulanan hece, kalan]
  icon: string
  backNoteType: "lines" | "spaces"
  backDotColor: string
  noteNames: string[]
}

function MemoCard({ data, clef }: { data: FlipCardData; clef: "treble" | "bass" }) {
  const lines = data.backNoteType === "lines"
  const ys = lines ? [80, 70, 60, 50, 40] : [75, 65, 55, 45]
  const x0 = 96
  const dx = lines ? 44 : 52
  const octs = clef === "treble" ? (lines ? [4, 4, 4, 5, 5] : [4, 4, 5, 5]) : lines ? [2, 2, 3, 3, 3] : [2, 3, 3, 3]
  const play = (i: number) => playPianoNote(data.noteNames[i], octs[i])
  const playAll = () => data.noteNames.forEach((_, i) => setTimeout(() => play(i), i * 260))
  const colorOf = (i: number) => NOTE_COLORS[data.noteNames[i]] ?? data.backDotColor
  return (
    <div
      style={{
        background: colors.surface,
        borderRadius: radius.lg,
        border: `1px solid ${colors.border}`,
        padding: "14px 14px 16px",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 4 }}>
        <p
          style={{
            color: colors.text,
            fontSize: font.size.md,
            fontWeight: font.weight.bold,
            fontFamily: font.family.ui,
          }}
        >
          {lines ? "Çizgilerdeki notalar" : "Aralıklardaki notalar"}
        </p>
        <button
          onClick={playAll}
          aria-label="Notaları sırayla çal"
          style={{
            display: "flex",
            alignItems: "center",
            gap: 5,
            padding: "6px 10px",
            borderRadius: radius.sm,
            border: "1px solid rgba(139,92,246,0.3)",
            background: alpha(palette.violet500, 0.12),
            color: colors.violetText,
            fontSize: font.size.sm,
            fontWeight: font.weight.bold,
            cursor: "pointer",
          }}
        >
          <Icon name="speaker" size={14} /> Dinle
        </button>
      </div>

      {/* Porte: notalar renkli, her birinin adı altında */}
      <svg
        viewBox="0 0 300 118"
        style={{ width: "100%", display: "block" }}
        role="img"
        aria-label={`${data.title}: ${data.noteNames.join(", ")}`}
      >
        {!lines &&
          ys.map((y, i) => (
            <rect
              key={"b" + i}
              x={x0 + i * dx - 18}
              y={y - 4.5}
              width={36}
              height={9}
              rx={3}
              fill={colorOf(i)}
              opacity={0.14}
            />
          ))}
        {[40, 50, 60, 70, 80].map((y) => (
          <line key={y} x1={44} y1={y} x2={294} y2={y} stroke={colors.staffLine} strokeWidth={1.2} />
        ))}
        {clef === "treble" ? (
          <Glyph name="gClef" x={48} y={70} opacity={0.85} />
        ) : (
          <Glyph name="fClef" x={48} y={50} opacity={0.85} />
        )}
        {ys.map((y, i) => {
          const x = x0 + i * dx
          const c = colorOf(i)
          return (
            <g key={i} onClick={() => play(i)} style={{ cursor: "pointer" }}>
              {lines && <line x1={x - 16} y1={y} x2={x + 16} y2={y} stroke={c} strokeWidth={2.4} />}
              <Glyph name="noteheadBlack" x={x - 5.9} y={y} fill={c} />
              <text
                x={x}
                y={106}
                textAnchor="middle"
                fontSize="14"
                fontWeight="800"
                fill={c}
                style={{ fontFamily: font.family.ui }}
              >
                {data.noteNames[i]}
              </text>
            </g>
          )
        })}
      </svg>

      {/* Tek satır tekerleme */}
      <p
        style={{
          marginTop: 6,
          fontSize: font.size.md,
          color: colors.textSecondary,
          fontFamily: font.family.ui,
          lineHeight: 1.4,
        }}
      >
        {(() => {
          let c = 0
          return data.words.map(([hl, rest], i) => {
            const color = hl ? (data.letterColors[c++] ?? palette.violet400) : undefined
            return (
              <span key={i}>
                {i > 0 && " "}
                {hl && <span style={{ color, fontWeight: font.weight.heavy }}>{hl}</span>}
                {rest}
              </span>
            )
          })
        })()}
      </p>

      {/* Klavyede aynı renkler */}
      <div
        style={{
          position: "relative",
          height: 46,
          marginTop: 10,
          display: "flex",
          borderRadius: radius.xs,
          overflow: "hidden",
        }}
      >
        {PIANO_ORDER.map((n) => {
          const i = data.noteNames.indexOf(n)
          const c = i >= 0 ? colorOf(i) : null
          return (
            <button
              key={n}
              onClick={() => playPianoNote(n, 4)}
              aria-label={`${n} tuşu`}
              style={{
                flex: 1,
                border: `1px solid ${palette.slate400}`,
                borderTop: "none",
                padding: 0,
                cursor: "pointer",
                background: c ?? palette.slate50,
                color: c ? palette.slate900 : colors.textMuted,
                display: "flex",
                alignItems: "flex-end",
                justifyContent: "center",
                paddingBottom: 3,
                fontSize: font.size.xs,
                fontWeight: font.weight.heavy,
                fontFamily: font.family.ui,
              }}
            >
              {n}
            </button>
          )
        })}
        {BLACK_AFTER.map((w) => (
          <div
            key={w}
            style={{
              position: "absolute",
              top: 0,
              height: "52%",
              left: `${((w + 1) * 100) / 7 - (100 / 7) * 0.3}%`,
              width: `${(100 / 7) * 0.6}%`,
              background: pianoColors.diagramBlack,
              borderRadius: "0 0 3px 3px",
              pointerEvents: "none",
            }}
          />
        ))}
      </div>
    </div>
  )
}

// ─── Tab 4: Mnemonics Study ────────────────────────────────────────────────────
const MNEMONICS_DATA = {
  treble: {
    lines: {
      title: "Çizgideki Notalar",
      notes: "Mi · Sol · Si · Re · Fa",
      letters: ["Mi", "Sol", "Si", "Re", "Fa"],
      letterColors: [palette.amber400, palette.green400, palette.violet400, palette.orange400, palette.lime400],
      mnemonic: "Misafir Sola Silgiyi Reçele Fırlattı",
      words: [
        ["Mi", "safir"],
        ["Sol", "a"],
        ["Si", "lgiyi"],
        ["Re", "çele"],
        ["F", "ırlattı"],
      ],
      icon: "note",
      backNoteType: "lines" as const,
      backDotColor: palette.violet600,
      noteNames: ["Mi", "Sol", "Si", "Re", "Fa"],
    },
    spaces: {
      title: "Aralıktaki Notalar",
      notes: "Fa · La · Do · Mi",
      letters: ["Fa", "La", "Do", "Mi"],
      letterColors: [palette.lime400, palette.blue400, palette.red400, palette.amber400],
      mnemonic: "Fare Lahanayı Dolapta Mideledi",
      words: [
        ["Fa", "re"],
        ["La", "hanayı"],
        ["Do", "lapta"],
        ["Mi", "deledi"],
      ],
      icon: "waves",
      backNoteType: "spaces" as const,
      backDotColor: palette.amber500,
      noteNames: ["Fa", "La", "Do", "Mi"],
    },
  },
  bass: {
    lines: {
      title: "Çizgideki Notalar",
      notes: "Sol · Si · Re · Fa · La",
      letters: ["Sol", "Si", "Re", "Fa", "La"],
      letterColors: [palette.green400, palette.violet400, palette.orange400, palette.lime400, palette.blue400],
      mnemonic: "Solucan Simit, Reçel, Fasulye, Lahana yedi",
      words: [
        ["Sol", "ucan"],
        ["Si", "mit,"],
        ["Re", "çel,"],
        ["Fa", "sulye,"],
        ["La", "hana"],
        ["", "yedi"],
      ],
      icon: "leaf",
      backNoteType: "lines" as const,
      backDotColor: palette.violet600,
      noteNames: ["Sol", "Si", "Re", "Fa", "La"],
    },
    spaces: {
      title: "Aralıktaki Notalar",
      notes: "La · Do · Mi · Sol",
      letters: ["La", "Do", "Mi", "Sol"],
      letterColors: [palette.blue400, palette.red400, palette.amber400, palette.green400],
      mnemonic: "Lacivert Dolapta Minik Solucan",
      words: [
        ["La", "civert"],
        ["Do", "lapta"],
        ["Mi", "nik"],
        ["Sol", "ucan"],
      ],
      icon: "note",
      backNoteType: "spaces" as const,
      backDotColor: palette.amber500,
      noteNames: ["La", "Do", "Mi", "Sol"],
    },
  },
}

// ─── Diyez & Bemol ezber bölümü ───────────────────────────────────────────────
const BLACK_KEYS = ["Do#", "Re#", "Fa#", "Sol#", "La#"]

export function AccidentalMemo() {
  const [active, setActive] = useState<string | null>(null)
  const card = {
    background: colors.surface,
    borderRadius: radius.md,
    padding: "14px 16px",
    border: `1px solid ${colors.border}`,
  } as const
  const h = {
    color: colors.textMuted,
    fontSize: font.size.xs,
    fontFamily: font.family.ui,
    fontWeight: font.weight.bold,
    letterSpacing: "0.08em",
    textTransform: "uppercase",
    marginBottom: 10,
  } as const
  const t = {
    color: colors.textSecondary,
    fontSize: font.size.sm,
    fontFamily: font.family.ui,
    lineHeight: 1.6,
  } as const
  const order = (names: string[], sym: string) => (
    <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginTop: 6 }}>
      {names.map((n) => (
        <span
          key={n}
          style={{
            padding: "6px 10px",
            borderRadius: radius.sm,
            background: alpha(palette.violet600, 0.18),
            color: colors.violetTextSoft,
            fontWeight: font.weight.bold,
            fontSize: font.size.sm,
            fontFamily: font.family.ui,
          }}
        >
          {n}
          {sym}
        </span>
      ))}
    </div>
  )
  return (
    <div>
      <div style={h}>Diyez ♯ ve Bemol ♭</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        <div style={card}>
          <div style={{ ...t, fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.textSoft }}>
            Kural
          </div>
          <div style={t}>
            ♯ diyez notayı yarım ses <b>yükseltir</b> (sağdaki tuşa), ♭ bemol <b>alçaltır</b> (soldaki tuşa). İşaret
            notanın önüne yazılır. Mi–Fa ve Si–Do arasında siyah tuş yoktur.
          </div>
        </div>
        <div style={card}>
          <div style={{ ...t, fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.textSoft }}>
            Diyez ve bemol sırası
          </div>
          {order(["Fa", "Do", "Sol", "Re", "La", "Mi", "Si"], "♯")}
          {order(["Si", "Mi", "La", "Re", "Sol", "Do", "Fa"], "♭")}
          <div style={{ ...t, fontSize: font.size.sm, color: colors.textMuted, marginTop: 6 }}>
            Bemol sırası, diyez sırasının tersidir.
          </div>
        </div>
        <div style={card}>
          <div style={{ ...t, fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.textSoft }}>
            Siyah tuşlar — dokun ve dinle
          </div>
          <div style={t}>Her siyah tuşun iki adı vardır (aynı ses).</div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 8 }}>
            {BLACK_KEYS.map((k) => (
              <button
                key={k}
                onClick={() => {
                  setActive(k)
                  playPianoNote(k, 4)
                }}
                style={{
                  flex: "1 1 30%",
                  padding: "12px 6px",
                  borderRadius: radius.md,
                  cursor: "pointer",
                  border: active === k ? `1.5px solid ${palette.violet400}` : `1.5px solid ${colors.border}`,
                  background: active === k ? alpha(palette.violet600, 0.3) : colors.bg,
                  color: colors.textSoft,
                  fontWeight: font.weight.bold,
                  fontSize: font.size.sm,
                  fontFamily: font.family.ui,
                }}
              >
                {blackKeyLabel(k)}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

export function MnemonicsStudy({ search = "", clef }: { search?: string; clef: "treble" | "bass" }) {
  const data = MNEMONICS_DATA[clef]

  const matchSearch = (d: typeof data.lines | typeof data.spaces) => {
    if (!search) return true
    const q = search.toLowerCase()
    return (
      d.notes.toLowerCase().includes(q) ||
      d.mnemonic.toLowerCase().includes(q) ||
      d.title.toLowerCase().includes(q) ||
      d.noteNames.some((n) => n.toLowerCase().includes(q))
    )
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        {matchSearch(data.lines) && <MemoCard data={data.lines} clef={clef} />}
        {matchSearch(data.spaces) && <MemoCard data={data.spaces} clef={clef} />}
        {!matchSearch(data.lines) && !matchSearch(data.spaces) && (
          <div
            style={{
              textAlign: "center",
              color: colors.textMuted,
              fontSize: font.size.sm,
              fontFamily: font.family.ui,
              padding: 32,
            }}
          >
            Arama sonucu bulunamadı
          </div>
        )}
      </div>
    </div>
  )
}
