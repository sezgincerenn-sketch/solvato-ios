// Porte çizimleri: tek nota portesi (soru ekranı), akor portesi, günlük hedef portesi, küçük anahtar ikonu.
// Web karşılıkları src/components/MusicalStaff.tsx, ChordStaffSvg.tsx, GoalStaff.tsx, Glyph.tsx (ClefIcon).
// Koordinatlar: porte çizgileri y = 40, 50, 60, 70, 80 (5. çizgiden 1.'ye); Sol anahtarında Do4 = 90.
import Foundation

public enum Staves {
    static let ink = Paint.theme(.notation)
    static let line = Paint.theme(.staffLine)
    static let staffLines: [Double] = [40, 50, 60, 70, 80]

    /// Cevaptan sonra notanın rengi (doğru yeşil, yanlış kırmızı); hareketi SwiftUI tarafında
    public enum Feedback: Sendable { case correct, wrong }

    /// Tek nota portesi (web MusicalStaff): anahtar, ek çizgiler, diyez/bemol, nota başı ve sap
    public static func note(
        clef: Clef, noteY: Int, ledgerLines: [Int], accidental: Accidental? = nil, showLabel: Bool = false,
        feedback: Feedback? = nil, maxHeight: Double? = nil
    ) -> Drawing {
        let noteX = 145.0
        let y = Double(noteY)
        let top = min(0, y - 42)
        let bottom = max(130, y + 44)
        let noteColor: Paint =
            switch feedback {
            case .correct: .palette(.green400)
            case .wrong: .palette(.red400)
            case nil: ink
            }
        var items: [DrawItem] = staffLines.map { .line(x1: 14, y1: $0, x2: 196, y2: $0, stroke: line, width: 1.5, round: true) }
        items.append(clef == .treble ? .glyph("gClef", x: 20, y: 70, fill: ink) : .glyph("fClef", x: 20, y: 50, fill: ink))
        for ly in ledgerLines {
            items.append(.line(x1: noteX - 11, y1: Double(ly), x2: noteX + 11, y2: Double(ly), stroke: line, width: 1.5, round: true))
        }
        if let accidental {
            let name = accidental == .sharp ? "accidentalSharp" : "accidentalFlat"
            items.append(.glyph(name, x: noteX - 5.9 - 4 - Smufl.width(name), y: y, fill: noteColor))
        }
        items.append(.glyph("noteheadBlack", x: noteX - 5.9, y: y, fill: noteColor))
        // Orta çizginin altında sap yukarı ve sağda; orta çizgi ve üstünde aşağı ve solda. Ek çizgide orta çizgiye uzar.
        if y > 60 {
            items.append(.line(x1: noteX + 5.3, y1: y - 1.5, x2: noteX + 5.3, y2: min(y - 35, 60), stroke: noteColor, width: 1.3))
        } else {
            items.append(.line(x1: noteX - 5.3, y1: y + 1.5, x2: noteX - 5.3, y2: max(y + 35, 60), stroke: noteColor, width: 1.3))
        }
        if showLabel {
            items.append(.text(clef == .treble ? "Sol Anahtarı" : "Fa Anahtarı", x: 13, y: 118, size: 9, fill: .theme(.staffLabel)))
        }
        return Drawing(
            viewBox: (0, top, 210, bottom - top), items: items,
            sizing: maxHeight.map { .init(height: $0, notationShadow: true) } ?? .init(maxWidth: 384, notationShadow: true))
    }

