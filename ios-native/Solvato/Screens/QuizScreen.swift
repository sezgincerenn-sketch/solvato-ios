// Soru turu: üstte çıkış, adım noktaları ve doğru sayısı; soru kartı (porte, ritim, terim, yazım, kulak); altta
// klavye ya da şıklar; yanlışta açıklama ve "Sıradaki". Web karşılığı src/screens/QuizSession.tsx. Akış ve bütün yazılar
// SolvatoCore QuizRound'dan (testli); burada yalnızca çizim. iPad'de 2 oktav, yan ekranda 3 oktav ve iki sütun.
// Doğruda "ting" + başarı titreşimi + şıkta yeşil nabız + notanın zıplaması; yanlışta "dum" + hata titreşimi + sallanma.
// Telefonda klavyeyle cevaplarken ilk 3 turda "yan çevir" ipucu (6 sn; yan çevrilince bir daha çıkmaz).
import SolvatoCore
import SwiftUI
import UIKit

struct QuizScreen: View {
    let model: AppModel
    let questions: [Question]
    var noHints = false
    var timerSeconds: Int?

    @State private var round: QuizRound
    @State private var showExit = false
    @State private var flare = false
    @State private var startedAt = Date()
    /// "Yan çevir" ipucu: klavyeyle cevaplarken ilk 3 turda (web: dokunmatik ekran + piano modu + sayaç < 3)
    @State private var rotateHint: Bool
    @Environment(\.horizontalSizeClass) private var hClass
    @Environment(\.verticalSizeClass) private var vClass

    init(model: AppModel, questions: [Question], noHints: Bool = false, timerSeconds: Int? = nil) {
        self.model = model
        self.questions = questions
        self.noHints = noHints
        self.timerSeconds = timerSeconds
        _round = State(
            initialValue: QuizRound(
                questions: questions, prefersPiano: model.settings.inputMode == .piano, keyLabels: model.settings.keyLabels,
                noHints: noHints))
        let hint = model.settings.inputMode == .piano && model.persistence.rotateHintCount() < 3
        _rotateHint = State(initialValue: hint)
    }

