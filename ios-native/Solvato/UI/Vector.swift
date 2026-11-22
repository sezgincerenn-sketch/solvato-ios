// SVG yolunu SwiftUI şekline çevirir: ikonlar, yıldız ve (ileride) Solfie gibi web'de SVG olarak çizilen her şey.
// Yol bir kez okunur; şekil verilen alana viewBox oranında ölçeklenir (SVG'deki gibi).
import SolvatoCore
import SwiftUI

struct SVGShape: Shape {
    let commands: [PathCommand]
    var viewBox: CGSize = CGSize(width: IconMetrics.viewBox, height: IconMetrics.viewBox)

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / viewBox.width
        let sy = rect.height / viewBox.height
        func p(_ point: SolvatoCore.Point) -> CGPoint {
            CGPoint(x: rect.minX + point.x * sx, y: rect.minY + point.y * sy)
        }
        var path = Path()
        for c in commands {
            switch c {
            case .move(let a): path.move(to: p(a))
            case .line(let a): path.addLine(to: p(a))
            case .cubic(let c1, let c2, let end): path.addCurve(to: p(end), control1: p(c1), control2: p(c2))
            case .quad(let c, let end): path.addQuadCurve(to: p(end), control: p(c))
            case .close: path.closeSubpath()
            }
        }
        return path
    }
}

/// Okunmuş yollar: her yol uygulama boyunca bir kez okunur
enum ParsedPaths {
    static let icons: [IconName: [PathCommand]] = Dictionary(
        uniqueKeysWithValues: IconName.allCases.map { ($0, (try? SVGPath.parse($0.path)) ?? []) })
    static let star: [PathCommand] = (try? SVGPath.parse(starPath)) ?? []
}

@MainActor
extension IconName {
    var shape: SVGShape { SVGShape(commands: ParsedPaths.icons[self] ?? []) }
}
