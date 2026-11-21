// Çekirdekteki renk değerlerini SwiftUI renklerine çevirir. Temaya duyarlı renkler (ThemeColor) koyu/açık görünüme
// göre kendiliğinden değişir; kök görünümdeki preferredColorScheme hangi temanın seçildiğini belirler.
import SolvatoCore
import SwiftUI
import UIKit

extension RGBA {
    var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: alpha) }
    var color: Color { Color(uiColor: uiColor) }
}

extension PaletteColor {
    var color: Color { rgba.color }
    /// Saydam versiyon (web: alpha(palette.x, a))
    func opacity(_ a: Double) -> Color { rgba.opacity(a).color }
}

extension ThemeColor {
    /// Koyu temada koyu değeri, açık temada açık değeri veren dinamik renk
    var color: Color {
        let dark = rgba(.dark).uiColor
        let light = rgba(.light).uiColor
        return Color(uiColor: UIColor { $0.userInterfaceStyle == .light ? light : dark })
    }
}

extension Appearance {
    var colorScheme: ColorScheme { self == .light ? .light : .dark }
    init(_ scheme: ColorScheme) { self = scheme == .light ? .light : .dark }
}

extension ThemeMode {
    /// preferredColorScheme için: sistem → nil (iOS ayarını izler)
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}

extension ShadowStyle {
    /// CSS box-shadow bulanıklığı ≈ 2 × SwiftUI gölge yarıçapı
    var radius: Double { blur / 2 }
}

extension View {
    /// Tasarım sistemi gölgesi (web: shadow.card / shadow.raised / shadow.glow)
    func shadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color.color, radius: style.radius, x: 0, y: style.y)
    }
}

/// CSS `linear-gradient(<açı>deg, a, b)` ile aynı çizim: gradyan çizgisi kutunun boyuna göre hesaplanır,
/// köşeler tam %0 ve %100'e denk gelir (SwiftUI'nin köşeden köşeye gradyanı geniş kutularda farklı görünür).
struct CSSLinearGradient: View {
    var angle: Double = 135
    let colors: [Color]

    init(angle: Double = 135, _ colors: [Color]) {
        self.angle = angle
        self.colors = colors
    }

    init(_ gradient: BrandGradient) {
        self.init(angle: 135, [gradient.stops.0.color, gradient.stops.1.color])
    }

    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let h = max(geo.size.height, 1)
            let rad = angle * .pi / 180
            let dx = sin(rad)
            let dy = -cos(rad)
            let half = (abs(w * dx) + abs(h * dy)) / 2
            LinearGradient(
                colors: colors,
                startPoint: UnitPoint(x: 0.5 - dx * half / w, y: 0.5 - dy * half / h),
                endPoint: UnitPoint(x: 0.5 + dx * half / w, y: 0.5 + dy * half / h)
            )
        }
    }
}

extension Category {
    /// Konu ilerleme çubuğu dolgusu (web: categoryBar, 90°)
    var bar: CSSLinearGradient { CSSLinearGradient(angle: 90, [base.color, light.color]) }
}
