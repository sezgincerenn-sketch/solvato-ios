// Çalışma kartlarındaki küçük şema klavye (web MemoVisuals KeyIntervals): akorun notaları renkli, tuş adları yazılı,
// üstte iki nota arasındaki yarım ses sayısı kemerle. Majör/minör dersi ve akor kartları kullanır.
import Foundation

public enum Diagrams {
    static let whiteOfPc: [Int: Int] = [0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6]
    static let blackPcs = [1, 3, 6, 8, 10]
    static let blackAfter: [Int: Int] = [1: 0, 3: 1, 6: 3, 8: 4, 10: 5]
    public static let trPc = ["Do", "Do#", "Re", "Mi♭", "Mi", "Fa", "Fa#", "Sol", "La♭", "La", "Si♭", "Si"]

    /// semis: Do'dan uzaklık (0–23). gaps: aradaki yarım ses sayılarını göster. skip: "atla" yazılan tuşlar.
    public static func keyIntervals(
        semis: [Int], color: RGBA, names: [String]? = nil, gaps: Bool = true, skip: [Int] = [], octaves octIn: Int? = nil
    ) -> Drawing {
        let octaves = octIn ?? ((semis.max() ?? 0) >= 12 ? 2 : 1)
        let nW = 7 * octaves
        let W = 320.0
        let kw = W / Double(nW)
        let top: Double = gaps ? 30 : 6
        let H = 74.0
        func xOf(_ semi: Int) -> Double {
            let o = Double(semi / 12)
            let pc = semi % 12
            if let w = whiteOfPc[pc] { return (o * 7 + Double(w) + 0.5) * kw }
            return (o * 7 + Double(blackAfter[pc]!) + 1) * kw
        }
        let lit = Set(semis)
        let c = Paint.color(color)
        var items: [DrawItem] = []
        for i in 0..<nW {
            let pc = [0, 2, 4, 5, 7, 9, 11][i % 7]
            let semi = (i / 7) * 12 + pc
            let on = lit.contains(semi)
            let idx = semis.firstIndex(of: semi)
            items.append(
                .rect(
                    x: Double(i) * kw + 0.5, y: top, w: kw - 1, h: H, rx: 3, fill: on ? c : .color(Piano.diagramWhite),
                    stroke: .color(PaletteColor.slate400.rgba), strokeWidth: 0.8))
            if on {
                items.append(
                    .text(
                        names?[idx!] ?? trPc[pc], x: (Double(i) + 0.5) * kw, y: top + H - 7, size: octaves == 1 ? 13 : 11, weight: 800,
                        anchor: .middle, fill: .color(PaletteColor.slate900.rgba)))
            }
            if skip.contains(semi) {
                items.append(
                    .text(
                        "atla", x: (Double(i) + 0.5) * kw, y: top + H - 7, size: 11, weight: 700, anchor: .middle,
                        fill: .color(PaletteColor.slate400.rgba)))
            }
        }
        for o in 0..<octaves {
            for pc in blackPcs {
                let semi = o * 12 + pc
                let on = lit.contains(semi)
                let x = (Double(o * 7) + Double(blackAfter[pc]!) + 1) * kw
                items.append(
                    .rect(
                        x: x - kw * 0.3, y: top, w: kw * 0.6, h: H * 0.6, rx: 2, fill: on ? c : .color(Piano.diagramBlack),
                        stroke: on ? .color(PaletteColor.white.rgba) : nil, strokeWidth: 1))
                if on, let idx = semis.firstIndex(of: semi) {
                    items.append(
                        .text(
                            names?[idx] ?? trPc[pc], x: x, y: top + H * 0.6 - 5, size: octaves == 1 ? 11 : 9, weight: 800, anchor: .middle,
                            fill: .color(PaletteColor.white.rgba)))
                }
            }
        }
        if gaps {
            for i in 0..<max(0, semis.count - 1) {
                let x1 = xOf(semis[i]), x2 = xOf(semis[i + 1])
                let mid = (x1 + x2) / 2
                items.append(
                    .path(
                        [.move(Point(x1, top - 2)), .quad(Point(mid, top - 26), Point(x2, top - 2))], fill: nil,
                        stroke: c, width: 1.8))
                items.append(
                    .rect(
                        x: mid - 9, y: top - 25, w: 18, h: 15, rx: 7, fill: .color(PaletteColor.slate900.rgba), stroke: c, strokeWidth: 1))
                items.append(.text("\(semis[i + 1] - semis[i])", x: mid, y: top - 13.5, size: 11, weight: 800, anchor: .middle, fill: c))
            }
        }
        return Drawing(viewBox: (0, 0, W, top + H + 2), items: items, sizing: .init())
    }
}
