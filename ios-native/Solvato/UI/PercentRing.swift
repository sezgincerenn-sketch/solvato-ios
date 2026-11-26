// Gezinme revizesinin küçük parçaları (docs/ozellikler/gezinme.md; web önizlemesi src/ui/PercentRing.tsx, GoalBar.tsx,
// TabTitle.tsx): Ana sayfa konu kartlarındaki yüzde halkası, Bugün kartındaki 10 bölmeli hedef çubuğu, sekme başlığı.
import SolvatoCore
import SwiftUI

/// Konu kartının sağındaki yüzde halkası: o konudaki doğruluk kadar konu renginde dolu, ortasında "%80".
/// Hiç çözülmemişse boş halka ve soluk "–".
struct PercentRing: View {
    let acc: Tally
    let color: PaletteColor
    var size: Double = 44

    var body: some View {
        let pct = acc.percent
        let sw = 5.0
        let r = size / 2 - sw
        ZStack {
            Circle().stroke(ThemeColor.fillStronger.color, lineWidth: sw).frame(width: r * 2, height: r * 2)
            if let pct, pct > 0 {
                Circle()
                    .trim(from: 0, to: Double(pct) / 100)
                    .stroke(color.color, style: StrokeStyle(lineWidth: sw, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: r * 2, height: r * 2)
            }
            Text(verbatim: pct.map { "%\($0)" } ?? "–")
                .font(.ui(pct == nil ? 13 : 11, .bold))
                .foregroundStyle((pct == nil ? ThemeColor.textFaint : ThemeColor.text).color)
                .lineLimit(1)
                .fixedSize()
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(pct.map { "Yüzde \($0) doğru" } ?? "Henüz çözülmedi")
    }
}

/// Bugün kartındaki günlük hedef çubuğu: 10 bölme, her bölme hedefin onda biri; dolu bölme mor, hedef tamamsa hepsi yeşil
struct GoalBar: View {
    /// Dolu bölme (HomeContent.goalSegments)
    let filled: Int
    let done: Bool
    /// "20 soruluk hedefin 12 sorusu çözüldü"
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10, id: \.self) { i in
                RoundedRectangle(cornerRadius: Radius.xs)
                    .fill(i < filled ? (done ? PaletteColor.green500 : PaletteColor.violet500).color : ThemeColor.fillStronger.color)
                    .frame(height: 10)
            }
        }
        .animation(.easeOut(duration: 0.3), value: filled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

/// Sekme sayfasının büyük başlığı (İlerleme, Öğren): Öğren sekmesindeki başlıkla aynı ölçü
struct TabTitle: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.ui(FontSize.xl, .heavy))
            .tracking(em: Tracking.tight, size: FontSize.xl)
            .foregroundStyle(ThemeColor.text.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}
