// UIKit penceresi açmak için en üstteki ekran (paylaşım menüsü, e-posta penceresi). Kullananlar: ShareTextLink, MailSupport.
import UIKit

@MainActor
enum Presenter {
    /// Öndeki pencerenin en üstte açık ekranı; `from` verilirse onun penceresi
    static func top(from view: UIView? = nil) -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        guard let window = view?.window ?? scene?.keyWindow ?? scene?.windows.first, var top = window.rootViewController
        else { return nil }
        while let p = top.presentedViewController { top = p }
        return top
    }
}
