// İlk açılış tanıtımı (docs/ozellikler/tanitim.md; web revize src/screens/Onboarding.tsx): giriş → merhaba ve ad → iki
// canlı deneme (Do, Sol) → öğretmen sorusu → anahtar → seviye ve günlük hedef → hatırlatma (saat satırı) → hazırsın.
// Üstte geri oku (ikinci adımdan itibaren), adım noktaları ve "Atla". "Ben öğretmenim" seçilirse sorudan sonra biter ve
// öğretmen kodu ekranı açılır. Adım sırası SolvatoCore OnboardingFlow'da. Metinler web'den harfi harfine.
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
    private static let clefs: [(key: ClefChoice, label: String, sub: String)] = [
        (.treble, "Sol anahtarı", "Genelde sağ el"), (.bass, "Fa anahtarı", "Genelde sol el"), (.both, "İkisi de", "İki elle çalıyorum"),
    ]
    /// Giriş adımındaki dört kutu: simge, ad, simge rengi
    private static let features: [(glyph: String, label: String, color: PaletteColor)] = [
        ("𝄞", "Nota okuma", .blue400), ("♩", "Ritim", .amber400), ("♬", "Akor", .green400), ("◉", "Kulak", .pink400),
    ]

    private func go(_ s: OnboardingStep) { withAnimation(.easeOut(duration: 0.2)) { step = s } }

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
        .frame(maxWidth: 600)
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
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 18) {
                    Logo(size: 48)
                    Text("Her gün birkaç dakika, nota okumak kolaylaşsın")
                        .font(.ui(FontSize.xxl, .heavy))
                        .tracking(em: -0.03, size: FontSize.xxl)
                        .foregroundStyle(ThemeColor.text.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text("Solvato, piyano öğrencileri için kısa pratik turları: nota, ritim, akor ve kulak. Ne kadar ilerlediğini de gösterir.")
                        .font(.ui(FontSize.md))
                        .foregroundStyle(ThemeColor.textSoft.color)
                        .lineHeight(1.5, size: FontSize.md)
                        .fixedSize(horizontal: false, vertical: true)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        ForEach(Self.features, id: \.label) { f in
                            HStack(spacing: 8) {
                                Text(verbatim: f.glyph).font(.ui(FontSize.lg)).foregroundStyle(f.color.color)
                                Text(f.label).font(.ui(FontSize.md, .semibold)).foregroundStyle(ThemeColor.text.color).lineLimit(1)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.fill.color))
                            .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
                            // Kutular tek tek okunur (simge okunmaz)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(f.label)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 18)
                primary("Başlayalım", action: next)
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
        case .hello:
            VStack(spacing: 0) {
                Spacer()
                SolfieSays(text: "Merhaba, ben Solfie!", size: 96, pose: .wave).padding(.bottom, 22)
                title("Hadi bir nota bulalım").padding(.bottom, 12)
                Text("Portedeki notayı görüp piyano tuşunda bulacaksın. Önce iki küçük denemeyle başlıyoruz.")
                    .font(.ui(FontSize.md))
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                TextField("", text: $name, prompt: Text("Adın (isteğe bağlı)").foregroundStyle(ThemeColor.textMuted.color))
                    .font(.ui(FontSize.md))
                    .foregroundStyle(ThemeColor.text.color)
                    .multilineTextAlignment(.center)
                    .textContentType(.givenName)
                    .onChange(of: name) { _, v in if v.count > 24 { name = String(v.prefix(24)) } }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: 300)
                    .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.fillStrong.color))
                    .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.borderStrong.color, lineWidth: 1))
                    .padding(.top, 22)
                    .accessibilityLabel("Adın (isteğe bağlı)")
                Spacer()
                primary("Devam") {
                    model.settings.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    next()
                }
            }
            .frame(maxWidth: .infinity)
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
        case .clef:
            VStack(alignment: .leading, spacing: 12) {
                title("Hangi anahtarı okuyorsun?")
                bodyText("Karışık turlarda bu anahtarın notaları sorulur. Ayarlar'dan değiştirebilirsin.").padding(.bottom, 6)
                ForEach(Self.clefs, id: \.label) { c in
                    ChoiceCard(selected: clef == c.key, title: c.label, sub: c.sub, action: { clef = c.key }) {
                        HStack(spacing: 2) {
                            if c.key == .both {
                                ClefIconView(clef: .treble, size: 32)
                                ClefIconView(clef: .bass, size: 32)
                            } else {
                                ClefIconView(clef: c.key == .bass ? .bass : .treble, size: 34)
                            }
                        }
                        .frame(width: 48)
                    }
                }
                Spacer()
                primary("Devam") {
                    model.settings.clef = clef
                    next()
                }
            }
        case .level:
            VStack(alignment: .leading, spacing: 12) {
                title("Piyanoda neredesin?")
                bodyText("Sorular seviyene göre gelir. Çalıştıkça yeni sorular açılır.").padding(.bottom, 6)
                ForEach(Array(Self.levels.enumerated()), id: \.offset) { k, l in
                    ChoiceCard(selected: level == k, title: l.label, sub: l.sub, action: { level = k }) { EmptyView() }
                }
                Text("Günlük hedefin").font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color).padding(.top, 10)
                Segmented(value: goal, options: [10, 20, 30].map { ($0, "\($0) soru") }) { goal = $0 }
                Spacer()
                primary("Devam") {
                    model.settings.level = Self.levels[level].level
                    model.settings.levelProgress = LevelProgress(n: 0, c: 0)
                    model.settings.dailyGoal = goal
                    next()
                }
            }
        case .reminder:
            VStack(alignment: .leading, spacing: 12) {
                title("Her gün hatırlatalım mı?")
                bodyText("Nota okuma, her gün birkaç dakikayla yerleşir. Seçtiğin saatte bir bildirim gönderelim.").padding(.bottom, 6)
                ChoiceCard(selected: remind, title: "Evet, hatırlat", sub: "Her gün aynı saatte", action: { remind = true }) { EmptyView() }
                if remind {
                    TimeField(hour: hour, minute: minute) { h, m in
                        hour = h
                        minute = m
                    }
                }
                ChoiceCard(
                    selected: !remind, title: "Şimdi değil", sub: "Ayarlar'dan istediğin zaman açabilirsin", action: { remind = false }
                ) { EmptyView() }
                Spacer()
                primary(remind ? "Hatırlat" : "Devam") {
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

    private func bodyText(_ s: String) -> some View {
        Text(s).font(.ui(FontSize.md)).foregroundStyle(ThemeColor.textMuted.color).fixedSize(horizontal: false, vertical: true)
    }
}

/// Mor ana düğme (tanıtım ve deneme adımları)
@MainActor
private func primary(_ title: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title)
            .font(.ui(FontSize.md, .bold))
            .foregroundStyle(PaletteColor.violet100.color)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(CSSLinearGradient(.primaryFlat).clipShape(RoundedRectangle(cornerRadius: Radius.lg)))
            .shadow(color: PaletteColor.violet600.opacity(0.45), radius: 10, y: 4)
            .opacity(enabled ? 1 : 0.35)
    }
    .buttonStyle(.plain)
    .allowsHitTesting(enabled)
}

