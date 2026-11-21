// Tasarım sisteminin renkleri: sabit palet (temadan bağımsız) ve temaya göre değişen anlamsal renkler.
// Web karşılığı src/design/tokens.ts (palette) ve tokens.css (koyu/açık değişkenler); değerler birebir aynı,
// Tests/SolvatoCoreTests/TokensTests.swift bunu scripts/native-tokens.mjs çıktısıyla doğrular.

/// sRGB renk: 0xRRGGBB_AA. Arayüz katmanı (SwiftUI) bunu Color'a çevirir; burada yalnızca değer tutulur.
public struct RGBA: Equatable, Hashable, Sendable {
    public let value: UInt32
    public init(_ value: UInt32) { self.value = value }

    public var red: Double { Double((value >> 24) & 0xFF) / 255 }
    public var green: Double { Double((value >> 16) & 0xFF) / 255 }
    public var blue: Double { Double((value >> 8) & 0xFF) / 255 }
    public var alpha: Double { Double(value & 0xFF) / 255 }

    /// Aynı renk, başka saydamlıkla. Web'deki alpha(hex, a) ile aynı yuvarlama: round(a * 255).
    public func opacity(_ a: Double) -> RGBA {
        RGBA((value & 0xFFFF_FF00) | UInt32((a * 255).rounded()))
    }

    /// "#RRGGBBAA" (büyük harf)
    public var hex: String {
        let digits = String(value, radix: 16, uppercase: true)
        return "#" + String(repeating: "0", count: 8 - digits.count) + digits
    }
}

/// Sabit palet: dolgu, gradyan, gölge, piyano tuşu. Temadan bağımsız.
public enum PaletteColor: String, CaseIterable, Sendable {
    case white
    case black
    case slate50
    case slate100
    case slate200
    case slate300
    case slate400
    case slate500
    case slate600
    case slate700
    case slate800
    case slate900
    case slate950
    case violet50
    case violet100
    case violet200
    case violet300
    case violet400
    case violet500
    case violet600
    case violet700
    case violet800
    case violet900
    case violet950
    case purple500
    case purple950
    case blue300
    case blue400
    case blue500
    case blue600
    case blue700
    case lime400
    case lime300
    case lime500
    case green300
    case green400
    case green500
    case green600
    case green700
    case teal400
    case teal500
    case teal600
    case teal700
    case cyan400
    case cyan500
    case amber300
    case amber400
    case amber500
    case amber600
    case amber800
    case orange300
    case orange400
    case orange500
    case red300
    case red400
    case red500
    case red600
    case red700
    case pink400
    case pink500
    case indigo400
    case indigo500

