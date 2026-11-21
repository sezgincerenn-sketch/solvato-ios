// Çizgi ikon (emoji yerine). Renk çevredeki yazı rengini izler (.foregroundStyle). Web karşılığı src/components/Icons.tsx.
import SolvatoCore
import SwiftUI

struct Icon: View {
    let name: IconName
    var size: Double = IconMetrics.defaultSize
    /// Dolu çizim (alev, yıldız, kalp için)
    var fill = false
    var strokeWidth: Double = IconMetrics.strokeWidth

    init(_ name: IconName, size: Double = IconMetrics.defaultSize, fill: Bool = false, strokeWidth: Double = IconMetrics.strokeWidth) {
        self.name = name
        self.size = size
        self.fill = fill
        self.strokeWidth = strokeWidth
    }

    var body: some View {
        let shape = name.shape
        ZStack {
            if fill { shape.fill(.foreground) }
            shape.stroke(
                .foreground,
                style: StrokeStyle(lineWidth: strokeWidth * size / IconMetrics.viewBox, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
