// Ana sayfa: günün çalışması, oyunlar ve konu kartları.
// Revize önizlemesi: R3 (tur bilgisi), R15 (seri hapı basılmaz), R18 (hedef çubuğu), R19 (yüzde halkası).
import LevelCard from "./profile/LevelCard"
import { GoalBar, PercentRing, StatPill, TopicLink } from "../ui"
import { currentStreak } from "../state/stats"
import { Fragment, useState } from "react"
import { allTopics } from "../utils/teacherCode"
import type { FilterCategory, AppStats } from "../types"
import { dailyInfo, loadDaily, todayStr } from "../utils/games"
import { useTablet } from "../utils/orientation"
import Logo from "../components/Logo"
import { rankFromXp, todayKey } from "../utils/level"
import { getSettings } from "../utils/settings"
import Icon from "../components/Icons"
import { ClefIcon } from "../components/Glyph"

import { space, category, alpha, colors, font, gradient, palette, radius } from "../design/tokens"

function greeting() {
  const h = new Date().getHours()
  return h < 6 ? "İyi geceler" : h < 12 ? "Günaydın" : h < 18 ? "Merhaba" : "İyi akşamlar"
}

export default function HomeScreen({
  stats,
  onStart,
  onChordQuiz,
  onRhythmTap,
  onGames,
  onOpenProfile,
  dailyGoal: dailyGoalProp,
}: {
  dailyGoal: number
  stats: AppStats
  onStart: (cat: FilterCategory) => void
  onChordQuiz: () => void
  onRhythmTap: () => void
  onGames: () => void
  onOpenProfile: () => void
}) {
  const lv = getSettings().level
  const tablet = useTablet()
  // Kategori başına doğruluk (yeterli veri varsa kartta küçük gösterilir; toplam soru sayısı gösterilmez)
  const ca = stats.categoryAccuracy
  const limitedNotes = getSettings().notes.length < 7
  const accNotes = Object.entries(stats.noteStats ?? {})
    .filter(([k]) => /:(sharp|flat)$/.test(k))
    .reduce((a, [, v]) => ({ correct: a.correct + v.correct, total: a.total + v.total }), { correct: 0, total: 0 })
  const categories: {
    key: FilterCategory
    label: string
    sub: string
    color: string
    icon: string
    acc: { correct: number; total: number }
  }[] = [
    {
      key: "treble",
      label: "Sol Anahtarı",
      sub: "Sağ el notaları",
      color: category.treble.base,
      icon: "𝄞",
      acc: ca.treble,
    },
    {
      key: "bass",
      label: "Fa Anahtarı",
      sub: "Sol el notaları",
      color: category.bass.base,
      icon: "𝄢",
      acc: ca.bass,
    },
    {
      key: "accidentals",
      label: "Diyez & Bemol",
      sub: "Siyah tuşlar: ♯ yukarı, ♭ aşağı",
      color: category.accidentals.base,
      icon: "♯",
      acc: accNotes,
    },
    {
      key: "rhythm",
      label: "Ritim & Ölçü",
      sub: "Nota değerleri, ölçüler",
      color: category.rhythm.base,
      icon: "♩",
      acc: ca.rhythm,
    },
    {
      key: "ear",
      label: "Kulak",
      sub: "Dinle, notayı ve akoru bul",
      color: category.ear.base,
      icon: "ear",
      acc: ca.ear ?? { correct: 0, total: 0 },
    },
    {
      key: "writing",
      label: "Nota Yazımı",
      sub: "Hangisi doğru yazılmış?",
      color: category.writing.base,
      icon: "✎",
      acc: ca.writing ?? { correct: 0, total: 0 },
    },
    {
      key: "terms",
      label: "Müzik Terimleri",
      sub: "Dinamik, tempo, artikülasyon",
      color: category.terms.base,
      icon: "𝄆",
      acc: ca.terms,
    },
  ]

  // Hiç soru çözülmediyse sahte bir değer göstermeyiz
  // Öğretmen kodundaki konu seçimi (utils/teacherCode.ts): seçilenler üstte, diğerleri kapalı grupta
  const topics = getSettings().topics ?? []
  const teacherPick = !allTopics(topics)
  const assigned = (k: string) =>
    !teacherPick ||
    topics.includes(k) ||
    (k === "accidentals" && (topics.includes("treble") || topics.includes("bass")))
  const ALL_KEYS = [...categories.map((c) => c.key as string), "chords"]
  const groups = [
    { key: "main", has: (k: string) => assigned(k), count: 0 },
    ...(teacherPick
      ? [
          {
            key: "rest",
            has: (k: string) => !assigned(k),
            count: ALL_KEYS.filter((k) => !assigned(k) && !(k === "accidentals" && lv < 2)).length,
          },
        ]
      : []),
  ]
  const [showRest, setShowRest] = useState(getSettings().showRestTopics)
  const rank = rankFromXp(stats.totalPoints)
  const streak = currentStreak(stats)
  const dailyGoal = dailyGoalProp
  const dailySolved = stats.dailyQuestions?.[todayKey()] ?? 0
  const goalDone = dailySolved >= dailyGoal

  return (
    <div className="flex flex-col h-full overflow-y-auto" style={{ background: colors.bg, scrollbarWidth: "none" }}>
      {/* Subtle left-side ambient color */}
      <div className="pointer-events-none fixed inset-0" style={{ maxWidth: 430 }}>
        <div
          style={{
            position: "absolute",
            top: 180,
            left: -60,
            width: 220,
            height: 220,
            background: "radial-gradient(circle, rgba(99,102,241,0.12) 0%, transparent 70%)",
            borderRadius: "50%",
          }}
        />
      </div>

      <div className="relative px-4 pt-6">
        {/* Top bar */}
        <div className="flex items-center justify-between mb-5">
          <h1 style={{ margin: 0 }}>
            <Logo size={30} />
          </h1>
          <div className="flex items-center gap-2">
            {/* Seri (turuncu) ve XP (amber): ui/StatPill. Seri yalnız bilgi (R15), XP'ye dokununca Profil.
                Rozetteki sayı ünvan sırası; "seviye" değil, seviye Başlangıç/Orta/İleri'dir. */}
            <StatPill
              tone={streak > 0 ? "orange" : "muted"}
              leading={
                <span
                  className={streak > 0 ? "flame-live" : undefined}
                  style={{ display: "flex", opacity: streak > 0 ? 1 : 0.6 }}
                >
                  <Icon name="flame" size={17} fill={streak > 0} />
                </span>
              }
              value={String(streak)}
              label={streak > 0 ? `${streak} gün seri` : "Seri yok. Bugün bir tur çözünce başlar"}
            />
            <StatPill
              tone="amber"
              leading={
                <span
                  style={{
                    width: 24,
                    height: 24,
                    borderRadius: "50%",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    background: palette.amber400,
                    color: palette.black,
                    fontSize: font.size.sm,
                    fontWeight: font.weight.heavy,
                  }}
                >
                  {rank.rank}
                </span>
              }
              value={`${stats.totalPoints} XP`}
              label={`${stats.totalPoints} XP, ${rank.rank}. ünvan: ${rank.label}. Profili aç`}
              onClick={onOpenProfile}
            />
          </div>
        </div>

        {/* Adla karşılama (ad girildiyse) */}
        {getSettings().name.trim() && (
          <p
            style={{
              fontSize: font.size.lg,
              fontWeight: font.weight.heavy,
              color: colors.text,
              letterSpacing: "-0.02em",
              margin: "-4px 2px 12px",
            }}
          >
            {greeting()}, {getSettings().name.trim()}
          </p>
        )}

        <div data-coach="level" style={{ marginBottom: space[3] }}>
          <LevelCard onClick={onOpenProfile} />
        </div>

        {/* Hero Glassmorphic Stat Card */}
        <div
          className="relative rounded-3xl p-5 mb-4 overflow-hidden"
          style={{
            background: colors.fill,
            border: `1px solid ${colors.border}`,
            backdropFilter: "blur(16px)",
            WebkitBackdropFilter: "blur(16px)",
          }}
        >
          {/* Daily goal */}
          <div className="mb-4">
            <div className="flex items-center justify-between mb-2">
              <p
                style={{
                  fontSize: font.size.xs,
                  fontWeight: font.weight.semibold,
                  color: colors.textMuted,
                  letterSpacing: "0.06em",
                  textTransform: "uppercase",
                }}
              >
                Bugün
              </p>
              <p
                style={{
                  fontSize: font.size.sm,
                  fontWeight: font.weight.bold,
                  color: colors.violetTextSoft,
                  fontFamily: font.family.mono,
                }}
              >
                {goalDone ? "Hedef tamam · " : ""}
                {Math.min(dailySolved, 9999)}/{dailyGoal} soru
              </p>
            </div>
            {/* Günlük hedef: 10 bölmeli çubuk (ui/GoalBar, R18) */}
            <GoalBar done={dailySolved} goal={dailyGoal} />
            <p style={{ fontSize: font.size.sm, color: colors.textMuted, marginTop: 8 }}>
              {goalDone ? (
                <>
                  <Icon name="flame" size={13} fill color={colors.orangeText} /> Bugünün serisi tamam
                </>
              ) : (
                `Hedefi tamamlayınca serin +1 olur · ${Math.max(0, dailyGoal - dailySolved)} soru kaldı`
              )}
            </p>
          </div>

          {/* Bugünün çalışması */}
          <button
            data-coach="today"
            onClick={() => onStart("all")}
            className="w-full rounded-2xl text-left"
            style={{
              padding: "14px 16px",
              background: gradient.primary,
              border: "1px solid rgba(196,181,253,0.35)",
              boxShadow: "0 8px 28px rgba(124,58,237,0.38)",
              display: "flex",
              alignItems: "center",
              gap: 12,
              cursor: "pointer",
            }}
          >
            <div style={{ flex: 1, minWidth: 0 }}>
              <p style={{ fontSize: font.size.md, fontWeight: font.weight.heavy, color: palette.white }}>
                {goalDone ? "Bir tur daha" : dailySolved > 0 ? "Devam et" : "Bugünün çalışması"}
              </p>
              <p style={{ fontSize: font.size.sm, color: alpha(palette.violet100, 0.85), marginTop: 2 }}>
                {teacherPick ? "Karma · 10 soru · ~3 dk · öğretmeninin konuları" : "Karma · 10 soru · ~3 dk"}
              </p>
            </div>
            <span
              aria-hidden="true"
              style={{
                width: 40,
                height: 40,
                borderRadius: radius.md,
                background: colors.fillStronger,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                flexShrink: 0,
              }}
            >
              <svg width={16} height={16} viewBox="0 0 24 24">
                <path d="M5 3l14 9-14 9V3z" fill={palette.white} />
              </svg>
            </span>
          </button>
        </div>

        <div data-coach="games">
          <GamesCard onClick={onGames} />
        </div>

        {/* Section label + seviye */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
          <p
            style={{
              fontSize: font.size.xs,
              fontWeight: font.weight.bold,
              color: colors.textSubtle,
              letterSpacing: "0.08em",
              textTransform: "uppercase",
            }}
          >
            {teacherPick ? "Öğretmeninin seçtiği konular" : "Pratik Kategorileri"}
          </p>
        </div>
      </div>

      {/* Konu kartları. Öğretmen konu seçtiyse önce onlar, diğerleri "Diğer konular" altında kapalı. */}
      {groups.map((g) => (
        <Fragment key={g.key}>
          {g.key === "rest" && (
            <button
              onClick={() => setShowRest((v) => !v)}
              aria-expanded={showRest}
              className="mx-4 mb-2.5"
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                width: "calc(100% - 32px)",
                minHeight: 44,
                background: "none",
                border: "none",
                borderTop: `1px solid ${colors.border}`,
                cursor: "pointer",
                fontFamily: font.family.ui,
                fontSize: font.size.sm,
                fontWeight: font.weight.semibold,
                color: colors.textMuted,
                padding: "8px 0 0",
              }}
            >
              <span>Diğer konular ({g.count})</span>
              <span aria-hidden="true">{showRest ? "▴" : "▾"}</span>
            </button>
          )}
          {(g.key === "main" || showRest) && (
            <div className={`px-4 pb-6 ${tablet ? "grid grid-cols-2 gap-3" : "flex flex-col gap-2.5"}`}>
              {categories.map((cat) => (
                <Fragment key={cat.key}>
                  {g.has(cat.key) && !(cat.key === "accidentals" && lv < 2) && (
                    <button
                      data-coach={cat.key === "treble" ? "categories" : undefined}
                      onClick={() => onStart(cat.key)}
                      className="flex items-center gap-3.5 rounded-2xl px-4 py-2.5 text-left w-full"
                      style={{
                        background: colors.fill,
                        border: `1px solid ${colors.border}`,
                        transition: "all 0.15s ease",
                      }}
                      onMouseEnter={(e) => {
                        const el = e.currentTarget as HTMLElement
                        el.style.background = alpha(cat.color, 0.08)
                        el.style.borderColor = alpha(cat.color, 0.27)
                      }}
                      onMouseLeave={(e) => {
                        const el = e.currentTarget as HTMLElement
                        el.style.background = colors.fill
                        el.style.borderColor = colors.border
                      }}
                    >
                      {/* Icon square */}
                      <div
                        style={{
                          width: 44,
                          height: 44,
                          borderRadius: radius.md,
                          background: `linear-gradient(135deg, ${cat.color}28, ${cat.color}14)`,
                          border: `1px solid ${cat.color}33`,
                          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06)",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          fontSize: font.size.lg,
                          color: cat.color,
                          flexShrink: 0,
                        }}
                      >
                        {cat.key === "treble" || cat.key === "bass" ? (
                          <ClefIcon clef={cat.key} size={24} />
                        ) : cat.key === "ear" ? (
                          <Icon name="speaker" size={22} />
                        ) : (
                          cat.icon
                        )}
                      </div>

                      {/* Text */}
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <p
                          style={{
                            fontSize: font.size.md,
                            fontWeight: font.weight.semibold,
                            color: colors.text,
                            marginBottom: 2,
                          }}
                        >
                          {cat.label}
                        </p>
                        <p style={{ fontSize: font.size.sm, color: colors.textMuted, fontWeight: font.weight.regular }}>
                          {(cat.key === "treble" || cat.key === "bass") && limitedNotes
                            ? `Sadece ${getSettings().notes.join(" ")}`
                            : cat.sub}
                        </p>
                      </div>

                      {/* Bu konudaki doğruluk (R19): yıldız ve oynat simgesi yerine yüzde halkası */}
                      <PercentRing acc={cat.acc} color={cat.color} />
                    </button>
                  )}
                  {cat.key === "accidentals" && g.has("chords") && (
                    <TopicLink
                      color={category.chords}
                      icon="piano"
                      title="Akor"
                      sub="Tanı, tuşlara bas"
                      acc={ca.chords}
                      onClick={onChordQuiz}
                    />
                  )}
                  {cat.key === "rhythm" && (
                    <TopicLink
                      color={category.rhythm}
                      icon="note"
                      title="Ritmi Tut"
                      sub="Metronomla dokunarak çal"
                      acc={stats.bestStars?.rhythmtap === undefined ? { correct: 0, total: 0 } : ca.rhythm}
                      onClick={onRhythmTap}
                    />
                  )}
                </Fragment>
              ))}
            </div>
          )}
        </Fragment>
      ))}
    </div>
  )
}