    public var rgba: RGBA {
        switch self {
        case .white: RGBA(0xFFFFFF_FF)
        case .black: RGBA(0x000000_FF)
        case .slate50: RGBA(0xF8FAFC_FF)
        case .slate100: RGBA(0xF1F5F9_FF)
        case .slate200: RGBA(0xE2E8F0_FF)
        case .slate300: RGBA(0xCBD5E1_FF)
        case .slate400: RGBA(0x94A3B8_FF)
        case .slate500: RGBA(0x64748B_FF)
        case .slate600: RGBA(0x475569_FF)
        case .slate700: RGBA(0x334155_FF)
        case .slate800: RGBA(0x1E293B_FF)
        case .slate900: RGBA(0x0F172A_FF)
        case .slate950: RGBA(0x080F1E_FF)
        case .violet50: RGBA(0xF5F3FF_FF)
        case .violet100: RGBA(0xEDE9FE_FF)
        case .violet200: RGBA(0xDDD6FE_FF)
        case .violet300: RGBA(0xC4B5FD_FF)
        case .violet400: RGBA(0xA78BFA_FF)
        case .violet500: RGBA(0x8B5CF6_FF)
        case .violet600: RGBA(0x7C3AED_FF)
        case .violet700: RGBA(0x6D28D9_FF)
        case .violet800: RGBA(0x5B21B6_FF)
        case .violet900: RGBA(0x4C1D95_FF)
        case .violet950: RGBA(0x2E1065_FF)
        case .purple500: RGBA(0xA855F7_FF)
        case .purple950: RGBA(0x3B0764_FF)
        case .blue300: RGBA(0x93C5FD_FF)
        case .blue400: RGBA(0x60A5FA_FF)
        case .blue500: RGBA(0x3B82F6_FF)
        case .blue600: RGBA(0x2563EB_FF)
        case .blue700: RGBA(0x1D4ED8_FF)
        case .lime400: RGBA(0x4ADE80_FF)
        case .lime300: RGBA(0xBEF264_FF)
        case .lime500: RGBA(0x84CC16_FF)
        case .green300: RGBA(0x6EE7B7_FF)
        case .green400: RGBA(0x34D399_FF)
        case .green500: RGBA(0x10B981_FF)
        case .green600: RGBA(0x059669_FF)
        case .green700: RGBA(0x047857_FF)
        case .teal400: RGBA(0x2DD4BF_FF)
        case .teal500: RGBA(0x14B8A6_FF)
        case .teal600: RGBA(0x0D9488_FF)
        case .teal700: RGBA(0x0F766E_FF)
        case .cyan400: RGBA(0x22D3EE_FF)
        case .cyan500: RGBA(0x06B6D4_FF)
        case .amber300: RGBA(0xFCD34D_FF)
        case .amber400: RGBA(0xFBBF24_FF)
        case .amber500: RGBA(0xF59E0B_FF)
        case .amber600: RGBA(0xD97706_FF)
        case .amber800: RGBA(0x92400E_FF)
        case .orange300: RGBA(0xFDBA74_FF)
        case .orange400: RGBA(0xFB923C_FF)
        case .orange500: RGBA(0xF97316_FF)
        case .red300: RGBA(0xFCA5A5_FF)
        case .red400: RGBA(0xF87171_FF)
        case .red500: RGBA(0xEF4444_FF)
        case .red600: RGBA(0xDC2626_FF)
        case .red700: RGBA(0xB91C1C_FF)
        case .pink400: RGBA(0xF472B6_FF)
        case .pink500: RGBA(0xEC4899_FF)
        case .indigo400: RGBA(0x818CF8_FF)
        case .indigo500: RGBA(0x6366F1_FF)
        }
    }
}

/// Görünüm: koyu ya da açık.
public enum Appearance: String, CaseIterable, Sendable {
    case dark, light
}

/// Temaya göre değişen renkler. Ham değer web'deki CSS değişkeninin adıdır (--c-bg → "c-bg").
public enum ThemeColor: String, CaseIterable, Sendable {
    case bg = "c-bg"
    case bgDeep = "c-bg-deep"
    case surface = "c-surface"
    case overlay = "c-overlay"
    case scrim = "c-scrim"
    case fill = "c-fill"
    case fillStrong = "c-fill-strong"
    case fillStronger = "c-fill-stronger"
    case border = "c-border"
    case borderStrong = "c-border-strong"
    case text = "c-text"
    case textSoft = "c-text-soft"
    case textSecondary = "c-text-secondary"
    case textMuted = "c-text-muted"
    case textSubtle = "c-text-subtle"
    case textFaint = "c-text-faint"
    case textDisabled = "c-text-disabled"
    case violetText = "c-violet-text"
    case violetTextSoft = "c-violet-text-soft"
    case blueText = "c-blue-text"
    case greenText = "c-green-text"
    case tealText = "c-teal-text"
    case cyanText = "c-cyan-text"
    case amberText = "c-amber-text"
    case orangeText = "c-orange-text"
    case limeText = "c-lime-text"
    case redText = "c-red-text"
    case pinkText = "c-pink-text"
    case indigoText = "c-indigo-text"
    case highlightTitle = "c-highlight-title"
    case highlightBody = "c-highlight-body"
    case paper = "c-paper"
    case staffLine = "staff-line"
    case notation = "notation"
    case staffLabel = "staff-label"
    case termSymbol = "term-symbol"
    case staffPanel = "staff-panel"
    case focusRing = "focus-ring"

