// İlk açılış tanıtımı (docs/ozellikler/tanitim.md, kullanici-testi-revize.md madde 2): giriş ve ad → iki canlı deneme
// (Do, Sol; doğru tuştan 1 sn sonra kendiliğinden ilerler) → öğretmen sorusu → Ayarların (anahtar, seviye, günlük hedef,
// hatırlatma tek ekranda) → hazırsın. Üstte geri oku (ikinci adımdan itibaren), adım noktaları ve "Atla". "Ben öğretmenim"
// seçilirse sorudan sonra biter ve öğretmen kodu ekranı açılır. Adım sırası ve giriş metinleri SolvatoCore OnboardingFlow'da.
import SolvatoCore
import SwiftUI
import UIKit

struct OnboardingScreen: View {
    let model: AppModel
    /// Tanıtım bitti; true ise öğretmen kodu ekranı açılsın (öğretmen yolu)
    let onDone: (_ openTeacher: Bool) -> Void

    @State private var step = OnboardingStep.intro
    @State private var level = 0
    @State private var goal = 10
    @State private var remind = true
    @State private var hour = 19
    @State private var minute = 0
    @State private var name = ""
    @State private var clef = ClefChoice.treble
    @State private var role: TeacherRole

    init(model: AppModel, onDone: @escaping (_ openTeacher: Bool) -> Void) {
        self.model = model
        self.onDone = onDone
        _role = State(initialValue: OnboardingFlow.initialRole(model.settings))
    }

    private static let levels: [(label: String, sub: String, level: Int)] = [
        ("Yeni başladım", "Temel notalar, ritim ve işaretler", 1),
        ("Bir süredir çalıyorum", "Tüm notalar, diyez/bemol, ek çizgiler", 2),
        ("Uzun süredir çalıyorum", "Tüm sorular, ileri ritim ve terimler", 3),
    ]
    /// Giriş adımındaki simgeli listenin simgeleri ve renkleri (adlar OnboardingFlow.features)
    private static let featureGlyphs: [(glyph: String, color: PaletteColor)] = [
        ("𝄞", .blue400), ("♩", .amber400), ("♬", .green400), ("◉", .pink400),
    ]
    private static let clefs: [(key: ClefChoice, label: String)] = [(.treble, "Sol"), (.bass, "Fa"), (.both, "İkisi de")]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func go(_ s: OnboardingStep) {
        if reduceMotion { step = s } else { withAnimation(.easeOut(duration: 0.2)) { step = s } }
    }

