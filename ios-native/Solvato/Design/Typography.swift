// Yazı tipleri: arayüz Outfit, sayılar ve kodlar JetBrains Mono, müzik terimleri Times New Roman italik (web: font.family).
// Dosyalar Resources/Fonts altında, Info.plist UIAppFonts ile yüklenir. Boyutlar sabit (web'deki px ile aynı);
// Dinamik Yazı desteği aşama 0.8'de eklenecek.
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
    /// Arayüz yazısı (Outfit). Örnek: .ui(FontSize.md, .bold)
    static func ui(_ size: Double, _ weight: FontWeight = .regular) -> Font {
        .custom(FontFamily.ui.postScriptName(weight), fixedSize: size)
    }

    /// Sayı ve kod yazısı (JetBrains Mono)
    static func mono(_ size: Double, _ weight: FontWeight = .regular) -> Font {
        .custom(FontFamily.mono.postScriptName(weight), fixedSize: size)
    }

    /// Müzik terimi (italik serif)
    static func term(_ size: Double, _ weight: FontWeight = .regular) -> Font {
        .custom(FontFamily.serif.postScriptName(weight), fixedSize: size)
    }
}

extension View {
    /// Harf aralığı, yazı boyutunun katı olarak (web: letter-spacing em)
    func tracking(em: Double, size: Double) -> some View {
        tracking(em * size)
    }
}