// Ana sayfadaki Oyunlar kartı: günün meydan okuması oynandı mı gösterir
function GamesCard({ onClick }: { onClick: () => void }) {
  const today = dailyInfo(todayStr())
  const done = loadDaily()[today.date]
  return (
    <button
      onClick={onClick}
      className="flex items-center gap-3 rounded-2xl text-left w-full"
      style={{
        padding: "10px 14px",
        marginBottom: 20,
        background: alpha(palette.green500, 0.06),
        border: "1px solid rgba(16,185,129,0.3)",
        cursor: "pointer",
      }}
    >
      <div
        style={{
          width: 36,
          height: 36,
          borderRadius: radius.md,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          flexShrink: 0,
          background: alpha(palette.green500, 0.14),
          color: colors.greenText,
        }}
      >
        <Icon name="trophy" size={19} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <p style={{ fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text }}>Oyunlar</p>
        <p
          style={{
            fontSize: font.size.xs,
            color: colors.textMuted,
            whiteSpace: "nowrap",
            overflow: "hidden",
            textOverflow: "ellipsis",
          }}
        >
          Meydan okuma ve düello
        </p>
      </div>
      <span
        style={{
          padding: "4px 10px",
          borderRadius: radius.pill,
          fontSize: font.size.xs,
          fontWeight: font.weight.bold,
          whiteSpace: "nowrap",
          color: done ? colors.textMuted : colors.greenText,
          background: done ? colors.fillStrong : alpha(palette.green500, 0.14),
        }}
      >
        {done ? `Bugün ${done.correct}/10` : "Günün oyunu"}
      </span>
    </button>
  )
}
