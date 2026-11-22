// Açılış animasyonu (~2 sn, dokununca geçer). Web src/screens/Splash.tsx: aynı sıra, süreler ve CSS eğrileri.
//  1. Mor zemin parlar, logo karesi yaylanarak belirir
//  2. Beyaz tuşlar sırayla aşağıdan yükselir, siyah tuşlar üstten iner
//  3. Üçüncü tuş "çalınır": basılır, sarıya döner, anahtar deliği belirir, halka yayılır
//  4. Çalınan tuştan üç sekizlik nota yükselip söner
//  5. "Solvato" harf harf gelir, ekran söner
// "Hareketi azalt" açıksa son kare görünür (G-06).
import SolvatoCore
import SwiftUI

struct SplashScreen: View {
    let onDone: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var out = false

    static let duration = 2.0
    static let fade = 0.38

    var body: some View {
        TimelineView(.animation(paused: out)) { tl in
            let t = reduceMotion ? 10 : tl.date.timeIntervalSince(start)
            ZStack {
                ThemeColor.bg.color.ignoresSafeArea()
                // Arkadaki mor parıltı (420, merkezden 40 yukarı)
                let g = Curve.easeOut.progress(t, delay: 0, duration: 1.4)
                RadialGradient(
                    colors: [PaletteColor.violet600.opacity(0x55 / 255), .clear], center: .center, startRadius: 0,
                    endRadius: 210 * 2.0.squareRoot() * 0.65
                )
                .clipShape(Circle())
                .frame(width: 420, height: 420)
                .scaleEffect(0.6 + 0.4 * g)
                .opacity(g)
                .offset(y: -40)
                VStack(spacing: 18) {
                    Canvas { ctx, size in SplashDrawing.draw(t, in: &ctx, size: size) }
                        .frame(width: 180, height: 250)
                    word(t)
                }
            }
        }
        .opacity(out ? 0 : 1)
        .animation(.easeInOut(duration: Self.fade), value: out)
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .accessibilityHidden(true)
        .task {
            try? await Task.sleep(for: .seconds(Self.duration))
            finish()
        }
    }

    private func finish() {
        guard !out else { return }
        out = true
        Task {
            try? await Task.sleep(for: .seconds(Self.fade))
            onDone()
        }
    }

    /// "Solv" beyaz, "ato" mor (Logo ile aynı); her harf 50 ms arayla aşağıdan gelir
    private func word(_ t: Double) -> some View {
        HStack(spacing: 0) {
            ForEach(Array("Solvato".enumerated()), id: \.offset) { i, ch in
                let p = Motion.ease.progress(t, delay: 1.15 + Double(i) * 0.05, duration: 0.4)
                Text(String(ch))
                    .font(.ui(40, i >= 4 ? .semibold : .heavy))
                    .tracking(em: i >= 4 ? 0.03 : -0.02, size: 40)
                    .foregroundStyle((i >= 4 ? ThemeColor.violetText : ThemeColor.text).color)
                    .opacity(min(1, max(0, p)))
                    .offset(y: 14 * (1 - p))
            }
        }
    }
}

/// Logo sahnesi (web svg viewBox 0 -420 1024 1444, 180×250)
@MainActor
private enum SplashDrawing {
    static let whiteX: [Double] = [166, 348, 530, 712]
    static let blackX: [Double] = [296, 478, 660]
    static let notes: [(x: Double, dx: Double, delay: Double, sp: Double)] = [
        (560, -260, 1.05, 130), (640, 120, 1.2, 100), (590, 330, 1.35, 115),
    ]

    static func clamp(_ x: Double) -> Double { min(1, max(0, x)) }

