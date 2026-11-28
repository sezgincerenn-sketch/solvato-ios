// Solfado logosu: mor kare içinde piyano tuşları; üçüncüsü sarı ve üstünde anahtar deliği ("notaların şifresini çöz")
// + "Solf·ado" yazısı. Web karşılığı src/components/Logo.tsx; geometri aynı (1024 birimlik çizim).
import SolvatoCore
import SwiftUI

struct LogoMark: View {
    var size: Double = 34

    var body: some View {
        Canvas { ctx, canvas in
            let s = canvas.width / 1024
            ctx.scaleBy(x: s, y: s)
            func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double) -> Path {
                Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r, style: .circular)
            }
            ctx.fill(
                rect(0, 0, 1024, 1024, 230),
                with: .linearGradient(
                    Gradient(colors: [PaletteColor.violet600.color, PaletteColor.purple950.color]),
                    startPoint: .zero, endPoint: CGPoint(x: 1024, y: 1024)))
            // Dört piyano tuşu: üçüncüsü sarı (çalınan nota)
            for i in 0..<4 {
                let color = i == 2 ? PaletteColor.amber400 : PaletteColor.white
                ctx.fill(rect(166 + Double(i) * 182, 250, 166, 524, 30), with: .color(color.color))
            }
            for x in [296.0, 478, 660] {
                ctx.fill(rect(x, 250, 92, 300, 22), with: .color(PaletteColor.violet950.color))
            }
            ctx.fill(Self.keyhole, with: .color(PaletteColor.violet950.color))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// Sarı tuştaki anahtar deliği (1024 birimlik koordinatlarda; açılış animasyonu da kullanır)
    static let keyhole: Path = {
        var p = Path(ellipseIn: CGRect(x: 613 - 32, y: 636 - 32, width: 64, height: 64))
        p.move(to: CGPoint(x: 595, y: 652))
        p.addLine(to: CGPoint(x: 631, y: 652))
        p.addLine(to: CGPoint(x: 644, y: 716))
        p.addLine(to: CGPoint(x: 582, y: 716))
        p.closeSubpath()
        return p
    }()
}

struct Logo: View {
    var size: Double = 34

    var body: some View {
        let fontSize = (size * 0.82).rounded()
        HStack(spacing: (size * 0.3).rounded()) {
            LogoMark(size: size)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("Solf")
                    .font(.uiFixed(fontSize, .heavy))
                    .tracking(-0.02 * fontSize)
                    .foregroundStyle(ThemeColor.text.color)
                Text("ado")
                    .font(.uiFixed(fontSize, .semibold))
                    .tracking(0.03 * fontSize)
                    .foregroundStyle(ThemeColor.violetText.color)
            }
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Solfado")
    }
}
