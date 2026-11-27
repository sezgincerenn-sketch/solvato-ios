// Alt menü: Apple'ın kendi sekme çubuğu (Ceren, 26 Kasım: "orijinal native Liquid Glass gibi"). iOS 26'da gerçek
// Liquid Glass çubuk ve seçili sekmede kayan cam; iOS 17–25'te klasik iPhone sekme çubuğu. Mor vurgu, kaydırınca
// küçülmez (gezinme.md kararı). Açık sekmeye tekrar dokununca sayfa en üste kayar (AppModel.selectTab).
// Kullanıldığı yer: AppRoot (yalnız dört sekme ekranında; alt ekranlarda ve turlarda çubuk yok).
import SolvatoCore
import SwiftUI

struct SystemTabs<Content: View>: View {
    let active: NavTab
    let onSelect: (NavTab) -> Void
    @ViewBuilder let content: (NavTab) -> Content
    /// Sekme çubuğunun seçimi: dokunuş önce burada tamamlanır, uygulamaya bir sonraki turda bildirilir. Sayfa yığını
    /// seçimle aynı anda değişince iPhone'da sekme çubuğu bir önceki sekmeyi seçiyordu (gezinme-cubugu.md).
    @State private var selection: NavTab?

    var body: some View {
        // Aynı sekmeye tekrar dokununca da çağrılır: onSelect açık sekmede "en üste kay" ister
        TabView(
            selection: Binding(
                get: { selection ?? active },
                set: { t in
                    selection = t
                    Task { @MainActor in onSelect(t) }
                })
        ) {
            ForEach(NavTab.allCases, id: \.self) { t in
                // Sekmeye geçince sayfanın yeniden kurulması içerikte (AppRoot, gezinme yığınının içinde): sekmenin
                // kendisi değişirse iPhone'da sekme çubuğu yanlış sekmeyi seçiyor (gezinme-cubugu.md)
                content(t)
                    .tabItem { Label(t.label, systemImage: t.symbol) }
                    .tag(t)
            }
        }
        .tint(ThemeColor.violetText.color)
        .modifier(NeverMinimize())
        // Uygulama sekmeyi kendisi değiştirdi (XP hapı → Profil, turdan sonra): çubuk da oraya geçer
        .onChange(of: active) { _, a in selection = a }
        // Ana sayfa ipuçlarının son adımı çubuğu gösterir: çubuğun yerinde görünmez bir hedef
        .overlay(alignment: .bottom) {
            Color.clear.frame(height: 56).frame(maxWidth: .infinity).coachTarget("nav").allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// iOS 26: kaydırırken çubuk küçülmesin
private struct NeverMinimize: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.never)
        } else {
            content
        }
    }
}
