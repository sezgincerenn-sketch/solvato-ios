// Uygulamanın kök görünümü: o anki ekran (AppModel.nav), sekme ekranlarında alt menü. Web App.tsx renderScreen.
// Henüz yazılmamış ekranlar (0.5–0.7) eklendikçe buraya bağlanır. Şimdilik yalnız UI test senaryolarında açılır;
// normal açılış tasarım sistemi ekranı (soru turu gelince kök bu olur).
import SolvatoCore
import SwiftUI

struct AppRoot: View {
    let model: AppModel

    var body: some View {
        let v = model.nav.current
        VStack(spacing: 0) {
            Group {
                switch v {
                case .home: HomeScreen(model: model)
                case .quiz:
                    QuizScreen(
                        model: model, questions: model.sessionQuestions, noHints: model.game != nil,
                        timerSeconds: model.settings.timer && model.game == nil ? AppModel.timerSeconds : nil
                    )
                    .id(model.quizToken)
                default:
                    // Ekran henüz yok: geri dönülebilsin
                    VStack(spacing: Space.s4) {
                        ScreenHeader(title: v.rawValue) { model.back() }
                        Spacer()
                    }
                }
            }
            .frame(maxHeight: .infinity)
            if v.isTab {
                NavBar(active: NavTab(rawValue: v.rawValue) ?? .home) { model.go(AppView(rawValue: $0.rawValue) ?? .home) }
            }
        }
        // iPad: içerik ortada, en geniş 1100 pt (G-03)
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity)
        .background(ThemeColor.bg.color.ignoresSafeArea())
    }
}
