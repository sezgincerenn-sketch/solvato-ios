// Ritmi Tut: ekranda tek ölçülük bir ritim görünür; metronomla dört vuruş sayılır, öğrenci ritmi dokunarak çalar.
// Dokunuşlar ses saatine göre ölçülür ve notalarla eşleştirilir (data/rhythmTap.ts). Tur sonunda ortak sonuç ekranı.
//
// Akış (her ritim): hazır → [Dinle: ritim metronomla çalınır] → Başla: 4 vuruş sayma → çalma → değerlendirme
import { useCallback, useEffect, useMemo, useRef, useState } from "react"
import Notation from "../components/Notation"
import RhythmTimeline from "../components/RhythmTimeline"
import Icon from "../components/Icons"
import { PASS, RHYTHM_ROUND, TEMPO, gradeTaps, onsets, pickPatterns, type TapResult } from "../data/rhythmTap"
import { alpha, category, colors, font, palette, radius, space } from "../design/tokens"
import type { RoundAnswer } from "../types"
import { Button, ExitConfirm } from "../ui"
import { audioLatency, audioNow, scheduleBeat, scheduleClick } from "../utils/audio"
import { hapticTapStrong } from "../utils/haptics"
import { getSettings, updateSettings, useSettings } from "../utils/settings"

type Phase = "ready" | "listen" | "countin" | "play" | "result"

const ACCENT = category.rhythm.base

