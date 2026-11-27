// Apple'ın gezinme çubuğunun görünümü (docs/ozellikler/gezinme-cubugu.md): başlıklar Outfit (büyük başlık ExtraBold,
// küçük başlık Bold), bugünkü başlık rengiyle; zemin kaydırma alanının en üstünde sayfanın zemini (saydam), içerik
// altına girince iOS'un kendi bulanık zemini. iOS 26'da çubuk ve düğmeler Liquid Glass (zemin saydam bırakılır).
// SwiftUI başlığın yazı tipini değiştiremediği için UIKit görünüm vekiliyle; SolvatoApp açılışta, AppRoot Dinamik
// Yazı değişince uygular. Dinamik Yazı sınırı uygulamanınki (xxxLarge).
import SolvatoCore
import SwiftUI
import UIKit

@MainActor
enum NavigationBarStyle {
    /// Uygulamanın yazı boyutuyla (Dinamik Yazı) çubuk görünümünü kurar; açık çubuklara da uygular
    static func apply(_ size: DynamicTypeSize) { apply(category(size)) }

    static func apply(_ category: UIContentSizeCategory) {
        let traits = UITraitCollection(preferredContentSizeCategory: min(category, .extraExtraExtraLarge))
        let standard = UINavigationBarAppearance()
        let edge = UINavigationBarAppearance()
        if #available(iOS 26.0, *) {
            // Liquid Glass: zemin hep saydam, kaydırınca iOS kenar efektini kendisi çizer
            standard.configureWithTransparentBackground()
        } else {
            standard.configureWithDefaultBackground()
        }
        edge.configureWithTransparentBackground()
        style(standard, traits)
        style(edge, traits)

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = standard
        bar.compactAppearance = standard
        bar.scrollEdgeAppearance = edge
        bar.compactScrollEdgeAppearance = edge

        // Görünüm vekili yalnız yeni çubuklara işler; açık olanlar da güncellensin
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for w in scene.windows { refresh(w, standard: standard, edge: edge) }
        }
    }

    /// Başlık yazıları (configureWith… zemini sıfırladıktan sonra)
    private static func style(_ a: UINavigationBarAppearance, _ traits: UITraitCollection) {
        let text = ThemeColor.text.uiColor
        let large = font(.heavy, FontSize.largeTitle, style: .largeTitle, traits)
        a.largeTitleTextAttributes = [.font: large, .foregroundColor: text, .kern: Tracking.tight * large.pointSize]
        a.titleTextAttributes = [.font: font(.bold, FontSize.barTitle, style: .headline, traits), .foregroundColor: text]
        let back = UIBarButtonItemAppearance(style: .plain)
        back.normal.titleTextAttributes = [.font: font(.medium, FontSize.barTitle, style: .body, traits)]
        a.backButtonAppearance = back
    }

    private static func font(_ weight: FontWeight, _ size: Double, style: UIFont.TextStyle, _ traits: UITraitCollection) -> UIFont {
        let base = UIFont(name: FontFamily.ui.postScriptName(weight), size: size) ?? .systemFont(ofSize: size, weight: .bold)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base, compatibleWith: traits)
    }

    private static func refresh(_ view: UIView, standard: UINavigationBarAppearance, edge: UINavigationBarAppearance) {
        if let bar = view as? UINavigationBar {
            bar.standardAppearance = standard
            bar.compactAppearance = standard
            bar.scrollEdgeAppearance = edge
            bar.compactScrollEdgeAppearance = edge
        }
        for v in view.subviews { refresh(v, standard: standard, edge: edge) }
    }

    /// SwiftUI yazı boyutu → UIKit karşılığı (erişilebilirlik boyutları uygulamanın sınırında, xxxLarge)
    private static func category(_ size: DynamicTypeSize) -> UIContentSizeCategory {
        switch size {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        default: .extraExtraExtraLarge
        }
    }
}
