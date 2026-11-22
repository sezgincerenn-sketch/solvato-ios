// İlk açılış tanıtımı (web src/screens/Onboarding.tsx): merhaba ve ad → iki canlı deneme (Do, Sol) → anahtar →
// seviye ve günlük hedef → hatırlatma → hazırsın. Üstte adım noktaları ve "Atla". Metinler web'den harfi harfine.
import SolvatoCore
import SwiftUI

struct OnboardingScreen: View {
    let model: AppModel
    let onDone: () -> Void

    private enum Step: Int, CaseIterable { case hello, try1, try2, clef, level, reminder, done }
    @State private var step = Step.hello
    @State private var level = 0
    @State private var goal = 10
    @State private var remind = true
    @State private var hour = 19
    @State private var name = ""
    @State private var clef = ClefChoice.treble

    private static let levels: [(label: String, sub: String, level: Int)] = [
        ("Yeni başladım", "Temel notalar, ritim ve işaretler", 1),
        ("Bir süredir çalıyorum", "Tüm notalar, diyez/bemol, ek çizgiler", 2),
        ("Uzun süredir çalıyorum", "Tüm sorular, ileri ritim ve terimler", 3),
    ]
    private static let clefs: [(key: ClefChoice, label: String, sub: String)] = [
        (.treble, "Sol anahtarı", "Genelde sağ el"), (.bass, "Fa anahtarı", "Genelde sol el"), (.both, "İkisi de", "İki elle çalıyorum"),
    ]
    private static let reminderHours = [17, 18, 19, 20, 21]

    private func next() { withAnimation(.easeOut(duration: 0.2)) { step = Step(rawValue: step.rawValue + 1) ?? .done } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    ForEach(Step.allCases, id: \.self) { k in
                        Capsule()
                            .fill(k.rawValue <= step.rawValue ? PaletteColor.violet500.color : ThemeColor.fillStronger.color)
                            .frame(width: k == step ? 22 : 8, height: 8)
                    }
                }
                Spacer()
                if step != .done {
                    Button("Atla", action: onDone)
                        .font(.ui(FontSize.md))
                        .foregroundStyle(ThemeColor.textMuted.color)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
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
                    HStack(spacing: 8) {
                        ForEach(Self.reminderHours, id: \.self) { h in
                            Chip("\(h):00", selected: hour == h) { hour = h }
                        }
                    }
                    .padding(.top, 2)
                    .padding(.bottom, 4)
                }
                ChoiceCard(
                    selected: !remind, title: "Şimdi değil", sub: "Ayarlar'dan istediğin zaman açabilirsin", action: { remind = false }
                ) { EmptyView() }
                Spacer()
                primary(remind ? "Hatırlat" : "Devam") {
                    model.settings.reminderHour = hour
                    if remind {
                        let h = hour
                        Task { @MainActor in
                            model.settings.reminder = await Reminder.enable(hour: h)
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
                primary("Başlayalım", action: onDone)
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
                height: Piano.quizHeight(screenHeight: 844, tall: false)
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
