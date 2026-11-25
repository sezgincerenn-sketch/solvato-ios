// Tur sonucundaki "Serin başladı! Hatırlatayım mı?" kartı (revize R8). Hatırlatma kapalıyken seri ilk kez 1
// olduğunda bir kez görünür; "Hatırlat" bildirim izni ister ve saati şimdiki saate en yakın tam saate kurar.
import { useState } from "react"
import Icon from "../components/Icons"
import { alpha, colors, font, palette, radius, space } from "../design/tokens"
import { enableReminder } from "../utils/reminder"
import { getSettings, updateSettings } from "../utils/settings"

function nearestHour() {
  const d = new Date()
  return (d.getHours() + (d.getMinutes() >= 30 ? 1 : 0)) % 24
}

export default function StreakReminderCard({ streak }: { streak: number }) {
  const s = getSettings()
  const [visible, setVisible] = useState(() => streak === 1 && !s.reminder && !s.streakReminderOffered)
  const [note, setNote] = useState<string | null>(null)
  const [hour] = useState(nearestHour)
  if (!visible && !note) return null
  const hh = String(hour).padStart(2, "0")

  const close = () => {
    updateSettings({ streakReminderOffered: true })
    setVisible(false)
  }
  const remind = async () => {
    const ok = await enableReminder(hour)
    updateSettings({ streakReminderOffered: true, ...(ok ? { reminder: true, reminderHour: hour } : {}) })
    setVisible(false)
    setNote(ok ? `Her gün ${hh}:00'de hatırlatacağım.` : "Bildirim izni verilmedi; Ayarlar'dan açabilirsin.")
  }

  if (note)
    return (
      <p style={{ width: "100%", marginBottom: space[4], fontSize: font.size.sm, color: colors.textMuted }}>{note}</p>
    )

  const btn = {
    flex: 1,
    padding: "12px",
    borderRadius: radius.md,
    border: "none",
    fontFamily: font.family.ui,
    fontSize: font.size.md,
    cursor: "pointer",
  } as const
  return (
    <div
      style={{
        width: "100%",
        marginBottom: space[4],
        padding: space[4],
        borderRadius: radius.lg,
        background: alpha(palette.orange500, 0.1),
        border: `1px solid ${alpha(palette.orange500, 0.35)}`,
        display: "flex",
        flexDirection: "column",
        gap: space[3],
      }}
    >
      <div style={{ display: "flex", gap: space[3], alignItems: "center" }}>
        <span
          aria-hidden="true"
          style={{
            width: 44,
            height: 44,
            borderRadius: radius.md,
            background: alpha(palette.orange500, 0.2),
            color: colors.orangeText,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexShrink: 0,
          }}
        >
          <Icon name="flame" size={22} fill />
        </span>
        <div>
          <p style={{ fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text }}>Serin başladı!</p>
          <p style={{ fontSize: font.size.sm, color: colors.textSoft }}>
            Serini koru. Yarın bu saatte hatırlatayım mı?
          </p>
        </div>
      </div>
      <div style={{ display: "flex", gap: space[2] }}>
        <button onClick={close} style={{ ...btn, background: colors.fillStrong, color: colors.text }}>
          Şimdi değil
        </button>
        <button
          onClick={remind}
          style={{ ...btn, background: palette.orange500, color: palette.white, fontWeight: font.weight.bold }}
        >
          Hatırlat · {hh}:00
        </button>
      </div>
    </div>
  )
}
