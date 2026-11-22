// Solfie: Solvato'nun maskotu (sekizlik nota; amber bayrağı saçı gibi, kolları ve ayakları var). Web src/components/
// Solfie.tsx'teki SVG'nin birebir çizimi (viewBox 20 20 380 380). Pozlar: idle (sakin), wave (el sallar), cheer (kollar
// havada, parıltılar). Az görünür: tanıtım, tur sonucu, kutlama. Hareket (sallanma/zıplama) "hareketi azalt"ta durur.
import SolvatoCore
import SwiftUI

enum SolfiePose { case idle, wave, cheer }

struct Solfie: View {
    var size: Double = 72
    var pose: SolfiePose = .idle
    var animate = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = false

    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 380
            ctx.scaleBy(x: s, y: s)
            ctx.translateBy(x: -20, y: -20)
            SolfieDrawing.draw(pose, in: &ctx)
        }
        .frame(width: size, height: size)
        .offset(y: animate && !reduceMotion ? (phase ? (pose == .cheer ? -size * 0.08 : -size * 0.03) : 0) : 0)
        .onAppear {
            guard animate && !reduceMotion else { return }
            withAnimation(.easeInOut(duration: pose == .cheer ? 0.45 : 1.6).repeatForever(autoreverses: true)) { phase = true }
        }
        .accessibilityHidden(true)
    }
}

private enum SolfieDrawing {
    static let ink = Color(red: 0x1E / 255, green: 0x1B / 255, blue: 0x2E / 255)
    static let line = PaletteColor.violet300.color
    static let blush = Color(red: 0xF9 / 255, green: 0xA8 / 255, blue: 0xD4 / 255)

    static func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    /// Gövde dolgusu: radialGradient cx .35 cy .3 r .8 (şeklin kutusuna göre)
    static func body(_ rect: CGRect) -> GraphicsContext.Shading {
        .radialGradient(
            Gradient(stops: [
                .init(color: PaletteColor.white.color, location: 0), .init(color: PaletteColor.violet50.color, location: 0.55),
                .init(color: PaletteColor.violet200.color, location: 1),
            ]),
            center: p(rect.minX + rect.width * 0.35, rect.minY + rect.height * 0.3), startRadius: 0,
            endRadius: 0.8 * (rect.width * rect.width / 2 + rect.height * rect.height / 2).squareRoot())
    }

    static func arm(_ ctx: inout GraphicsContext, _ start: CGPoint, _ ctrl: CGPoint, _ end: CGPoint, hand: CGPoint) {
        var path = Path()
        path.move(to: start)
        path.addQuadCurve(to: end, control: ctrl)
        ctx.stroke(path, with: .color(line), style: StrokeStyle(lineWidth: 24, lineCap: .round))
        ctx.stroke(path, with: .color(PaletteColor.violet50.color), style: StrokeStyle(lineWidth: 15, lineCap: .round))
        let h = Path(ellipseIn: CGRect(x: hand.x - 14, y: hand.y - 14, width: 28, height: 28))
        ctx.fill(h, with: .color(PaletteColor.violet50.color))
        ctx.stroke(h, with: .color(line), lineWidth: 4.5)
    }

    static func star(_ x: Double, _ y: Double, _ a: Double, _ b: Double) -> Path {
        // "M x y l a/… " parıltı: dört köşeli yıldız (web yolu)
        var path = Path()
        path.move(to: p(x, y))
        path.addLine(to: p(x + a, y - b))
        path.addLine(to: p(x + 2 * a, y))
        path.addLine(to: p(x + 2 * a + b, y + a))
        path.addLine(to: p(x + 2 * a, y + 2 * a))
        path.addLine(to: p(x + a, y + 2 * a + b))
        path.addLine(to: p(x, y + 2 * a))
        path.addLine(to: p(x - b, y + a))
        path.closeSubpath()
        return path
    }

