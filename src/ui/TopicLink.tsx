// Konu altı bağlantısı: bir konunun hemen altında duran ek alıştırma satırı
// (Diyez & Bemol › Akor, Ritim & Ölçü › Ritmi Tut). Konu kartından biraz küçük, ikon rengi o konunun rengi; oynat düğmesi her satırda aynı (PlayChip).
import type { IconName } from "../components/Icons"
import Icon from "../components/Icons"
import { alpha, colors, font, radius } from "../design/tokens"
import PlayChip from "./PlayChip"
import Stars from "./Stars"
import PercentRing from "./PercentRing"

export default function TopicLink({
  color,
  icon,
  title,
  sub,
  stars,
  acc,
  onClick,
}: {
  color: { base: string; text: string }
  icon: IconName
  title: string
  sub: string
  stars?: number
  /** Verilirse yıldız ve oynat simgesi yerine yüzde halkası (revize R19) */
  acc?: { correct: number; total: number }
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      style={{
        display: "flex",
        alignItems: "center",
        gap: 14,
        width: "100%",
        padding: "10px 16px",
        borderRadius: 16,
        textAlign: "left",
        cursor: "pointer",
        fontFamily: font.family.ui,
        background: colors.fill,
        border: `1px solid ${colors.border}`,
        transition: "all 0.15s ease",
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.background = alpha(color.base, 0.08)
        e.currentTarget.style.borderColor = alpha(color.base, 0.27)
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.background = colors.fill
        e.currentTarget.style.borderColor = colors.border
      }}
    >
      <div
        style={{
          width: 44,
          height: 44,
          borderRadius: radius.md,
          background: `linear-gradient(135deg, ${alpha(color.base, 0.16)}, ${alpha(color.base, 0.08)})`,
          border: `1px solid ${alpha(color.base, 0.2)}`,
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          flexShrink: 0,
        }}
      >
        <Icon name={icon} size={22} color={color.text} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <p style={{ fontSize: font.size.md, fontWeight: font.weight.semibold, color: colors.text, marginBottom: 2 }}>
          {title}
        </p>
        <p style={{ fontSize: font.size.sm, color: colors.textMuted, fontWeight: font.weight.regular }}>{sub}</p>
      </div>
      {acc ? (
        <PercentRing acc={acc} color={color.base} />
      ) : (
        <>
          {stars !== undefined && <Stars value={stars} size={13} />}
          <PlayChip />
        </>
      )}
    </button>
  )
}