    /// Sonraki adım; öğretmen yolunda sorudan sonra tanıtım biter
    private func next() {
        if let n = OnboardingFlow.next(after: step, role: role) { go(n) } else { onDone(role == .teacher) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                // Geri (R28): ilk adımda görünmez ama yeri boş kalır, noktalar kaymaz
                let showsBack = OnboardingFlow.showsBack(step)
                BackButton { go(OnboardingFlow.back(from: step)) }
                    .opacity(showsBack ? 1 : 0)
                    .disabled(!showsBack)
                    .accessibilityHidden(!showsBack)
                Spacer(minLength: 8)
                HStack(spacing: 6) {
                    ForEach(OnboardingStep.allCases, id: \.self) { k in
                        Capsule()
                            .fill(k.rawValue <= step.rawValue ? PaletteColor.violet500.color : ThemeColor.fillStronger.color)
                            .frame(width: k == step ? 18 : 6, height: 6)
                    }
                }
                .accessibilityHidden(true)
                Spacer(minLength: 8)
                if step != .done {
                    Button("Atla") { onDone(false) }
                        .font(.ui(FontSize.md))
                        .foregroundStyle(ThemeColor.textMuted.color)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
                } else {
                    Color.clear.frame(width: 44, height: 1)
                }
            }
            .frame(minHeight: 44)
            .padding(.bottom, 6)
            content.frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: Metrics.tabletColumn)
        .frame(maxWidth: .infinity)
        .background(ThemeColor.bg.color.ignoresSafeArea())
        // Kap adlı bir grup; içindeki düğmeler ayrı ayrı erişilebilir kalır
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel("Hoş geldin")
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .intro:
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Logo(size: 48)
                        Text(OnboardingFlow.introTitle)
                            .font(.ui(FontSize.xxl, .heavy))
                            .tracking(em: -0.03, size: FontSize.xxl)
                            .foregroundStyle(ThemeColor.text.color)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        Text("Solfado, piyano öğrencileri için kısa pratik turları: nota, ritim, akor ve kulak. Ne kadar ilerlediğini de gösterir.")
                            .font(.ui(FontSize.md))
                            .foregroundStyle(ThemeColor.textSoft.color)
                            .lineHeight(1.5, size: FontSize.md)
                            .fixedSize(horizontal: false, vertical: true)
                        // Basılacakmış gibi görünmeyen düz liste: çerçeve, zemin ve gölge yok; VoiceOver tek öğe
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(OnboardingFlow.features.enumerated()), id: \.offset) { i, label in
                                HStack(spacing: 12) {
                                    Text(verbatim: Self.featureGlyphs[i].glyph)
                                        .font(.ui(FontSize.lg))
                                        .foregroundStyle(Self.featureGlyphs[i].color.color)
                                        .frame(width: 24)
                                    Text(label).font(.ui(FontSize.md, .semibold)).foregroundStyle(ThemeColor.text.color)
                                }
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(OnboardingFlow.featuresLabel)
                        TextField("", text: $name, prompt: Text("Adın (isteğe bağlı)").foregroundStyle(ThemeColor.textFaint.color))
                            .font(.ui(FontSize.md))
                            .foregroundStyle(ThemeColor.text.color)
                            .textContentType(.givenName)
                            .submitLabel(.done)
                            .onChange(of: name) { _, v in if v.count > 24 { name = String(v.prefix(24)) } }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.fillStrong.color))
                            .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.borderStrong.color, lineWidth: 1))
                            .padding(.top, 6)
                            .accessibilityLabel("Adın (isteğe bağlı)")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
                    .padding(.bottom, 18)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
                primary("Başla") {
                    model.settings.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    next()
                }
            }
        case .teacher:
            VStack(alignment: .leading, spacing: 12) {
                title("Bir öğretmenle mi çalışıyorsun?").padding(.bottom, 6)
                ForEach(OnboardingFlow.roles, id: \.title) { r in
                    ChoiceCard(selected: role == r.role, title: r.title, sub: r.sub, action: { role = r.role }) { EmptyView() }
                }
                Spacer()
                primary("Devam") {
                    // Geri dönüp değiştirilirse son "Devam"daki seçim geçerli
                    model.settings.teacherRole = role
                    next()
                }
            }
        case .try1:
            TryStep(
                note: "Do", noteY: 90, ledger: [90], title: "Bu nota Do. Tuşunu bul.",
                helpWrong: "Do, iki siyah tuşlu grubun solundaki beyaz tuştur. Bir daha dene.", onPass: next
            )
            .id("t1")
        case .try2:
            TryStep(
                note: "Sol", noteY: 70, ledger: [], title: "Şimdi sen bul: bu hangi nota?",
                helpWrong: "Sol anahtarının sarmal ortası ikinci çizgiyi sarar: bu çizgi Sol notasıdır. Tekrar dene.", onPass: next
            )
            .id("t2")
        case .setup:
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        title("Ayarların")
                        bodyText("Hepsini sonra Ayarlar'dan değiştirebilirsin.")
                        sectionTitle("Hangi anahtarı okuyorsun?")
                        Segmented(value: clef, options: Self.clefs.map { ($0.key, $0.label) }) { clef = $0 }
                        sectionTitle("Piyanoda neredesin?")
                        ForEach(Array(Self.levels.enumerated()), id: \.offset) { k, l in
                            ChoiceCard(selected: level == k, title: l.label, sub: l.sub, action: { level = k }) { EmptyView() }
                        }
                        sectionTitle("Günlük hedefin")
                        Segmented(value: goal, options: [10, 20, 30].map { ($0, "\($0) soru") }) { goal = $0 }
                        sectionTitle("Hatırlatma")
                        AppCard(padding: 0) {
                            VStack(spacing: 0) {
                                ToggleRow(title: "Günlük hatırlatma", sub: "Her gün aynı saatte bildirim", on: remind) { remind.toggle() }
                                if remind {
                                    SettingsDivider()
                                    TimeRow(title: "Hatırlatma saati", hour: hour, minute: minute) { h, m in
                                        hour = h
                                        minute = m
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    .padding(.bottom, 18)
                }
                .scrollBounceBehavior(.basedOnSize)
                primary("Devam") {
                    model.settings.clef = clef
                    model.settings.level = Self.levels[level].level
                    model.settings.levelProgress = LevelProgress(n: 0, c: 0)
                    model.settings.dailyGoal = goal
                    model.settings.reminderHour = hour
                    model.settings.reminderMinute = minute
                    if remind {
                        let h = hour
                        let m = minute
                        Task { @MainActor in
                            model.settings.reminder = await Reminder.enable(hour: h, minute: m)
                            next()
                        }
                    } else {
                        next()
                    }
                }
            }
        case .done:
            VStack(spacing: 0) {
                Spacer()
                SolfieSays(text: "Her gün birlikte çalışalım!", size: 104, pose: .cheer).padding(.bottom, 22)
                title("Hazırsın").padding(.bottom, 12)
                Text(verbatim: "Günde \(goal) soru yeter. Doğru cevapladıkça yeni sorular açılır.")
                    .font(.ui(FontSize.md))
                    .lineHeight(1.55, size: FontSize.md)
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                Spacer()
                primary("Başlayalım") { onDone(false) }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func title(_ s: String) -> some View {
        Text(s).font(.ui(FontSize.xl, .heavy)).tracking(em: -0.03, size: FontSize.xl).foregroundStyle(ThemeColor.text.color)
            .accessibilityAddTraits(.isHeader)
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color).padding(.top, 10)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private func bodyText(_ s: String) -> some View {
        Text(s).font(.ui(FontSize.md)).foregroundStyle(ThemeColor.textMuted.color).lineHeight(1.5, size: FontSize.md).fixedSize(horizontal: false, vertical: true)
    }
}

/// Mor ana düğme (tanıtım ve deneme adımları)
@MainActor
private func primary(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title)
            .font(.ui(FontSize.md, .bold))
            .foregroundStyle(PaletteColor.violet100.color)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(CSSLinearGradient(.primaryFlat).clipShape(RoundedRectangle(cornerRadius: Radius.lg)))
            .shadow(color: PaletteColor.violet600.opacity(0.45), radius: 10, y: 4)
    }
    .buttonStyle(.plain)
}

