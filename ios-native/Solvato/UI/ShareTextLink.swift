// Metin paylaşma düğmesi: sistemin paylaşım menüsünü açar; içerik yalnız düz metin olarak verilir. SwiftUI ShareLink
// metindeki App Store bağlantısını ayrıca bağlantı olarak da sunuyordu; WhatsApp'ta menüden kişi seçilince yalnız
// bağlantı gidiyordu (kullanici-testi-revize.md madde 12). Kullanıldığı yer: AppButton (share:), Profil ve İlerleme'deki
// haftalık rapor. Uygulama kendisi bir şey göndermez; seçilen uygulama gönderir.
import LinkPresentation
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
        guard let view = anchor.view, let window = view.window, var top = window.rootViewController else { return }
        while let p = top.presentedViewController { top = p }
        let sheet = UIActivityViewController(activityItems: [PlainTextShareItem(text: text)], applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = view.bounds
        top.present(sheet, animated: true)
    }
}

/// Paylaşılan içerik: her uygulamaya tek parça düz metin (kod, açıklama ve bağlantı birlikte)
private final class PlainTextShareItem: NSObject, UIActivityItemSource {
    let text: String
    init(text: String) { self.text = text }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any { text }

    func activityViewController(_ controller: UIActivityViewController, itemForActivityType type: UIActivity.ActivityType?) -> Any? { text }

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
