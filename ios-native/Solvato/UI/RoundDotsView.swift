// Tur üstündeki adım noktaları (R2): doğru yeşil, yanlış kırmızı, şimdiki uzun mor, kalanlar gri. Durumlar SolvatoCore
// RoundDots'tan. Soru turu (oyunlar dahil) ve akor turu; ölçüler ekranın eski noktalarıyla aynı.
import SolvatoCore
import SwiftUI

struct RoundDotsView: View {
    let dots: [RoundDot]
    let index: Int
    /// Şimdiki noktanın ve diğerlerinin genişliği, yükseklik, ara
    var currentWidth: Double = 18
    var width: Double = 6
    var spacing: Double = 4
    /// Kalan noktaların rengi
    var upcoming: ThemeColor = .fillStronger

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(dots.enumerated()), id: \.offset) { i, d in
                let now = i == index
                Capsule()
                    .fill(style(d))
                    .frame(width: now ? currentWidth : width, height: width)
                    .shadow(color: now ? glow(d) : .clear, radius: 4)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: dots)
        .animation(.easeInOut(duration: 0.3), value: index)
        .accessibilityElement(children: .ignore)
        // "3. soru, 10 sorudan" (erisilebilirlik-ipad.md); doğru/yanlış sayısı değer olarak
        .accessibilityLabel(AccessibilityText.roundPosition(index: index, count: dots.count))
        .accessibilityValue("\(dots.filter { $0 == .correct }.count) doğru, \(dots.filter { $0 == .wrong }.count) yanlış")
    }

    private func style(_ d: RoundDot) -> AnyShapeStyle {
        switch d {
        case .correct: AnyShapeStyle(PaletteColor.green500.color)
        case .wrong: AnyShapeStyle(PaletteColor.red500.color)
        case .current:
            AnyShapeStyle(LinearGradient(colors: [PaletteColor.violet500.color, PaletteColor.violet400.color], startPoint: .leading, endPoint: .trailing))
        case .upcoming: AnyShapeStyle(upcoming.color)
        }
    }

    private func glow(_ d: RoundDot) -> Color {
        switch d {
        case .correct: PaletteColor.green500.opacity(0.5)
        case .wrong: PaletteColor.red500.opacity(0.5)
        default: PaletteColor.violet500.opacity(0.6)
        }
    }
}
