// İlerleme sekmesi, yukarıdan aşağı: başlık · Doğruluk · Bu hafta · Konular · Zorlandığın notalar · Son turlar.
// Revize önizlemesi: R23 başlık, R24 öğrenme yolu kaldırıldı, R25 "Çalış ▶", R26 Konular altındaki çizgi yok.
// Her bilgi tek yerde: "ne çalışmalıyım" cevabı öğrenme yolunda, konular satıra dokununca açılır.
import type { Period } from "../utils/dates"
import WeeklyReportCard from "./progress/WeeklyReportCard"
import { weakNotes } from "../state/weakNotes"
import RoundHistory from "./profile/RoundHistory"
import { Button, Chip, ScoreRing } from "../ui"
import { accuracyFor } from "../state/stats"
import { useState } from "react"
import type { AppStats } from "../types"
import MusicalStaff from "../components/MusicalStaff"
import { useTablet } from "../utils/orientation"

import { alpha, category, categoryBar, colors, font, gradient, palette, radius } from "../design/tokens"
interface DashboardProps {
  stats: AppStats
  onStartQuiz: () => void
  onPracticeWeak: (keys: string[]) => void
  onPracticeCategory: (key: "treble" | "bass" | "rhythm" | "terms" | "chords" | "writing" | "ear") => void
  header?: React.ReactNode // sekme başlığı (App'ten)
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
type TopicCat = "treble" | "bass" | "rhythm" | "terms" | "chords" | "writing" | "ear"

const card = {
  background: colors.surface,
  border: `1px solid ${colors.border}`,
  borderRadius: radius.lg,
  padding: 16,
} as const
const column = { display: "flex", flexDirection: "column", gap: 16, minWidth: 0 } as const
const cardTitle = { fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text } as const

/** Konular kartında tek satır: ad · ince çubuk · yüzde · ›  (dokununca o konuda tur) */
function TopicRow({
  cat,
  label,
  v,
  note,
  first,
  onClick,
}: {
  cat: TopicCat
  label: string
  v: { correct: number; total: number }
  note?: string
  /** İlk satırın üst çizgisi yok (R26) */
  first?: boolean
  onClick: () => void
}) {
  const pct = v.total > 0 ? Math.round((v.correct / v.total) * 100) : null
  return (
    <button
      onClick={onClick}
      aria-label={`${label}: ${pct === null ? "henüz çözülmedi" : `yüzde ${pct}`}. Bu konuda tur başlat`}
      style={{
        display: "grid",
        gridTemplateColumns: "minmax(0, 1fr) 64px 40px auto",
        alignItems: "center",
        gap: 10,
        width: "100%",
        minHeight: 44,
        padding: "6px 0",
        background: "none",
        border: "none",
        borderTop: first ? "none" : `1px solid ${colors.border}`,
        cursor: "pointer",
        textAlign: "left",
        fontFamily: font.family.ui,
      }}
    >
      <span style={{ minWidth: 0 }}>
        <span
          style={{ display: "block", fontSize: font.size.sm, fontWeight: font.weight.semibold, color: colors.text }}
        >
          {label}
        </span>
        {note && <span style={{ display: "block", fontSize: font.size.xs, color: colors.textMuted }}>{note}</span>}
      </span>
      <span style={{ height: 6, borderRadius: radius.pill, background: colors.fill, overflow: "hidden" }}>
        {pct !== null && (
          <span
            style={{
              display: "block",
              height: "100%",
              width: `${pct}%`,
              background: categoryBar(cat),
              borderRadius: radius.pill,
            }}
          />
        )}
      </span>
      <span
        style={{
          fontSize: font.size.sm,
          fontWeight: font.weight.bold,
          fontFamily: font.family.mono,
          textAlign: "right",
          color: pct === null ? colors.textFaint : category[cat].text,
        }}
      >
        {pct === null ? "—" : `%${pct}`}
      </span>
      <span
        aria-hidden="true"
        style={{
          display: "inline-flex",
          alignItems: "center",
          gap: 4,
          padding: "5px 10px",
          borderRadius: radius.pill,
          background: alpha(palette.violet500, 0.16),
          color: colors.violetTextSoft,
          fontSize: font.size.xs,
          fontWeight: font.weight.bold,
        }}
      >
        Çalış
        <svg width={9} height={9} viewBox="0 0 24 24" fill="currentColor">
          <path d="M6 3l15 9-15 9z" />
        </svg>
      </span>
    </button>
  )
}

// ─── Doğruluk kartı: dönem seçmeli ───────────────────────────────────────────
// Başta düşük doğruluk cesaret kırmasın diye varsayılan "Bu hafta"; artış varsa gösterilir,
// düşüş vurgulanmaz. Halka kırmızı/yeşil değil, marka renginde.
// Takvim dönemleri: hafta Pazartesi'den, ay 1'inden başlar
const PERIODS: { key: Period | "all"; label: string; prev: string }[] = [
  { key: "week", label: "Bu hafta", prev: "geçen haftaya" },
  { key: "month", label: "Bu ay", prev: "geçen aya" },
  { key: "all", label: "Tümü", prev: "" },
]

function AccuracyCard({ stats }: { stats: AppStats }) {
  const [period, setPeriod] = useState<Period | "all">(() => (accuracyFor(stats, "week").total > 0 ? "week" : "all"))
  const cur = accuracyFor(stats, period === "all" ? undefined : period)
  const prev = period === "all" ? null : accuracyFor(stats, period, 1)
  const pct = cur.total ? Math.round((cur.correct / cur.total) * 100) : null
  const prevPct = prev && prev.total >= 10 ? Math.round((prev.correct / prev.total) * 100) : null
  const delta = pct !== null && prevPct !== null ? pct - prevPct : null
  const p = PERIODS.find((x) => x.key === period)!
  return (
    <div
      style={{ background: colors.surface, border: `1px solid ${colors.border}`, borderRadius: radius.lg, padding: 16 }}
    >
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8, marginBottom: 12 }}>
        <p style={{ fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text }}>Doğruluk</p>
        <div style={{ display: "flex", gap: 4 }}>
          {PERIODS.map((x) => (
            <Chip
              key={x.key}
              selected={period === x.key}
              onClick={() => setPeriod(x.key)}
              style={{ minHeight: 32, padding: "4px 10px", fontSize: font.size.xs }}
            >
              {x.label}
            </Chip>
          ))}
        </div>
      </div>
      {pct === null ? (
        <p style={{ fontSize: font.size.sm, color: colors.textMuted, lineHeight: 1.5 }}>
          {p.label} henüz tur yok. Bir tur çöz, doğruluğun burada görünsün.
        </p>
      ) : (
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <ScoreRing value={cur.correct} max={cur.total} size={88} label={`%${pct}`} color={palette.violet500} />
          <div style={{ minWidth: 0 }}>
            <p style={{ fontSize: font.size.sm, color: colors.textMuted, lineHeight: 1.6 }}>
              {cur.total} sorudan {cur.correct} doğru
            </p>
            {delta !== null && delta > 0 && (
              <p
                style={{
                  fontSize: font.size.sm,
                  color: colors.greenText,
                  fontWeight: font.weight.semibold,
                  marginTop: 2,
                }}
              >
                {p.prev[0].toUpperCase() + p.prev.slice(1)} göre +{delta} puan
              </p>
            )}
            {pct < 60 && (
              <p style={{ fontSize: font.size.sm, color: colors.textFaint, marginTop: 2, lineHeight: 1.5 }}>
                Başta düşük olması normal; tekrar ettikçe yükselir.
              </p>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

// ─── Main dashboard ───────────────────────────────────────────────────────────
export default function ProgressScreen({
  stats,
  onStartQuiz,
  onPracticeWeak,
  onPracticeCategory,
  header,
}: DashboardProps) {
  const tablet = useTablet()
  const [allRounds, setAllRounds] = useState(false)

  const { categoryAccuracy: ca } = stats

  const totalAnswered =
    ca.treble.total +
    ca.bass.total +
    ca.rhythm.total +
    ca.terms.total +
    (ca.chords?.total ?? 0) +
    (ca.writing?.total ?? 0) +
    (ca.ear?.total ?? 0)
  // Gerçek veriden zayıf nota konumları (state/weakNotes.ts)
  const weakList = weakNotes(stats)

  // Konu listesi. Ek çizgiler Sol/Fa anahtarının içinde sayıldığından ayrı satır değil, alt bilgi.
  const zero = { correct: 0, total: 0 }
  const ledgerNote = (v: { correct: number; total: number }) =>
    v.total >= 5 ? `Ek çizgiler %${Math.round((v.correct / v.total) * 100)}` : undefined
  const topics: { cat: TopicCat; label: string; v: { correct: number; total: number }; note?: string }[] = [
    { cat: "treble", label: "Sol anahtarı", v: ca.treble, note: ledgerNote(ca.trebleLedger) },
    { cat: "bass", label: "Fa anahtarı", v: ca.bass, note: ledgerNote(ca.bassLedger) },
    { cat: "rhythm", label: "Ritim", v: ca.rhythm },
    { cat: "chords", label: "Akorlar", v: ca.chords ?? zero },
    { cat: "ear", label: "Kulak", v: ca.ear ?? zero },
    { cat: "writing", label: "Nota yazımı", v: ca.writing ?? zero },
    { cat: "terms", label: "Müzik terimleri", v: ca.terms },
  ]

  if (totalAnswered === 0) {
    return (
      <div
        style={{ display: "flex", flexDirection: "column", height: "100%", background: colors.bg, overflowY: "auto" }}
      >
        {header && (
          <div
            style={{
              padding: "16px 16px 0",
              paddingTop: "max(32px, calc(env(safe-area-inset-top, 0px) + 12px))",
              display: "flex",
              flexDirection: "column",
              gap: 16,
            }}
          >
            {header}
          </div>
        )}
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            flex: 1,
            alignItems: "center",
            justifyContent: "center",
            padding: 28,
            textAlign: "center",
          }}
        >
          <svg width={168} height={120} viewBox="0 0 168 120" aria-hidden="true" style={{ marginBottom: 18 }}>
            {/* porte */}
            {[30, 42, 54, 66, 78].map((y) => (
              <line
                key={y}
                x1={8}
                y1={y}
                x2={160}
                y2={y}
                stroke={colors.textDisabled}
                strokeWidth={1.4}
                strokeLinecap="round"
              />
            ))}
            {/* silik sütunlar */}
            <rect
              x={26}
              y={62}
              width={20}
              height={34}
              rx={5}
              fill="none"
              stroke={colors.violetText}
              strokeWidth={2}
              strokeDasharray="5 4"
            />
            <rect
              x={58}
              y={44}
              width={20}
              height={52}
              rx={5}
              fill="none"
              stroke={colors.violetText}
              strokeWidth={2}
              strokeDasharray="5 4"
            />
            <rect
              x={90}
              y={28}
              width={20}
              height={68}
              rx={5}
              fill="none"
              stroke={colors.violetText}
              strokeWidth={2}
              strokeDasharray="5 4"
            />
            {/* nota */}
            <ellipse cx={132} cy={66} rx={9} ry={6.4} transform="rotate(-20 132 66)" fill={colors.violetText} />
            <line
              x1={140}
              y1={64}
              x2={140}
              y2={28}
              stroke={colors.violetText}
              strokeWidth={2.4}
              strokeLinecap="round"
            />
            <path
              d="M140 28 C 150 32, 152 40, 148 46"
              fill="none"
              stroke={colors.violetText}
              strokeWidth={2.4}
              strokeLinecap="round"
            />
          </svg>
          <h1
            style={{
              fontSize: font.size.xl,
              fontWeight: font.weight.heavy,
              color: colors.text,
              fontFamily: font.family.ui,
              marginBottom: 8,
            }}
          >
            İstatistiklerin burada görünecek
          </h1>
          <p
            style={{
              fontSize: font.size.md,
              color: colors.textMuted,
              lineHeight: 1.5,
              marginBottom: 22,
              maxWidth: 280,
            }}
          >
            İlk turunu çöz; doğruluğun, serin ve zorlandığın notalar burada görünsün.
          </p>
          <button
            onClick={onStartQuiz}
            style={{
              padding: "15px 28px",
              borderRadius: radius.lg,
              fontSize: font.size.md,
              fontWeight: font.weight.bold,
              background: gradient.primaryFlat,
              color: colors.onPrimary,
              border: "none",
              boxShadow: "0 4px 20px rgba(124,58,237,0.45)",
              fontFamily: font.family.ui,
              cursor: "pointer",
            }}
          >
            İlk tura başla
          </button>
        </div>
      </div>
    )
  }

  // Kartlar bir kez tanımlanır: telefonda tek sütunda sırayla, tablette iki bağımsız sütunda.
  const sections = {
    // 1. Doğruluk: bu hafta / bu ay / tümü
    accuracy: <AccuracyCard stats={stats} />,
    // 2. Bu hafta: gün şeridi + öğretmene haftalık rapor
    week: <WeeklyReportCard stats={stats} />,
    // Sekme başlığı (App'ten gelir)
    path: header,
    // 4. Konular: tek satır, dokununca o konuda tur
    topics: (
      <div style={card}>
        <p style={cardTitle}>Konular</p>
        {topics.map((t, i) => (
          <TopicRow key={t.cat} {...t} first={i === 0} onClick={() => onPracticeCategory(t.cat)} />
        ))}
      </div>
    ),
    // 5. Zorlandığın notalar: her biri kendi anahtarında küçük portede; altında bu notalardan tur
    weak: weakList.length > 0 && (
      <div style={card}>
        <p style={cardTitle}>Zorlandığın notalar</p>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(3, minmax(0, 1fr))",
            gap: 8,
            margin: "10px 0 14px",
          }}
        >
          {weakList.map((n) => (
            <div
              key={n.key}
              aria-label={`${n.clef === "treble" ? "Sol" : "Fa"} anahtarında ${n.note}, yüzde ${n.pct}`}
              style={{
                display: "flex",
                flexDirection: "column",
                gap: 2,
                padding: "6px 8px 8px",
                borderRadius: radius.md,
                background: colors.fill,
                border: `1px solid ${colors.border}`,
                minWidth: 0,
              }}
            >
              <MusicalStaff
                clef={n.clef}
                noteY={n.noteY}
                ledgerLines={n.ledgerLines}
                accidental={n.accidental}
                maxHeight={72}
              />
              <p style={{ fontSize: font.size.sm, color: colors.textMuted }}>
                <b style={{ color: colors.text, fontWeight: font.weight.bold }}>{n.note}</b> %{n.pct}
              </p>
            </div>
          ))}
        </div>
        <Button block variant="primary" onClick={() => onPracticeWeak(weakList.map((w) => w.key))}>
          Bu notaları çalış
        </Button>
      </div>
    ),
    // 6. Son turlar: ilk 3, gerisi isteyince
    rounds: (stats.history?.length ?? 0) > 0 && (
      <div style={card}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 4 }}>
          <p style={cardTitle}>Son turlar</p>
          {(stats.history?.length ?? 0) > 3 && (
            <button
              onClick={() => setAllRounds((v) => !v)}
              style={{
                background: "none",
                border: "none",
                color: colors.violetText,
                fontSize: font.size.sm,
                fontWeight: font.weight.semibold,
                cursor: "pointer",
                padding: 6,
                fontFamily: font.family.ui,
              }}
            >
              {allRounds ? "Daha az" : "Tümünü göster"}
            </button>
          )}
        </div>
        <RoundHistory rounds={stats.history ?? []} limit={allRounds ? 30 : 3} />
      </div>
    ),
  }

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        height: "100%",
        background: colors.bg,
        overflowY: "auto",
        scrollbarWidth: "none",
      }}
    >
      <div
        style={{
          padding: "16px 16px 28px",
          paddingTop: "max(32px, calc(env(safe-area-inset-top, 0px) + 12px))",
          gap: 16,
          ...(tablet
            ? { display: "grid", gridTemplateColumns: "minmax(0, 1fr) minmax(0, 1fr)", alignItems: "start" }
            : { display: "flex", flexDirection: "column" }),
        }}
      >
        {tablet ? (
          <>
            <div style={column}>
              {sections.accuracy}
              {sections.path}
              {sections.weak}
            </div>
            <div style={column}>
              {sections.week}
              {sections.topics}
              {sections.rounds}
            </div>
          </>
        ) : (
          <>
            {sections.path}
            {sections.accuracy}
            {sections.week}
            {sections.topics}
            {sections.weak}
            {sections.rounds}
          </>
        )}
      </div>
    </div>
  )
}
