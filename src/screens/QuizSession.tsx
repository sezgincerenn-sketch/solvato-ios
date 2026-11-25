// Soru turu ekranı (nota, ritim, terim, nota yazımı): piyano ya da şıklarla cevap, ipucu, süre.
import EarPrompt from "../components/EarPrompt"
import { useState, useEffect, useRef, useCallback } from "react"
import type { Question, SessionResult } from "../types"
import MusicalStaff, { RhythmDisplay, TermDisplay } from "../components/MusicalStaff"
import Notation, { termScore } from "../components/Notation"
import RotateHint from "../components/RotateHint"
import { useTwoColumn, useTablet, rotateHintCount, bumpRotateHint } from "../utils/orientation"
import { playCorrectChime, playWrongBuzz } from "../utils/audio"
import { hapticSuccess, hapticError } from "../utils/haptics"
import { getSettings } from "../utils/settings"
import Icon from "../components/Icons"
import { ExitConfirm } from "../ui"
import { category, type CategoryKey, alpha, colors, font, gradient, palette, radius } from "../design/tokens"
import { QuizPiano } from "../components/piano/QuizPiano"
import type { AnswerState } from "../types"

// Terim sorusu partisyonda nasıl görünüyorsa öyle çizilir. "Hangi terim …" gibi
// ters sorularda ekranda anlam yazar, çizim yapılmaz.
function termScoreFor(q: Question): string | null {
  if (q.category !== "musical_terms" || q.questionText.startsWith("Hangi") || !q.displayText) return null
  return termScore(q.displayText)
}

interface QuizSessionProps {
  questions: Question[]
  timerEnabled: boolean
  timerSeconds: number
  onComplete: (results: SessionResult[]) => void
  onExit: () => void
  noHints?: boolean // oyunlarda ipucu yok
}

// ─── Timer bar ────────────────────────────────────────────────────────────────
function TimerBar({ seconds, onTimeout }: { seconds: number; onTimeout: () => void }) {
  const [remaining, setRemaining] = useState(seconds)
  const ref = useRef<ReturnType<typeof setInterval> | null>(null)
  useEffect(() => {
    setRemaining(seconds)
    ref.current = setInterval(() => {
      setRemaining((r) => {
        if (r <= 1) {
          clearInterval(ref.current!)
          onTimeout()
          return 0
        }
        return r - 1
      })
    }, 1000)
    return () => clearInterval(ref.current!)
  }, [seconds, onTimeout])
  const pct = (remaining / seconds) * 100
  const color = pct > 50 ? palette.green500 : pct > 25 ? palette.amber500 : palette.red500
  return (
    <div className="flex items-center gap-2.5 px-4 pb-2">
      <span
        style={{
          fontSize: font.size.sm,
          fontWeight: font.weight.bold,
          color,
          fontFamily: font.family.mono,
          minWidth: 16,
        }}
      >
        {remaining}
      </span>
      <div className="flex-1 rounded-full overflow-hidden" style={{ height: 3, background: colors.fillStrong }}>
        <div
          style={{
            width: `${pct}%`,
            height: "100%",
            background: color,
            borderRadius: radius.pill,
            transition: "width 1s linear, background 0.3s",
          }}
        />
      </div>
    </div>
  )
}

// ─── Notanın klavyedeki tam yeri (oktavıyla) ─────────────────────────────────
const KB_NAMES = ["Do", "Do#", "Re", "Re#", "Mi", "Fa", "Fa#", "Sol", "Sol#", "La", "La#", "Si"]

const LETTER_PC = [0, 2, 4, 5, 7, 9, 11]

