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

    var body: some View {
        // Aynı sekmeye tekrar dokununca da çağrılır: onSelect açık sekmede "en üste kay" ister
        TabView(selection: Binding(get: { active }, set: { onSelect($0) })) {
            ForEach(NavTab.allCases, id: \.self) { t in
                content(t)
                    .tabItem { Label(t.label, systemImage: t.symbol) }
                    .tag(t)
            }
        }
        .tint(ThemeColor.violetText.color)
        .modifier(NeverMinimize())
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
