// Nota çizimi: SolvatoCore'un ürettiği çizim listesini (Drawing) Canvas'a çizer. Yerleşim (koordinatlar, semboller,
// renk adları) çekirdekte ve web'le aynı olduğu testlerle doğrulanır; burada yalnızca SVG'deki gibi viewBox'a
// ölçekleyip çizilir. Bravura sembolleri web'deki yollarla aynı (Smufl), bir kez okunup saklanır.
import SolvatoCore
import SwiftUI

struct DrawingView: View {
    let drawing: Drawing
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let vb = drawing.viewBox
        let s = drawing.sizing
        Canvas { ctx, size in
            let scale = min(size.width / vb.w, size.height / vb.h)
            // SVG gibi ortala (preserveAspectRatio xMidYMid meet)
            ctx.translateBy(x: (size.width - vb.w * scale) / 2, y: (size.height - vb.h * scale) / 2)
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: -vb.x, y: -vb.y)
            for item in drawing.items { DrawingRenderer.draw(item, in: ctx, appearance: Appearance(scheme)) }
        }
        .aspectRatio(vb.w / vb.h, contentMode: .fit)
        .frame(width: s.width.map { CGFloat($0) }, height: s.height.map { CGFloat($0) })
        // Sabit boyutlu çizim (anahtar ikonu) genişlemez; diğerleri kapsayıcıyı doldurur, en çok maxWidth/maxHeight
        .frame(
            maxWidth: s.maxWidth.map { CGFloat($0) } ?? (s.width == nil ? .infinity : nil),
            maxHeight: s.maxHeight.map { CGFloat($0) } ?? (s.height == nil ? .infinity : nil))
        // Koyu temada notaların hafif mor parıltısı (web --notation-shadow; açık temada yok)
        .shadow(color: s.notationShadow && scheme == .dark ? PaletteColor.violet500.opacity(0.15) : .clear, radius: 4)
        .accessibilityHidden(true)
    }
}

enum DrawingRenderer {
    /// Bravura yolları: uygulama boyunca bir kez
    nonisolated(unsafe) static let glyphPaths: [String: Path] = Smufl.glyphs.mapValues { path($0.path) }

    static func path(_ commands: [PathCommand]) -> Path {
        var p = Path()
        func pt(_ q: SolvatoCore.Point) -> CGPoint { CGPoint(x: q.x, y: q.y) }
        for c in commands {
            switch c {
            case .move(let a): p.move(to: pt(a))
            case .line(let a): p.addLine(to: pt(a))
            case .cubic(let c1, let c2, let e): p.addCurve(to: pt(e), control1: pt(c1), control2: pt(c2))
            case .quad(let c, let e): p.addQuadCurve(to: pt(e), control: pt(c))
            case .close: p.closeSubpath()
            }
        }
        return p
    }

    static func shading(_ paint: Paint, _ appearance: Appearance) -> GraphicsContext.Shading {
        switch paint {
        case .theme(let t): .color(t.rgba(appearance).color)
        case .color(let c): .color(c.color)
        case .current: .foreground
        }
    }

    static func color(_ paint: Paint, _ appearance: Appearance) -> Color {
        switch paint {
        case .theme(let t): t.rgba(appearance).color
        case .color(let c): c.color
        case .current: .primary
        }
    }

    static func font(_ role: FontRole, size: Double, weight: Int, italic: Bool) -> Font {
        let w = FontWeight(rawValue: weight) ?? .regular
        switch role {
        case .ui: return .ui(size, w)
        case .serif:
            let bold = weight >= 600
            let name =
                italic
                ? (bold ? "TimesNewRomanPS-BoldItalicMT" : "TimesNewRomanPS-ItalicMT")
                : (bold ? "TimesNewRomanPS-BoldMT" : "TimesNewRomanPSMT")
            return .custom(name, fixedSize: size)
        }
    }