    /// Telefon yan çevrilmiş (iki sütun, 3 oktav)
    private var land: Bool { vClass == .compact }
    private var tablet: Bool { hClass == .regular && vClass == .regular }
    private var octaves: Int { land ? 3 : tablet ? 2 : 1 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ThemeColor.bg.color.ignoresSafeArea()
                VStack(spacing: 0) {
                    topBar
                    if let s = timerSeconds, round.answerState == .pending {
                        TimerBar(seconds: round.seconds(base: s)) { finish(round.timeout(timeMs: elapsed)) }
                            .id(round.index)
                    }
                    if land {
                        HStack(alignment: .top, spacing: 14) {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 0) {
                                    header
                                    if round.showExplanation { landExplanation }
                                }
                            }
                            .frame(width: (geo.size.width - 32 - 14) * 0.4)
                            VStack(spacing: 0) {
                                promptCard(height: geo.size.height).frame(maxHeight: .infinity)
                                answerArea
                            }
                        }
                        .padding(.horizontal, Space.s4)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                header.padding(.horizontal, Space.s4)
                                promptCard(height: geo.size.height).padding(.horizontal, Space.s4).padding(.bottom, 12)
                                if round.showExplanation { explanation }
                            }
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        answerArea
                    }
                }
                if showExit {
                    ExitConfirm(onStay: { showExit = false }, onExit: { model.back() })
                }
            }
        }
        .onChange(of: octaves, initial: true) { _, o in round.octaves = o }
        // İpucu gösterildiyse sayaç bir artar; 6 sn sonra kapanır; telefon yan çevrilince bir daha çıkmaz
        .onAppear { if rotateHint { model.persistence.bumpRotateHint() } }
        .task(id: rotateHint) {
            guard rotateHint else { return }
            try? await Task.sleep(for: .seconds(6))
            rotateHint = false
        }
        .onChange(of: land, initial: true) { _, l in
            guard l else { return }
            model.persistence.bumpRotateHint(done: true)
            rotateHint = false
        }
        // Kenardan kaydırma çıkış onayını açar
        .onChange(of: model.exitRequest) { _, _ in showExit = true }
    }

    private var elapsed: Int { Int(Date().timeIntervalSince(startedAt) * 1000) }

    private func finish(_ outcome: QuizRound.Outcome) {
        switch outcome {
        case let .correct(f):
            Sound.play(Sounds.correctChime)
            Haptics.success()
            if f { flare = true }
            // Doğru cevapta 0,7 sn sonra sıradaki soru (alev de o kadar görünür)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(700))
                flare = false
                next()
            }
        case .wrong:
            Sound.play(Sounds.wrongBuzz)
            Haptics.error()
        case .ignored: break
        }
    }

    private func next() {
        if let results = round.advance() {
            model.completeQuiz(results)
        } else {
            startedAt = Date()
        }
    }

    // MARK: Üst çubuk
    private var topBar: some View {
        ZStack {
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(0..<round.questions.count, id: \.self) { i in
                        Capsule()
                            .fill(
                                i < round.index
                                    ? AnyShapeStyle(PaletteColor.violet500.color)
                                    : i == round.index
                                        ? AnyShapeStyle(LinearGradient(colors: [PaletteColor.violet500.color, PaletteColor.violet400.color], startPoint: .leading, endPoint: .trailing))
                                        : AnyShapeStyle(ThemeColor.fillStronger.color)
                            )
                            .frame(width: i == round.index ? 18 : 6, height: 6)
                            .shadow(color: i == round.index ? PaletteColor.violet500.opacity(0.6) : .clear, radius: 4)
                    }
                }
                Text(verbatim: "\(round.index + 1)/\(round.questions.count)")
                    .font(.mono(FontSize.sm, .bold))
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .padding(.leading, 2)
            }
            .animation(.easeInOut(duration: 0.3), value: round.index)
            HStack {
                Button { showExit = true } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ThemeColor.textMuted.color)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: Radius.sm).fill(ThemeColor.fillStrong.color))
                        .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(ThemeColor.border.color, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Çık")
                Spacer()
                Text(verbatim: "✓ \(round.score)")
                    .font(.mono(FontSize.sm, .bold))
                    .foregroundStyle(ThemeColor.greenText.color)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 11)
                    .background(Capsule().fill(PaletteColor.green500.opacity(0.1)))
                    .overlay(Capsule().strokeBorder(PaletteColor.green500.opacity(0.25), lineWidth: 1))
                    .overlay(alignment: .top) {
                        if flare {
                            StreakFlare { Icon(.flame, size: 20, fill: true).foregroundStyle(ThemeColor.orangeText.color) }
                                .offset(y: -24)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
        .padding(.top, 14)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    // MARK: Soru başlığı
    private var header: some View {
        let cc = round.categoryColor
        return VStack(alignment: .leading, spacing: 0) {
            Text(round.categoryLabel)
                .font(.ui(FontSize.xs, .bold))
                .tracking(em: 0.1, size: FontSize.xs)
                .foregroundStyle(cc.text.color)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Capsule().fill(cc.base.opacity(0.14)))
                .overlay(Capsule().strokeBorder(cc.base.opacity(0.2), lineWidth: 1))
                .padding(.bottom, Space.s2)
            Text(round.question.questionText)
                .font(.ui(FontSize.lg, .bold))
                .tracking(em: -0.02, size: FontSize.lg)
                .foregroundStyle(ThemeColor.text.color)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)
        }
    }

    // MARK: Soru kartı
    private func promptCard(height: Double) -> some View {
        let q = round.question
        let st = round.answerState
        let minH: Double =
            q.category == .writing
            ? 0
            : round.isNote
                ? (land ? 0 : st == .wrong ? 170 : min(400, max(240, height * 0.44)))
                : (st == .wrong ? 120 : min(340, max(200, height * 0.38)))
        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            promptContent
            Spacer(minLength: 0)
            if round.showHint && round.hintAvailable {
                Text(round.hintText)
                    .font(.ui(FontSize.sm, .medium))
                    .foregroundStyle(ThemeColor.amberText.color)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.amber500.opacity(0.1)))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(PaletteColor.amber500.opacity(0.25), lineWidth: 1))
                    .padding([.horizontal, .bottom], 12)
                    .slideUpOnAppear()
            }
        }
        .padding(q.category == .writing ? EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14) : EdgeInsets())
        .frame(maxWidth: .infinity, minHeight: minH)
        .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.paper.color))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
        .overlay(alignment: .topTrailing) { if round.hintAvailable { hintButton } }
        .overlay(alignment: .bottom) {
            if round.isNote && st == .correct {
                Text(q.correctAnswer)
                    .font(.ui(FontSize.xl, .heavy))
                    .tracking(em: -0.01, size: FontSize.xl)
                    .foregroundStyle(ThemeColor.greenText.color)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 18)
                    .background(Capsule().fill(PaletteColor.green400.opacity(0.16)))
                    .overlay(Capsule().strokeBorder(PaletteColor.green400.opacity(0.45), lineWidth: 1))
                    .padding(.bottom, 14)
                    .popInOnAppear()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .popInOnAppear()
        .id(round.index)
    }

    @ViewBuilder
    private var promptContent: some View {
        let q = round.question
        switch q.category {
        case .ear:
            if let ear = q.ear {
                EarPromptView(prompt: ear, answerState: round.answerState, soundOn: model.settings.soundKeys) { model.settings.soundKeys = true }
            }
        case .writing:
            Text("Dört yazımdan sadece biri doğru. Doğru olanı seç.")
                .font(.ui(FontSize.sm))
                .foregroundStyle(ThemeColor.textMuted.color)
                .multilineTextAlignment(.center)
        case .noteIdentification:
            if let y = q.noteY, let clef = q.clef {
                MusicalStaffView(
                    clef: clef, noteY: y, ledgerLines: q.ledgerLines ?? [], accidental: q.accidental,
                    feedback: round.answerState == .correct ? .correct : round.answerState == .wrong ? .wrong : nil,
                    maxHeight: land ? 130 : nil)
            }
        case .rhythm:
            if let score = q.score ?? NotationLayout.rhythmScore(rhythmType: q.rhythmType ?? "", displayText: q.displayText) {
                NotationView(score: score, maxW: q.score == nil ? 220 : nil).padding(.horizontal, 12)
            } else {
                Text(q.displayText ?? "")
                    .font(.ui(FontSize.xl, .bold))
                    .foregroundStyle(ThemeColor.notation.color)
                    .frame(minHeight: 110)
            }
        case .musicalTerms:
            if let score = round.termScore {
                NotationView(score: score).padding(.horizontal, 12)
            } else {
                let t = round.termText
                Text(t)
                    .font(.term(t.count <= 4 ? 72 : 38.4, .regular))
                    .foregroundStyle(ThemeColor.termSymbol.color)
                    .multilineTextAlignment(.center)
                    .shadow(color: PaletteColor.violet500.opacity(0.4), radius: 12)
                    .frame(minHeight: 128)
            }
        }
    }

    private var hintButton: some View {
        let on = round.showHint
        return Button { withAnimation(.easeOut(duration: 0.18)) { round.showHint.toggle() } } label: {
            HStack(spacing: 4) {
                Icon(.bulb, size: 14)
                Text("İpucu")
            }
            .font(.ui(FontSize.sm, .semibold))
            .foregroundStyle((on ? ThemeColor.amberText : ThemeColor.textMuted).color)
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(Capsule().fill(on ? PaletteColor.amber500.opacity(0.2) : ThemeColor.fillStrong.color))
            .overlay(Capsule().strokeBorder(on ? PaletteColor.amber500.opacity(0.45) : ThemeColor.border.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.top, 10)
        .padding(.trailing, 12)
        .accessibilityValue(on ? "Açık" : "Kapalı")
    }

    // MARK: Açıklama
    private var explanation: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("✕").font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.redText.color).padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                (Text("Doğru cevap: ").foregroundStyle(ThemeColor.redText.color).font(.ui(FontSize.md, .semibold))
                    + Text(round.question.correctAnswer).foregroundStyle(ThemeColor.greenText.color).font(.ui(FontSize.md, .bold)))
                if let w = round.wrongOctaveText {
                    Text(w).font(.ui(FontSize.sm, .semibold)).foregroundStyle(ThemeColor.amberText.color)
                }
                Text(round.question.explanation).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.red500.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(PaletteColor.red500.opacity(0.22), lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .slideUpOnAppear()
    }

    /// Yan ekranda açıklama sol sütunda, kısa
    private var landExplanation: some View {
        VStack(alignment: .leading, spacing: 0) {
            (Text("Doğru cevap: ").foregroundStyle(ThemeColor.redText.color).font(.ui(FontSize.sm, .semibold))
                + Text(round.window.octaveMode && round.target != nil ? round.target!.key : round.question.correctAnswer)
                .foregroundStyle(ThemeColor.greenText.color).font(.ui(FontSize.sm, .bold)))
            if round.wrongOctave {
                Text("Nota doğru, oktav yanlış.").font(.ui(FontSize.xs, .semibold)).foregroundStyle(ThemeColor.amberText.color)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.red500.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(PaletteColor.red500.opacity(0.22), lineWidth: 1))
        .padding(.top, Space.s2)
        .slideUpOnAppear()
    }

    // MARK: Cevap alanı
    private var answerArea: some View {
        VStack(spacing: 0) {
            if !land && !tablet && rotateHint && round.usesPiano {
                RotateHintView { rotateHint = false }
            }
            if round.usesPiano {
                QuizPianoView(
                    keys: round.pianoKeys,
                    height: Piano.quizHeight(screenHeight: screenHeight, tall: land),
                    disabled: round.answerState != .pending
                ) { key in
                    finish(round.answer(key.answer, timeMs: elapsed))
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            } else {
                choices
            }
            if round.answerState == .wrong {
                Button { next() } label: {
                    Text(round.nextTitle)
                        .font(.ui(FontSize.md, .bold))
                        .tracking(em: -0.01, size: FontSize.md)
                        .foregroundStyle(Brand.onPrimary.color)
                        .frame(maxWidth: .infinity)
                        .padding(15)
                        .background(CSSLinearGradient(.primaryFlat).clipShape(RoundedRectangle(cornerRadius: Radius.lg)))
                        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(PaletteColor.violet500.opacity(0.3), lineWidth: 1))
                        .shadow(color: PaletteColor.violet600.opacity(0.45), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            } else {
                Color.clear.frame(height: 16)
            }
        }
        .background(ThemeColor.bg.color)
    }

    private var screenHeight: Double {
        Double((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.height ?? 844)
    }

    private var choices: some View {
        let q = round.question
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(q.options, id: \.self) { opt in
                let state = round.optionState(opt)
                let (bg, border, fg, glow): (Color, Color, Color, Color) =
                    switch state {
                    case .correct, .reveal:
                        (PaletteColor.green500.opacity(0.15), PaletteColor.green500.color, ThemeColor.greenText.color, PaletteColor.green500.opacity(0.35))
                    case .wrong: (PaletteColor.red500.opacity(0.13), PaletteColor.red500.color, ThemeColor.redText.color, PaletteColor.red500.opacity(0.3))
                    case .idle: (ThemeColor.fill.color, ThemeColor.border.color, ThemeColor.textSecondary.color, .clear)
                    }
                Button { finish(round.answer(opt, timeMs: elapsed)) } label: {
                    Group {
                        if let score = q.optionScores?[opt] {
                            NotationView(score: score, maxW: 170)
                                .overlay(alignment: .topLeading) {
                                    Text(opt).font(.ui(FontSize.xs, .bold)).opacity(0.7).offset(x: 4, y: 0)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity, minHeight: 120)
                        } else {
                            Text(opt)
                                .font(.ui(FontSize.md, .semibold))
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 18)
                                .padding(.horizontal, 14)
                                .frame(maxWidth: .infinity, minHeight: 64)
                        }
                    }
                    .foregroundStyle(fg)
                    .background(RoundedRectangle(cornerRadius: Radius.lg).fill(bg))
                    .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(border, lineWidth: 1))
                    .overlay(alignment: .trailing) {
                        if state == .reveal {
                            Text("✓").font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.greenText.color).padding(.trailing, 12)
                        }
                    }
                    .shadow(color: glow, radius: 7)
                    .correctPulse(state == .correct, cornerRadius: Radius.lg)
                    .shake(state == .wrong)
                }
                .buttonStyle(.plain)
                .allowsHitTesting(round.answerState == .pending)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .id(round.index)
    }
}

/// Zaman yarışı çubuğu: kalan saniye ve daralan çizgi; süre dolunca onTimeout (web TimerBar)
private struct TimerBar: View {
    let seconds: Int
    let onTimeout: () -> Void
    @State private var started = Date()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let left = max(0, seconds - Int(ctx.date.timeIntervalSince(started)))
            let pct = Double(left) / Double(max(seconds, 1)) * 100
            let color = (pct > 50 ? PaletteColor.green500 : pct > 25 ? PaletteColor.amber500 : PaletteColor.red500).color
            HStack(spacing: 10) {
                Text(verbatim: "\(left)").font(.mono(FontSize.sm, .bold)).foregroundStyle(color).frame(minWidth: 16)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ThemeColor.fillStrong.color)
                        Capsule().fill(color).frame(width: g.size.width * Double(left) / Double(max(seconds, 1)))
                            .animation(.linear(duration: 1), value: left)
                    }
                }
                .frame(height: 3)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .onChange(of: left) { _, l in if l == 0 { onTimeout() } }
        }
        .onAppear { started = Date() }
    }
}

