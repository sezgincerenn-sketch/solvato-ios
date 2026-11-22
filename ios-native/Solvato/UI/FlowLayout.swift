// Satıra sığmayanı alt satıra geçiren dizilim (CSS flex-wrap). Öğretmen kodu ekranındaki konu çiplerinde kullanılır.
import SwiftUI

struct FlowLayout: Layout {
    var spacing: Double = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews)
        let w = rows.map(\.width).max() ?? 0
        let h = rows.map(\.height).reduce(0, +) + spacing * Double(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? w, height: h)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews) {
            var x = bounds.minX
            for i in row.items {
                let size = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var items: [Int] = []
        var width: Double = 0
        var height: Double = 0
    }

    private func arrange(width: Double, _ subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var cur = Row()
        for (i, v) in subviews.enumerated() {
            let size = v.sizeThatFits(.unspecified)
            let next = cur.items.isEmpty ? size.width : cur.width + spacing + size.width
            if !cur.items.isEmpty && next > width {
                rows.append(cur)
                cur = Row()
            }
            cur.width = cur.items.isEmpty ? size.width : cur.width + spacing + size.width
            cur.height = max(cur.height, size.height)
            cur.items.append(i)
        }
        if !cur.items.isEmpty { rows.append(cur) }
        return rows
    }
}
