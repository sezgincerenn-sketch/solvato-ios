// Tur sonu ekranı
import { Stars } from "../ui"
import { SolfieSays } from "../components/Solfie"
import { nextStarHint } from "../utils/stars"
import RankCard from "./profile/RankCard"
import StreakReminderCard from "./StreakReminderCard"
import { ScoreRing } from "../ui"
import type { FilterCategory, RoundAnswer, Question, SpecialRound } from "../types"
import Icon from "../components/Icons"

import { alpha, colors, font, gradient, palette, radius } from "../design/tokens"

// ─── Result screen ─────────────────────────────────────────────────────────────
// ─── Result screen ─────────────────────────────────────────────────────────────
export const CATEGORY_LABELS: Record<FilterCategory | SpecialRound, string> = {
  all: "Karma Pratik",
  treble: "Sol Anahtarı Pratiği",
  bass: "Fa Anahtarı Pratiği",
  rhythm: "Ritim Pratiği",
  terms: "Müzik Terimleri Pratiği",
  accidentals: "Diyez & Bemol Pratiği",
  writing: "Nota Yazımı Pratiği",
  ear: "Kulak Pratiği",
  chords: "Akor Pratiği",
  rhythmtap: "Ritmi Tut",
}

export default function ResultScreen({
  results,
  pointsEarned,
  stars,
  prevBest,
  totalXp,
  questions,
  category,
  streak,
  onHome,
  onRetry,
  onRetryWrong,
}: {
  results: RoundAnswer[]
  pointsEarned: number
  /** Bu turun yıldızı (0–3) */
  stars: number
  /** Konu turuysa bu konudaki önceki en iyi yıldız; değilse null */
  prevBest: number | null
  /** Tur sonrası toplam XP (ünvan kartı için) */
  totalXp: number
  questions: Question[]
  /** Hangi konunun turu; akor turu "chords", ritim oyunu "rhythmtap" */
  category: FilterCategory | SpecialRound
  streak: number
  onHome: () => void
  onRetry: () => void
  onRetryWrong: () => void
}) {
  const newBest = prevBest !== null && stars > prevBest

  const correct = results.filter((r) => r.correct).length
  const total = results.length
  const pct = total > 0 ? Math.round((correct / total) * 100) : 0
  const avgMs =
    results.length > 0 ? Math.round(results.reduce((s, r) => s + r.timeMs, 0) / results.length / 100) / 10 : 0
  // Ritmi Tut'ta timeMs cevap süresi değil, vuruştan ortalama sapma (ms)
  const tapRound = category === "rhythmtap"
  const avgDevMs = results.length > 0 ? Math.round(results.reduce((s, r) => s + r.timeMs, 0) / results.length) : 0
  const wrongResults = results.filter((r) => !r.correct)
  const wrongQuestions = wrongResults
    .map((r) => questions.find((q) => q.id === r.questionId))
    .filter(Boolean) as Question[]

  const headline =
    pct >= 90 ? "Harika iş!" : pct >= 70 ? "Çok iyi!" : pct >= 50 ? "Güzel gidiyorsun" : "Tekrarla, oturacak"

  return (
    <div
      className="flex flex-col h-full overflow-y-auto animate-fade-in-up"
      style={{ background: colors.bg, scrollbarWidth: "none" }}
    >
      {/* Ambient glow top */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: "50%",
          transform: "translateX(-50%)",
          width: 320,
          height: 220,
          pointerEvents: "none",
          background: `radial-gradient(ellipse, ${alpha(palette.violet500, 0.3)} 0%, transparent 70%)`,
          zIndex: 0,
        }}
      />

      <div
        style={{
          position: "relative",
          zIndex: 1,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          padding: "36px 20px 0",
        }}
      >
        {/* Yıldızlar (utils/stars.ts): turun özeti, tek bakışta */}
        <div style={{ marginBottom: 14 }}>
          <Stars value={stars} size={52} animate />
        </div>

        <h1
          style={{
            fontSize: font.size.xl,
            fontWeight: font.weight.heavy,
            color: colors.text,
            letterSpacing: "-0.03em",
            textAlign: "center",
            fontFamily: font.family.ui,
            marginBottom: 4,
          }}
        >
          Tur bitti · {headline}
        </h1>
        <p
          style={{
            fontSize: font.size.sm,
            color: colors.textSubtle,
            fontWeight: font.weight.medium,
            marginBottom: 6,
          }}
        >
          {CATEGORY_LABELS[category]}
        </p>
        {/* Solfie: rekor haberi ya da bir sonraki yıldız için ipucu */}
        <div style={{ marginBottom: 20, marginTop: 4 }}>
          <SolfieSays tone={newBest ? "amber" : "default"} pose={newBest ? "cheer" : "idle"}>
            {newBest ? "Bu konuda yeni rekor!" : (nextStarHint(stars) ?? "Tam puan: 3 yıldız")}
          </SolfieSays>
        </div>

        {/* Circular progress ring */}
        <div style={{ position: "relative", marginBottom: 28 }}>
          {/* Outer glow ring */}
          <div
            style={{
              position: "absolute",
              inset: -10,
              borderRadius: "50%",
              background: `radial-gradient(circle, ${alpha(palette.violet500, 0.4)} 0%, transparent 65%)`,
              pointerEvents: "none",
            }}
          />
          <ScoreRing
            value={correct}
            max={total}
            label={`%${pct}`}
            caption="Doğruluk"
            detail={`${correct}/${total} doğru`}
          />
        </div>

        {/* XP ve ortalama süre */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gap: 10,
            width: "100%",
            marginBottom: 16,
          }}
        >
          {/* XP card */}
          <div
            style={{
              borderRadius: radius.lg,
              padding: "14px 10px",
              textAlign: "center",
              background: alpha(palette.amber500, 0.08),
              border: "1px solid rgba(245,158,11,0.2)",
            }}
          >
            <div style={{ marginBottom: 4, color: colors.amberText }}>
              <Icon name="sparkles" size={20} />
            </div>
            <p
              style={{
                fontSize: font.size.md,
                fontWeight: font.weight.heavy,
                color: colors.amberText,
                fontFamily: font.family.mono,
                lineHeight: 1,
              }}
            >
              +{pointsEarned}
            </p>
            <p
              style={{
                fontSize: font.size.xs,
                color: colors.textSubtle,
                marginTop: 4,
                fontWeight: font.weight.semibold,
                textTransform: "uppercase",
                letterSpacing: "0.05em",
              }}
            >
              XP
            </p>
          </div>

          {/* Avg time card */}
          <div
            style={{
              borderRadius: radius.lg,
              padding: "14px 10px",
              textAlign: "center",
              background: alpha(palette.blue400, 0.08),
              border: "1px solid rgba(96,165,250,0.2)",
            }}
          >
            <div style={{ marginBottom: 4 }}>
              <svg
                width={20}
                height={20}
                viewBox="0 0 24 24"
                fill="none"
                stroke={colors.blueText}
                strokeWidth={2}
                strokeLinecap="round"
                style={{ display: "inline-block" }}
              >
                <circle cx="12" cy="12" r="10" />
                <polyline points="12 6 12 12 16 14" />
              </svg>
            </div>
            <p
              style={{
                fontSize: font.size.md,
                fontWeight: font.weight.heavy,
                color: colors.blueText,
                fontFamily: font.family.mono,
                lineHeight: 1,
              }}
            >
              {tapRound ? `${avgDevMs} ms` : `${avgMs.toLocaleString("tr-TR")} sn`}
            </p>
            <p
              style={{
                fontSize: font.size.xs,
                color: colors.textSubtle,
                marginTop: 4,
                fontWeight: font.weight.semibold,
                textTransform: "uppercase",
                letterSpacing: "0.05em",
              }}
            >
              {tapRound ? "Ort. Sapma" : "Ort. Süre"}
            </p>
          </div>
        </div>

        {/* İlk seri gününde, hatırlatma kapalıysa bir kez: "Serini koru" (revize R8) */}
        <StreakReminderCard streak={streak} />

        {/* Ünvan: XP ile ilerleme */}
        <div style={{ width: "100%", marginBottom: 16 }}>
          <RankCard xp={totalXp} gained={pointsEarned} />
        </div>

        {/* Action buttons */}
        <div
          style={{
            width: "100%",
            display: "flex",
            flexDirection: "column",
            gap: 10,
            paddingBottom: 28,
          }}
        >
          {/* Primary CTA */}
          <button
            onClick={wrongQuestions.length > 0 ? onRetryWrong : onRetry}
            style={{
              width: "100%",
              height: 56,
              borderRadius: radius.lg,
              fontSize: font.size.md,
              fontWeight: font.weight.bold,
              cursor: "pointer",
              background: gradient.primaryFlat,
              color: colors.onPrimary,
              border: "none",
              boxShadow: "0 6px 28px rgba(124,58,237,0.5), 0 0 0 1px rgba(139,92,246,0.3)",
              fontFamily: font.family.ui,
              letterSpacing: "-0.01em",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 8,
              transition: "all 0.15s",
            }}
            onMouseEnter={(e) => {
              ;(e.currentTarget as HTMLElement).style.boxShadow =
                "0 8px 36px rgba(124,58,237,0.65), 0 0 0 1px rgba(139,92,246,0.4)"
            }}
            onMouseLeave={(e) => {
              ;(e.currentTarget as HTMLElement).style.boxShadow =
                "0 6px 28px rgba(124,58,237,0.5), 0 0 0 1px rgba(139,92,246,0.3)"
            }}
          >
            <svg width={16} height={16} viewBox="0 0 24 24">
              <path d="M5 3l14 9-14 9V3z" fill={palette.violet100} />
            </svg>
            {wrongQuestions.length > 0 ? `Hatalarını tekrar et · ${wrongQuestions.length} soru` : "Yeni tur"}
          </button>

          {/* Secondary row */}
          <div style={{ display: "flex", gap: 10 }}>
            <button
              onClick={onHome}
              data-back
              style={{
                flex: 1,
                height: 46,
                borderRadius: radius.md,
                fontSize: font.size.sm,
                fontWeight: font.weight.semibold,
                cursor: "pointer",
                background: colors.fill,
                color: colors.textSubtle,
                border: `1px solid ${colors.border}`,
                fontFamily: font.family.ui,
                transition: "all 0.15s",
              }}
              onMouseEnter={(e) => {
                ;(e.currentTarget as HTMLElement).style.color = colors.textMuted
              }}
              onMouseLeave={(e) => {
                ;(e.currentTarget as HTMLElement).style.color = colors.textFaint
              }}
            >
              Bitir
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