/// Canlı deneme: gerçek porte, gerçek klavye; doğru tuşu bulunca 1 sn sonra kendiliğinden sonraki adıma geçer. Yanlış
/// tuşun uyarısı ekranda kalır, yalnız yeni bir tuşa basınca değişir.
private struct TryStep: View {
    /// Web 21vh (en çok 190): vh tam ekran yüksekliği
    static var screenHeight: Double {
        // Pencerenin yüksekliği (iPad'de Split View / Stage Manager); telefonda ekranla aynı
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return Double(scene?.keyWindow?.bounds.height ?? scene?.screen.bounds.height ?? 844)
    }

    let note: String
    let noteY: Int
    let ledger: [Int]
    let title: String
    let helpWrong: String
    let onPass: () -> Void
    @State private var state = AnswerState.pending
    @State private var picked: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.ui(FontSize.xl, .heavy)).tracking(em: -0.03, size: FontSize.xl).foregroundStyle(ThemeColor.text.color)
            MusicalStaffView(clef: .treble, noteY: noteY, ledgerLines: ledger, label: AccessibilityText.noteStaff(.treble))
                .frame(maxWidth: .infinity, minHeight: 170)
                .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.fill.color))
                .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            Group {
                switch state {
                case .correct: Text("Doğru! Bu nota \(note).").font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.greenText.color)
                case .wrong: Text(helpWrong).font(.ui(FontSize.md)).foregroundStyle(ThemeColor.redText.color).lineHeight(1.45, size: FontSize.md)
                case .pending: Text("Piyano tuşlarından birine dokun.").font(.ui(FontSize.md)).foregroundStyle(ThemeColor.textMuted.color).lineHeight(1.45, size: FontSize.md)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 48, alignment: .topLeading)
            Spacer(minLength: 0)
            QuizPianoView(
                keys: Piano.quizKeys(answerState: state.rawValue, selectedNote: picked, showLabels: true),
                height: Piano.quizHeight(screenHeight: Self.screenHeight, tall: false),
                // Doğru bulununca klavye kapanır; yanlıştan sonra hemen yeni tuşa basılabilir
                disabled: state == .correct
            ) { key in answer(key.answer) }
        }
        // Doğrudan 1 sn sonra kendiliğinden sonraki adım; adımdan çıkılırsa (geri, atla) görev iptal olur
        .task(id: state) {
            guard state == .correct else { return }
            do {
                try await Task.sleep(for: .seconds(OnboardingFlow.autoAdvanceDelay))
                onPass()
            } catch {}
        }
    }

    private func answer(_ n: String) {
        guard state != .correct else { return }
        picked = n
        if n == note {
            state = .correct
            Sound.play(Sounds.correctChime)
            Haptics.success()
        } else {
            state = .wrong
            Sound.play(Sounds.wrongBuzz)
            Haptics.error()
        }
    }
}
