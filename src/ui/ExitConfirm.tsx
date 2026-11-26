// Turdan çıkış onayı: test, akor ve Ritmi Tut ekranlarının geri düğmesi bunu açar.
// "Devam et" data-back taşır: açıkken Android geri tuşu / kenardan kaydırma pencereyi kapatır.
import { colors, font, gradient, radius } from "../design/tokens"

export default function ExitConfirm({
  onStay,
  onExit,
  title = "Turdan çıkılsın mı?",
  text = "Bu turdaki cevapların kaydedilmeyecek.",
}: {
  onStay: () => void
  onExit: () => void
  title?: string
  text?: string
}) {
  const btn = {
    flex: 1,
    padding: 13,
    borderRadius: radius.md,
    fontSize: font.size.sm,
    fontWeight: font.weight.bold,
    cursor: "pointer",
  } as const
  return (
    <div
      role="dialog"
      aria-modal="true"
      data-exit-open
      aria-label="Turdan çık"
      style={{
        position: "absolute",
        inset: 0,
        background: colors.scrim,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 24,
        zIndex: 60,
      }}
    >
      <div
        style={{
          width: "100%",
          maxWidth: 320,
          background: colors.surface,
          border: `1px solid ${colors.border}`,
          borderRadius: radius.lg,
          padding: 20,
          fontFamily: font.family.ui,
        }}
      >
        <p style={{ fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text, marginBottom: 6 }}>
          {title}
        </p>
        <p style={{ fontSize: font.size.sm, color: colors.textMuted, lineHeight: 1.5, marginBottom: 16 }}>{text}</p>
        <div style={{ display: "flex", gap: 10 }}>
          <button
            data-back
            onClick={onStay}
            style={{ ...btn, background: gradient.primaryFlat, color: colors.onPrimary, border: "none" }}
          >
            Devam et
          </button>
          <button
            onClick={onExit}
            style={{
              ...btn,
              background: colors.fillStrong,
              color: colors.textSecondary,
              border: `1px solid ${colors.border}`,
            }}
          >
            Çık
          </button>
        </div>
      </div>
    </div>
  )
}
