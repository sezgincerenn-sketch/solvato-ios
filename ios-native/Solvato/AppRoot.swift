// Uygulamanın kök görünümü: alt menü Apple'ın sekme çubuğu (UI/SystemTabs), her sekme Apple'ın gezinme yığını
// (NavigationStack; büyük başlık, "‹ Profil" geri düğmesi, kenardan kaydırarak geri; gezinme-cubugu.md). Yol
// AppModel.nav'dan gelir (ScreenStack.navPath); sistemin geri düğmesi ya da hareketi AppModel.back'i çağırır.
// Turlar (soru, akor, Ritmi Tut) ve tur sonucu sekmelerin üstünde tam ekran katman: sol kenardan (28 pt) sağa
// kaydırınca katman parmakla kayar, altında turdan önceki ekran görünür (web utils/swipeBack.tsx, R34); cevap
// verilmişse bırakınca yerine döner ve "Turdan çıkılsın mı?" onayı açılır, cevap yoksa geri dönülür.
// Üstte kutlama, tanıtım, açılış ve Ana sayfa ipuçları. Telefonda yalnız soru ve akor turu yan döner (G-02).
import SolvatoCore
import SwiftUI

struct AppRoot: View {
    let model: AppModel
    @State private var dragX: Double = 0
    /// Tam ekran katman parmakla kaydırılıyor
    @State private var sliding = false
    @State private var coach = 0
    /// Açık sekmenin gezinme yolu (AppModel.nav'dan eşitlenir)
    @State private var path: [AppView] = []
    /// İpucu hedeflerinin ekran konumları: Ana sayfa (gezinme yığınının içi) ve alt menü
    @State private var homeTargets: [String: CGRect] = [:]
    @State private var tabTargets: [String: CGRect] = [:]
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase

    static let edge = 28.0

