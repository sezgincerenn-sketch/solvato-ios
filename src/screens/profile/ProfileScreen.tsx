// Profil sekmesi (revize R13): isim ve renk, seviye, toplam ilerleme; Ayarlar yalnız sağ üstte (R14)
import { useState } from "react"
import Icon from "../../components/Icons"
import { colors, font, radius, space } from "../../design/tokens"
import { currentStreak } from "../../state/stats"
import type { AppStats } from "../../types"
import { AVATAR_COLORS, Avatar, Button, Card, ScreenHeader, StatTile, useToast } from "../../ui"
import { buildWeeklyReport, weeklyReportText } from "../../utils/weeklyReport"
import { shareWithToast } from "../gameShared"
import { rankFromXp } from "../../utils/level"
import RankCard from "./RankCard"
import { getSettings, updateSettings } from "../../utils/settings"
import LevelCard from "./LevelCard"

export default function ProfileScreen({
  stats,
  onOpenSettings,
  onOpenProgress,
}: {
  stats: AppStats
  onOpenSettings: () => void
  onOpenProgress: () => void
}) {
  const s = getSettings()
  const [name, setName] = useState(s.name)
  const [color, setColor] = useState(s.avatarColor)
  const xp = rankFromXp(stats.totalPoints)
  const toast = useToast()
  const solved = Object.values(stats.dailyQuestions ?? {}).reduce((a, b) => a + b, 0)
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

        <LevelCard detailed />
        <RankCard xp={stats.totalPoints} detailed />

        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, minmax(0, 1fr))", gap: space[2] }}>
          <StatTile value={`${currentStreak(stats)} gün`} label="Seri" />
          <StatTile value={`${stats.totalSessions}`} label="Tamamlanan tur" />
          <StatTile value={`${solved}`} label="Çözülen soru" />
        </div>

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
