// Konu kartının sağındaki küçük yüzde halkası (revize R19): o konudaki doğruluk oranı kadar dolu.
// Hiç çözülmemişse boş halka ve "–". Ana sayfa konu kartları ve konu altı bağlantıları (TopicLink) kullanır.
import { colors, font } from "../design/tokens"

export default function PercentRing({
  acc,
  color,
  size = 44,
}: {
  /** Doğru / toplam; toplam 0 ise boş halka */
  acc: { correct: number; total: number } | undefined
  color: string
  size?: number
}) {
  const total = acc?.total ?? 0
  const pct = total > 0 ? Math.round(((acc?.correct ?? 0) / total) * 100) : null
  const sw = 5
  const r = size / 2 - sw
  const circ = 2 * Math.PI * r
  const c = size / 2
  return (
    <svg
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      role="img"
      aria-label={pct === null ? "Henüz çözülmedi" : `Yüzde ${pct} doğru`}
      style={{ flexShrink: 0 }}
    >
      <circle cx={c} cy={c} r={r} fill="none" stroke={colors.fillStronger} strokeWidth={sw} />
      {pct !== null && pct > 0 && (
        <circle
          cx={c}
          cy={c}
          r={r}
          fill="none"
          stroke={color}
          strokeWidth={sw}
          strokeLinecap="round"
          strokeDasharray={`${(circ * pct) / 100} ${circ}`}
          transform={`rotate(-90 ${c} ${c})`}
        />
      )}
      <text
        x={c}
        y={c + 4}
        textAnchor="middle"
        fontSize={pct === null ? 13 : 11}
        fontWeight={700}
        fill={pct === null ? colors.textFaint : colors.text}
        fontFamily={font.family.ui}
      >
        {pct === null ? "–" : `%${pct}`}
      </text>
    </svg>
  )
}