    static func draw(_ pose: SolfiePose, in ctx: inout GraphicsContext) {
        if pose == .cheer {
            let amber = GraphicsContext.Shading.color(PaletteColor.amber400.color)
            ctx.fill(star(44, 150, 8, 22), with: amber)
            ctx.fill(star(372, 300, 6, 16), with: amber)
            ctx.fill(Path(ellipseIn: CGRect(x: 89, y: 81, width: 14, height: 14)), with: amber)
            ctx.fill(Path(ellipseIn: CGRect(x: 367, y: 227, width: 10, height: 10)), with: amber)
        }
        // Ayaklar
        for (cx, cy) in [(128.0, 356.0), (214, 350)] {
            let f = Path(ellipseIn: CGRect(x: cx - 30, y: cy - 15, width: 60, height: 30))
            ctx.fill(f, with: .color(PaletteColor.violet100.color))
            ctx.stroke(f, with: .color(line), lineWidth: 4.5)
        }
        // Sol kol
        if pose == .cheer {
            arm(&ctx, p(72, 268), p(40, 228), p(52, 190), hand: p(52, 186))
        } else {
            arm(&ctx, p(70, 290), p(44, 312), p(52, 338), hand: p(52, 340))
        }
        // Sap ve bayrak (saç)
        let stemRect = CGRect(x: 250, y: 56, width: 32, height: 232)
        let stem = Path(roundedRect: stemRect, cornerRadius: 14)
        ctx.fill(stem, with: body(stemRect))
        ctx.stroke(stem, with: .color(line), lineWidth: 5)
        var flag = Path()
        flag.move(to: p(270, 56))
        flag.addCurve(to: p(346, 232), control1: p(340, 86), control2: p(382, 146))
        flag.addCurve(to: p(270, 150), control1: p(336, 176), control2: p(304, 156))
        flag.closeSubpath()
        let fb = flag.boundingRect
        ctx.fill(
            flag,
            with: .linearGradient(
                Gradient(colors: [PaletteColor.amber300.color, PaletteColor.amber500.color]), startPoint: fb.origin,
                endPoint: p(fb.maxX, fb.maxY)))
        ctx.stroke(flag, with: .color(PaletteColor.amber500.color), style: StrokeStyle(lineWidth: 5, lineJoin: .round))
        var shine = Path()
        shine.move(to: p(284, 80))
        shine.addCurve(to: p(344, 156), control1: p(318, 98), control2: p(340, 124))
        ctx.stroke(shine, with: .color(PaletteColor.white.color.opacity(0.55)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
        // Baş: elips, -18° döndürülmüş
        let headRect = CGRect(x: 175 - 118, y: 268 - 90, width: 236, height: 180)
        let rot = CGAffineTransform(translationX: 175, y: 268).rotated(by: -18 * .pi / 180).translatedBy(x: -175, y: -268)
        let head = Path(ellipseIn: headRect).applying(rot)
        var hctx = ctx
        hctx.concatenate(rot)
        hctx.fill(Path(ellipseIn: headRect), with: body(headRect))
        ctx.stroke(head, with: .color(line), lineWidth: 5)
        // Sağ kol
        switch pose {
        case .wave:
            arm(&ctx, p(284, 262), p(322, 232), p(320, 192), hand: p(320, 188))
            var w = Path()
            w.move(to: p(346, 170))
            w.addQuadCurve(to: p(352, 200), control: p(358, 182))
            ctx.stroke(w, with: .color(line), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        case .cheer: arm(&ctx, p(284, 256), p(322, 220), p(322, 182), hand: p(322, 178))
        case .idle: arm(&ctx, p(282, 270), p(312, 292), p(306, 320), hand: p(306, 322))
        }
        // Yanaklar
        for (cx, cy) in [(108.0, 300.0), (240, 282)] {
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 16, y: cy - 16, width: 32, height: 32)), with: .color(blush.opacity(0.75)))
        }
        // Gözler
        if pose == .cheer {
            for (x, y) in [(124.0, 272.0), (190, 258)] {
                var e = Path()
                e.move(to: p(x, y))
                e.addQuadCurve(to: p(x + 32, y), control: p(x + 16, y - 20))
                ctx.stroke(e, with: .color(ink), style: StrokeStyle(lineWidth: 8, lineCap: .round))
            }
        } else {
            for (cx, cy) in [(140.0, 268.0), (206, 254)] {
                ctx.fill(Path(ellipseIn: CGRect(x: cx - 15, y: cy - 21, width: 30, height: 42)), with: .color(ink))
                ctx.fill(Path(ellipseIn: CGRect(x: cx + 6 - 6, y: cy - 8 - 6, width: 12, height: 12)), with: .color(.white))
                ctx.fill(Path(ellipseIn: CGRect(x: cx - 5 - 2.5, y: cy + 8 - 2.5, width: 5, height: 5)), with: .color(.white))
            }
        }
        // Ağız
        if pose != .idle {
            var m = Path()
            m.move(to: p(150, 298))
            m.addQuadCurve(to: p(214, 290), control: p(180, 338))
            m.addQuadCurve(to: p(150, 298), control: p(182, 306))
            m.closeSubpath()
            ctx.fill(m, with: .color(ink))
            ctx.stroke(m, with: .color(ink), style: StrokeStyle(lineWidth: 4, lineJoin: .round))
            var tctx = ctx
            tctx.concatenate(CGAffineTransform(translationX: 186, y: 314).rotated(by: -14 * .pi / 180).translatedBy(x: -186, y: -314))
            tctx.fill(Path(ellipseIn: CGRect(x: 175, y: 308, width: 22, height: 12)), with: .color(Color(red: 0xF4 / 255, green: 0x72 / 255, blue: 0xB6 / 255)))
        } else {
            var m = Path()
            m.move(to: p(154, 302))
            m.addQuadCurve(to: p(208, 298), control: p(180, 322))
            ctx.stroke(m, with: .color(ink), style: StrokeStyle(lineWidth: 8, lineCap: .round))
        }
    }
}

/// Solfie + konuşma balonu (tek cümle). "amber" tonu: rekor, kutlama
struct SolfieSays: View {
    let text: String
    var size: Double = 56
    var amber = false
    var pose: SolfiePose = .idle

    var body: some View {
        HStack(alignment: .bottom, spacing: Space.s2) {
            Solfie(size: size, pose: pose)
            Text(text)
                .font(.ui(FontSize.sm, .semibold))
                .foregroundStyle((amber ? ThemeColor.amberText : ThemeColor.text).color)
                .padding(.vertical, Space.s2)
                .padding(.horizontal, 14)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: Radius.lg, bottomLeadingRadius: 4, bottomTrailingRadius: Radius.lg, topTrailingRadius: Radius.lg)
                        .fill(ThemeColor.fillStrong.color))
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: Radius.lg, bottomLeadingRadius: 4, bottomTrailingRadius: Radius.lg, topTrailingRadius: Radius.lg)
                        .strokeBorder(amber ? PaletteColor.amber500.color : ThemeColor.border.color, lineWidth: 1))
                .padding(.bottom, (size * 0.35).rounded())
        }
        .accessibilityElement(children: .combine)
    }
}
