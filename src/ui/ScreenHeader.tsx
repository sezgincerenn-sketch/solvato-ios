// Alt ekran başlığı: geri düğmesi + başlık (+ sağda isteğe bağlı öğe). onBack yoksa (sekme ekranı) geri düğmesi çizilmez.
import type { ReactNode } from "react"
import { colors, font, space } from "../design/tokens"
import BackButton from "./BackButton"

export default function ScreenHeader({
  title,
  onBack,
  right,
  flush,
}: {
  title: string
  onBack?: () => void
  right?: ReactNode
  /** Kapsayıcı zaten iç boşluk veriyorsa yan boşluk ekleme */
  flush?: boolean
}) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 10,
        padding: flush ? 0 : `${space[4]}px ${space[4]}px ${space[2]}px`,
      }}
    >
      {onBack && <BackButton onClick={onBack} />}
      <h1
        style={{
          flex: 1,
          minWidth: 0,
          fontSize: font.size.xl,
          fontWeight: font.weight.heavy,
          color: colors.text,
          letterSpacing: font.tracking.tight,
        }}
      >
        {title}
      </h1>
      {right}
    </div>
  )
}
