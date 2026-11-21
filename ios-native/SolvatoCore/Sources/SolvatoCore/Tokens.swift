// Tasarım sisteminin renk dışındaki değerleri: rol renkleri, konu renkleri, gradyan, köşe, boşluk, yazı, gölge, hareket.
// Web karşılığı src/design/tokens.ts; değerler birebir aynı (TokensTests doğrular). Ekranlar ham sayı değil bunları kullanır.

/// Rol renkleri (web: brand)
public enum Brand {
    public static let primary = PaletteColor.violet600
    public static let primaryHover = PaletteColor.violet700
    public static let accent = PaletteColor.violet500
    /// Logodaki sarı tuş
    public static let highlight = PaletteColor.amber400
    public static let success = PaletteColor.green500
    public static let danger = PaletteColor.red500
    public static let warning = PaletteColor.amber500
    /// Mor düğme üstündeki yazı (iki temada aynı; web: colors.onPrimary)
    public static let onPrimary = PaletteColor.violet100
}

/// Her konunun tek rengi: ana sayfa kartı, soru etiketi ve ilerleme çubuğu aynı rengi kullanır.
/// base: dolgu/kenar/ikon · light: çubuk gradyanının açık ucu · text: yazı (temaya duyarlı)
public enum CategoryColor: String, CaseIterable, Sendable {
    case treble, bass, accidentals, rhythm, writing, terms, chords, games, ear

    public var base: PaletteColor {
        switch self {
        case .treble: .blue500
        case .bass: .indigo500
        case .accidentals: .pink500
        case .rhythm: .cyan500
        case .writing: .teal500
        case .terms: .amber500
        case .chords: .violet500
        case .games: .green500
        case .ear: .lime500
        }
    }

    public var light: PaletteColor {
        switch self {
        case .treble: .blue400
        case .bass: .indigo400
        case .accidentals: .pink400
        case .rhythm: .cyan400
        case .writing: .teal400
        case .terms: .amber300
        case .chords: .violet400
        case .games: .green400
        case .ear: .lime300
        }
    }

    public var text: ThemeColor {
        switch self {
        case .treble: .blueText
        case .bass: .indigoText
        case .accidentals: .pinkText
        case .rhythm: .cyanText
        case .writing: .tealText
        case .terms: .amberText
        case .chords: .violetText
        case .games: .greenText
        case .ear: .limeText
        }
    }
}

/// 135° doğrusal gradyanlar (web: gradient). Konu çubuğu ise 90°: CategoryColor.base → CategoryColor.light.
public enum BrandGradient: String, CaseIterable, Sendable {
    case primary, primaryFlat, success, warning, danger

    public var stops: (PaletteColor, PaletteColor) {
        switch self {
        case .primary: (.violet600, .violet800)
        case .primaryFlat: (.violet600, .violet700)
        case .success: (.green600, .green700)
        case .warning: (.amber500, .amber600)
        case .danger: (.red500, .red600)
        }
    }
}

/// Köşe yuvarlaklığı: xs ince çubuklar, sm küçük öğe, md düğme/şık, lg kart, pill hap.
public enum Radius {
    public static let xs: Double = 4
    public static let sm: Double = 8
    public static let md: Double = 12
    public static let lg: Double = 20
    public static let pill: Double = 999
}

/// 4'ün katları. Boşluk, iç boşluk ve aralıklar bu basamaklardan seçilir (web: space[0…12]).
public enum Space {
    public static let s0: Double = 0
    public static let s1: Double = 4
    public static let s2: Double = 8
    public static let s3: Double = 12
    public static let s4: Double = 16
    public static let s5: Double = 20
    public static let s6: Double = 24
    public static let s8: Double = 32
    public static let s10: Double = 40
    public static let s12: Double = 48
}

/// 12 etiket · 14 gövde/alt yazı · 16 ana metin · 20 alt başlık · 24 başlık · 32 büyük sayı
public enum FontSize {
    public static let xs: Double = 12
    public static let sm: Double = 14
    public static let md: Double = 16
    public static let lg: Double = 20
    public static let xl: Double = 24
    public static let xxl: Double = 32
}

/// Yazı kalınlığı (CSS sayısı). Uygulama katmanı her birini Outfit / JetBrains Mono dosyasına eşler.
public enum FontWeight: Int, CaseIterable, Sendable {
    case regular = 400
    case medium = 500
    case semibold = 600
    case bold = 700
    case heavy = 800
}

/// Harf aralığı, yazı boyutunun katı olarak (CSS em): tight başlıklar, label büyük harf etiketler.
public enum Tracking {
    public static let tight: Double = -0.03
    public static let label: Double = 0.08
}

/// Gölge: dikey kayma, bulanıklık (CSS blur yarıçapı) ve renk.
public struct BoxShadow: Equatable, Sendable {
    public let y: Double
    public let blur: Double
    public let color: RGBA

    public static let none = BoxShadow(y: 0, blur: 0, color: RGBA(0))
    public static let card = BoxShadow(y: 4, blur: 16, color: PaletteColor.black.rgba.opacity(0.18))
    public static let raised = BoxShadow(y: 8, blur: 28, color: PaletteColor.black.rgba.opacity(0.28))

    /// Renkli parıltı: öne çıkan düğme ve rozetler (web: shadow.glow(hex, strength))
    public static func glow(_ color: PaletteColor, strength: Double = 0.38) -> BoxShadow {
        BoxShadow(y: 8, blur: 28, color: color.rgba.opacity(strength))
    }
}

/// Kübik Bezier eğrisi (CSS cubic-bezier)
public struct Curve: Equatable, Sendable {
    public let x1: Double, y1: Double, x2: Double, y2: Double
}

/// Geçiş süreleri (saniye) ve eğrileri
public enum Motion {
    public static let fast: Double = 0.120
    public static let base: Double = 0.220
    public static let slow: Double = 0.380
    public static let ease = Curve(x1: 0.2, y1: 0.8, x2: 0.2, y2: 1)
    public static let spring = Curve(x1: 0.34, y1: 1.56, x2: 0.64, y2: 1)
}

/// Dokunma hedefi en az 44 pt (Apple HIG / WCAG 2.5.5)
public enum Touch {
    public static let min: Double = 44
}

/// Düzen ölçüleri
public enum Metrics {
    /// Tablette okunur içerik genişliği (web: ui/TabletColumn varsayılanı)
    public static let tabletColumn: Double = 680
}