    static func draw(_ t: Double, in ctx: inout GraphicsContext, size: CGSize) {
        let s = min(size.width / 1024, size.height / 1444)
        ctx.translateBy(x: (size.width - 1024 * s) / 2, y: (size.height - 1444 * s) / 2)
        ctx.scaleBy(x: s, y: s)
        ctx.translateBy(x: 0, y: 420)

        // Kare: yaylanarak (scale .55 → 1, −8° → 0)
        let m = Motion.spring.progress(t, delay: 0, duration: 0.55)
        var mc = ctx
        transform(&mc, cx: 512, cy: 512, scale: 0.55 + 0.45 * m, rotate: -8 * (1 - m))
        mc.opacity = clamp(m)
        let square = Path(roundedRect: CGRect(x: 0, y: 0, width: 1024, height: 1024), cornerRadius: 230)
        mc.fill(
            square,
            with: .linearGradient(
                Gradient(colors: [PaletteColor.violet600.color, PaletteColor.purple950.color]), startPoint: .zero,
                endPoint: CGPoint(x: 1024, y: 1024)))

        // Beyaz tuşlar: aşağıdan yükselir; üçüncüsü basılır ve sarıya döner
        for (i, x) in whiteX.enumerated() {
            var kc = ctx
            if i == 2 {
                // spPress: 0 → %45'te scaleY .93 → 1 (ease-in-out), üstten
                let p = Curve.easeInOut.progress(t, delay: 1.0, duration: 0.34)
                let sy = p <= 0 || p >= 1 ? 1 : p < 0.45 ? 1 - 0.07 * (p / 0.45) : 0.93 + 0.07 * ((p - 0.45) / 0.55)
                kc.translateBy(x: 0, y: 250)
                kc.scaleBy(x: 1, y: sy)
                kc.translateBy(x: 0, y: -250)
            }
            let r = Motion.ease.progress(t, delay: 0.25 + Double(i) * 0.08, duration: 0.42)
            var rc = kc
            rc.translateBy(x: 0, y: 774)
            rc.scaleBy(x: 1, y: 0.15 + 0.85 * r)
            rc.translateBy(x: 0, y: -774)
            rc.opacity = clamp(r)
            let key = Path(roundedRect: CGRect(x: x, y: 250, width: 166, height: 524), cornerRadius: 30)
            rc.fill(key, with: .color(PaletteColor.white.color))
            if i == 2 {
                var gc = kc
                gc.opacity = clamp(Curve.easeOut.progress(t, delay: 1.02, duration: 0.3))
                gc.fill(key, with: .color(PaletteColor.amber400.color))
            }
        }
        // Siyah tuşlar: üstten iner
        for (i, x) in blackX.enumerated() {
            let r = Motion.ease.progress(t, delay: 0.6 + Double(i) * 0.07, duration: 0.32)
            var bc = ctx
            bc.translateBy(x: 0, y: 250)
            bc.scaleBy(x: 1, y: max(0.0001, r))
            bc.translateBy(x: 0, y: -250)
            bc.opacity = clamp(r)
            bc.fill(Path(roundedRect: CGRect(x: x, y: 250, width: 92, height: 300), cornerRadius: 22), with: .color(PaletteColor.violet950.color))
        }
        // Anahtar deliği: yaylanarak
        let k = Motion.spring.progress(t, delay: 1.12, duration: 0.4)
        var lc = ctx
        transform(&lc, cx: 613, cy: 676, scale: 0.55 + 0.45 * k, rotate: -8 * (1 - k))
        lc.opacity = clamp(k)
        lc.fill(LogoMark.keyhole, with: .color(PaletteColor.violet950.color))
        // Çalınan tuşun halkası: yayılıp söner
        let hp = Curve.easeOut.progress(t, delay: 1.02, duration: 0.7)
        if hp > 0 && hp < 1 {
            var hc = ctx
            transform(&hc, cx: 613, cy: 512, scale: 0.4 + 1.8 * hp, rotate: 0)
            hc.opacity = 0.8 * (1 - hp)
            hc.stroke(Path(ellipseIn: CGRect(x: 613 - 140, y: 512 - 140, width: 280, height: 280)), with: .color(PaletteColor.amber400.color), lineWidth: 22)
        }
        // Tuştan yükselen notalar
        for (i, n) in notes.enumerated() {
            let p = Curve.easeOut.progress(t, delay: n.delay, duration: 1)
            guard p > 0 && p < 1 else { continue }
            let op = p < 0.2 ? p / 0.2 : 1 - (p - 0.2) / 0.8
            var nc = ctx
            nc.opacity = op
            nc.translateBy(x: n.dx * p, y: 60 + (-380 - 60) * p)
            let scale = 0.6 + 0.4 * p
            // kendi merkezi çevresinde
            let cx = n.x + n.sp * 0.6, cy = 160 - n.sp * 1.7
            nc.translateBy(x: cx, y: cy)
            nc.scaleBy(x: scale, y: scale)
            nc.translateBy(x: -cx, y: -cy)
            eighth(&nc, x: n.x, y: 160, sp: n.sp, color: i == 1 ? PaletteColor.violet300.color : PaletteColor.amber400.color)
        }
    }

    static func transform(_ c: inout GraphicsContext, cx: Double, cy: Double, scale: Double, rotate: Double) {
        c.translateBy(x: cx, y: cy)
        c.rotate(by: .degrees(rotate))
        c.scaleBy(x: scale, y: scale)
        c.translateBy(x: -cx, y: -cy)
    }

    /// Bravura sekizlik: baş + sap + bayrak (web EighthNote)
    static func eighth(_ c: inout GraphicsContext, x: Double, y: Double, sp: Double, color: Color) {
        let s = sp / 250
        let stemX = x + 11.8 * (sp / 10) - 0.65 * (sp / 10)
        let top = y - 3.4 * sp
        if let head = DrawingRenderer.glyphPaths["noteheadBlack"] {
            c.fill(head.applying(CGAffineTransform(a: s, b: 0, c: 0, d: -s, tx: x, ty: y)), with: .color(color))
        }
        c.fill(Path(CGRect(x: stemX - 0.6, y: top, width: 1.3 * (sp / 10), height: y - top - 1)), with: .color(color))
        if let flag = DrawingRenderer.glyphPaths["flag8thUp"] {
            c.fill(flag.applying(CGAffineTransform(a: s, b: 0, c: 0, d: -s, tx: stemX - 0.6, ty: top)), with: .color(color))
        }
    }
}
