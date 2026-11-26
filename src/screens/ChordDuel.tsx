// Akor düellosu: aynı telefonda iki kişi karşılıklı oynar. Telefon masada,
// üst yarı karşıdaki oyuncu için ters çevrili. Doğru şıkka ilk basan puanı alır.
import { useEffect, useRef, useState } from "react"
import { chordsUpTo, CHORD_LEVEL_LABELS, type Chord, type ChordLevel } from "../data/chords"
import { effectiveChordLevel } from "../utils/settings"
import { hapticSuccess, hapticError } from "../utils/haptics"
import { playCorrectChime, playWrongBuzz } from "../utils/audio"
import ChordStaffSvg from "../components/ChordStaffSvg"
import { Button, ScreenHeader, Segmented } from "../ui"
import { MultiPiano, litKeys, fitsKeyboard } from "../components/piano/MultiPiano"
import { distractors, shuffle } from "../data/chordQuiz"

import { alpha, colors, font, gradient, palette, radius } from "../design/tokens"
type DuelQ = { chord: Chord; type: "staff" | "keys"; options: Chord[] }
const ROUNDS = 10
const FONT = font.family.ui
const P_COLORS = [palette.violet500, palette.amber500]

function buildDuel(level: ChordLevel): DuelQ[] {
  const pool = chordsUpTo(level)
  return shuffle(pool)
    .slice(0, ROUNDS)
    .map((chord, i) => ({
      chord,
      type: i % 2 === 0 && fitsKeyboard(chord) ? "keys" : "staff",
      options: shuffle([chord, ...distractors(chord, pool)]),
    }))
}

function Half({
  q,
  name,
  score,
  color,
  flipped,
  locked,
  reveal,
  picked,
  onPick,
}: {
  q: DuelQ
  name: string
  score: number
  color: string
  flipped: boolean
  locked: boolean
  reveal: boolean
  picked: string | null
  onPick: (id: string) => void
}) {
  return (
    <div
      style={{
        flex: 1,
        minHeight: 0,
        display: "flex",
        flexDirection: "column",
        gap: 8,
        padding: "10px 14px",
        transform: flipped ? "rotate(180deg)" : undefined,
        borderTop: flipped ? undefined : `3px solid ${color}`,
        borderBottom: flipped ? `3px solid ${color}` : undefined,
      }}
    >
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <span style={{ color, fontSize: font.size.md, fontWeight: font.weight.heavy, fontFamily: FONT }}>{name}</span>
        <span
          style={{
            color: colors.text,
            fontSize: font.size.xl,
            fontWeight: font.weight.heavy,
            fontFamily: font.family.mono,
          }}
        >
          {score}
        </span>
      </div>
      <div
        style={{
          flex: 1,
          minHeight: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: colors.bg,
          borderRadius: radius.md,
          overflow: "hidden",
        }}
      >
        {q.type === "staff" ? (
          <ChordStaffSvg chord={q.chord} maxWidth={230} color={reveal ? palette.green500 : palette.violet500} />
        ) : (
          <div style={{ width: "100%", padding: "4px 6px 18px", transform: "scale(0.92)" }}>
            <MultiPiano
              selected={new Set()}
              lit={litKeys(q.chord)}
              onToggle={() => {}}
              disabled
              correctKeys={[]}
              showResult={false}
            />
          </div>
        )}
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 6 }}>
        {q.options.map((o) => {
          const correct = o.id === q.chord.id
          const mine = picked === o.id
          let bg: string = colors.fill
          let bd: string = colors.border
          if (reveal && correct) {
            bg = alpha(palette.green500, 0.18)
            bd = palette.green500
          } else if (mine) {
            bg = alpha(palette.red500, 0.15)
            bd = palette.red500
          }
          return (
            <button
              key={o.id}
              disabled={locked || reveal}
              onClick={() => onPick(o.id)}
              style={{
                padding: "10px 6px",
                borderRadius: radius.md,
                background: bg,
                border: `1px solid ${bd}`,
                color: colors.textSoft,
                fontSize: font.size.sm,
                fontWeight: font.weight.bold,
                fontFamily: FONT,
                opacity: locked && !reveal ? 0.45 : 1,
                cursor: locked || reveal ? "default" : "pointer",
                lineHeight: 1.2,
              }}
            >
              {o.name}
              <span style={{ display: "block", fontSize: font.size.xs, opacity: 0.7, fontFamily: font.family.mono }}>
                {o.symbol}
              </span>
            </button>
          )
        })}
      </div>
    </div>
  )
}

