// Akor turu: portedeki akor, basılı tuşlar, akoru kur (çoklu tuş seçimi).
import { useState, useEffect, useRef, useCallback } from "react"
import type { RoundAnswer } from "../types"
import { hapticSuccess, hapticError } from "../utils/haptics"
import { playPianoNote } from "../utils/audio"
import Icon from "../components/Icons"
import { ExitConfirm } from "../ui"
import { getSettings, effectiveChordLevel } from "../utils/settings"
import ChordStaffSvg from "../components/ChordStaffSvg"
import RotateHint from "../components/RotateHint"
import { useTwoColumn, useTablet, rotateHintCount, bumpRotateHint } from "../utils/orientation"
import { chordsUpTo, PC_KEY, CHORD_LEVEL_LABELS, type Chord } from "../data/chords"

import { alpha, colors, font, gradient, palette, radius } from "../design/tokens"
import { MultiPiano, fitsKeyboard, litKeys } from "../components/piano/MultiPiano"
import { distractors, shuffle } from "../data/chordQuiz"

interface ChordQuizSessionProps {
  onExit: () => void
  /** Tur bitince her sorunun sonucu; sonuç ekranını App gösterir */
  onComplete: (answers: RoundAnswer[]) => void
}

// Üç soru tipi:
//  staff: portede yazılı akoru tanı (şıklardan seç)
//  keys:  klavyede basılı akoru tanı (şıklardan seç)
//  build: adı verilen akoru klavyede bas
type QType = "staff" | "keys" | "build"

interface ChordQuestion {
  chord: Chord
  type: QType
  options: Chord[]
}

const SESSION = 10

function buildQuestions(): ChordQuestion[] {
  const level = effectiveChordLevel()
  const pool = chordsUpTo(level)
  const current = shuffle(pool.filter((c) => c.level === level))
  const earlier = shuffle(pool.filter((c) => c.level < level))
  // Yeni seviye ile önceki seviyeler yarı yarıya karışsın
  const nCur = earlier.length ? Math.min(5, current.length) : Math.min(SESSION, current.length)
  let picked = [...current.slice(0, nCur), ...earlier.slice(0, SESSION - nCur)]
  if (picked.length < SESSION) picked = [...picked, ...shuffle(pool)].slice(0, SESSION)
  const types: QType[] = shuffle(
    Array.from({ length: SESSION }, (_, i) => (["staff", "keys", "build"] as QType[])[i % 3]),
  )
  const distractorPool = level === 1 ? chordsUpTo(1) : pool
  return shuffle(picked).map((chord, i) => ({
    chord,
    type: types[i] === "keys" && !fitsKeyboard(chord) ? "staff" : types[i],
    options: shuffle([chord, ...distractors(chord, distractorPool)]),
  }))
}

// ─── Countdown ring timer ─────────────────────────────────────────────────────
function CountdownRing({ seconds, running, onTimeout }: { seconds: number; running: boolean; onTimeout: () => void }) {
  const [rem, setRem] = useState(seconds)
  const [timedOut, setTimedOut] = useState(false)
  const ref = useRef<ReturnType<typeof setInterval> | null>(null)
  const onTimeoutRef = useRef(onTimeout)
  onTimeoutRef.current = onTimeout

  useEffect(() => {
    setRem(seconds)
    setTimedOut(false)
  }, [seconds])

  useEffect(() => {
    if (!running) {
      clearInterval(ref.current!)
      return
    }
    ref.current = setInterval(() => {
      setRem((r) => {
        if (r <= 1) {
          clearInterval(ref.current!)
          setTimedOut(true)
          return 0
        }
        return r - 1
      })
    }, 1000)
    return () => clearInterval(ref.current!)
  }, [running])

  useEffect(() => {
    if (timedOut) onTimeoutRef.current()
  }, [timedOut])

  const pct = rem / seconds
  const R = 20,
    circ = 2 * Math.PI * R
  const col = pct > 0.5 ? palette.green500 : pct > 0.25 ? palette.amber500 : palette.red500
  return (
    <div style={{ position: "relative", width: 52, height: 52, flexShrink: 0 }}>
      <svg width={52} height={52} viewBox="0 0 52 52" style={{ transform: "rotate(-90deg)" }}>
        <circle cx={26} cy={26} r={R} fill="none" stroke={colors.fillStrong} strokeWidth={4} />
        <circle
          cx={26}
          cy={26}
          r={R}
          fill="none"
          stroke={col}
          strokeWidth={4}
          strokeLinecap="round"
          strokeDasharray={`${pct * circ} ${circ}`}
          style={{ transition: "stroke-dasharray 0.9s linear, stroke 0.3s", filter: `drop-shadow(0 0 4px ${col}88)` }}
        />
      </svg>
      <span
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: font.size.sm,
          fontWeight: font.weight.heavy,
          color: col,
          fontFamily: font.family.mono,
        }}
      >
        {rem}
      </span>
    </div>
  )
}