    /// Akor portesi (web ChordStaffSvg): notalar üst üste, ikili aralıkta üstteki sağa kayar, işaretler sütunlara dizilir
    public static func chord(_ chord: Chord, color: Paint = .theme(.violetText), maxWidth: Double = 310) -> Drawing {
        let dy = 18.0
        let hw = Smufl.width("noteheadBlack")
        let nx = 140.0
        let ys = chord.notes.map { Double($0.staffY) }
        let xs = ys.indices.map { i in
            i > 0 && ys[i - 1] - ys[i] == 5 && !(i > 1 && ys[i - 2] - ys[i - 1] == 5) ? nx + hw - 1 : nx
        }
        var ledgers: [Double] = []
        func addLedger(_ l: Double) { if !ledgers.contains(l) { ledgers.append(l) } }
        for y in ys {
            var l = 90.0
            while l <= y { addLedger(l); l += 10 }
            l = 30
            while l >= y { addLedger(l); l -= 10 }
        }
        var items: [DrawItem] = staffLines.map { .line(x1: 14, y1: $0 + dy, x2: 196, y2: $0 + dy, stroke: line, width: 1.3) }
        items.append(.glyph("gClef", x: 20, y: 70 + dy, fill: ink, opacity: 0.85))
        let maxX = xs.max()!
        for y in ledgers {
            items.append(.line(x1: nx - hw / 2 - 4, y1: y + dy, x2: maxX + hw / 2 + 4, y2: y + dy, stroke: line, width: 1.3))
        }
        let glow: Paint? = if case let .color(c) = color { .color(c.opacity(0x88 / 255.0)) } else { nil }
        var colLast: [Double?] = []
        for i in chord.notes.indices.reversed() {
            let n = chord.notes[i]
            let y = ys[i]
            let acc: String? = [-2: "accidentalDoubleFlat", -1: "accidentalFlat", 1: "accidentalSharp", 2: "accidentalDoubleSharp"][n.acc]
            var ac = 0
            if acc != nil {
                while ac < colLast.count, let last = colLast[ac], abs(last - y) < 22 { ac += 1 }
                while colLast.count <= ac { colLast.append(nil) }
                colLast[ac] = y
            }
            let ax = nx - hw / 2 - 3 - (acc.map { Smufl.width($0) + Double(ac) * 11 } ?? 0)
            if let acc { items.append(.glyph(acc, x: ax, y: y + dy, fill: color)) }
            items.append(.glyph("noteheadBlack", x: xs[i] - hw / 2, y: y + dy, fill: color, opacity: 0.95, glow: glow))
        }
        return Drawing(viewBox: (0, 0, 210, 140), items: items, sizing: .init(maxWidth: maxWidth))
    }

    /// Günlük hedef portesi (web GoalStaff): hedefin her parçası bir nota; çözülen kadar dolu, kalanlar soluk.
    /// Hedef 10'dan büyükse 10 nota, her nota hedef/10 soru.
    public static func goal(done: Int, goal: Int) -> Drawing {
        let w = 330.0
        let firstX = 54.0
        let headW = 11.8
        let n = max(1, min(goal, 10))
        let filled = goal > 0 ? min(n, Int((Double(done) / Double(goal) * Double(n)).rounded(.down))) : 0
        let gap = (w - firstX - 22) / Double(n)
        var items: [DrawItem] = staffLines.map { .line(x1: 2, y1: $0, x2: w - 2, y2: $0, stroke: line, width: 1.2) }
        items.append(.glyph("gClef", x: 6, y: 70, fill: ink))
        let violet = Paint.theme(.violetText)
        for i in 0..<n {
            let y = Double(85 - 5 * i)
            let x = firstX + Double(i) * gap
            if i >= filled {
                items.append(.glyph("noteheadHalf", x: x, y: y, fill: .theme(.textDisabled)))
                continue
            }
            let up = y > 60
            items.append(.glyph("noteheadBlack", x: x, y: y, fill: violet))
            let sx = up ? x + headW - 0.7 : x + 0.7
            items.append(.line(x1: sx, y1: up ? y - 1.5 : y + 1.5, x2: sx, y2: up ? y - 35 : y + 35, stroke: violet, width: 1.3))
        }
        let full = filled >= n
        items.append(.line(x1: w - 4, y1: 40, x2: w - 4, y2: 80, stroke: full ? violet : line, width: full ? 3 : 1.2))
        return Drawing(viewBox: (0, 24, w, 72), items: items, sizing: .init())
    }

    /// Metin içindeki küçük anahtar ikonu (web ClefIcon); renk çevredeki yazının rengi
    public static func clefIcon(_ clef: Clef, size: Double = 20) -> Drawing {
        let name = clef == .treble ? "gClef" : "fClef"
        let g = Smufl.glyphs[name]!
        let hSp = g.northEast.y - g.southWest.y
        let wSp = g.northEast.x - g.southWest.x
        // Sol anahtarı daha uzun; ikisi aynı kutuya sığsın
        let sp = clef == .treble ? size / hSp : (size * 0.62) / hSp
        let w = wSp * sp
        let yOrigin = clef == .treble ? g.northEast.y * sp : (size - hSp * sp) / 2 + g.northEast.y * sp
        return Drawing(
            viewBox: (g.southWest.x * sp - 1, 0, w + 2, size), items: [.glyph(name, x: 0, y: yOrigin, sp: sp, fill: .current)],
            sizing: .init(height: size, width: w + 2))
    }
}