export default function RhythmTapSession({
  onExit,
  onComplete,
}: {
  onExit: () => void
  onComplete: (answers: RoundAnswer[]) => void
}) {
  const settings = useSettings()
  const level = getSettings().level
  const bpm = TEMPO[level]
  const beat = 60 / bpm
  const patterns = useMemo(() => pickPatterns(level), [level])
  const [idx, setIdx] = useState(0)
  const [phase, setPhase] = useState<Phase>("ready")
  const [result, setResult] = useState<TapResult | null>(null)
  const [answers, setAnswers] = useState<RoundAnswer[]>([])
  // En az bir ritim denendi mi (revize R34)
  const answered = answers.length > 0 || result !== null
  const [count, setCount] = useState<number | null>(null) // sayma: 1..4
  const [progress, setProgress] = useState<number | null>(null)
  const [pulse, setPulse] = useState(0)
  const [showExitConfirm, setShowExitConfirm] = useState(false)
  const score = patterns[idx]
  const measureStart = useRef(0)
  const taps = useRef<number[]>([])
  const raf = useRef(0)
  const timer = useRef<number[]>([])

  const clearTimers = () => {
    timer.current.forEach((t) => clearTimeout(t))
    timer.current = []
    cancelAnimationFrame(raf.current)
  }
  useEffect(() => clearTimers, [])

  /** Sayma + ölçü: tıkları zamanla; listen ise ritim notalarını da çal */
  const run = useCallback(
    (mode: "listen" | "play") => {
      clearTimers()
      setResult(null)
      taps.current = []
      const t0 = audioNow() + 0.15
      const m0 = t0 + 4 * beat
      measureStart.current = m0
      for (let i = 0; i < 4; i++) scheduleClick(t0 + i * beat, i === 0)
      for (let i = 0; i < 4; i++) scheduleClick(m0 + i * beat, i === 0)
      if (mode === "listen") onsets(score).forEach((b) => scheduleBeat(m0 + b * beat))
      setPhase("countin")
      const lat = audioLatency()
      // Görsel sayma ve oynatma çizgisi ses saatini izler
      const tick = () => {
        const now = audioNow() - lat
        if (now < m0) {
          setCount(now < t0 ? null : Math.min(4, Math.floor((now - t0) / beat) + 1))
          setProgress(null)
        } else {
          // Çalarken de vuruş ışıkları metronomla birlikte yanar
          setCount(now < m0 + 4 * beat ? Math.floor((now - m0) / beat) + 1 : null)
          setPhase((p) => (p === "countin" ? (mode === "listen" ? "listen" : "play") : p))
          setProgress(Math.min(1, (now - m0) / (4 * beat)))
        }
        if (now < m0 + 4 * beat + 0.35) raf.current = requestAnimationFrame(tick)
        else {
          setProgress(null)
          if (mode === "listen") setPhase("ready")
          else {
            const r = gradeTaps(score, taps.current, bpm, level)
            setResult(r)
            setPhase("result")
          }
        }
      }
      raf.current = requestAnimationFrame(tick)
    },
    [beat, bpm, level, score],
  )

  const tap = useCallback(() => {
    if (phase !== "play" && phase !== "countin") return
    hapticTapStrong()
    setPulse((p) => p + 1)
    // Duyulan sese göre: dokunuş anından ses gecikmesini çıkar
    const t = audioNow() - audioLatency() - measureStart.current
    if (t > -0.3) taps.current.push(t)
  }, [phase])

  // Bilgisayarda boşluk tuşu da dokunuş sayılır
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.code === "Space") {
        e.preventDefault()
        tap()
      }
    }
    window.addEventListener("keydown", onKey)
    return () => window.removeEventListener("keydown", onKey)
  }, [tap])

  const finishPattern = () => {
    if (!result) return
    const next = [
      ...answers,
      { questionId: 3000 + idx, correct: result.score >= PASS, timeMs: result.meanAbsMs } satisfies RoundAnswer,
    ]
    if (idx + 1 >= patterns.length) {
      onComplete(next)
      return
    }
    setAnswers(next)
    setIdx(idx + 1)
    setResult(null)
    setPhase("ready")
  }

  // Çıkış onayı: çalarken açılırsa deneme durur, "Devam et" ile aynı ritim baştan
  const askExit = () => {
    // Hiç ritim denenmediyse sormadan çık (revize R34)
    if (!answered) return onExit()
    if (phase !== "result" && phase !== "ready") {
      clearTimers()
      setCount(null)
      setProgress(null)
      setPhase("ready")
    }
    setShowExitConfirm(true)
  }

  const passed = result && result.score >= PASS
  const hits = result ? result.notes.filter((n) => n.grade !== "miss").length : 0
  // Ortalama sapma belirginse yön söyle (geçtiyse de: iyi ama biraz erken/geç)
  const bias =
    result && hits >= 2 && Math.abs(result.biasMs) > 45
      ? `${passed ? "Güzel; " : ""}${
          result.biasMs < 0
            ? "biraz erken dokunuyorsun, metronomu dinle."
            : "biraz geç dokunuyorsun, vuruşla birlikte dokun."
        }`.replace(/^b/, passed ? "b" : "B")
      : null
  const busy = phase === "countin" || phase === "play" || phase === "listen"

  return (
    <div
      style={{
        height: "100%",
        position: "relative",
        display: "flex",
        flexDirection: "column",
        fontFamily: font.family.ui,
        padding: `${space[3]}px ${space[4]}px ${space[4]}px`,
        gap: space[3],
      }}
    >
      {/* Üst bar */}
      <div style={{ display: "flex", alignItems: "center", gap: space[3] }}>
        <button
          onClick={askExit}
          data-back
          data-answered={answered ? "1" : undefined}
          aria-label="Turdan çık"
          style={{
            width: 40,
            height: 40,
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
          <Icon name="x" size={18} />
        </button>
        <div style={{ flex: 1, display: "flex", gap: 4 }} aria-label={`${idx + 1}. ritim, ${RHYTHM_ROUND} ritimden`}>
          {patterns.map((_, i) => (
            <span
              key={i}
              style={{
                flex: 1,
                height: 6,
                borderRadius: radius.pill,
                background:
                  i < idx
                    ? answers[i]?.correct
                      ? palette.green500
                      : palette.amber500
                    : i === idx
                      ? ACCENT
                      : colors.fillStrong,
              }}
            />
          ))}
        </div>
        <span style={{ fontSize: font.size.sm, fontFamily: font.family.mono, color: colors.textMuted }}>{bpm} BPM</span>
      </div>

      <div>
        <p
          style={{
            fontSize: font.size.xs,
            fontWeight: font.weight.bold,
            letterSpacing: font.tracking.label,
            color: category.rhythm.text,
            textTransform: "uppercase",
          }}
        >
          Ritmi Tut · {idx + 1}/{patterns.length}
        </p>
        <p style={{ fontSize: font.size.lg, fontWeight: font.weight.bold, color: colors.text, marginTop: 4 }}>
          {phase === "result"
            ? passed
              ? "Ritim yerinde!"
              : "Bir daha deneyelim"
            : "Dört vuruş say, sonra ritmi dokunarak çal"}
        </p>
      </div>

      {/* Ritim */}
      <div
        style={{
          background: colors.fill,
          border: `1px solid ${colors.border}`,
          borderRadius: radius.lg,
          padding: `${space[3]}px 0 ${space[3]}px`,
          display: "flex",
          flexDirection: "column",
          gap: space[3],
        }}
      >
        <div data-score={score} style={{ display: "flex", justifyContent: "center", padding: `0 ${space[2]}px` }}>
          <Notation score={`ts:4/4 ${score} ||`} maxW={340} />
        </div>
        <RhythmTimeline score={score} result={result} bpm={bpm} progress={progress} />
      </div>

      {/* Sonuç ya da sayma */}
      <div style={{ minHeight: 64, display: "flex", flexDirection: "column", justifyContent: "center", gap: 6 }}>
        {phase === "result" && result ? (
          <>
            <p style={{ fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text }}>
              {hits}/{result.notes.length} vuruş yerinde
              {result.extra.length > 0 ? ` · ${result.extra.length} fazla dokunuş` : ""}
              <span style={{ color: passed ? colors.greenText : colors.amberText }}>
                {" "}
                · %{Math.round(result.score * 100)}
              </span>
            </p>
            <p style={{ fontSize: font.size.sm, color: colors.textMuted, lineHeight: 1.4 }}>
              {bias ??
                (passed ? "Güzel zamanlama." : "Mor çizgiler dokunman gereken anlar; noktalar senin dokunuşların.")}
            </p>
          </>
        ) : (
          <div style={{ display: "flex", justifyContent: "center", gap: space[3] }} aria-live="polite">
            {[1, 2, 3, 4].map((n) => (
              <span
                key={n}
                style={{
                  width: 40,
                  height: 40,
                  borderRadius: "50%",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  fontSize: font.size.md,
                  fontWeight: font.weight.heavy,
                  fontFamily: font.family.mono,
                  background: count === n ? ACCENT : colors.fillStrong,
                  color: count === n ? palette.white : colors.textMuted,
                  transform: count === n ? "scale(1.15)" : "none",
                  transition: "transform 0.08s",
                }}
              >
                {n}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Ses kapalıysa: metronom duyulmadan oynanamaz */}
      {!settings.soundKeys ? (
        <div style={{ marginTop: "auto", display: "flex", flexDirection: "column", gap: space[2] }}>
          <p style={{ fontSize: font.size.sm, color: colors.textMuted, textAlign: "center" }}>
            Bu oyun metronomla oynanır; ses kapalı.
          </p>
          <Button block onClick={() => updateSettings({ soundKeys: true })}>
            Sesi aç
          </Button>
        </div>
      ) : phase === "result" ? (
        <div style={{ marginTop: "auto", display: "flex", gap: space[2] }}>
          <Button variant="secondary" block onClick={() => run("play")}>
            Tekrar dene
          </Button>
          <Button block onClick={finishPattern}>
            {idx + 1 >= patterns.length ? "Turu bitir" : "Sıradaki"}
          </Button>
        </div>
      ) : (
        <div style={{ marginTop: "auto", display: "flex", flexDirection: "column", gap: space[2] }}>
          {/* Dokunma alanı */}
          <button
            onPointerDown={(e) => {
              e.preventDefault()
              tap()
            }}
            disabled={phase === "ready" || phase === "listen"}
            aria-label="Dokun"
            style={{
              height: 150,
              borderRadius: radius.lg,
              border: `2px solid ${busy && phase !== "listen" ? ACCENT : colors.border}`,
              background:
                phase === "play" || phase === "countin" ? alpha(ACCENT, 0.16 + (pulse % 2) * 0.12) : colors.fill,
              color: phase === "play" || phase === "countin" ? category.rhythm.text : colors.textFaint,
              fontSize: font.size.xl,
              fontWeight: font.weight.heavy,
              cursor: "pointer",
              touchAction: "manipulation",
              userSelect: "none",
              transition: "background 0.06s",
            }}
          >
            {phase === "play"
              ? "Dokun"
              : phase === "countin"
                ? "Hazır…"
                : phase === "listen"
                  ? "Dinle…"
                  : "Dokunma alanı"}
          </button>
          <div style={{ display: "flex", gap: space[2] }}>
            <Button variant="secondary" block disabled={busy} onClick={() => run("listen")}>
              Dinle
            </Button>
            <Button block disabled={busy} onClick={() => run("play")}>
              Başla
            </Button>
          </div>
        </div>
      )}
      {showExitConfirm && <ExitConfirm onStay={() => setShowExitConfirm(false)} onExit={onExit} />}
    </div>
  )
}