    public func rgba(_ appearance: Appearance) -> RGBA {
        let pair = values
        return appearance == .dark ? pair.dark : pair.light
    }

    private var values: (dark: RGBA, light: RGBA) {
        switch self {
        case .bg: (RGBA(0x0F172A_FF), RGBA(0xF8FAFC_FF))
        case .bgDeep: (RGBA(0x080F1E_FF), RGBA(0xE2E8F0_FF))
        case .surface: (RGBA(0x1E293B_FF), RGBA(0xFFFFFF_FF))
        case .overlay: (RGBA(0x0F172A_EB), RGBA(0xF8FAFC_F0))
        case .scrim: (RGBA(0x020617_B3), RGBA(0x0F172A_73))
        case .fill: (RGBA(0xFFFFFF_0A), RGBA(0x0F172A_0A))
        case .fillStrong: (RGBA(0xFFFFFF_12), RGBA(0x0F172A_0F))
        case .fillStronger: (RGBA(0xFFFFFF_1F), RGBA(0x0F172A_1A))
        case .border: (RGBA(0xFFFFFF_14), RGBA(0x0F172A_24))
        case .borderStrong: (RGBA(0xFFFFFF_26), RGBA(0x0F172A_38))
        case .text: (RGBA(0xF1F5F9_FF), RGBA(0x0F172A_FF))
        case .textSoft: (RGBA(0xE2E8F0_FF), RGBA(0x1E293B_FF))
        case .textSecondary: (RGBA(0xCBD5E1_FF), RGBA(0x334155_FF))
        case .textMuted: (RGBA(0x94A3B8_FF), RGBA(0x475569_FF))
        case .textSubtle: (RGBA(0x8294AE_FF), RGBA(0x475569_FF))
        case .textFaint: (RGBA(0x7D8CA3_FF), RGBA(0x5F6F86_FF))
        case .textDisabled: (RGBA(0x475569_FF), RGBA(0x94A3B8_FF))
        case .violetText: (RGBA(0xA78BFA_FF), RGBA(0x6D28D9_FF))
        case .violetTextSoft: (RGBA(0xC4B5FD_FF), RGBA(0x6D28D9_FF))
        case .blueText: (RGBA(0x60A5FA_FF), RGBA(0x1D4ED8_FF))
        case .greenText: (RGBA(0x34D399_FF), RGBA(0x065F46_FF))
        case .tealText: (RGBA(0x2DD4BF_FF), RGBA(0x0F766E_FF))
        case .cyanText: (RGBA(0x22D3EE_FF), RGBA(0x0E7490_FF))
        case .amberText: (RGBA(0xFCD34D_FF), RGBA(0x92400E_FF))
        case .orangeText: (RGBA(0xFB923C_FF), RGBA(0x9A3412_FF))
        case .limeText: (RGBA(0xA3E635_FF), RGBA(0x4D7C0F_FF))
        case .redText: (RGBA(0xF87171_FF), RGBA(0xB91C1C_FF))
        case .pinkText: (RGBA(0xF472B6_FF), RGBA(0xBE185D_FF))
        case .indigoText: (RGBA(0x818CF8_FF), RGBA(0x4338CA_FF))
        case .highlightTitle: (RGBA(0xEDE9FE_FF), RGBA(0x4C1D95_FF))
        case .highlightBody: (RGBA(0xB4A9D6_FF), RGBA(0x5B21B6_FF))
        case .paper: (RGBA(0xFFFFFF_0A), RGBA(0xFFFFFF_FF))
        case .staffLine: (RGBA(0xD4D8E8_FF), RGBA(0x64748B_FF))
        case .notation: (RGBA(0xF0F0FF_FF), RGBA(0x0F172A_FF))
        case .staffLabel: (RGBA(0xA0A0C8_B3), RGBA(0x475569_FF))
        case .termSymbol: (RGBA(0xC4B5FD_FF), RGBA(0x6D28D9_FF))
        case .staffPanel: (RGBA(0x000000_40), RGBA(0xFFFFFF_FF))
        case .focusRing: (RGBA(0xA78BFA_FF), RGBA(0x6D28D9_FF))
        }
    }
}
