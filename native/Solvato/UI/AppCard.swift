// Kart: hafif dolgulu yüzey. `tone` verilirse o rengin açık tonuyla çerçevelenir. Web karşılığı src/ui/Card.tsx.
import SolvatoCore
import SwiftUI

struct AppCard<Content: View>: View {
    /// Vurgu rengi, ör. konu rengi
    var tone: PaletteColor?
    var padding: Double = Space.s4
    @ViewBuilder let content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.lg, style: .circular)
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tone.map { $0.opacity(0.06) } ?? ThemeColor.fill.color, in: shape)
            .overlay(shape.strokeBorder(tone.map { $0.opacity(0.3) } ?? ThemeColor.border.color, lineWidth: 1))
    }
}