    var body: some View {
        let v = model.nav.current
        GeometryReader { geo in
            let w = geo.size.width
            let p = min(1, max(0, dragX / max(w, 1)))
            ZStack {
                // Sekmeler ve gezinme yığını; tam ekran katman açıkken altta durur (kaydırınca görünür)
                tabs
                    .offset(x: v.isFullScreen && sliding ? -0.3 * w * (1 - p) : 0)
                    .overlay {
                        if v.isFullScreen && sliding {
                            PaletteColor.black.color.opacity(0.35 * (1 - p)).ignoresSafeArea().allowsHitTesting(false)
                        }
                    }
                    .allowsHitTesting(!v.isFullScreen)
                    .accessibilityHidden(v.isFullScreen)
                    // Tur açıkken (kaydırılmıyorsa) görünmez: VoiceOver ve erişilebilirlik denetimi alttakini okumasın
                    .opacity(v.isFullScreen && !sliding ? 0 : 1)
                if v.isFullScreen {
                    screen(v)
                        .frame(maxHeight: .infinity)
                        .background(ThemeColor.bg.color.ignoresSafeArea())
                        .offset(x: dragX)
                        .shadow(color: dragX > 0 ? .black.opacity(0.25) : .clear, radius: 12, x: -8)
                        // VoiceOver altta kalan sekmeleri okumasın (sekmeler UIKit'te: gizleme tek başına yetmiyor)
                        .accessibilityElement(children: .contain)
                        .accessibilityAddTraits(.isModal)
                }
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
            // Yalnız tam ekran katmanda; alt ekranlarda Apple'ın geri hareketi
            .simultaneousGesture(edgeSwipe(width: w), including: v.isFullScreen ? .all : .subviews)
            // Ana sayfa ipuçları: hedeflerin ekran konumları bu katmanın koordinatına çevrilir
            .overlay {
                if showCoach {
                    GeometryReader { g in
                        let o = g.frame(in: .global).origin
                        let target = CoachStep.home[coach].target
                        CoachmarkView(
                            steps: CoachStep.home, index: coach,
                            rect: (homeTargets[target] ?? tabTargets[target]).map { $0.offsetBy(dx: -o.x, dy: -o.y) },
                            onNext: { withAnimation(.easeOut(duration: 0.2)) { coach += 1 } },
                            onDone: {
                                model.settings.coachDone = true
                                coach = 0
                            })
                    }
                }
            }
        }
        // iPad: içerik ortada, en geniş 1100 pt (G-03)
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity)
        .background(ThemeColor.bg.color.ignoresSafeArea())
        .onChange(of: v, initial: true) { _, nv in Orientation.allowLandscape(nv.allowsLandscape) }
        // Toplam çalışma süresi: turlarda, oyunlarda ve derslerde, uygulama öndeyken sayılır
        .onChange(of: v, initial: true) { _, _ in model.updateStudyClock(active: scenePhase == .active, now: Date().timeIntervalSince1970) }
        .onChange(of: scenePhase) { _, p in model.updateStudyClock(active: p == .active, now: Date().timeIntervalSince1970) }
        // Gezinme yolu: ileri / geri / sekme değişince yığın eşitlenir. Tam ekran katmanın altında (tura girerken,
        // turdan oyun sonucuna geçerken) geçiş canlandırılmaz.
        .onChange(of: model.nav, initial: true) { old, new in
            if old.rootTab != new.rootTab {
                // Başka sekmeye geçildi: sayfa en üstten açılır (web'de sekme yeniden kurulur)
                NotificationCenter.default.post(name: .scrollToTop, object: new.rootTab.rawValue, userInfo: ["animated": false])
            }
            let target = new.navPath
            guard target != path else { return }
            if old.current.isFullScreen || new.current.isFullScreen {
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) { path = target }
            } else {
                path = target
            }
        }
        .onChange(of: typeSize) { _, s in NavigationBarStyle.apply(s) }
        // Ayarlar › Ses / Titreşim (G-07, G-08): kapalıysa hiçbir ses ya da titreşim yok
        .onChange(of: model.settings.soundKeys, initial: true) { _, on in Sound.enabled = on }
        .onChange(of: model.settings.haptics, initial: true) { _, on in Haptics.enabled = on }
        // Tur bitti: kutlama yoksa üç notalık melodi (kutlamanın kendi sesi CelebrationView'da)
        .onChange(of: model.roundsCompleted) { _, _ in if model.celebrate == nil { Sound.play(Sounds.sessionDone) } }
        // Açık sekmeye tekrar dokunuldu: o sayfanın kaydırma alanı en üste kayar (UI/ScrollMemoryProbe)
        .onChange(of: model.scrollTopRequest) { _, _ in NotificationCenter.default.post(name: .scrollToTop, object: model.nav.current.rawValue) }
    }

    // MARK: Sekmeler ve gezinme yığını
    /// Dört sekme; her biri Apple'ın gezinme yığını. Yalnız açık sekmenin yolu dolu (başka sekmeye geçmek yığını sıfırlar).
    private var tabs: some View {
        let root = model.nav.rootTab
        return SystemTabs(
            active: NavTab(rawValue: root.rawValue) ?? .home,
            onSelect: {
                if $0.rawValue != model.nav.current.rawValue { Perf.beginTab() }
                model.selectTab(AppView(rawValue: $0.rawValue) ?? .home)
            }
        ) { t in
            let tab = AppView(rawValue: t.rawValue) ?? .home
            NavigationStack(path: tab == root ? pathBinding : .constant([])) {
                // Sekmeler yeniden kurulmaz (kimlik değişince iPhone'da sekme çubuğu yanlış sekmeyi seçiyordu); sekmeye
                // geçince sayfa en üste kayar (aşağıda) ve ekranlar kendi durumlarını sıfırlar (web gibi)
                tabRoot(tab)
                    .navigationTitle(tab.title)
                    .navigationDestination(for: AppView.self) { d in
                        screen(d)
                            .frame(maxHeight: .infinity)
                            .background(ThemeColor.bg.color.ignoresSafeArea())
                            .navigationTitle(title(d))
                            .navigationBarTitleDisplayMode(.inline)
                            // Alt ekranlar tam ekran: alt menü görünmez (gezinme.md)
                            .toolbar(.hidden, for: .tabBar)
                    }
            }
        }
        .coachFrames(active: showCoach) { tabTargets = $0 }
    }

    /// Sistemin geri düğmesi ya da kenardan kaydırma yolu kısalttı: her kalkan ekran için bir geri
    private var pathBinding: Binding<[AppView]> {
        Binding(
            get: { path },
            set: { new in
                let removed = path.count - new.count
                path = new
                if removed > 0 { for _ in 0..<removed { model.back() } }
            })
    }

    /// Sekmenin kök ekranı: İlerleme, Öğren, Profil büyük başlıklı; Ana sayfa çubuksuz (kendi üst satırı var)
    @ViewBuilder
    private func tabRoot(_ t: AppView) -> some View {
        Group {
            if t == .home {
                HomeScreen(model: model, coachTarget: showCoach ? CoachStep.home[coach].target : nil)
                    .onAppear { Perf.endTab() }
                    .coachFrames(active: showCoach) { homeTargets = $0 }
                    // Başlık görünmez ama alt ekranların geri düğmesi "‹ Ana sayfa" der
                    .toolbar(.hidden, for: .navigationBar)
            } else {
                screen(t).navigationBarTitleDisplayMode(.large)
            }
        }
        .frame(maxHeight: .infinity)
        .background(ThemeColor.bg.color.ignoresSafeArea())
    }

    /// Gezinme çubuğundaki başlık: ders ve öğretmen kodu içeriğe göre
    private func title(_ v: AppView) -> String {
        switch v {
        case .lesson: Lessons.byId(model.lessonId)?.title ?? v.title
        case .teacher: TeacherSection(model.settings.teacherRole).title
        default: v.title
        }
    }

    /// Ana sayfa ipuçları: Pratik'te, açılış/tanıtım/kutlama kapalıyken, bir kez (settings.coachDone)
    private var showCoach: Bool {
        model.nav.current == .home && !model.showSplash && !model.showOnboarding && model.celebrate == nil && !model.settings.coachDone
    }

    @ViewBuilder
    private func screen(_ v: AppView) -> some View {
        switch v {
        case .home: HomeScreen(model: model)
        case .quiz:
            QuizScreen(
                model: model, questions: model.sessionQuestions, noHints: model.game != nil,
                timerSeconds: model.settings.timer && model.game == nil ? AppModel.timerSeconds : nil
            )
            .id(model.quizToken)
            .dynamicTypeSize(AppTypeSize.round)
        case .dashboard: ProgressScreen(model: model).onAppear { Perf.endTab() }
        case .profile: TabletColumn { ProfileScreen(model: model) }
        case .settings: TabletColumn { SettingsScreen(model: model) }
        case .notes: TabletColumn { NotesSettingsScreen(model: model) }
        case .chordquiz: ChordQuizScreen(model: model).id(model.quizToken).dynamicTypeSize(AppTypeSize.round)
        case .result: TabletColumn { ResultScreen(model: model) }
        case .study: TabletColumn(width: 820) { StudyScreen(model: model) }
        case .lesson: TabletColumn(width: 820) { LessonScreen(model: model) }
        case .games: TabletColumn { GamesListScreen(model: model) }
        case .gameDaily: TabletColumn { DailyGameScreen(model: model) }
        case .gameChallenge: TabletColumn { ChallengeGameScreen(model: model) }
        case .gameresult: TabletColumn { GameResultScreen(model: model) }
        case .duel: ChordDuelScreen(model: model).dynamicTypeSize(AppTypeSize.round)
        case .rhythmtap: TabletColumn(width: 680) { RhythmTapScreen(model: model).id(model.quizToken) }.dynamicTypeSize(AppTypeSize.round)
        case .teacher: TabletColumn { TeacherScreen(model: model) }
        case .privacy: TabletColumn { LegalScreen(model: model, page: .privacy) }
        case .licenses: TabletColumn { LegalScreen(model: model, page: .licenses) }
        case .help: TabletColumn { HelpScreen(model: model) }
        }
    }

    // MARK: Kenardan kaydırma (tam ekran katman)
    /// Turlarda ve tur sonucunda kenardan kaydırma katmanı kaydırır mı: sonuçta geri götürür, turlarda çıkış onayı
    /// sorar (R34). Alt ekranlarda Apple'ın kendi geri hareketi çalışır.
    private var swipeSlides: Bool {
        model.nav.canSwipeBack(overlayOpen: model.overlayOpen) || model.nav.current.confirmsExit && !model.overlayOpen
    }

    private func edgeSwipe(width w: Double) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { g in
                guard g.startLocation.x <= Self.edge else { return }
                let dx = g.translation.width
                let dy = abs(g.translation.height)
                if !sliding {
                    // Dikey hareket önce geldiyse kaydırma değil
                    if dy > 14 && dy > dx { return }
                    guard dx > 10, swipeSlides else { return }
                    sliding = true
                }
                dragX = max(0, dx)
            }
            .onEnded { g in
                guard g.startLocation.x <= Self.edge, sliding else { return }
                let dx = g.translation.width
                let fast = g.predictedEndTranslation.width - dx > 120 && dx > 40
                let passed = dx > w * 0.35 || fast
                let settle = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.22)
                if model.nav.current.confirmsExit && model.roundHasAnswers {
                    // Turda cevap var: ekran yerine döner; eşik geçildiyse çıkış onayı (onay açıksa kapanır)
                    withAnimation(settle) { dragX = 0 } completion: { sliding = false }
                    if passed { model.requestExit() }
                } else if passed {
                    // Tur sonucu ya da henüz cevapsız tur: sormadan geri (tur-ekranlari.md)
                    withAnimation(settle) { dragX = w } completion: {
                        model.back()
                        sliding = false
                        dragX = 0
                    }
                } else {
                    withAnimation(settle) { dragX = 0 } completion: { sliding = false }
                }
            }
    }
}
