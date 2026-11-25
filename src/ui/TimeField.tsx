// Saat seçici (revize R9): telefonda sistemin saat çarkını açar; tanıtımda ve Ayarlar'da aynı, bütün saatler seçilebilir.
import { colors, font, radius } from "../design/tokens"

export default function TimeField({
  hour,
  minute,
  onChange,
  label = "Hatırlatma saati",
}: {
  hour: number
  minute: number
  onChange: (hour: number, minute: number) => void
  label?: string
}) {
  const p = (n: number) => String(n).padStart(2, "0")
  return (
    <input
      type="time"
      className="time-field"
      aria-label={label}
      value={`${p(hour)}:${p(minute)}`}
      onChange={(e) => {
        const [h, m] = e.target.value.split(":").map(Number)
        if (Number.isFinite(h) && Number.isFinite(m)) onChange(h, m)
      }}
      style={{
        display: "block",
        width: "100%",
        maxWidth: "100%",
        minWidth: 0,
        boxSizing: "border-box",
        // iOS Safari saat alanına kendi genişliğini verir ve kutudan taşar; görünümü sıfırlanınca %100'e uyar
        appearance: "none",
        WebkitAppearance: "none",
        padding: "14px 16px",
        borderRadius: radius.lg,
        fontSize: font.size.xl,
        fontWeight: font.weight.bold,
        fontFamily: font.family.ui,
        fontVariantNumeric: "tabular-nums",
        textAlign: "center",
        color: colors.text,
        background: colors.fillStrong,
        border: `1px solid ${colors.borderStrong}`,
        colorScheme: "inherit",
      }}
    />
  )
}
