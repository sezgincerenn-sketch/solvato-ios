// Seviye kartı: Başlangıç / Orta / İleri ve bir sonraki seviyeye ilerleme.
// Ana sayfada (kısa) ve Profil'de (açıklamalı) kullanılır.
import { LEVEL_LABELS } from "../../data/questions"
import { alpha, colors, font, palette, radius, space } from "../../design/tokens"
import { LEVEL_ACC, LEVEL_NEED } from "../../state/stats"
import { getSettings } from "../../utils/settings"

// onClick varsa sağ üstte "›" (revize R39, R37): Ana sayfada Profil'i, Profil'de Ayarlar'ı açar
export default function LevelCard({
  onClick,
  detailed,
  actionLabel = "Profili aç",
}: {
  onClick?: () => void
  detailed?: boolean
  actionLabel?: string
}) {
  const s = getSettings()
  const lv = s.level
  const { n, c } = s.levelProgress
  const acc = n > 0 ? Math.round((c / n) * 100) : null
  const top = lv >= 3
  const pct = top ? 100 : Math.min(100, (n / LEVEL_NEED) * 100)
  const accOk = acc !== null && acc >= LEVEL_ACC * 100

  const body = (
    <>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: space[2] }}>
        <div style={{ minWidth: 0, flex: 1 }}>
          <p
            style={{
              fontSize: font.size.xs,
              fontWeight: font.weight.bold,
              color: colors.textSubtle,
              letterSpacing: font.tracking.label,
              textTransform: "uppercase",
            }}
          >
            Seviye
          </p>
          <p
            style={{
              fontSize: font.size.lg,
              fontWeight: font.weight.heavy,
              color: colors.text,
              letterSpacing: "-0.02em",
            }}
          >
            {LEVEL_LABELS[lv]}
          </p>
        </div>
        {/* Üç basamak: geçilen, şu anki, sonraki */}
        <div style={{ display: "flex", gap: 6 }} aria-label={`3 seviyeden ${lv}.`}>
          {[1, 2, 3].map((k) => (
            <span
              key={k}
              title={LEVEL_LABELS[k as 1 | 2 | 3]}
              style={{
                padding: "4px 10px",
                borderRadius: radius.pill,
                fontSize: font.size.xs,
                fontWeight: font.weight.bold,
                background: k === lv ? palette.violet600 : k < lv ? alpha(palette.violet500, 0.25) : colors.fillStrong,
                color: k === lv ? palette.white : k < lv ? colors.violetTextSoft : colors.textMuted,
              }}
            >
              {LEVEL_LABELS[k as 1 | 2 | 3]}
            </span>
          ))}
        </div>
        {onClick && (
          <span aria-hidden="true" style={{ color: colors.textFaint, fontSize: font.size.lg }}>
            ›
          </span>
        )}
      </div>
      {!top && (
        <>
          <div
            style={{
              height: 6,
              borderRadius: radius.pill,
              background: colors.fillStrong,
              marginTop: space[3],
              overflow: "hidden",
            }}
          >
            <div
              style={{
                width: `${pct}%`,
                height: "100%",
                borderRadius: radius.pill,
                background: `linear-gradient(90deg, ${palette.violet600}, ${palette.violet400})`,
                transition: "width 0.6s ease",
              }}
            />
          </div>
          <p style={{ fontSize: font.size.sm, color: colors.textMuted, marginTop: space[2] }}>
            {n === 0
              ? `${LEVEL_LABELS[(lv + 1) as 2 | 3]} için bu seviyede ${LEVEL_NEED} soru çöz, %${LEVEL_ACC * 100} doğru yap.`
              : `${LEVEL_LABELS[(lv + 1) as 2 | 3]} seviyesine: ${Math.min(n, LEVEL_NEED)}/${LEVEL_NEED} soru · %${acc} doğru${accOk ? "" : ` (en az %${LEVEL_ACC * 100})`}`}
          </p>
        </>
      )}
      {top && (
        <p style={{ fontSize: font.size.sm, color: colors.textMuted, marginTop: space[2] }}>
          En üst seviyedesin. Ek çizgili zor notalar açık.
        </p>
      )}
      {detailed && (
        <p style={{ fontSize: font.size.sm, color: colors.textFaint, marginTop: space[2], lineHeight: 1.5 }}>
          Seviye, gelen soruların zorluğunu belirler. Ayarlar'dan elle de değiştirebilirsin.
        </p>
      )}
    </>
  )

  const box = {
    width: "100%",
    textAlign: "left" as const,
    padding: space[4],
    borderRadius: radius.lg,
    background: colors.fill,
    border: `1px solid ${colors.border}`,
    fontFamily: font.family.ui,
  }
  return onClick ? (
    <button
      onClick={onClick}
      style={{ ...box, cursor: "pointer" }}
      aria-label={`Seviye: ${LEVEL_LABELS[lv]}. ${actionLabel}`}
    >
      {body}
    </button>
  ) : (
    <div style={box}>{body}</div>
  )
}
