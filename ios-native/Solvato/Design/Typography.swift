// Yazı tipleri: arayüz Outfit, sayılar ve kodlar JetBrains Mono, müzik terimleri Times New Roman italik (web: font.family).
// Dosyalar Resources/Fonts altında, Info.plist UIAppFonts ile yüklenir. Boyutlar web'deki px ile aynı.
// Dinamik Yazı (0.8, erisilebilirlik-ipad.md): `.ui` / `.mono` / `.term` telefonun yazı boyutuyla büyür ya da küçülür
// (varsayılan Large'da tam bu boyut); sınır xSmall…xxxLarge (SolvatoApp, `AppTypeSize`). Porte, klavye, halkalar,
// açılış ve logo gibi büyümemesi gereken yerler `…Fixed` kullanır.
import SolvatoCore
import SwiftUI

enum FontFamily {
    case ui, mono, serif

    func postScriptName(_ weight: FontWeight) -> String {
        switch self {
        case .ui: "Outfit-" + Self.suffix(weight)
        case .mono: "JetBrainsMono-" + Self.suffix(weight)
        case .serif: weight.rawValue >= 600 ? "TimesNewRomanPS-BoldItalicMT" : "TimesNewRomanPS-ItalicMT"
        }
    }

    private static func suffix(_ weight: FontWeight) -> String {
        switch weight {
        case .regular: "Regular"
        case .medium: "Medium"
        case .semibold: "SemiBold"
        case .bold: "Bold"
        case .heavy: "ExtraBold"
        }
    }
}

extension Font {
    /// Arayüz yazısı (Outfit), Dinamik Yazı ile ölçeklenir. Örnek: .ui(FontSize.md, .bold)
    static func ui(_ size: Double, _ weight: FontWeight = .regular) -> Font {
        .custom(FontFamily.ui.postScriptName(weight), size: size, relativeTo: .body)
    }

    /// Sayı ve kod yazısı (JetBrains Mono), ölçeklenir
    static func mono(_ size: Double, _ weight: FontWeight = .regular) -> Font {
        .custom(FontFamily.mono.postScriptName(weight), size: size, relativeTo: .body)
    }

    /// Müzik terimi (italik serif), ölçeklenir
    static func term(_ size: Double, _ weight: FontWeight = .regular) -> Font {
        .custom(FontFamily.serif.postScriptName(weight), size: size, relativeTo: .body)
    }

    /// Büyümeyen arayüz yazısı: klavye tuş adları, halka içindeki sayılar, açılış, logo, çizim içindeki yazılar
    static func uiFixed(_ size: Double, _ weight: FontWeight = .regular) -> Font {
        .custom(FontFamily.ui.postScriptName(weight), fixedSize: size)
    }

    /// Büyümeyen sayı yazısı (halkalar, klavyedeki oktav rakamı)
    static func monoFixed(_ size: Double, _ weight: FontWeight = .regular) -> Font {
        .custom(FontFamily.mono.postScriptName(weight), fixedSize: size)
    }

    /// Büyümeyen terim sembolü (soru turundaki büyük "p", "mf")
    static func termFixed(_ size: Double, _ weight: FontWeight = .regular) -> Font {
        .custom(FontFamily.serif.postScriptName(weight), fixedSize: size)
    }
}

/// Dinamik Yazı sınırları (erisilebilirlik-ipad.md §1): uygulama genelinde xSmall…xxxLarge (AX boyutlarında
/// xxxLarge'da kalır); tur ekranlarında (soru, akor, Ritmi Tut, düello) kaydırmasız sığsın diye en çok xxLarge.
enum AppTypeSize {
    static var app: ClosedRange<DynamicTypeSize> { .xSmall ... .xxxLarge }
    static var round: ClosedRange<DynamicTypeSize> { .xSmall ... .xxLarge }
}

extension View {
    /// Harf aralığı, yazı boyutunun katı olarak (web: letter-spacing em)
    func tracking(em: Double, size: Double) -> some View {
        tracking(em * size)
    }
}

extension View {
    /// CSS line-height: satır kutusu `multiple × size`. Outfit'in doğal satır yüksekliği 1,26 em (hhea 1000/−260);
    /// fark satır arasına ve (yarısı) üste/alta eklenir. Örnek: .lineHeight(1.5, size: FontSize.sm)
    func lineHeight(_ multiple: Double, size: Double, natural: Double = 1.26) -> some View {
        let extra = max(0, (multiple - natural) * size)
        return lineSpacing(extra).padding(.vertical, extra / 2)
    }
}
