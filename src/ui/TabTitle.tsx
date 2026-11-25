// Sekme sayfasının büyük başlığı (İlerleme, Öğren gibi); revize R23. Öğren sekmesindeki başlıkla aynı ölçü.
import type { ReactNode } from "react"
import { colors, font } from "../design/tokens"

export default function TabTitle({ children }: { children: ReactNode }) {
  return (
    <h1
      style={{
        margin: 0,
        fontSize: font.size.xl,
        fontWeight: font.weight.heavy,
        color: colors.text,
        letterSpacing: font.tracking.tight,
        fontFamily: font.family.ui,
      }}
    >
      {children}
    </h1>
  )
}
