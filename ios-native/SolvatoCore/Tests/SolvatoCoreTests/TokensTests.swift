// Native tasarım değerleri web'dekiyle birebir aynı mı: Fixtures/tokens.json (scripts/native-tokens.mjs çıktısı) ile karşılaştırır.
// Bir renk, ölçü ya da yazı değeri ayrışırsa hangi adın farklı olduğunu söyleyerek düşer.
import Foundation
import XCTest

@testable import SolvatoCore

final class TokensTests: XCTestCase {
    private var web: [String: Any] = [:]

    override func setUpWithError() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "tokens", withExtension: "json", subdirectory: "Fixtures"))
        web = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    private func dict(_ key: String) -> [String: Any] { web[key] as? [String: Any] ?? [:] }
    private func number(_ group: String, _ key: String) -> Double? { (dict(group)[key] as? NSNumber)?.doubleValue }
    /// JSON sayı dizisi → [Double] (Linux'ta NSNumber köprüsü doğrudan `as? [Double]` ile çalışmaz)
    private func doubles(_ value: Any?) -> [Double]? { (value as? [Any])?.compactMap { ($0 as? NSNumber)?.doubleValue } }

    func testPalette() {
        let palette = dict("palette")
        XCTAssertEqual(Set(palette.keys), Set(PaletteColor.allCases.map(\.rawValue)), "palet adları")
        for color in PaletteColor.allCases {
            XCTAssertEqual(color.rgba.hex, palette[color.rawValue] as? String, "palette.\(color.rawValue)")
        }
    }

    func testThemeColors() {
        let theme = dict("theme")
        for appearance in Appearance.allCases {
            let values = theme[appearance.rawValue] as? [String: String] ?? [:]
            XCTAssertEqual(Set(values.keys), Set(ThemeColor.allCases.map(\.rawValue)), "\(appearance) değişken adları")
            for color in ThemeColor.allCases {
                XCTAssertEqual(color.rgba(appearance).hex, values[color.rawValue], "\(appearance) --\(color.rawValue)")
            }
        }
    }

    func testBrandCategoryGradient() {
        let brand = dict("brand")
        let native: [String: PaletteColor] = [
            "primary": Brand.primary, "primaryHover": Brand.primaryHover, "accent": Brand.accent,
            "highlight": Brand.highlight, "success": Brand.success, "danger": Brand.danger, "warning": Brand.warning,
        ]
        XCTAssertEqual(Set(brand.keys), Set(native.keys))
        for (key, color) in native { XCTAssertEqual(color.rgba.hex, brand[key] as? String, "brand.\(key)") }

        let onPrimary = (dict("colors")["onPrimary"] as? [String: String])?["fixed"]
        XCTAssertEqual(Brand.onPrimary.rgba.hex, onPrimary, "colors.onPrimary")

        let category = dict("category")
        XCTAssertEqual(Set(category.keys), Set(Category.allCases.map(\.rawValue)), "konu adları")
        for c in Category.allCases {
            let w = category[c.rawValue] as? [String: String] ?? [:]
            XCTAssertEqual(c.base.rgba.hex, w["base"], "category.\(c.rawValue).base")
            XCTAssertEqual(c.light.rgba.hex, w["light"], "category.\(c.rawValue).light")
            XCTAssertEqual(c.text.rawValue, w["text"], "category.\(c.rawValue).text")
        }

        let gradient = dict("gradient")
        XCTAssertEqual(Set(gradient.keys), Set(BrandGradient.allCases.map(\.rawValue)), "gradyan adları")
        for g in BrandGradient.allCases {
            XCTAssertEqual([g.stops.0.rgba.hex, g.stops.1.rgba.hex], gradient[g.rawValue] as? [String], "gradient.\(g.rawValue)")
        }
    }

    func testMetrics() {
        let radius: [String: Double] = ["xs": Radius.xs, "sm": Radius.sm, "md": Radius.md, "lg": Radius.lg, "pill": Radius.pill]
        XCTAssertEqual(Set(dict("radius").keys), Set(radius.keys))
        for (k, v) in radius { XCTAssertEqual(v, number("radius", k), "radius.\(k)") }

        let space: [String: Double] = [
            "0": Space.s0, "1": Space.s1, "2": Space.s2, "3": Space.s3, "4": Space.s4,
            "5": Space.s5, "6": Space.s6, "8": Space.s8, "10": Space.s10, "12": Space.s12,
        ]
        XCTAssertEqual(Set(dict("space").keys), Set(space.keys))
        for (k, v) in space { XCTAssertEqual(v, number("space", k), "space[\(k)]") }

        let size: [String: Double] = [
            "xs": FontSize.xs, "sm": FontSize.sm, "md": FontSize.md, "lg": FontSize.lg, "xl": FontSize.xl, "xxl": FontSize.xxl,
        ]
        XCTAssertEqual(Set(dict("fontSize").keys), Set(size.keys))
        for (k, v) in size { XCTAssertEqual(v, number("fontSize", k), "font.size.\(k)") }

        XCTAssertEqual(Set(dict("fontWeight").keys), Set(FontWeight.allCases.map { "\($0)" }))
        for w in FontWeight.allCases { XCTAssertEqual(Double(w.rawValue), number("fontWeight", "\(w)"), "font.weight.\(w)") }

        XCTAssertEqual(Tracking.tight, number("tracking", "tight"))
        XCTAssertEqual(Tracking.label, number("tracking", "label"))
        XCTAssertEqual(Touch.min, (web["touchMin"] as? NSNumber)?.doubleValue)
    }

    func testShadowAndMotion() {
        for (name, s) in [("card", ShadowStyle.card), ("raised", ShadowStyle.raised)] {
            let w = dict("shadow")[name] as? [String: Any] ?? [:]
            XCTAssertEqual(s.y, (w["y"] as? NSNumber)?.doubleValue, "shadow.\(name).y")
            XCTAssertEqual(s.blur, (w["blur"] as? NSNumber)?.doubleValue, "shadow.\(name).blur")
            XCTAssertEqual(s.color.hex, w["color"] as? String, "shadow.\(name).color")
        }
        let glow = ShadowStyle.glow(.black)
        XCTAssertEqual(glow.y, number("glow", "y"))
        XCTAssertEqual(glow.blur, number("glow", "blur"))
        XCTAssertEqual(glow.color.hex, dict("glow")["alpha38"] as? String, "glow varsayılan güç 0.38")

        XCTAssertEqual(Motion.fast * 1000, number("motion", "fast")!, accuracy: 0.001)
        XCTAssertEqual(Motion.base * 1000, number("motion", "base")!, accuracy: 0.001)
        XCTAssertEqual(Motion.slow * 1000, number("motion", "slow")!, accuracy: 0.001)
        for (name, c) in [("ease", Motion.ease), ("spring", Motion.spring)] {
            XCTAssertEqual([c.x1, c.y1, c.x2, c.y2], doubles(dict("motion")[name]), "motion.\(name)")
        }
    }

    func testRGBA() {
        let violet = PaletteColor.violet500.rgba
        XCTAssertEqual(violet.opacity(0.12).hex, "#8B5CF61F", "web: alpha(palette.violet500, 0.12)")
        XCTAssertEqual(RGBA(0x0000_00FF).hex, "#000000FF")
        XCTAssertEqual(violet.red, Double(0x8B) / 255, accuracy: 1e-9)
        XCTAssertEqual(violet.alpha, 1)
    }
}

final class ThemeModeTests: XCTestCase {
    func testStoredValues() {
        XCTAssertEqual(ThemeMode.storageKey, "pianote_theme_v1")
        XCTAssertEqual(ThemeMode(stored: nil), .system)
        XCTAssertEqual(ThemeMode(stored: "bozuk"), .system)
        XCTAssertEqual(ThemeMode(stored: "light"), .light)
        XCTAssertEqual(ThemeMode(stored: "dark"), .dark)
    }

    func testResolve() {
        XCTAssertEqual(ThemeMode.system.resolve(system: .light), .light)
        XCTAssertEqual(ThemeMode.system.resolve(system: .dark), .dark)
        XCTAssertEqual(ThemeMode.dark.resolve(system: .light), .dark)
        XCTAssertEqual(ThemeMode.light.resolve(system: .dark), .light)
    }
}