/// Kulak sorusunun üst alanı (web EarPrompt): açılınca 0,35 sn sonra bir kez çalar; dokununca tekrar. Nota → referans Do,
/// ara, soru notası; akor → notalar tek tek, sonra birlikte. Çalarken halka yayılır. Ses kapalıysa "Sesi aç".
struct EarPromptView: View {
    let prompt: EarPrompt
    let answerState: AnswerState
    let soundOn: Bool
    let onEnableSound: () -> Void
    @State private var playing = 0

    var body: some View {
        let base = CategoryColor.ear.base
        let size: Double = answerState == .pending ? 104 : 64
        if !soundOn {
            VStack(spacing: 0) {
                Text("Ses kapalı").font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color)
                Text("Kulak soruları için sesi açman gerek.")
                    .font(.ui(FontSize.sm))
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .padding(.top, 4)
                    .padding(.bottom, 14)
                Button(action: onEnableSound) {
                    Text("Sesi aç")
                        .font(.ui(FontSize.md, .bold))
                        .foregroundStyle(PaletteColor.white.color)
                        .padding(.horizontal, 20)
                        .frame(minHeight: 44)
                        .background(Capsule().fill(PaletteColor.violet600.color))
                }
                .buttonStyle(.plain)
            }
            .multilineTextAlignment(.center)
            .padding(20)
        } else {
            VStack(spacing: answerState == .pending ? 14 : 8) {
                Button(action: play) {
                    Icon(.speaker, size: (size * 0.42).rounded())
                        .foregroundStyle(CategoryColor.ear.text.color)
                        .frame(width: size, height: size)
                        .background(Circle().fill(base.opacity(playing > 0 ? 0.22 : 0.12)))
                        .overlay(Circle().strokeBorder(base.opacity(0.5), lineWidth: 2))
                        .overlay { if playing > 0 { EarPulse(color: base.color).padding(-8) } }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tekrar dinle")
                Text(
                    answerState != .pending
                        ? "Bir daha dinlemek için dokun"
                        : { if case .note = prompt { return "Tekrar dinlemek için dokun" } else { return "Notalar tek tek, sonra birlikte çalınır · tekrar dinlemek için dokun" } }()
                )
                .font(.ui(FontSize.sm))
                .foregroundStyle(ThemeColor.textMuted.color)
                .multilineTextAlignment(.center)
            }
            .padding(.vertical, answerState == .pending ? 16 : 10)
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.2), value: answerState)
            .animation(.easeInOut(duration: 0.2), value: playing > 0)
            // Soru açılınca kendiliğinden bir kez
            .task(id: prompt) {
                try? await Task.sleep(for: .milliseconds(350))
                if !Task.isCancelled { play() }
            }
        }
    }

    private func play() {
        let ear = Sounds.ear(prompt)
        Sound.play(ear.voices)
        playing += 1
        let token = playing
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(ear.duration))
            if playing == token { playing = 0 }
        }
    }
}

/// Çalarken düğmenin çevresinde yayılan halka (web earPulse: 1 sn, 0,92 → 1,25, saydamlaşarak, sürekli)
private struct EarPulse: View {
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        if reduce {
            Circle().strokeBorder(color.opacity(0.45), lineWidth: 2)
        } else {
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
                let e = UnitCurve.easeOut.value(at: t)
                Circle().strokeBorder(color.opacity(0.45), lineWidth: 2)
                    .scaleEffect(0.92 + (1.25 - 0.92) * e)
                    .opacity(0.9 * (1 - e))
            }
        }
    }
}
