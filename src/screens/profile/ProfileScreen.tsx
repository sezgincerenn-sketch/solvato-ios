// Profil sekmesi (revize R13): isim ve renk, seviye, toplam ilerleme; Ayarlar yalnız sağ üstte (R14)
import { useState } from "react"
import Icon from "../../components/Icons"
import { alpha, colors, font, palette, radius, space } from "../../design/tokens"
import type { AppStats } from "../../types"
import { AVATAR_COLORS, Avatar, Button, Card, ScreenHeader, useToast } from "../../ui"
import { buildWeeklyReport, weeklyReportText } from "../../utils/weeklyReport"
import { shareWithToast } from "../gameShared"
import { rankFromXp } from "../../utils/level"
import RankCard from "./RankCard"
import { getSettings, updateSettings } from "../../utils/settings"
import LevelCard from "./LevelCard"

export default function ProfileScreen({
  stats,
  onOpenTeacher,
  onOpenSettings,
  onOpenProgress,
}: {
  stats: AppStats
  /** Öğretmen kodu ekranı (revize R14: Ayarlar'dan Profil'e taşındı) */
  onOpenTeacher: () => void
  onOpenSettings: () => void
  onOpenProgress: () => void
}) {
  const s = getSettings()
  const [name, setName] = useState(s.name)
  const [color, setColor] = useState(s.avatarColor)
  const xp = rankFromXp(stats.totalPoints)
  const toast = useToast()
  const since = s.joinedAt
    ? new Date(s.joinedAt).toLocaleDateString("tr-TR", { day: "numeric", month: "long", year: "numeric" })
    : null

  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column", fontFamily: font.family.ui }}>
      <ScreenHeader
        title="Profil"
        right={
          <button
            onClick={onOpenSettings}
            aria-label="Ayarlar"
            style={{
              width: 44,
              height: 44,
              borderRadius: radius.md,
              background: colors.fillStrong,
              border: `1px solid ${colors.border}`,
              color: colors.textSecondary,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              cursor: "pointer",
            }}
          >
            <Icon name="settings" size={20} />
          </button>
        }
      />
      <div
        style={{
          flex: 1,
          minHeight: 0,
          overflowY: "auto",
          padding: `${space[2]}px ${space[4]}px ${space[8]}px`,
          display: "flex",
          flexDirection: "column",
          gap: space[3],
        }}
      >
        {/* Kimlik */}
        <Card
          style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: space[3], padding: space[5] }}
        >
          <Avatar name={name} color={color} size={80} />
          <input
            value={name}
            onChange={(e) => {
              const v = e.target.value.slice(0, 24)
              setName(v)
              updateSettings({ name: v.trim() })
            }}
            placeholder="İsmin"
            aria-label="İsim"
            style={{
              width: "100%",
              maxWidth: 260,
              textAlign: "center",
              padding: `${space[2]}px ${space[3]}px`,
              borderRadius: radius.md,
              fontSize: font.size.lg,
              fontWeight: font.weight.heavy,
              fontFamily: font.family.ui,
              color: colors.text,
              background: "transparent",
              border: `1px dashed ${colors.borderStrong}`,
              outline: "none",
            }}
          />
          <div style={{ display: "flex", gap: space[2] }} role="radiogroup" aria-label="Profil rengi">
            {Object.entries(AVATAR_COLORS).map(([k, [a, b]]) => (
              <button
                key={k}
                role="radio"
                aria-checked={color === k}
                aria-label={k}
                onClick={() => {
                  setColor(k)
                  updateSettings({ avatarColor: k })
                }}
                style={{
                  width: 28,
                  height: 28,
                  borderRadius: "50%",
                  cursor: "pointer",
                  background: `linear-gradient(135deg, ${a}, ${b})`,
                  border: "none",
                  outline: color === k ? `2px solid ${colors.text}` : "none",
                  outlineOffset: 2,
                }}
              />
            ))}
          </div>
          <p style={{ fontSize: font.size.sm, color: colors.textMuted }}>
            {xp.label} ünvanı
            {since ? ` · ${since}'den beri` : ""}
          </p>
        </Card>

        <TeacherCard onOpen={onOpenTeacher} onRemoved={() => toast.show("Öğretmen kodu kaldırıldı")} />

        <LevelCard detailed actionLabel="Ayarları aç" onClick={onOpenSettings} />
        <RankCard xp={stats.totalPoints} detailed />

        <Button
          onClick={() => shareWithToast(weeklyReportText(buildWeeklyReport(stats, getSettings())), toast.show)}
          icon={<Icon name="share" size={18} />}
        >
          Haftalık raporu öğretmenine gönder
        </Button>
        <Button variant="secondary" onClick={onOpenProgress}>
          Tüm ilerleme
        </Button>
      </div>
      {toast.el}
    </div>
  )
}

