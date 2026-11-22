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
    /// Birlikte hareket eden parça (web'de cevaptan sonra zıplayan / titreyen nota grubu `<g>`): öğe aralığı ve
    /// `transform-box: fill-box; transform-origin: center` için kutunun ortası. Karşılaştırmaya girmez.
    public var group: (items: Range<Int>, center: Point)?

    public init(viewBox: (x: Double, y: Double, w: Double, h: Double), items: [DrawItem], sizing: Sizing, group: (items: Range<Int>, center: Point)? = nil) {
        self.viewBox = viewBox
        self.items = items
        self.sizing = sizing
        self.group = group
    }

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

    /// Öğelerin geometrik kutusu (SVG fill-box: çizgi kalınlığı hariç); sembol ve çizgi dışındakiler yok sayılır
    public static func box(_ items: some Sequence<DrawItem>) -> (minX: Double, minY: Double, maxX: Double, maxY: Double)? {
        var b: (minX: Double, minY: Double, maxX: Double, maxY: Double)?
        func add(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) {
            let n = (min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1))
            b = b.map { (min($0.minX, n.0), min($0.minY, n.1), max($0.maxX, n.2), max($0.maxY, n.3)) } ?? n
        }
        for it in items {
            switch it {
            case let .line(x1, y1, x2, y2, _, _, _): add(x1, y1, x2, y2)
            case let .glyph(name, x, y, sp, _, _, _):
                guard let g = glyphs[name] else { continue }
                add(x + g.southWest.x * sp, y - g.northEast.y * sp, x + g.northEast.x * sp, y - g.southWest.y * sp)
            default: continue
            }
        }
        return b
    }

    /// Sembolün genişliği (web glyphWidth)
    public static func width(_ name: String, sp: Double = 10) -> Double { (glyphs[name]?.width ?? 0) * sp }
}
