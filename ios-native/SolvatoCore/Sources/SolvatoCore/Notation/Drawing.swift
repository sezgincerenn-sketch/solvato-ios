// Çizim listesi: nota yerleşim motorunun çıktısı. SVG'deki gibi viewBox koordinatlarında çizgi, dikdörtgen, daire,
// yol, Bravura sembolü ve yazı. SwiftUI tarafı (Solvato/Notation/DrawingView) bunu Canvas'a çizer; yerleşim burada
// ve Linux'ta testlenir (web'deki SVG çıktısıyla karşılaştırılır).
import Foundation

/// Renk: temaya göre değişen ad (web `var(--notation)`) ya da sabit renk
public enum Paint: Equatable, Hashable, Sendable {
    case theme(ThemeColor)
    case color(RGBA)
    /// SVG `currentColor`: çevredeki yazı rengi
    case current

    /// Testlerde karşılaştırma anahtarı: "var:notation", "#8B5CF6FF", "current"
    public var key: String {
        switch self {
        case let .theme(t): "var:\(t.rawValue)"
        case let .color(c): c.hex
        case .current: "current"
        }
    }

    public static func palette(_ p: PaletteColor) -> Paint { .color(p.rgba) }
}

public enum TextAnchor: String, Sendable { case start, middle, end }
public enum FontRole: String, Sendable {
    /// Outfit
    case ui
    /// 'Times New Roman' (müzik terimleri, tempo yazısı, triole)
    case serif
}

public enum DrawItem: Equatable, Sendable {
    case line(x1: Double, y1: Double, x2: Double, y2: Double, stroke: Paint, width: Double, round: Bool = false)
    case rect(x: Double, y: Double, w: Double, h: Double, rx: Double = 0, fill: Paint?, stroke: Paint? = nil, strokeWidth: Double = 0)
    case circle(cx: Double, cy: Double, r: Double, fill: Paint)
    /// Serbest yol (bağ, legato, crescendo çatalı)
    case path([PathCommand], fill: Paint? = nil, stroke: Paint?, width: Double, round: Bool = false)
    /// Bravura sembolü: (x, y) çıkış noktası, sp porte aralığı
    case glyph(String, x: Double, y: Double, sp: Double = 10, fill: Paint, opacity: Double = 1, glow: Paint? = nil)
    /// SVG gibi: y yazının taban çizgisi
    case text(String, x: Double, y: Double, size: Double, weight: Int = 400, italic: Bool = false, anchor: TextAnchor = .start, font: FontRole = .ui, fill: Paint)
}

public struct Drawing: Equatable, Sendable {
    /// x, y, genişlik, yükseklik
    public var viewBox: (x: Double, y: Double, w: Double, h: Double)
    public var items: [DrawItem]
    /// Ekrandaki boyut kuralları (web'deki svg stili)
    public var sizing: Sizing

    public struct Sizing: Equatable, Sendable {
        /// Genişlik kapsayıcıyı doldurur, en çok bu kadar (pt)
        public var maxWidth: Double?
        public var maxHeight: Double?
        /// Sabit yükseklik (genişlik orana göre)
        public var height: Double?
        /// Sabit genişlik
        public var width: Double?
        /// Nota gölgesi (koyu temada mor parıltı, `--notation-shadow`)
        public var notationShadow = false
        public init(maxWidth: Double? = nil, maxHeight: Double? = nil, height: Double? = nil, width: Double? = nil, notationShadow: Bool = false) {
            self.maxWidth = maxWidth
            self.maxHeight = maxHeight
            self.height = height
            self.width = width
            self.notationShadow = notationShadow
        }
    }

    public static func == (a: Drawing, b: Drawing) -> Bool {
        a.viewBox == b.viewBox && a.items == b.items && a.sizing == b.sizing
    }
}

// MARK: - Bravura sembolleri
public struct SmuflGlyph: Sendable {
    public let path: [PathCommand]
    /// Genişlik (porte aralığı cinsinden)
    public let width: Double
    public let southWest: (x: Double, y: Double)
    public let northEast: (x: Double, y: Double)
}

/// Web src/data/smufl.ts (Bravura'dan çıkarılmış yollar; 1 em = 1000, porte aralığı = 250, y yukarı).
/// scripts/altin.mjs Resources/smufl.json'a kopyalar.
public enum Smufl {
    public static let glyphs: [String: SmuflGlyph] = {
        guard let url = Bundle.module.url(forResource: "smufl", withExtension: "json"),
            let data = try? Data(contentsOf: url), let o = (try? JSON.parse(data))?.object
        else { fatalError("smufl.json okunamadı") }
        var out: [String: SmuflGlyph] = [:]
        for e in o.entries {
            let sw = e.value["sw"]?.array?.compactMap(\.double) ?? [0, 0]
            let ne = e.value["ne"]?.array?.compactMap(\.double) ?? [0, 0]
            out[e.key] = SmuflGlyph(
                path: (try? SVGPath.parse(e.value["d"]?.string ?? "")) ?? [], width: e.value["w"]?.double ?? 0,
                southWest: (sw[0], sw[1]), northEast: (ne[0], ne[1]))
        }
        return out
    }()

    /// Sembolün genişliği (web glyphWidth)
    public static func width(_ name: String, sp: Double = 10) -> Double { (glyphs[name]?.width ?? 0) * sp }
}