// ─── Toast ────────────────────────────────────────────────────────────────────
function Toast({ msg, type }: { msg: string; type: "success" | "error" }) {
  return (
    <div
      className="animate-slide-up"
      style={{
        position: "absolute",
        bottom: 88,
        left: 16,
        right: 16,
        zIndex: 50,
        padding: "12px 16px",
        borderRadius: radius.lg,
        background: type === "success" ? alpha(palette.green500, 0.15) : alpha(palette.red500, 0.15),
        border: `1px solid ${type === "success" ? alpha(palette.green500, 0.4) : alpha(palette.red500, 0.4)}`,
        display: "flex",
        alignItems: "center",
        gap: 10,
        backdropFilter: "blur(12px)",
      }}
    >
      <span style={{ display: "flex", color: type === "success" ? colors.greenText : colors.redText }}>
        <Icon name={type === "success" ? "check" : "x"} size={18} strokeWidth={2.4} />
      </span>
      <p
        style={{
          fontSize: font.size.sm,
          fontWeight: font.weight.bold,
          color: type === "success" ? colors.greenText : colors.redText,
          fontFamily: font.family.ui,
        }}
      >
        {msg}
      </p>
    </div>
  )
}

// ─── Main component ───────────────────────────────────────────────────────────
type AnswerState = "pending" | "correct" | "wrong" | "timeout"

const TYPE_TAG: Record<QType, string> = { staff: "AKOR TANIMA", keys: "TUŞLARDAN BUL", build: "AKORU BAS" }

