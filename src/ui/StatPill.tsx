// Üst bardaki küçük gösterge hapı: seri, XP. Hepsi aynı ölçüde; onClick verilirse dokununca ilgili ekranı açar,
// verilmezse yalnız bilgi verir (revize R15: seri hapı basılmaz).
// Renk anlamı tasarım sisteminde sabit: seri = turuncu, XP = amber, henüz yok = soluk.
import type { ReactNode } from "react"
import { alpha, colors, font, palette, radius } from "../design/tokens"

const TONES = {
  orange: { base: palette.orange500, text: colors.orangeText },
  amber: { base: palette.amber500, text: colors.amberText },
  muted: { base: palette.slate400, text: colors.textMuted },
} as const

export type StatPillTone = keyof typeof TONES

export default function StatPill({
  tone,
  leading,
  value,
  label,
  onClick,
}: {
  tone: StatPillTone
  /** Soldaki ikon ya da rozet; currentColor ile boyanır */
  leading: ReactNode
  /** Sayı (mono yazılır), ör. "12" ya da "180 XP" */
  value: string
  /** Ekran okuyucu için tam cümle, ör. "12 gün seri. Haftanı gör" */
  label: string
  onClick?: () => void
}) {
  const t = TONES[tone]
  const Tag = onClick ? "button" : "span"
  return (
    <Tag
      onClick={onClick}
      aria-label={label}
      role={onClick ? undefined : "img"}
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 6,
        minHeight: 36,
        padding: "0 12px 0 6px",
        borderRadius: radius.pill,
        background: alpha(t.base, 0.12),
        border: `1px solid ${alpha(t.base, 0.3)}`,
        color: t.text,
        cursor: onClick ? "pointer" : "default",
        whiteSpace: "nowrap",
        fontFamily: font.family.ui,
      }}
    >
      <span
        aria-hidden="true"
        style={{ width: 26, height: 26, display: "inline-flex", alignItems: "center", justifyContent: "center" }}
      >
        {leading}
      </span>
      <span style={{ fontSize: font.size.sm, fontWeight: font.weight.bold, fontFamily: font.family.mono }}>
        {value}
      </span>
    </Tag>
  )
}
