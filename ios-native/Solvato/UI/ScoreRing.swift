// Puan halkası: oran kadar dolu. Rengi marka moru; başarıya göre kırmızı/yeşil yapılmaz (tasarım sistemi kuralı).
// Web karşılığı src/ui/ScoreRing.tsx; halka kalınlığı, yarıçap ve yazıların taban çizgisi konumları aynı.
import SolvatoCore
import SwiftUI

struct ScoreRing: View {
    let value: Int
    let max: Int
    var size: Double = 140
    /// Ortadaki büyük yazı (varsayılan: "value/max")
    var label: String?
    /// Altındaki küçük yazı
    var caption: String?
    /// En altta, halka renginde ek satır (ör. "7/10 doğru")
    var detail: String?
    var color: PaletteColor = .violet500

    var body: some View {
        let ratio = max > 0 ? Double(value) / Double(max) : 0
        let big = size > 120
        let lineWidth: Double = big ? 11 : 9
        let r = size / 2 - 10
        let c = size / 2
        // Üç satır varsa yazılar biraz yukarı kayar
        let lift: Double = detail != nil ? 8 : 0

        ZStack(alignment: .top) {
            Circle()
                .stroke(ThemeColor.fillStrong.color, lineWidth: lineWidth)
                .frame(width: r * 2, height: r * 2)
                .position(x: c, y: c)
            Circle()
                .trim(from: 0, to: min(1, Swift.max(0, ratio)))
                .stroke(color.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: r * 2, height: r * 2)
                // web: drop-shadow(0 0 8px) → yarıçap 4
                .shadow(color: color.color, radius: 4)
                .position(x: c, y: c)
                .animation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.8), value: ratio)

            baseline(
                Text(label ?? "\(value)/\(max)")
                    .font(.monoFixed(big ? FontSize.xxl : FontSize.xl, .heavy))
                    .foregroundStyle(ThemeColor.text.color),
                at: c + (big ? 4 : 2) - lift)
            if let caption {
                baseline(
                    Text(caption)
                        .font(.uiFixed(big ? FontSize.xs : 11))
                        .foregroundStyle(ThemeColor.textSubtle.color),
                    at: c + (big ? 24 : 20) - lift)
            }
            if let detail {
                baseline(
                    Text(detail)
                        .font(.monoFixed(10, .bold))
                        .foregroundStyle(color.color),
                    at: c + (big ? 39 : 33) - lift)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) / \(max)")
    }

    /// Yazının taban çizgisini y'ye koyar, yatayda ortalar (SVG <text y=… text-anchor="middle"> gibi)
    private func baseline(_ text: some View, at y: Double) -> some View {
        text
            .lineLimit(1)
            .fixedSize()
            .alignmentGuide(.top) { d in d[.firstTextBaseline] - y }
    }
}