// Sol anahtarında y=90, Fa anahtarında y=30 orta Do (Do4); her 5 birim bir harf
export function noteKeyOf(q: Question): { key: string; octave: number } | null {
  if (q.noteY === undefined || !q.clef) return null
  const idx = 28 + ((q.clef === "treble" ? 90 : 30) - q.noteY) / 5
  const letter = ((idx % 7) + 7) % 7
  const oct = Math.floor(idx / 7)
  const midi = oct * 12 + LETTER_PC[letter] + (q.accidental === "sharp" ? 1 : q.accidental === "flat" ? -1 : 0)
  const o = Math.floor(midi / 12)
  return { key: `${KB_NAMES[((midi % 12) + 12) % 12]}${o}`, octave: o }
}

// ─── Main quiz session ────────────────────────────────────────────────────────
export default function QuizSession({
  questions,
  timerEnabled,
  timerSeconds,
  onComplete,
  onExit,
  noHints,
}: QuizSessionProps) {
  const [idx, setIdx] = useState(0)
  const [answerState, setAnswerState] = useState<AnswerState>("pending")
  const [selectedAnswer, setSelectedAnswer] = useState<string | undefined>()
  const [results, setResults] = useState<SessionResult[]>([])
  const [showExplanation, setShowExplanation] = useState(false)
  const [prefMode] = useState<"piano" | "choice">(() => getSettings().inputMode)
  const [showExitConfirm, setShowExitConfirm] = useState(false)
  const showKeyLabels = getSettings().keyLabels
  const [showHint, setShowHint] = useState(false)
  const land = useTwoColumn()
  const tablet = useTablet()
  // "Yan çevir" ipucu: dokunmatik ekranda, klavyeyle cevaplarken, ilk 3 turda
  const [showRotateHint, setShowRotateHint] = useState(
    () =>
      typeof window !== "undefined" &&
      !!window.matchMedia?.("(pointer: coarse)").matches &&
      getSettings().inputMode === "piano" &&
      rotateHintCount() < 3,
  )
  const closeRotateHint = () => {
    setShowRotateHint(false)
  }
  useEffect(() => {
    if (showRotateHint) bumpRotateHint()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])
  useEffect(() => {
    if (land) {
      bumpRotateHint(true)
      setShowRotateHint(false)
    }
  }, [land])
  useEffect(() => {
    if (!showRotateHint) return
    const t = setTimeout(() => setShowRotateHint(false), 6000)
    return () => clearTimeout(t)
  }, [showRotateHint])
  const [timerKey, setTimerKey] = useState(0)
  const [correctStreak, setCorrectStreak] = useState(0)
  const [showStreakFlare, setShowStreakFlare] = useState(false)
  const startTimeRef = useRef(Date.now())

  const q = questions[idx]
  const isNoteQ = q.category === "note_identification"
  const isRhythmQ = q.category === "rhythm"
  const isTermQ = q.category === "musical_terms"
  const isWritingQ = q.category === "writing"
  const isEarQ = q.category === "ear"
  const inputMode: "piano" | "choice" = isNoteQ ? prefMode : "choice"
  // İki oktavlı klavyede (yan ekran / tablet) cevap oktavıyla birlikte alınır
  const kbOctaves = land ? 3 : tablet ? 2 : 1
  const octaveMode = kbOctaves >= 2 && isNoteQ
  const target = isNoteQ ? noteKeyOf(q) : null
  // Klavye penceresi: Sol anahtarında Do4–Si5, Fa'da Do2–Si3; nota dışarıda kalırsa kaydır
  let kbStart = q.clef === "bass" ? 2 : kbOctaves >= 3 ? 3 : 4
  if (target) {
    if (target.octave < kbStart) kbStart = target.octave
    else if (target.octave > kbStart + kbOctaves - 1) kbStart = target.octave - kbOctaves + 1
  }
  if (!octaveMode) kbStart = 4
  const wrongOctave =
    octaveMode &&
    answerState === "wrong" &&
    !!target &&
    !!selectedAnswer &&
    selectedAnswer.replace(/\d+$/, "") === target.key.replace(/\d+$/, "")
  // Soru türüne göre süre: ritim biraz, terim (uzun metin) çok daha uzun
  const effectiveSeconds = isTermQ
    ? Math.max(timerSeconds * 2, 10)
    : isRhythmQ
      ? Math.ceil(timerSeconds * 1.6)
      : timerSeconds

  useEffect(() => {
    setAnswerState("pending")
    setSelectedAnswer(undefined)
    setShowExplanation(false)
    setShowHint(false)
    setTimerKey((k) => k + 1)
    startTimeRef.current = Date.now()
  }, [idx, isNoteQ])

  const handleAnswer = useCallback(
    (answer: string, exact?: boolean) => {
      if (answerState !== "pending") return
      const timeMs = Date.now() - startTimeRef.current
      // Piyanoda diyez/bemol: basılan siyah tuş adı (ör. 'Do#'), eş sesli her iki yazımı da doğru sayar.
      // Çok oktavlı klavyede (exact verildiğinde) oktav da doğru olmalı.
      const correct = exact ?? (answer === q.correctAnswer || (!!q.keyName && answer === q.keyName))
      setSelectedAnswer(answer)
      setAnswerState(correct ? "correct" : "wrong")

      const result: SessionResult = {
        questionId: q.id,
        category: q.category,
        clef: q.clef,
        correct,
        timeMs,
        hasLedger: (q.ledgerLines?.length ?? 0) > 0,
        noteY: q.noteY,
        accidental: q.accidental,
      }
      setResults((r) => [...r, result])

      if (correct) {
        playCorrectChime()
        hapticSuccess()
        const ns = correctStreak + 1
        setCorrectStreak(ns)
        if (ns % 3 === 0) {
          setShowStreakFlare(true)
          setTimeout(() => setShowStreakFlare(false), 700)
        }
        setTimeout(() => {
          if (idx + 1 >= questions.length) onComplete([...results, result])
          else setIdx((i) => i + 1)
        }, 700)
      } else {
        playWrongBuzz()
        hapticError()
        setCorrectStreak(0)
        setShowExplanation(true)
      }
    },
    [answerState, q, correctStreak, results, idx, questions.length, onComplete],
  )

  const handleTimeout = useCallback(() => {
    if (answerState !== "pending") return
    handleAnswer("__timeout__")
  }, [answerState, handleAnswer])

  const handleNext = () => {
    if (idx + 1 >= questions.length) onComplete(results)
    else setIdx((i) => i + 1)
  }

  const score = results.filter((r) => r.correct).length

  const clefLabel = isNoteQ
    ? q.clef === "treble"
      ? "SOL ANAHTARI"
      : "FA ANAHTARI"
    : isRhythmQ
      ? "RİTİM & ÖLÇÜ"
      : isWritingQ
        ? "NOTA YAZIMI"
        : isEarQ
          ? "KULAK"
          : "MÜZİK TERİMİ"
  // Soru etiketi konunun rengini taşır (ana sayfa kartıyla aynı)
  const qCat: CategoryKey = isNoteQ
    ? q.accidental
      ? "accidentals"
      : q.clef === "bass"
        ? "bass"
        : "treble"
    : isRhythmQ
      ? "rhythm"
      : isWritingQ
        ? "writing"
        : isEarQ
          ? "ear"
          : "terms"
  const clefColor = category[qCat].text
  const clefBg = alpha(category[qCat].base, 0.14)

  return (
    <div
      className="flex flex-col h-full"
      style={{ background: colors.bg, overflowY: "auto", overflowX: "hidden", position: "relative" }}
    >
      {/* Yan ekranda iki sütun: solda soru, sağda klavye/şıklar. Dikeyde sarmalayıcılar görünmez. */}
      <div
        style={
          land
            ? { display: "flex", flexDirection: "column", flex: "1 1 auto", minHeight: "100%" }
            : { display: "contents" }
        }
      >
        <div style={land ? { flex: "1 0 auto", display: "flex", flexDirection: "column" } : { display: "contents" }}>
          {/* ── Top navigation bar ── */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              padding: "14px 16px 10px",
              position: "relative",
            }}
          >
            {/* Turdan çık: ✕ (revize R16) */}
            <button
              onClick={() => setShowExitConfirm(true)}
              style={{
                width: 44,
                height: 44,
                borderRadius: radius.sm,
                background: colors.fillStrong,
                border: `1px solid ${colors.border}`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                cursor: "pointer",
                flexShrink: 0,
              }}
              aria-label="Çık"
              data-back
            >
              <svg
                width={16}
                height={16}
                viewBox="0 0 24 24"
                fill="none"
                stroke={colors.textMuted}
                strokeWidth={2.5}
                strokeLinecap="round"
              >
                <path d="M6 6l12 12M18 6L6 18" />
              </svg>
            </button>

            {/* Centered step pill */}
            <div
              style={{
                position: "absolute",
                left: "50%",
                transform: "translateX(-50%)",
                display: "flex",
                alignItems: "center",
                gap: 6,
              }}
            >
              {/* Dot steps */}
              <div style={{ display: "flex", gap: 4, alignItems: "center" }}>
                {questions.map((_, i) => (
                  <div
                    key={i}
                    style={{
                      width: i === idx ? 18 : 6,
                      height: 6,
                      borderRadius: radius.pill,
                      // Cevaplanan sorular doğruysa yeşil, yanlışsa kırmızı (revize R2)
                      background:
                        i < idx
                          ? results[i]?.correct
                            ? palette.green500
                            : palette.red500
                          : i === idx
                            ? `linear-gradient(90deg, ${palette.violet500}, ${palette.violet400})`
                            : colors.fillStronger,
                      transition: "all 0.3s ease",
                      boxShadow: i === idx ? "0 0 8px rgba(139,92,246,0.6)" : "none",
                    }}
                  />
                ))}
              </div>
              <span
                style={{
                  fontSize: font.size.sm,
                  fontWeight: font.weight.bold,
                  color: colors.textMuted,
                  fontFamily: font.family.mono,
                  marginLeft: 2,
                }}
              >
                {idx + 1}/{questions.length}
              </span>
            </div>

            {/* Score */}
            <div style={{ marginLeft: "auto", position: "relative" }}>
              {showStreakFlare && (
                <span
                  className="absolute -top-6 left-1/2 -translate-x-1/2 text-base animate-streak-flare pointer-events-none"
                  style={{ color: colors.orangeText, display: "flex" }}
                >
                  <Icon name="flame" size={20} fill />
                </span>
              )}
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 5,
                  padding: "5px 11px",
                  borderRadius: radius.pill,
                  background: alpha(palette.green500, 0.1),
                  border: "1px solid rgba(16,185,129,0.25)",
                }}
              >
                <span
                  style={{
                    fontSize: font.size.sm,
                    color: colors.greenText,
                    fontWeight: font.weight.bold,
                    fontFamily: font.family.mono,
                  }}
                >
                  ✓ {score}
                </span>
              </div>
            </div>
          </div>

          {/* Timer */}
          {timerEnabled && answerState === "pending" && (
            <TimerBar key={timerKey} seconds={effectiveSeconds} onTimeout={handleTimeout} />
          )}

          {/* ── Question area ── */}
          <div
            style={
              land
                ? {
                    padding: "0 16px 6px",
                    display: "grid",
                    gridTemplateColumns: "minmax(0, 0.8fr) minmax(0, 1.2fr)",
                    gridTemplateRows: "auto auto 1fr",
                    columnGap: 14,
                    alignItems: "start",
                  }
                : {
                    padding: "0 16px 12px",
                    flex: isWritingQ ? "0 0 auto" : "1 1 auto",
                    display: "flex",
                    flexDirection: "column",
                    minHeight: 0,
                  }
            }
          >
            {/* Category pill */}
            <div style={{ marginBottom: 8 }}>
              <span
                style={{
                  display: "inline-block",
                  fontSize: font.size.xs,
                  fontWeight: font.weight.bold,
                  letterSpacing: "0.1em",
                  padding: "4px 10px",
                  borderRadius: radius.pill,
                  background: clefBg,
                  color: clefColor,
                  border: `1px solid ${alpha(category[qCat].base, 0.2)}`,
                  fontFamily: font.family.ui,
                }}
              >
                {clefLabel}
              </span>
            </div>

            {/* Main question title */}
            <p
              style={{
                fontSize: font.size.lg,
                fontWeight: font.weight.bold,
                color: colors.text,
                marginBottom: 12,
                lineHeight: 1.25,
                fontFamily: font.family.ui,
                letterSpacing: "-0.02em",
              }}
            >
              {q.questionText}
            </p>

            {/* Yan ekranda açıklama sol sütunda, sorunun altında */}
            {land && showExplanation && answerState === "wrong" && (
              <div
                className="animate-slide-up"
                style={{
                  gridColumn: 1,
                  marginTop: 8,
                  padding: "8px 12px",
                  borderRadius: radius.md,
                  background: alpha(palette.red500, 0.08),
                  border: "1px solid rgba(239,68,68,0.22)",
                }}
              >
                <p style={{ fontSize: font.size.sm, color: colors.redText, fontWeight: font.weight.semibold }}>
                  Doğru cevap:{" "}
                  <span style={{ color: colors.greenText, fontWeight: font.weight.bold }}>
                    {octaveMode && target ? target.key : q.correctAnswer}
                  </span>
                </p>
                {wrongOctave && (
                  <p style={{ fontSize: font.size.xs, color: colors.amberText, fontWeight: font.weight.semibold }}>
                    Nota doğru, oktav yanlış.
                  </p>
                )}
              </div>
            )}

            {/* Staff / display card */}
            <div
              style={{
                position: "relative",
                flex: isWritingQ ? "0 0 auto" : "1 1 auto",
                display: "flex",
                flexDirection: "column",
                ...(land ? { gridColumn: 2, gridRow: "1 / span 3" } : {}),
              }}
              key={idx}
            >
              <div
                className="animate-pop-in"
                style={{
                  flex: isWritingQ ? "0 0 auto" : "1 0 auto",
                  background: colors.paper,
                  border: `1px solid ${colors.border}`,
                  borderRadius: radius.lg,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  flexDirection: "column",
                  minHeight: isWritingQ
                    ? 0
                    : isNoteQ
                      ? land
                        ? 0
                        : answerState === "wrong"
                          ? 170
                          : "clamp(240px, 44vh, 400px)"
                      : answerState === "wrong"
                        ? 120
                        : "clamp(200px, 38vh, 340px)",
                  padding: isWritingQ ? "12px 14px" : undefined,
                  position: "relative",
                  overflow: "hidden",
                }}
              >
                {isEarQ && q.ear ? (
                  <EarPrompt prompt={q.ear} answerState={answerState} />
                ) : isWritingQ ? (
                  <p
                    style={{
                      fontSize: font.size.sm,
                      color: colors.textMuted,
                      fontFamily: font.family.ui,
                      textAlign: "center",
                    }}
                  >
                    Dört yazımdan sadece biri doğru. Doğru olanı seç.
                  </p>
                ) : isNoteQ && q.noteY !== undefined ? (
                  <MusicalStaff
                    clef={q.clef!}
                    noteY={q.noteY}
                    ledgerLines={q.ledgerLines ?? []}
                    showLabel={false}
                    accidental={q.accidental}
                    feedback={answerState === "pending" ? null : answerState}
                    maxHeight={land ? 130 : undefined}
                  />
                ) : isRhythmQ && q.score ? (
                  <div style={{ width: "100%", display: "flex", justifyContent: "center", padding: "0 12px" }}>
                    <Notation score={q.score} />
                  </div>
                ) : isRhythmQ ? (
                  <RhythmDisplay rhythmType={q.rhythmType ?? ""} displayText={q.displayText} />
                ) : termScoreFor(q) ? (
                  <div style={{ width: "100%", display: "flex", justifyContent: "center", padding: "0 12px" }}>
                    <Notation score={termScoreFor(q)!} />
                  </div>
                ) : (
                  <TermDisplay displayText={q.displayText ?? q.questionText.slice(1, q.questionText.indexOf("'", 1))} />
                )}

                {/* Doğru cevapta nota adı */}
                {isNoteQ && answerState === "correct" && (
                  <div
                    className="animate-pop-in"
                    style={{
                      position: "absolute",
                      left: "50%",
                      bottom: 14,
                      transform: "translateX(-50%)",
                      padding: "6px 18px",
                      borderRadius: radius.pill,
                      background: alpha(palette.green400, 0.16),
                      border: "1px solid rgba(52,211,153,0.45)",
                      color: colors.greenText,
                      fontSize: font.size.xl,
                      fontWeight: font.weight.heavy,
                      fontFamily: font.family.ui,
                      letterSpacing: "-0.01em",
                    }}
                  >
                    {q.correctAnswer}
                  </div>
                )}

                {/* Hint control (note questions only) */}
                {isNoteQ && !noHints && answerState === "pending" && (
                  <button
                    onClick={() => setShowHint((h) => !h)}
                    aria-expanded={showHint}
                    aria-controls={`note-hint-${idx}`}
                    style={{
                      position: "absolute",
                      top: 10,
                      right: 12,
                      padding: "7px 12px",
                      borderRadius: radius.pill,
                      background: showHint ? alpha(palette.amber500, 0.2) : colors.fillStrong,
                      border: showHint ? "1px solid rgba(245,158,11,0.45)" : `1px solid ${colors.border}`,
                      color: showHint ? colors.amberText : colors.textMuted,
                      fontSize: font.size.sm,
                      fontWeight: font.weight.semibold,
                      cursor: "pointer",
                      transition: "all 0.18s",
                      fontFamily: font.family.ui,
                      zIndex: 10,
                      whiteSpace: "nowrap",
                    }}
                  >
                    <Icon name="bulb" size={14} /> İpucu
                  </button>
                )}

                {/* Hint content stays inside the staff card */}
                {showHint && isNoteQ && answerState === "pending" && (
                  <div
                    id={`note-hint-${idx}`}
                    className="animate-slide-up"
                    style={{
                      width: "calc(100% - 24px)",
                      margin: "0 12px 12px",
                      padding: "9px 14px",
                      borderRadius: radius.md,
                      background: alpha(palette.amber500, 0.1),
                      border: "1px solid rgba(245,158,11,0.25)",
                    }}
                  >
                    <p
                      style={{
                        fontSize: font.size.sm,
                        color: colors.amberText,
                        lineHeight: 1.5,
                        fontWeight: font.weight.medium,
                      }}
                    >
                      {q.accidental
                        ? "♯ (diyez) notayı yarım ses yükseltir, ♭ (bemol) yarım ses alçaltır. İkisi de piyanoda siyah tuşa denk gelir; Do♯ ile Re♭ aynı tuştur."
                        : q.clef === "treble"
                          ? "Sol anahtarında çizgiler aşağıdan yukarı: Mi–Sol–Si–Re–Fa. Aralıklar: Fa–La–Do–Mi."
                          : "Fa anahtarında çizgiler aşağıdan yukarı: Sol–Si–Re–Fa–La. Aralıklar: La–Do–Mi–Sol."}
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* ── Explanation sheet ── */}
          {showExplanation && answerState === "wrong" && !land && (
            <div
              className="animate-slide-up"
              style={{
                margin: "0 16px 10px",
                padding: "10px 14px",
                borderRadius: radius.md,
                background: alpha(palette.red500, 0.08),
                border: "1px solid rgba(239,68,68,0.22)",
              }}
            >
              <div style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
                <span
                  style={{
                    fontSize: font.size.sm,
                    color: colors.redText,
                    flexShrink: 0,
                    marginTop: 1,
                  }}
                >
                  ✕
                </span>
                <div>
                  <p
                    style={{
                      fontSize: font.size.md,
                      color: colors.redText,
                      fontWeight: font.weight.semibold,
                      marginBottom: 2,
                    }}
                  >
                    Doğru cevap:{" "}
                    <span style={{ color: colors.greenText, fontWeight: font.weight.bold }}>{q.correctAnswer}</span>
                  </p>
                  {wrongOctave && target && (
                    <p
                      style={{
                        fontSize: font.size.sm,
                        color: colors.amberText,
                        fontWeight: font.weight.semibold,
                        lineHeight: 1.5,
                      }}
                    >
                      Nota doğru, oktav yanlış: bu nota {target.key.replace(/(\d+)$/, " ($1. oktav)")}.
                    </p>
                  )}
                  <p style={{ fontSize: font.size.sm, color: colors.textMuted, lineHeight: 1.5 }}>{q.explanation}</p>
                </div>
              </div>
            </div>
          )}
        </div>
        {/* ── Answer area ── */}
        <div style={land ? { flex: "0 0 auto", paddingTop: 6 } : isWritingQ ? { marginTop: 4 } : { marginTop: "auto" }}>
          {!land && !tablet && showRotateHint && isNoteQ && inputMode === "piano" && (
            <RotateHint onClose={closeRotateHint} />
          )}
          {/* Piano mode */}
          {inputMode === "piano" && isNoteQ && (
            <div>
              {/* Piano */}
              <div style={{ padding: "0 10px", paddingBottom: 12 }}>
                <QuizPiano
                  onAnswer={octaveMode && target ? (id) => handleAnswer(id, id === target.key) : handleAnswer}
                  correctAnswer={octaveMode && target ? target.key : (q.keyName ?? q.correctAnswer)}
                  octaveMode={octaveMode && !!target}
                  startOctave={kbStart}
                  answerState={answerState}
                  selectedNote={selectedAnswer}
                  showLabels={showKeyLabels}
                  tall={land}
                  octaves={kbOctaves}
                />
              </div>
            </div>
          )}

          {/* Multiple choice mode */}
          {(inputMode === "choice" || !isNoteQ) && (
            <div
              key={`choice-${idx}`}
              style={{
                padding: "0 16px 16px",
                display: "grid",
                gridTemplateColumns: "1fr 1fr",
                gap: 10,
              }}
            >
              {q.options.map((opt) => {
                const isSel = selectedAnswer === opt
                const isCorrectOpt = opt === q.correctAnswer
                let bg: string = colors.fill
                let border: string = colors.border
                let textCol: string = colors.textSecondary
                let extraClass = ""
                let boxShadow = "none"

                if (answerState !== "pending") {
                  if (isSel && answerState === "correct") {
                    bg = alpha(palette.green500, 0.15)
                    border = palette.green500
                    textCol = colors.greenText
                    extraClass = "animate-correct-pulse"
                    boxShadow = "0 0 14px rgba(16,185,129,0.35)"
                  } else if (isSel && answerState === "wrong") {
                    bg = alpha(palette.red500, 0.13)
                    border = palette.red500
                    textCol = colors.redText
                    extraClass = "animate-shake"
                    boxShadow = "0 0 12px rgba(239,68,68,0.3)"
                  } else if (isCorrectOpt && answerState === "wrong") {
                    bg = alpha(palette.green500, 0.15)
                    border = palette.green500
                    textCol = colors.greenText
                    boxShadow = "0 0 14px rgba(16,185,129,0.35)"
                  }
                }

                return (
                  <button
                    key={opt}
                    disabled={answerState !== "pending"}
                    onClick={() => handleAnswer(opt)}
                    className={extraClass}
                    style={{
                      background: bg,
                      border: `1px solid ${border}`,
                      color: textCol,
                      boxShadow,
                      borderRadius: radius.lg,
                      padding: q.optionScores ? "8px 6px" : "18px 14px",
                      minHeight: q.optionScores ? 120 : 64,
                      fontSize: font.size.md,
                      fontWeight: font.weight.semibold,
                      textAlign: "center",
                      cursor: answerState === "pending" ? "pointer" : "default",
                      transition: "all 0.1s",
                      position: "relative",
                      fontFamily: font.family.ui,
                    }}
                    onMouseEnter={(e) => {
                      if (answerState === "pending") {
                        ;(e.currentTarget as HTMLElement).style.background = alpha(palette.violet500, 0.1)
                        ;(e.currentTarget as HTMLElement).style.borderColor = alpha(palette.violet500, 0.4)
                      }
                    }}
                    onMouseLeave={(e) => {
                      if (answerState === "pending") {
                        ;(e.currentTarget as HTMLElement).style.background = colors.fill
                        ;(e.currentTarget as HTMLElement).style.borderColor = colors.fillStrong
                      }
                    }}
                  >
                    {q.optionScores ? (
                      <span style={{ display: "block", pointerEvents: "none" }}>
                        <span
                          style={{
                            position: "absolute",
                            left: 10,
                            top: 8,
                            fontSize: font.size.xs,
                            fontWeight: font.weight.bold,
                            opacity: 0.7,
                          }}
                        >
                          {opt}
                        </span>
                        <Notation score={q.optionScores[opt]} maxW={170} />
                      </span>
                    ) : (
                      opt
                    )}
                    {isCorrectOpt && answerState === "wrong" && (
                      <span
                        style={{
                          position: "absolute",
                          right: 12,
                          top: "50%",
                          transform: "translateY(-50%)",
                          color: colors.greenText,
                          fontSize: font.size.sm,
                        }}
                      >
                        ✓
                      </span>
                    )}
                  </button>
                )
              })}
            </div>
          )}

          {/* FAB İleri button — shown after wrong answer */}
          {answerState === "wrong" && (
            <div style={{ padding: "8px 16px 20px", position: "sticky", bottom: 0, background: colors.bg, zIndex: 30 }}>
              <button
                onClick={handleNext}
                style={{
                  width: "100%",
                  padding: "15px",
                  borderRadius: radius.lg,
                  fontSize: font.size.md,
                  fontWeight: font.weight.bold,
                  cursor: "pointer",
                  background: gradient.primaryFlat,
                  color: colors.onPrimary,
                  border: "none",
                  boxShadow: "0 4px 20px rgba(124,58,237,0.45), 0 0 0 1px rgba(139,92,246,0.3)",
                  fontFamily: font.family.ui,
                  letterSpacing: "-0.01em",
                  transition: "all 0.15s",
                }}
                onMouseEnter={(e) => {
                  ;(e.currentTarget as HTMLElement).style.boxShadow =
                    "0 6px 28px rgba(124,58,237,0.6), 0 0 0 1px rgba(139,92,246,0.4)"
                }}
                onMouseLeave={(e) => {
                  ;(e.currentTarget as HTMLElement).style.boxShadow =
                    "0 4px 20px rgba(124,58,237,0.45), 0 0 0 1px rgba(139,92,246,0.3)"
                }}
              >
                {idx + 1 >= questions.length ? "Turu bitir" : "Sıradaki"}
              </button>
            </div>
          )}

          {answerState !== "wrong" && <div style={{ paddingBottom: 16 }} />}
        </div>
      </div>

      {showExitConfirm && <ExitConfirm onStay={() => setShowExitConfirm(false)} onExit={onExit} />}
    </div>
  )
}
