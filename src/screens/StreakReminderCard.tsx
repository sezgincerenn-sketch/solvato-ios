// Tur sonucundaki "Serini koru" kartı (revize R8; native ile aynı, Ceren 26 Kasım). Hatırlatma kapalıyken seri ilk kez 1
// olduğunda bir kez görünür; "Hatırlat" bildirim izni ister ve hatırlatmayı şimdiki saate kurar. İzin verilmezse kartta
// uyarı kalır; verilirse kart kapanır.
import { useEffect, useState } from "react"
import Icon from "../components/Icons"
import { colors, font, palette, space } from "../design/tokens"
import { Button, Card } from "../ui"
import { enableReminder } from "../utils/reminder"
import { getSettings, updateSettings } from "../utils/settings"

export default function StreakReminderCard({ streak }: { streak: number }) {
  const s = getSettings()
  const [visible, setVisible] = useState(() => streak === 1 && !s.reminder && !s.streakReminderOffered)
  const [msg, setMsg] = useState("")
  // Bir kez: gösterildiği an işaretlenir (native gibi)
  useEffect(() => {
    if (visible) updateSettings({ streakReminderOffered: true })
  }, []) // eslint-disable-line react-hooks/exhaustive-deps
  if (!visible) return null

  const close = () => setVisible(false)
  const remind = async () => {
    const d = new Date()
    const h = d.getHours()
    const m = d.getMinutes()
    const ok = await enableReminder(h, m)
    updateSettings({
      streakReminderOffered: true,
      ...(ok ? { reminder: true, reminderHour: h, reminderMinute: m } : {}),
    })
    if (ok) setVisible(false)
    else setMsg("Bildirim izni verilmedi. iPhone Ayarlar → Solvato → Bildirimler bölümünden açabilirsin.")
  }

  return (
    <Card
      tone={palette.violet500}
      style={{ width: "100%", marginBottom: space[4], display: "flex", flexDirection: "column", gap: space[3] }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: space[2] }}>
        <span aria-hidden="true" style={{ color: colors.orangeText, display: "flex" }}>
          <Icon name="flame" size={18} fill />
        </span>
        <p style={{ fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text }}>Serini koru</p>
      </div>
      <p style={{ fontSize: font.size.sm, color: colors.textMuted }}>Yarın bu saatte hatırlatayım mı?</p>
      {msg ? (
        <p style={{ fontSize: font.size.sm, color: colors.redText, lineHeight: 1.4 }}>{msg}</p>
      ) : (
        <div style={{ display: "flex", gap: space[2] }}>
          <Button block variant="secondary" onClick={close}>
            Şimdi değil
          </Button>
          <Button block onClick={remind}>
            Hatırlat
          </Button>
        </div>
      )}
    </Card>
  )
}
