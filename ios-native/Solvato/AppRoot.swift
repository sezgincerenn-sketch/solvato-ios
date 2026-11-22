// Uygulamanın kök görünümü: o anki ekran (AppModel.nav), sekme ekranlarında alt menü, kutlama penceresi.
// Web App.tsx renderScreen. Hazır ekranlar: Pratik, soru turu, tur sonucu. Diğerleri (İlerleme, Çalışma, Profil,
// Ayarlar, Oyunlar, akor turu, Ritmi Tut …) 0.5–0.7'de gelir; o güne kadar yerlerinde yalnızca başlık ve kısa not var.
import SolvatoCore
import SwiftUI

struct AppRoot: View {
    let model: AppModel

    var body: some View {
        let v = model.nav.current
        ZStack {
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
                    case .result: TabletColumn { ResultScreen(model: model) }
                    default: PendingScreen(view: v) { v.isTab ? model.go(.home) : model.back() }
                    }
                }
                .frame(maxHeight: .infinity)
                if v.isTab {
                    NavBar(active: NavTab(rawValue: v.rawValue) ?? .home) { model.go(AppView(rawValue: $0.rawValue) ?? .home) }
                }
            }
            if let c = model.celebrate {
                CelebrationView(data: c) { model.celebrate = nil }
            }
            if model.showSplash {
                SplashScreen { model.showSplash = false }.zIndex(10)
            }
        }
        // iPad: içerik ortada, en geniş 1100 pt (G-03)
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity)
        .background(ThemeColor.bg.color.ignoresSafeArea())
    }
}

/// Native sürümde henüz yazılmamış ekran (yalnız geliştirme sürümlerinde görünür; yayından önce hepsi gelir)
private struct PendingScreen: View {
    let view: AppView
    let onBack: () -> Void

    private var title: String {
        switch view {
        case .dashboard: "İlerleme"
        case .study: "Çalışma"
        case .profile: "Profil"
        case .settings: "Ayarlar"
        case .games, .gameDaily, .gameChallenge, .gameresult, .duel: "Oyunlar"
        case .chordquiz: "Akor"
        case .rhythmtap: "Ritmi Tut"
        case .lesson: "Ders"
        case .teacher: "Öğretmen kodu"
        case .privacy: "Gizlilik"
        case .licenses: "Lisanslar"
        default: ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            ScreenHeader(title: title, onBack: onBack)
            Text("Bu ekran native sürüme henüz taşınmadı.")
                .font(.ui(FontSize.sm))
                .foregroundStyle(ThemeColor.textMuted.color)
                .padding(.horizontal, Space.s4)
            Spacer()
        }
        .background(ThemeColor.bg.color)
    }
}