    static func draw(_ item: DrawItem, in ctx: GraphicsContext, appearance a: Appearance) {
        switch item {
        case let .line(x1, y1, x2, y2, stroke, width, round):
            var p = Path()
            p.move(to: CGPoint(x: x1, y: y1))
            p.addLine(to: CGPoint(x: x2, y: y2))
            ctx.stroke(p, with: shading(stroke, a), style: StrokeStyle(lineWidth: width, lineCap: round ? .round : .butt))
        case let .rect(x, y, w, h, rx, fill, stroke, sw):
            let p = Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: rx)
            if let fill { ctx.fill(p, with: shading(fill, a)) }
            if let stroke { ctx.stroke(p, with: shading(stroke, a), lineWidth: sw) }
        case let .circle(cx, cy, r, fill):
            ctx.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)), with: shading(fill, a))
        case let .path(cmds, fill, stroke, width, round):
            let p = path(cmds)
            if let fill { ctx.fill(p, with: shading(fill, a)) }
            if let stroke {
                ctx.stroke(p, with: shading(stroke, a), style: StrokeStyle(lineWidth: width, lineJoin: round ? .round : .miter))
            }
        case let .glyph(name, x, y, sp, fill, opacity, glow):
            guard let base = glyphPaths[name] else { return }
            let s = sp / 250
            let p = base.applying(CGAffineTransform(a: s, b: 0, c: 0, d: -s, tx: x, ty: y))
            var c = ctx
            c.opacity = opacity
            if let glow { c.addFilter(.shadow(color: color(glow, a), radius: 2.5)) }
            c.fill(p, with: shading(fill, a))
        case let .text(s, x, y, size, weight, italic, anchor, role, fill):
            let resolved = ctx.resolve(Text(s).font(font(role, size: size, weight: weight, italic: italic)).foregroundStyle(color(fill, a)))
            let box = resolved.measure(in: CGSize(width: 10_000, height: 10_000))
            let baseline = resolved.firstBaseline(in: box)
            let left: Double =
                switch anchor {
                case .start: x
                case .middle: x - box.width / 2
                case .end: x - box.width
                }
            ctx.draw(resolved, in: CGRect(x: left, y: y - baseline, width: box.width, height: box.height))
        }
    }
}

// MARK: - Kullanım kolaylıkları (web bileşen adlarıyla)

/// Web <Notation score maxW />
struct NotationView: View {
    let score: String
    var maxW: Double?
    var body: some View { DrawingView(drawing: NotationLayout.notation(score, maxW: maxW)) }
}

/// Web <MusicalStaff />: tek nota portesi; cevaptan sonra nota yeşil/kırmızı olur
struct MusicalStaffView: View {
    let clef: Clef
    let noteY: Int
    var ledgerLines: [Int] = []
    var accidental: Accidental?
    var showLabel = false
    var feedback: Staves.Feedback?
    var maxHeight: Double?
    var body: some View {
        DrawingView(
            drawing: Staves.note(
                clef: clef, noteY: noteY, ledgerLines: ledgerLines, accidental: accidental, showLabel: showLabel,
                feedback: feedback, maxHeight: maxHeight))
    }
}

/// Web <ChordStaffSvg />
struct ChordStaffView: View {
    let chord: Chord
    var color: Paint = .theme(.violetText)
    var maxWidth: Double = 310
    var body: some View { DrawingView(drawing: Staves.chord(chord, color: color, maxWidth: maxWidth)) }
}

/// Web <GoalStaff /> (Pratik › Bugün)
struct GoalStaffView: View {
    let done: Int
    let goal: Int
    var body: some View { DrawingView(drawing: Staves.goal(done: done, goal: goal)) }
}

/// Web <ClefIcon />: yazının içinde küçük anahtar; rengi çevredeki yazı rengi
struct ClefIconView: View {
    let clef: Clef
    var size: Double = 20
    var body: some View { DrawingView(drawing: Staves.clefIcon(clef, size: size)) }
}
