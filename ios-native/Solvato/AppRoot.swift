// Uygulamanın kök görünümü: o anki ekran (AppModel.nav), sekme ekranlarında Apple'ın sekme çubuğu (UI/SystemTabs),
// kutlama, tanıtım, açılış.
// Web App.tsx renderScreen + utils/swipeBack.tsx: sol kenardan (28 pt) sağa kaydırınca ekran parmakla kayar, altında
// önceki ekran görünür; %35'i geçince ya da hızlı bırakınca geri dönülür. Turlarda da ekran aynı biçimde kayar (R34);
// cevap verilmişse bırakınca ekran yerine döner ve "Turdan çıkılsın mı?" onayı açılır, cevap yoksa geri dönülür. Telefonda yalnız soru ve akor turu yan döner (G-02).
// Hazır ekranlar: Pratik, soru turu, tur sonucu. Diğerleri 0.5–0.7'de; yerlerinde başlık ve kısa not.
import SolvatoCore
import SwiftUI

struct AppRoot: View {
    let model: AppModel
    @State private var dragX: Double = 0
    @State private var underlay: AppView?
    @State private var coach = 0

    static let edge = 28.0

    var body: some View {
        let v = model.nav.current
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // Kaydırırken alttan görünen önceki ekran
                if let u = underlay {
                    let p = min(1, max(0, dragX / max(w, 1)))
                    screenWithNav(u)
                        .allowsHitTesting(false)
                        .offset(x: -0.3 * w * (1 - p))
                        .overlay(PaletteColor.black.color.opacity(0.35 * (1 - p)).ignoresSafeArea().allowsHitTesting(false))
                }
                screenWithNav(v)
                    .background(ThemeColor.bg.color.ignoresSafeArea())
                    .offset(x: dragX)
                    .shadow(color: dragX > 0 ? .black.opacity(0.25) : .clear, radius: 12, x: -8)
                if let c = model.celebrate {
                    CelebrationView(data: c) { model.celebrate = nil }
                }
                if model.showOnboarding && !model.showSplash {
                    OnboardingScreen(model: model) { model.finishOnboarding(openTeacher: $0) }.zIndex(5)
                }
                if model.showSplash {
                    SplashScreen { model.showSplash = false }.zIndex(10)
                }
            }
            // Ana sayfa ipuçları: hedeflerin konumu ekranlardan toplanır
            .overlayPreferenceValue(CoachTargets.self) { anchors in
                if showCoach {
                    GeometryReader { p in
                        CoachmarkView(
                            steps: CoachStep.home, index: coach,
                            rect: anchors[CoachStep.home[coach].target].map { p[$0] },
                            onNext: { withAnimation(.easeOut(duration: 0.2)) { coach += 1 } },
                            onDone: {
                                model.settings.coachDone = true
                                coach = 0
                            })
                    }
                }
            }
            .simultaneousGesture(edgeSwipe(width: w))
        }
        // iPad: içerik ortada, en geniş 1100 pt (G-03)
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity)
        .background(ThemeColor.bg.color.ignoresSafeArea())
        .onChange(of: v, initial: true) { _, nv in Orientation.allowLandscape(nv.allowsLandscape) }
        // Ayarlar › Ses / Titreşim (G-07, G-08): kapalıysa hiçbir ses ya da titreşim yok
        .onChange(of: model.settings.soundKeys, initial: true) { _, on in Sound.enabled = on }
        .onChange(of: model.settings.haptics, initial: true) { _, on in Haptics.enabled = on }
        // Tur bitti: kutlama yoksa üç notalık melodi (kutlamanın kendi sesi CelebrationView'da)
        .onChange(of: model.roundsCompleted) { _, _ in if model.celebrate == nil { Sound.play(Sounds.sessionDone) } }
        // Açık sekmeye tekrar dokunuldu: o sayfanın kaydırma alanı en üste kayar (UI/ScrollMemoryProbe)
        .onChange(of: model.scrollTopRequest) { _, _ in NotificationCenter.default.post(name: .scrollToTop, object: model.nav.current.rawValue) }
    }

    /// Sekme ekranları Apple'ın sekme çubuğunun içinde (UI/SystemTabs); alt ekranlar ve turlar çubuksuz, tam ekran
    @ViewBuilder
    private func screenWithNav(_ v: AppView) -> some View {
        if v.isTab {
            SystemTabs(active: NavTab(rawValue: v.rawValue) ?? .home, onSelect: { model.selectTab(AppView(rawValue: $0.rawValue) ?? .home) }) { t in
                screen(AppView(rawValue: t.rawValue) ?? .home).frame(maxHeight: .infinity)
            }
        } else {
            screen(v).frame(maxHeight: .infinity)
        }
    }

    /// Ana sayfa ipuçları: Pratik'te, açılış/tanıtım/kutlama kapalıyken, bir kez (settings.coachDone)
    private var showCoach: Bool {
        model.nav.current == .home && !model.showSplash && !model.showOnboarding && model.celebrate == nil && !model.settings.coachDone
    }

    @ViewBuilder
    private func screen(_ v: AppView) -> some View {
        switch v {
        case .home: HomeScreen(model: model, coachTarget: showCoach ? CoachStep.home[coach].target : nil)
        case .quiz:
            QuizScreen(
                model: model, questions: model.sessionQuestions, noHints: model.game != nil,
                timerSeconds: model.settings.timer && model.game == nil ? AppModel.timerSeconds : nil
            )
            .id(model.quizToken)
        case .dashboard: ProgressScreen(model: model)
        case .profile: TabletColumn { ProfileScreen(model: model) }
        case .settings: TabletColumn { SettingsScreen(model: model) }
        case .notes: TabletColumn { NotesSettingsScreen(model: model) }
        case .chordquiz: ChordQuizScreen(model: model).id(model.quizToken)
        case .result: TabletColumn { ResultScreen(model: model) }
        case .study: TabletColumn(width: 820) { StudyScreen(model: model) }
        case .lesson: TabletColumn(width: 820) { LessonScreen(model: model) }
        case .games: TabletColumn { GamesListScreen(model: model) }
        case .gameDaily: TabletColumn { DailyGameScreen(model: model) }
        case .gameChallenge: TabletColumn { ChallengeGameScreen(model: model) }
        case .gameresult: TabletColumn { GameResultScreen(model: model) }
        case .duel: ChordDuelScreen(model: model)
        case .rhythmtap: TabletColumn(width: 680) { RhythmTapScreen(model: model).id(model.quizToken) }
        case .teacher: TabletColumn { TeacherScreen(model: model) }
        case .privacy: TabletColumn { LegalScreen(model: model, page: .privacy) }
        case .licenses: TabletColumn { LegalScreen(model: model, page: .licenses) }
        default: PendingScreen(view: v) { v.isTab ? model.go(.home) : model.back() }
        }
    }

    // MARK: Kenardan kaydırma
    /// Bu ekranda kenardan kaydırma ekranı kaydırır mı: alt ekranlarda geri götürür, turlarda çıkış onayı sorar (R34)
    private var swipeSlides: Bool {
        model.nav.canSwipeBack(overlayOpen: model.overlayOpen) || model.nav.current.confirmsExit && !model.overlayOpen
    }

    private func edgeSwipe(width w: Double) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { g in
                guard g.startLocation.x <= Self.edge else { return }
                let dx = g.translation.width
                let dy = abs(g.translation.height)
                if underlay == nil {
                    // Dikey hareket önce geldiyse kaydırma değil
                    if dy > 14 && dy > dx { return }
                    guard dx > 10, swipeSlides else { return }
                    underlay = model.nav.backTarget
                }
                dragX = max(0, dx)
            }
            .onEnded { g in
                guard g.startLocation.x <= Self.edge, underlay != nil else { return }
                let dx = g.translation.width
                let fast = g.predictedEndTranslation.width - dx > 120 && dx > 40
                let passed = dx > w * 0.35 || fast
                let settle = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.22)
                if model.nav.current.confirmsExit && model.roundHasAnswers {
                    // Turda cevap var: ekran yerine döner; eşik geçildiyse çıkış onayı (onay açıksa kapanır)
                    withAnimation(settle) { dragX = 0 } completion: { underlay = nil }
                    if passed { model.requestExit() }
                } else if passed {
                    // Alt ekran ya da henüz cevapsız tur: sormadan geri (tur-ekranlari.md)
                    withAnimation(settle) { dragX = w } completion: {
                        model.back()
                        underlay = nil
                        dragX = 0
                    }
                } else {
                    withAnimation(settle) { dragX = 0 } completion: { underlay = nil }
                }
            }
    }
}

/// Native sürümde henüz yazılmamış ekran (yalnız geliştirme sürümlerinde görünür; yayından önce hepsi gelir)
private struct PendingScreen: View {
    let view: AppView
    let onBack: () -> Void

    private var title: String {
        switch view {
        case .dashboard: "İlerleme"
        case .study: "Öğren"
        case .profile: "Profil"
        case .settings: "Ayarlar"
        case .notes: "Çalışılacak notalar"
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
