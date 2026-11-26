// Son turlar: tarih, konu, doğru sayısı, süre. onReplay verilirse satıra dokununca aynı konudan yeni tur (revize R38)
import { fmtSec } from "../../utils/games"
import type { RoundRecord } from "../../types"
import { colors, font, space } from "../../design/tokens"
import { Stars } from "../../ui"
import { starsFor } from "../../utils/stars"

function when(at: number) {
  const d = new Date(at)
  const today = new Date()
  const y = new Date(Date.now() - 86400000)
  const hm = d.toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })
  if (d.toDateString() === today.toDateString()) return `Bugün ${hm}`
  if (d.toDateString() === y.toDateString()) return `Dün ${hm}`
  return d.toLocaleDateString("tr-TR", { day: "numeric", month: "short" }) + ` ${hm}`
}

export default function RoundHistory({
  rounds,
  limit,
  onReplay,
}: {
  rounds: RoundRecord[]
  limit?: number
  onReplay?: (r: RoundRecord) => void
}) {
  const list = limit ? rounds.slice(0, limit) : rounds
  if (list.length === 0)
    return <p style={{ fontSize: font.size.sm, color: colors.textMuted }}>Tamamladığın turlar burada listelenir.</p>
  return (
    <ul style={{ listStyle: "none", margin: 0, padding: 0, display: "flex", flexDirection: "column" }}>
      {list.map((r, i) => {
        return (
          <li
            key={r.at + "-" + i}
            role={onReplay ? "button" : undefined}
            tabIndex={onReplay ? 0 : undefined}
            aria-description={onReplay ? "Aynı konudan yeni tur" : undefined}
            onClick={onReplay ? () => onReplay(r) : undefined}
            onKeyDown={onReplay ? (e) => e.key === "Enter" && onReplay(r) : undefined}
            style={{
              cursor: onReplay ? "pointer" : undefined,
              display: "flex",
              alignItems: "center",
              gap: space[3],
              padding: `${space[2]}px 0`,
              borderTop: i ? `1px solid ${colors.border}` : "none",
            }}
          >
            <Stars value={starsFor(r.correct, r.total)} size={11} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <p style={{ fontSize: font.size.sm, fontWeight: font.weight.semibold, color: colors.text }}>{r.label}</p>
              <p style={{ fontSize: font.size.xs, color: colors.textSubtle }}>{when(r.at)}</p>
            </div>
            <div style={{ textAlign: "right" }}>
              <p
                style={{
                  fontSize: font.size.sm,
                  fontWeight: font.weight.bold,
                  color: colors.text,
                  fontFamily: font.family.mono,
                }}
              >
                {r.correct}/{r.total}
              </p>
              {r.sec !== undefined && (
                <p style={{ fontSize: font.size.xs, color: colors.textSubtle, fontFamily: font.family.mono }}>
                  {fmtSec(r.sec)}
                </p>
              )}
            </div>
            {onReplay && (
              <span aria-hidden="true" style={{ color: colors.textFaint, fontSize: font.size.lg }}>
                ›
              </span>
            )}
          </li>
        )
      })}
    </ul>
  )
}