export default function ChordDuel({ onExit }: { onExit: () => void }) {
  const [names, setNames] = useState(["1. oyuncu", "2. oyuncu"])
  const [level, setLevel] = useState<ChordLevel>(() => effectiveChordLevel())
  const [qs, setQs] = useState<DuelQ[] | null>(null)
  const [idx, setIdx] = useState(0)
  const [scores, setScores] = useState([0, 0])
  const [locked, setLocked] = useState([false, false])
  const [picked, setPicked] = useState<(string | null)[]>([null, null])
  const [reveal, setReveal] = useState(false)
  const [confirmExit, setConfirmExit] = useState(false)
  // Düello sürüyor ve bir şıkka basıldı mı (revize R34)
  const answered = idx > 0 || picked.some((p) => p !== null)
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(
    () => () => {
      if (timer.current) clearTimeout(timer.current)
    },
    [],
  )

  const next = () => {
    timer.current = setTimeout(() => {
      setReveal(false)
      setLocked([false, false])
      setPicked([null, null])
      setIdx((i) => i + 1)
    }, 1600)
  }

  function pick(p: 0 | 1, id: string) {
    if (!qs || reveal || locked[p]) return
    const q = qs[idx]
    const pk = [...picked]
    pk[p] = id
    setPicked(pk)
    if (id === q.chord.id) {
      playCorrectChime()
      hapticSuccess()
      setScores((s) => s.map((v, i) => (i === p ? v + 1 : v)))
      setReveal(true)
      next()
    } else {
      playWrongBuzz()
      hapticError()
      const lk = [...locked]
      lk[p] = true
      setLocked(lk)
      // İkisi de yanlışsa doğruyu göster, sonraki soruya geç
      if (lk[0] && lk[1]) {
        setReveal(true)
        next()
      }
    }
  }

  const screen = {
    position: "absolute",
    inset: 0,
    zIndex: 80,
    background: colors.bg,
    display: "flex",
    flexDirection: "column",
    fontFamily: FONT,
  } as const

  // ── Kurulum ──
  if (!qs)
    return (
      <div style={{ ...screen, padding: "20px 20px 24px", gap: 14 }}>
        <ScreenHeader title="Akor düellosu" onBack={onExit} flush />
        <p style={{ fontSize: font.size.sm, color: colors.textMuted, lineHeight: 1.5 }}>
          Telefonu ikinizin arasına, masaya koyun. Ekranın iki yarısı var, her biri bir oyuncunun. Doğru akora ilk basan
          puanı alır. Yanlış basan o soruda bir daha basamaz. {ROUNDS} soru.
        </p>
        {[0, 1].map((i) => (
          <input
            key={i}
            value={names[i]}
            onChange={(e) => setNames((n) => n.map((v, j) => (j === i ? e.target.value.slice(0, 14) : v)))}
            aria-label={`${i + 1}. oyuncunun adı`}
            style={{
              padding: "14px 16px",
              borderRadius: radius.md,
              fontSize: font.size.md,
              fontFamily: FONT,
              color: colors.text,
              background: colors.fillStrong,
              border: `1.5px solid ${P_COLORS[i]}`,
              outline: "none",
            }}
          />
        ))}
        <p style={{ fontSize: font.size.md, fontWeight: font.weight.semibold, color: colors.text, marginTop: 6 }}>
          Akor seviyesi
        </p>
        <Segmented
          columns={4}
          size="sm"
          value={level}
          options={([1, 2, 3, 4] as ChordLevel[]).map((l) => [l, CHORD_LEVEL_LABELS[l]] as const)}
          onChange={setLevel}
        />
        <button
          onClick={() => {
            setQs(buildDuel(level))
            setIdx(0)
            setScores([0, 0])
          }}
          style={{
            marginTop: "auto",
            padding: 16,
            borderRadius: radius.lg,
            fontSize: font.size.md,
            fontWeight: font.weight.bold,
            background: gradient.primaryFlat,
            color: colors.onPrimary,
            border: "none",
            cursor: "pointer",
          }}
        >
          Başlayalım
        </button>
      </div>
    )

  // ── Sonuç ──
  if (idx >= qs.length) {
    const w = scores[0] === scores[1] ? -1 : scores[0] > scores[1] ? 0 : 1
    return (
      <div
        style={{ ...screen, alignItems: "center", justifyContent: "center", padding: 24, gap: 10, textAlign: "center" }}
      >
        <p style={{ fontSize: font.size.md, color: colors.textMuted }}>Düello bitti</p>
        <p
          style={{
            fontSize: font.size.xxl,
            fontWeight: font.weight.heavy,
            color: w === -1 ? colors.text : P_COLORS[w],
          }}
        >
          {w === -1 ? "Berabere!" : `${names[w]} kazandı!`}
        </p>
        <p
          style={{
            fontSize: font.size.xl,
            fontWeight: font.weight.heavy,
            color: colors.text,
            fontFamily: font.family.mono,
          }}
        >
          {scores[0]} – {scores[1]}
        </p>
        <div style={{ display: "flex", gap: 10, width: "100%", maxWidth: 320, marginTop: 16 }}>
          <button
            onClick={onExit}
            style={{
              flex: 1,
              padding: 14,
              borderRadius: radius.md,
              fontSize: font.size.md,
              fontWeight: font.weight.bold,
              background: colors.fillStrong,
              color: colors.textSecondary,
              border: `1px solid ${colors.border}`,
              cursor: "pointer",
            }}
          >
            Çık
          </button>
          <button
            onClick={() => {
              setQs(buildDuel(level))
              setIdx(0)
              setScores([0, 0])
            }}
            style={{
              flex: 1,
              padding: 14,
              borderRadius: radius.md,
              fontSize: font.size.md,
              fontWeight: font.weight.bold,
              background: gradient.primaryFlat,
              color: colors.onPrimary,
              border: "none",
              cursor: "pointer",
            }}
          >
            Rövanş
          </button>
        </div>
      </div>
    )
  }

  // ── Oyun ──
  const q = qs[idx]
  return (
    <div style={screen}>
      <Half
        q={q}
        name={names[1]}
        score={scores[1]}
        color={P_COLORS[1]}
        flipped
        locked={locked[1]}
        reveal={reveal}
        picked={picked[1]}
        onPick={(id) => pick(1, id)}
      />
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "4px 14px",
          background: colors.fill,
        }}
      >
        {/* Turdan çık: ✕ (revize R16, R34); hiç şıkka basılmadıysa sormadan çıkar */}
        <button
          data-back
          data-answered={answered ? "1" : undefined}
          aria-label="Turdan çık"
          onClick={() => (answered ? setConfirmExit(true) : onExit())}
          style={{
            width: 44,
            height: 44,
            margin: "4px 0",
            borderRadius: radius.md,
            background: colors.fillStrong,
            border: `1px solid ${colors.border}`,
            color: colors.textMuted,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: "pointer",
          }}
        >
          <svg
            width={18}
            height={18}
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth={2.5}
            strokeLinecap="round"
            aria-hidden="true"
          >
            <path d="M6 6l12 12M18 6L6 18" />
          </svg>
        </button>
        <span
          style={{
            fontSize: font.size.xs,
            fontWeight: font.weight.bold,
            color: colors.textMuted,
            fontFamily: font.family.mono,
          }}
        >
          {idx + 1}/{qs.length} · {q.type === "staff" ? "portedeki akor" : "basılı tuşlar"}
        </span>
        <span style={{ width: 44 }} />
      </div>
      <Half
        q={q}
        name={names[0]}
        score={scores[0]}
        color={P_COLORS[0]}
        flipped={false}
        locked={locked[0]}
        reveal={reveal}
        picked={picked[0]}
        onPick={(id) => pick(0, id)}
      />

      {/* Çıkış onayı (diğer turlardaki gibi) */}
      {confirmExit && (
        <div
          role="dialog"
          aria-modal="true"
          data-exit-open
          aria-label="Düellodan çık"
          style={{
            position: "absolute",
            inset: 0,
            zIndex: 90,
            background: colors.scrim,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: 24,
          }}
        >
          <div
            className="animate-pop-in"
            style={{
              width: "100%",
              maxWidth: 340,
              padding: 20,
              borderRadius: radius.lg,
              background: colors.surface,
              border: `1px solid ${colors.border}`,
              textAlign: "center",
            }}
          >
            <p style={{ fontSize: font.size.lg, fontWeight: font.weight.heavy, color: colors.text }}>
              Düellodan çıkılsın mı?
            </p>
            <p style={{ fontSize: font.size.sm, color: colors.textMuted, marginTop: 6, marginBottom: 16 }}>
              Skor {scores[0]} – {scores[1]}. Çıkarsan düello yarıda kalır.
            </p>
            <div style={{ display: "flex", gap: 10 }}>
              <Button data-back variant="primary" style={{ flex: 1 }} onClick={() => setConfirmExit(false)}>
                Devam et
              </Button>
              <Button variant="secondary" style={{ flex: 1 }} onClick={onExit}>
                Çık
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
