// Kaydırma hafızasının ekran tarafı (G-10, web utils/scrollMemory.ts): kaydırma alanının içeriğine görünmez bir
// görünüm eklenir; o görünüm çevreleyen UIScrollView'u bulur, konumunu AppModel.scroll'a bildirir ve açılışta saklanan
// konumu uygular (içerik ilk karede tam çizilmemiş olabilir, web gibi birkaç kare dener).
// Kullanım: ScrollView { içerik.remembersScroll(model, .profile) }; bir ekranda birden çok alan varsa `slot` ile.
// Alt menüde açık sekmeye tekrar dokununca (`.scrollToTop` bildirimi) o ekranın ilk kaydırma alanı en üste kayar.
import SolvatoCore
import SwiftUI
import UIKit

extension View {
    /// Bu kaydırma alanının konumu, ileri gidip geri dönünce korunur
    func remembersScroll(_ model: AppModel, _ view: AppView, slot: Int = 0) -> some View {
        background(ScrollMemoryProbe(model: model, view: view, slot: slot).allowsHitTesting(false).accessibilityHidden(true))
    }
}

extension Notification.Name {
    /// Alt menüde açık sekmeye tekrar dokunuldu; nesne: ekran adı (AppView.rawValue)
    static let scrollToTop = Notification.Name("solvato.scrollToTop")
}

private struct ScrollMemoryProbe: UIViewRepresentable {
    let model: AppModel
    let view: AppView
    let slot: Int

    func makeUIView(context: Context) -> ProbeView {
        let v = ProbeView()
        v.isUserInteractionEnabled = false
        v.onAttach = { [model, view, slot] sv in
            // Geri dönülen ya da kaydırırken altta görünen ekran: saklanan konuma git
            if let y = model.scroll.restore(view, slot: slot, current: model.nav.current) { ProbeView.apply(y, to: sv, tries: 6) }
        }
        v.onTop = { [model, view, slot] name in
            slot == 0 && model.nav.current == view && name == view.rawValue
        }
        v.onScroll = { [model, view, slot] y in
            // Yalnız görünen ekranın konumu saklanır (altta görünen kopya değil)
            if model.nav.current == view { model.scroll.report(view, slot: slot, y: y) }
        }
        return v
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {}
}

final class ProbeView: UIView {
    var onAttach: ((UIScrollView) -> Void)?
    var onScroll: ((Double) -> Void)?
    /// En üste kaydırma isteği bu kaydırma alanı için mi (bildirimdeki ekran adıyla)
    var onTop: ((String) -> Bool)?
    private var observation: NSKeyValueObservation?
    nonisolated(unsafe) private var topObserver: NSObjectProtocol?
    private weak var scrollView: UIScrollView?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, scrollView == nil else { return }
        var s = superview
        while let v = s, !(v is UIScrollView) { s = v.superview }
        guard let sv = s as? UIScrollView else { return }
        scrollView = sv
        onAttach?(sv)
        observation = sv.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.report() }
        }
        topObserver = NotificationCenter.default.addObserver(forName: .scrollToTop, object: nil, queue: .main) { [weak self] n in
            let name = n.object as? String ?? ""
            MainActor.assumeIsolated {
                guard let self, let sv = self.scrollView, self.window != nil, self.onTop?(name) == true else { return }
                sv.setContentOffset(CGPoint(x: sv.contentOffset.x, y: -sv.adjustedContentInset.top), animated: true)
            }
        }
    }

    deinit {
        if let topObserver { NotificationCenter.default.removeObserver(topObserver) }
    }

    /// Üstten uzaklık (pt; içerik boşluğu düşülür)
    private func report() {
        guard let sv = scrollView else { return }
        onScroll?(Double(sv.contentOffset.y + sv.adjustedContentInset.top))
    }

    /// Konumu uygular; içerik henüz o kadar uzun değilse sonraki karelerde yeniden dener
    static func apply(_ y: Double, to sv: UIScrollView, tries: Int) {
        sv.layoutIfNeeded()
        let maxY = Double(sv.contentSize.height + sv.adjustedContentInset.top + sv.adjustedContentInset.bottom - sv.bounds.height)
        sv.setContentOffset(CGPoint(x: sv.contentOffset.x, y: min(y, max(0, maxY)) - sv.adjustedContentInset.top), animated: false)
        guard maxY < y - 2, tries > 1 else { return }
        DispatchQueue.main.async { [weak sv] in
            guard let sv else { return }
            MainActor.assumeIsolated { apply(y, to: sv, tries: tries - 1) }
        }
    }
}
