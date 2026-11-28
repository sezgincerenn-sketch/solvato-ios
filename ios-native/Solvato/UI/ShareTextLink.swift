// Metin paylaşma düğmesi: sistemin paylaşım menüsünü açar; içerik yalnız düz metin olarak verilir. SwiftUI ShareLink
// metindeki App Store bağlantısını ayrıca bağlantı olarak da sunuyordu; WhatsApp'ta menüden kişi seçilince yalnız
// bağlantı gidiyordu (kullanici-testi-revize.md madde 12). Kullanıldığı yer: AppButton (share:), Profil ve İlerleme'deki
// haftalık rapor. WhatsApp'a bağlantı "https://" olmadan gider (AppStoreLink.forWhatsApp). Uygulama kendisi bir şey
// göndermez; seçilen uygulama gönderir.
import LinkPresentation
import SolvatoCore
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ShareTextLink<Label: View>: View {
    let text: String
    @ViewBuilder let label: Label
    @State private var anchor = ShareAnchor()

    var body: some View {
        Button(action: present) { label }
            // iPad'de menü düğmenin üstünden açılır
            .background(ShareAnchorView(anchor: anchor).allowsHitTesting(false).accessibilityHidden(true))
    }

    private func present() {
        // Gezinme çubuğundaki düğmede (İlerleme'nin sağ üstü) alttaki görünüm pencereye bağlı olmayabilir: o zaman
        // uygulamanın açık penceresi kullanılır, iPad'de menü sağ üstten açılır
        let anchored = anchor.view.flatMap { $0.window != nil ? $0 : nil }
        guard let top = Presenter.top(from: anchored) else { return }
        let sheet = UIActivityViewController(activityItems: [PlainTextShareItem(text: text)], applicationActivities: nil)
        if let popover = sheet.popoverPresentationController {
            if let anchored {
                popover.sourceView = anchored
                popover.sourceRect = anchored.bounds
            } else {
                popover.sourceView = top.view
                popover.sourceRect = CGRect(x: top.view.bounds.maxX - 44, y: top.view.safeAreaInsets.top, width: 1, height: 1)
            }
        }
        top.present(sheet, animated: true)
    }
}

/// Paylaşılan içerik: her uygulamaya tek parça düz metin (kod, açıklama ve bağlantı birlikte)
private final class PlainTextShareItem: NSObject, UIActivityItemSource {
    let text: String
    init(text: String) { self.text = text }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any { text }

    func activityViewController(_ controller: UIActivityViewController, itemForActivityType type: UIActivity.ActivityType?) -> Any? {
        AppStoreLink.isWhatsApp(type?.rawValue) ? AppStoreLink.forWhatsApp(text) : text
    }

    func activityViewController(_ controller: UIActivityViewController, dataTypeIdentifierForActivityType type: UIActivity.ActivityType?) -> String {
        UTType.plainText.identifier
    }

    /// Menünün üstündeki önizleme: metnin ilk satırı (bağlantı önizlemesi oluşturulmaz, ağ isteği yok)
    func activityViewControllerLinkMetadata(_ controller: UIActivityViewController) -> LPLinkMetadata? {
        let m = LPLinkMetadata()
        m.title = text.split(separator: "\n").first.map(String.init) ?? text
        return m
    }
}

/// Düğmenin altındaki UIKit görünümü (paylaşım menüsünün iPad'deki çıkış noktası)
@MainActor
final class ShareAnchor {
    weak var view: UIView?
}

private struct ShareAnchorView: UIViewRepresentable {
    let anchor: ShareAnchor

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        anchor.view = v
        return v
    }

    func updateUIView(_ v: UIView, context: Context) { anchor.view = v }
}