/// Canlı deneme: gerçek porte, gerçek klavye; doğru tuşu bulunca "Devam" açılır, yanlışta 0,9 sn sonra yeniden denenir
private struct TryStep: View {
    /// Web 21vh (en çok 190): vh tam ekran yüksekliği
    static var screenHeight: Double {
        Double((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.height ?? 844)
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
            MusicalStaffView(clef: .treble, noteY: noteY, ledgerLines: ledger)
                .frame(maxWidth: .infinity, minHeight: 170)
                .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.fill.color))
                .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            Group {
                switch state {
                case .correct: Text("Doğru! Bu nota \(note).").font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.greenText.color)
                case .wrong: Text(helpWrong).font(.ui(FontSize.md)).foregroundStyle(ThemeColor.redText.color)
                case .pending: Text("Piyano tuşlarından birine dokun.").font(.ui(FontSize.md)).foregroundStyle(ThemeColor.textMuted.color)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 48, alignment: .topLeading)
            Spacer(minLength: 0)
            QuizPianoView(
                keys: Piano.quizKeys(answerState: state.rawValue, selectedNote: picked, showLabels: true),
                height: Piano.quizHeight(screenHeight: Self.screenHeight, tall: false),
                // Web: cevap beklenmiyorken (doğru ya da yanlışın 0,9 sn'si) klavye kapalı
                disabled: state != .pending
            ) { key in answer(key.answer) }
            primary("Devam", enabled: state == .correct, action: onPass).padding(.top, 0)
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
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(900))
                if state == .wrong {
                    state = .pending
                    picked = nil
                }
            }
        }
    }
}