export default function ChordQuizSession({ onExit, onComplete }: ChordQuizSessionProps) {
  const [questions] = useState(buildQuestions)
  const [level] = useState(() => effectiveChordLevel())
  const [idx, setIdx] = useState(0)
  const [answerState, setAnswerState] = useState<AnswerState>("pending")
  const [selectedKeys, setSelectedKeys] = useState<Set<string>>(new Set())
  const [choiceAnswer, setChoiceAnswer] = useState<string | null>(null)
  const [score, setScore] = useState(0)
  const [timerKey, setTimerKey] = useState(0)
  const [timerOn] = useState(() => getSettings().timer)
  // En az bir soru cevaplandı ya da süresi doldu mu: yoksa ✕ ve kaydırma sormadan çıkar (revize R34)
  const answered = idx > 0 || answerState !== "pending"
  const [toast, setToast] = useState<{ msg: string; type: "success" | "error" } | null>(null)
  const [playingChord, setPlayingChord] = useState(false)
  const [showHint, setShowHint] = useState(false)
  const [showExitConfirm, setShowExitConfirm] = useState(false)
  const correctRef = useRef(0)
  // Sorunun sonucu (idx → cevap) ve sorunun açıldığı an; sonuç ekranı için
  const answersRef = useRef<RoundAnswer[]>([])
  const shownAtRef = useRef(Date.now())
  useEffect(() => {
    shownAtRef.current = Date.now()
  }, [idx])
  const record = (correct: boolean) => {
    if (!answersRef.current[idx])
      answersRef.current[idx] = { questionId: idx, correct, timeMs: Date.now() - shownAtRef.current }
  }
  const land = useTwoColumn()
  const tablet = useTablet()
  const [rotateHint, setRotateHint] = useState(
    () => typeof window !== "undefined" && !!window.matchMedia?.("(pointer: coarse)").matches && rotateHintCount() < 3,
  )
  useEffect(() => {
    if (land) {
      bumpRotateHint(true)
      setRotateHint(false)
    }
  }, [land])

  const q = questions[idx]
  const chord = q.chord
  const pending = answerState === "pending"
  const usesPiano = q.type === "build"

  useEffect(() => {
    setAnswerState("pending")
    setSelectedKeys(new Set())
    setChoiceAnswer(null)
    setToast(null)
    setShowHint(false)
    setTimerKey((k) => k + 1)
  }, [idx])

  function listenChord(arpeggio = false) {
    if (playingChord) return
    setPlayingChord(true)
    const play = (i: number) => playPianoNote(PC_KEY[chord.notes[i].pc], chord.notes[i].octave)
    if (arpeggio) {
      chord.notes.forEach((_, i) => setTimeout(() => play(i), i * 220))
      setTimeout(() => setPlayingChord(false), chord.notes.length * 220 + 300)
    } else {
      chord.notes.forEach((_, i) => play(i))
      setTimeout(() => setPlayingChord(false), 600)
    }
  }

  function toggleKey(noteName: string) {
    setSelectedKeys((prev) => {
      const next = new Set(prev)
      if (next.has(noteName)) next.delete(noteName)
      else next.add(noteName)
      return next
    })
  }

  const advancedRef = useRef(-1)
  const advance = useCallback(() => {
    if (advancedRef.current === idx) return
    advancedRef.current = idx
    setToast(null)
    if (idx + 1 < questions.length) setIdx((i) => i + 1)
    else onComplete(questions.map((_, i) => answersRef.current[i] ?? { questionId: i, correct: false, timeMs: 0 }))
  }, [idx, questions, onComplete])

  const checkAnswer = useCallback(() => {
    let correct: boolean
    if (usesPiano) {
      const sorted = (arr: string[]) => [...arr].sort().join(",")
      correct = sorted([...selectedKeys]) === sorted(chord.keys)
    } else {
      correct = choiceAnswer === chord.id
    }
    setAnswerState(correct ? "correct" : "wrong")
    record(correct)
    if (correct) {
      correctRef.current += 1
      hapticSuccess()
      const pts = 10 // App de doğru başına 10 XP verir (handleChordComplete)
      setScore((s) => s + pts)
      setToast({ msg: `Harika! ${chord.label} (+${pts} XP)`, type: "success" })
      setTimeout(advance, 1500)
    } else {
      hapticError()
    }
  }, [usesPiano, selectedKeys, choiceAnswer, chord, advance])

  const handleTimeout = useCallback(() => {
    if (answerState !== "pending") return
    setAnswerState("timeout")
    record(false)
    hapticError()
  }, [answerState])

  const canCheck = usesPiano ? selectedKeys.size > 0 : choiceAnswer !== null

  const prompt =
    q.type === "staff"
      ? "Portedeki akor hangisi?"
      : q.type === "keys"
        ? "Klavyede basılı akor hangisi?"
        : "Bu akorun tuşlarına bas"

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        height: "100%",
        background: colors.bg,
        fontFamily: font.family.ui,
        overflow: "hidden",
        position: "relative",
      }}
    >
      {/* ── Top bar ── */}
      <div style={{ padding: "14px 16px 10px", display: "flex", alignItems: "center", gap: 10 }}>
        <button
          onClick={() => (answered ? setShowExitConfirm(true) : onExit())}
          data-answered={answered ? "1" : undefined}
          aria-label="Çık"
          data-back
          style={{
            width: 44,
            height: 44,
            borderRadius: radius.sm,
            flexShrink: 0,
            background: colors.fill,
            border: `1px solid ${colors.border}`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: "pointer",
          }}
        >
          <svg
            width={16}
            height={16}
            viewBox="0 0 24 24"
            fill="none"
            stroke={colors.textFaint}
            strokeWidth={2.5}
            strokeLinecap="round"
          >
            <path d="M6 6l12 12M18 6L6 18" />
          </svg>
        </button>

        <div
          style={{
            flex: 1,
            minWidth: 0,
            overflow: "hidden",
            display: "flex",
            alignItems: "center",
            gap: 3,
            justifyContent: "center",
          }}
        >
          {questions.map((_, i) => (
            <div
              key={i}
              style={{
                height: 5,
                borderRadius: radius.pill,
                flexShrink: 1,
                minWidth: 3,
                width: i === idx ? 14 : 5,
                // Cevaplanan akorlar doğruysa yeşil, yanlışsa kırmızı (revize R2)
                background:
                  i < idx
                    ? answersRef.current[i]?.correct
                      ? palette.green500
                      : palette.red500
                    : i === idx
                      ? `linear-gradient(90deg,${palette.violet500},${palette.violet400})`
                      : colors.fillStrong,
                boxShadow: i === idx ? "0 0 8px rgba(139,92,246,0.5)" : "none",
                transition: "all 0.3s",
              }}
            />
          ))}
          <span
            style={{
              fontSize: font.size.sm,
              fontWeight: font.weight.bold,
              color: colors.textMuted,
              fontFamily: font.family.mono,
              marginLeft: 4,
            }}
          >
            {idx + 1}/{questions.length}
          </span>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 6, flexShrink: 0 }}>
          <div
            style={{
              padding: "4px 10px",
              borderRadius: radius.pill,
              background: alpha(palette.violet500, 0.12),
              border: "1px solid rgba(139,92,246,0.25)",
            }}
          >
            <span
              style={{
                fontSize: font.size.sm,
                fontWeight: font.weight.bold,
                color: colors.violetText,
                fontFamily: font.family.mono,
              }}
            >
              {score} XP
            </span>
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflowY: "auto", scrollbarWidth: "none", padding: "0 16px 8px" }}>
        {/* ── Question card ── */}
        <div
          style={{
            background: colors.surface,
            borderRadius: radius.lg,
            padding: "14px 16px 12px",
            border: `1px solid ${colors.border}`,
            marginBottom: 12,
          }}
        >
          <div
            style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 10, gap: 8 }}
          >
            <span
              style={{
                fontSize: font.size.xs,
                fontWeight: font.weight.bold,
                letterSpacing: "0.1em",
                padding: "3px 10px",
                borderRadius: radius.pill,
                background: alpha(palette.violet500, 0.14),
                color: colors.violetText,
                border: "1px solid rgba(139,92,246,0.3)",
                textTransform: "uppercase",
              }}
            >
              {TYPE_TAG[q.type]}
            </span>
            <span
              style={{
                fontSize: font.size.xs,
                fontWeight: font.weight.semibold,
                color: colors.textMuted,
                marginLeft: "auto",
              }}
            >
              {CHORD_LEVEL_LABELS[level]}
            </span>
            {timerOn && <CountdownRing key={timerKey} seconds={15} running={pending} onTimeout={handleTimeout} />}
          </div>

          <div
            style={{
              display: "flex",
              alignItems: "flex-start",
              justifyContent: "space-between",
              gap: 8,
              marginBottom: 10,
            }}
          >
            <p
              style={{
                fontSize: font.size.md,
                fontWeight: font.weight.bold,
                color: colors.textSecondary,
                lineHeight: 1.35,
                flex: 1,
              }}
            >
              {prompt}
            </p>
            <button
              onClick={() => listenChord(true)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 6,
                padding: "7px 12px",
                borderRadius: radius.md,
                flexShrink: 0,
                background: playingChord ? alpha(palette.violet500, 0.25) : alpha(palette.violet500, 0.12),
                border: `1px solid ${playingChord ? alpha(palette.violet500, 0.55) : alpha(palette.violet500, 0.25)}`,
                color: colors.violetText,
                fontSize: font.size.sm,
                fontWeight: font.weight.bold,
                cursor: "pointer",
                transition: "all 0.15s",
              }}
            >
              <Icon name="speaker" size={16} />
              <span>Dinle</span>
            </button>
          </div>

          {q.type === "staff" && (
            <div
              style={{
                background: colors.bg,
                borderRadius: radius.md,
                padding: "6px 8px 0",
                border: `1px solid ${colors.border}`,
                display: "flex",
                justifyContent: "center",
              }}
            >
              <ChordStaffSvg chord={chord} color={answerState === "correct" ? palette.green500 : palette.violet500} />
            </div>
          )}

          {q.type === "keys" && (
            <div style={{ padding: "4px 2px 26px" }}>
              <MultiPiano
                selected={new Set()}
                lit={litKeys(chord)}
                onToggle={() => {}}
                disabled
                correctKeys={[]}
                showResult={false}
              />
            </div>
          )}

          {q.type === "build" && (
            <div
              style={{
                background: colors.bg,
                borderRadius: radius.md,
                padding: "18px 12px",
                border: `1px solid ${colors.border}`,
                textAlign: "center",
              }}
            >
              <p
                style={{
                  fontSize: font.size.xxl,
                  fontWeight: font.weight.heavy,
                  color: colors.text,
                  letterSpacing: "-0.02em",
                }}
              >
                {chord.name}
              </p>
              <p
                style={{
                  fontSize: font.size.lg,
                  fontWeight: font.weight.bold,
                  color: colors.violetText,
                  fontFamily: font.family.mono,
                  marginTop: 2,
                }}
              >
                {chord.symbol}
              </p>
            </div>
          )}

          {answerState !== "pending" && (
            <div style={{ marginTop: 10 }}>
              <button
                onClick={() => setShowHint((h) => !h)}
                style={{
                  fontSize: font.size.sm,
                  fontWeight: font.weight.semibold,
                  color: colors.amberText,
                  background: alpha(palette.amber500, 0.08),
                  border: "1px solid rgba(245,158,11,0.25)",
                  padding: "4px 10px",
                  borderRadius: radius.pill,
                  cursor: "pointer",
                }}
              >
                <Icon name="bulb" size={14} /> {showHint ? "Gizle" : "Formülü Göster"}
              </button>
              {showHint && (
                <div
                  className="animate-slide-up"
                  style={{
                    marginTop: 8,
                    padding: "9px 12px",
                    borderRadius: radius.md,
                    background: alpha(palette.amber500, 0.06),
                    border: "1px solid rgba(245,158,11,0.2)",
                  }}
                >
                  <p style={{ fontSize: font.size.sm, color: colors.amberText, lineHeight: 1.6 }}>
                    <strong>{chord.label}</strong> · {chord.noteNames.join(" – ")}
                    <br />
                    {chord.formula}
                  </p>
                </div>
              )}
            </div>
          )}
        </div>

        {/* ── Şıklar ── */}
        {!usesPiano && (
          <div
            key={`choice-${idx}`}
            style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 9, marginBottom: 14 }}
          >
            {q.options.map((opt) => {
              const isSel = choiceAnswer === opt.id
              const isCorrect = opt.id === chord.id
              let bg: string = colors.fill
              let border: string = colors.border
              let color: string = colors.textSecondary
              let shadow = "none"
              let extraClass = ""
              if (!pending) {
                if (isSel && answerState === "correct") {
                  bg = alpha(palette.green500, 0.14)
                  border = palette.green500
                  color = colors.greenText
                  shadow = "0 0 12px rgba(16,185,129,0.3)"
                  extraClass = "animate-correct-pulse"
                } else if (isSel) {
                  bg = alpha(palette.red500, 0.12)
                  border = palette.red500
                  color = colors.redText
                  shadow = "0 0 12px rgba(239,68,68,0.3)"
                  extraClass = "animate-shake"
                } else if (isCorrect) {
                  bg = alpha(palette.green500, 0.14)
                  border = palette.green500
                  color = colors.greenText
                  shadow = "0 0 12px rgba(16,185,129,0.3)"
                }
              }
              return (
                <button
                  key={opt.id}
                  disabled={!pending}
                  onClick={() => setChoiceAnswer(opt.id)}
                  className={extraClass}
                  style={{
                    padding: "14px 12px",
                    borderRadius: radius.lg,
                    textAlign: "center",
                    minHeight: 60,
                    fontSize: font.size.md,
                    fontWeight: font.weight.bold,
                    cursor: pending ? "pointer" : "default",
                    background: isSel && pending ? alpha(palette.violet500, 0.14) : bg,
                    border: `1px solid ${isSel && pending ? alpha(palette.violet500, 0.4) : border}`,
                    color: isSel && pending ? colors.violetTextSoft : color,
                    boxShadow: isSel && pending ? "0 0 10px rgba(139,92,246,0.25)" : shadow,
                    transition: "all 0.12s",
                    position: "relative",
                    fontFamily: font.family.ui,
                    lineHeight: 1.25,
                  }}
                >
                  {opt.name}
                  <span
                    style={{
                      display: "block",
                      fontSize: font.size.sm,
                      fontWeight: font.weight.semibold,
                      opacity: 0.7,
                      fontFamily: font.family.mono,
                      marginTop: 2,
                    }}
                  >
                    {opt.symbol}
                  </span>
                </button>
              )
            })}
          </div>
        )}

        {/* ── Piyano ile cevap ── */}
        {usesPiano && (
          <div key={`piano-${idx}`}>
            {!land && !tablet && rotateHint && <RotateHint onClose={() => setRotateHint(false)} />}
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 8,
                marginBottom: 10,
                padding: "8px 14px",
                borderRadius: radius.md,
                background: colors.fill,
                border: `1px solid ${colors.border}`,
              }}
            >
              <span
                style={{
                  fontSize: font.size.xs,
                  color: colors.textFaint,
                  fontWeight: font.weight.bold,
                  textTransform: "uppercase",
                  letterSpacing: "0.06em",
                  flexShrink: 0,
                }}
              >
                Seçilen
              </span>
              <div style={{ display: "flex", gap: 5, flex: 1, flexWrap: "wrap" }}>
                {selectedKeys.size === 0 ? (
                  <span style={{ fontSize: font.size.xs, color: colors.textFaint }}>{chord.keys.length} tuşa bas…</span>
                ) : (
                  [...selectedKeys].map((k) => (
                    <span
                      key={k}
                      style={{
                        fontSize: font.size.sm,
                        fontWeight: font.weight.bold,
                        padding: "2px 8px",
                        borderRadius: radius.pill,
                        background: alpha(palette.violet500, 0.15),
                        color: colors.violetText,
                        border: "1px solid rgba(139,92,246,0.35)",
                        fontFamily: font.family.mono,
                      }}
                    >
                      {k}
                    </span>
                  ))
                )}
              </div>
              {selectedKeys.size > 0 && pending && (
                <button
                  onClick={() => setSelectedKeys(new Set())}
                  style={{
                    fontSize: font.size.sm,
                    color: colors.textFaint,
                    background: "none",
                    border: "none",
                    cursor: "pointer",
                    flexShrink: 0,
                  }}
                >
                  ✕ Temizle
                </button>
              )}
            </div>
            <div style={{ padding: "0 2px", paddingBottom: 28 }}>
              <MultiPiano
                selected={selectedKeys}
                onToggle={toggleKey}
                disabled={!pending}
                correctKeys={answerState !== "pending" ? chord.keys : []}
                showResult={!pending}
              />
            </div>
          </div>
        )}
      </div>

      {/* ── Bottom action bar ── */}
      <div
        style={{
          padding: "10px 16px 20px",
          borderTop: `1px solid ${colors.border}`,
          background: colors.overlay,
          backdropFilter: "blur(16px)",
        }}
      >
        {(answerState === "wrong" || answerState === "timeout") && (
          <div
            className="animate-slide-up"
            style={{
              marginBottom: 10,
              padding: "10px 14px",
              borderRadius: radius.md,
              background: alpha(palette.red500, 0.08),
              border: "1px solid rgba(239,68,68,0.22)",
            }}
          >
            <p style={{ fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.redText, marginBottom: 2 }}>
              {answerState === "timeout" ? "Süre doldu. " : ""}Doğru cevap:{" "}
              <span style={{ color: colors.greenText }}>{chord.label}</span>
            </p>
            <p style={{ fontSize: font.size.sm, color: colors.textMuted, lineHeight: 1.5 }}>
              Notalar: {chord.noteNames.join(" – ")}
            </p>
          </div>
        )}
        <button
          disabled={pending && !canCheck}
          onClick={pending ? checkAnswer : advance}
          style={{
            width: "100%",
            height: 52,
            borderRadius: radius.lg,
            fontSize: font.size.md,
            fontWeight: font.weight.heavy,
            cursor: !pending || canCheck ? "pointer" : "default",
            background: !pending || canCheck ? gradient.primaryFlat : colors.fill,
            color: !pending || canCheck ? colors.onPrimary : colors.textFaint,
            border: "none",
            boxShadow: !pending || canCheck ? "0 4px 20px rgba(124,58,237,0.45)" : "none",
            transition: "all 0.2s",
            fontFamily: font.family.ui,
            letterSpacing: "-0.01em",
          }}
        >
          {!pending
            ? idx + 1 >= questions.length
              ? "Turu bitir"
              : "Sıradaki"
            : canCheck
              ? "Kontrol Et ✓"
              : usesPiano
                ? "Tuşlara Bas..."
                : "Seçenek Seç..."}
        </button>
      </div>

      {toast && <Toast msg={toast.msg} type={toast.type} />}

      {showExitConfirm && <ExitConfirm onStay={() => setShowExitConfirm(false)} onExit={onExit} />}
    </div>
  )
}