// Öğretmen kodu kartı (revize R14, R20): kod yoksa koda götürür; varsa kodu, "Diğer konuları da göster" ve "Kodu kaldır".
function TeacherCard({ onOpen, onRemoved }: { onOpen: () => void; onRemoved: () => void }) {
  const s = getSettings()
  const [showRest, setShowRest] = useState(s.showRestTopics)
  const [code, setCode] = useState(s.teacherCode)
  // Tanıtımdaki öğretmen sorusuna göre kart öne çıkar (revize R5)
  const title = code
    ? "Öğretmen kodu"
    : s.teacherRole === "teacher"
      ? "Öğrenci kodu hazırla"
      : s.teacherRole === "student"
        ? "Öğretmen kodunu gir"
        : "Öğretmen kodu"
  const sub = code
    ? `Uygulandı · ${code}`
    : s.teacherRole === "teacher"
      ? "Öğrencilerine konu, seviye ve hedef gönder"
      : s.teacherRole === "student"
        ? "Öğretmeninin gönderdiği kodu yaz"
        : "Öğretmeninin kodunu gir ya da öğrencine kod hazırla"
  const highlight = !code && (s.teacherRole === "student" || s.teacherRole === "teacher")
  const rowBtn = {
    padding: "8px 12px",
    borderRadius: radius.md,
    border: "none",
    fontFamily: font.family.ui,
    fontSize: font.size.sm,
    fontWeight: font.weight.semibold,
    cursor: "pointer",
  } as const
  return (
    <Card
      style={highlight ? { borderColor: palette.violet500, background: alpha(palette.violet500, 0.08) } : undefined}
    >
      <button
        onClick={onOpen}
        style={{
          display: "flex",
          alignItems: "center",
          gap: space[3],
          width: "100%",
          padding: 0,
          background: "none",
          border: "none",
          textAlign: "left",
          cursor: "pointer",
          fontFamily: font.family.ui,
        }}
      >
        <span
          aria-hidden="true"
          style={{
            width: 36,
            height: 36,
            borderRadius: radius.md,
            background: colors.fillStrong,
            color: colors.violetText,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexShrink: 0,
          }}
        >
          <Icon name="users" size={18} />
        </span>
        <span style={{ flex: 1, minWidth: 0 }}>
          <span style={{ display: "block", fontWeight: font.weight.bold, color: colors.text }}>{title}</span>
          <span style={{ display: "block", fontSize: font.size.sm, color: colors.textMuted }}>{sub}</span>
        </span>
        <span aria-hidden="true" style={{ color: colors.textMuted }}>
          ›
        </span>
      </button>
      {code && (
        <div style={{ display: "flex", flexDirection: "column", gap: space[2], marginTop: space[3] }}>
          <p style={{ fontSize: font.size.sm, color: colors.textMuted }}>
            Öğretmeninin konuları Ana sayfada üstte. Diğer konuları da açık tutabilirsin.
          </p>
          <div style={{ display: "flex", gap: space[2], flexWrap: "wrap" }}>
            <button
              aria-pressed={showRest}
              onClick={() => {
                updateSettings({ showRestTopics: !showRest })
                setShowRest(!showRest)
              }}
              style={{ ...rowBtn, background: showRest ? colors.fillStronger : colors.fillStrong, color: colors.text }}
            >
              {showRest ? "Diğer konular açık ✓" : "Diğer konuları da göster"}
            </button>
            <button
              onClick={() => {
                updateSettings({ teacherCode: "", topics: [], showRestTopics: false })
                setCode("")
                onRemoved()
              }}
              style={{ ...rowBtn, background: colors.fillStrong, color: colors.redText }}
            >
              Kodu kaldır
            </button>
          </div>
        </div>
      )}
    </Card>
  )
}
