// Akor turu: üstte çıkış, adım noktaları ve XP; soru kartı (tür etiketi, seviye, isteğe bağlı 15 sn halkası, soru,
// "Dinle", porte / basılı klavye / akor adı, cevaptan sonra "Formülü Göster"); şıklar ya da akor klavyesi ve "Seçilen"
// satırı; altta yanlış/süre kutusu ve ana düğme. Web src/screens/ChordQuizSession.tsx. Akış ve yazılar SolvatoCore
// ChordRound'dan (testli). "Dinle" akoru arpej çalar; doğruda başarı, yanlışta ve süre dolunca hata titreşimi; şıklarda
// nabız / sallanma. Akoru basarken telefonda ilk turlarda "yan çevir" ipucu (yan çevrilince bir daha çıkmaz).
import SolvatoCore
import SwiftUI

struct ChordQuizScreen: View {
    let model: AppModel
    @State private var round: ChordRound
    @State private var showExit = false
    @State private var toast: String?
    @State private var shownAt = Date()
    @State private var playingChord = false
    /// "Yan çevir" ipucu (web: dokunmatik ekran + sayaç < 3; akor turunda sayaç artmaz, süre yok)
    @State private var rotateHint: Bool
    @Environment(\.horizontalSizeClass) private var hClass
    @Environment(\.verticalSizeClass) private var vClass
    private let timerOn: Bool

    init(model: AppModel) {
        self.model = model
        timerOn = model.settings.timer
        _round = State(initialValue: ChordRound(level: model.settings.effectiveChordLevel))
        _rotateHint = State(initialValue: model.persistence.rotateHintCount() < 3)
    }

    private var land: Bool { vClass == .compact }
    private var tablet: Bool { hClass == .regular && vClass == .regular }

    private var elapsed: Int { Int(Date().timeIntervalSince(shownAt) * 1000) }

    var body: some View {
        ZStack {
            ThemeColor.bg.color.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 0) {
                        questionCard.padding(.bottom, 12)
                        if round.usesPiano { pianoArea } else { options.padding(.bottom, 14) }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .scrollIndicators(.hidden)
                bottomBar
            }
            if let toast {
                HStack(spacing: 10) {
                    Icon(.check, size: 18, strokeWidth: 2.4)
                    Text(toast).font(.ui(FontSize.sm, .bold))
                }
                .foregroundStyle(ThemeColor.greenText.color)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Radius.lg).fill(.ultraThinMaterial))
                .background(RoundedRectangle(cornerRadius: Radius.lg).fill(PaletteColor.green500.opacity(0.15)))
                .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(PaletteColor.green500.opacity(0.4), lineWidth: 1))
                .padding(.horizontal, 16)
                .padding(.bottom, 88)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .slideUpOnAppear()
            }
            if showExit { ExitConfirm(onStay: { showExit = false }, onExit: { model.back() }) }
        }
        .onChange(of: model.exitRequest) { _, _ in showExit = true }
        .onChange(of: land, initial: true) { _, l in
            guard l else { return }
            model.persistence.bumpRotateHint(done: true)
            rotateHint = false
        }
    }

    /// Akoru arpej çalar: notalar 0,22 sn arayla (web listenChord(true)); çalarken düğme koyulaşır
    private func listenChord() {
        guard !playingChord else { return }
        playingChord = true
        let notes = round.question.chord.notes
        Sound.play(Sounds.notes(notes.map { Pitch(name: Chords.pcKey[$0.pc], octave: $0.octave) }, gap: 0.22))
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(notes.count * 220 + 300))
            playingChord = false
        }
    }

    // MARK: Üst çubuk
    private var topBar: some View {
        HStack(spacing: 10) {
            Button { showExit = true } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ThemeColor.textFaint.color)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: Radius.sm).fill(ThemeColor.fill.color))
                    .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Çık")
            HStack(spacing: 3) {
                ForEach(0..<round.questions.count, id: \.self) { i in
                    Capsule()
                        .fill(
                            i < round.index
                                ? AnyShapeStyle(PaletteColor.violet500.color)
                                : i == round.index
                                    ? AnyShapeStyle(LinearGradient(colors: [PaletteColor.violet500.color, PaletteColor.violet400.color], startPoint: .leading, endPoint: .trailing))
                                    : AnyShapeStyle(ThemeColor.fillStrong.color)
                        )
                        .frame(width: i == round.index ? 14 : 5, height: 5)
                        .shadow(color: i == round.index ? PaletteColor.violet500.opacity(0.5) : .clear, radius: 4)
                }
                Text(verbatim: "\(round.index + 1)/\(round.questions.count)")
                    .font(.mono(FontSize.sm, .bold))
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .padding(.leading, 4)
            }
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.3), value: round.index)
            Text(verbatim: "\(round.score) XP")
                .font(.mono(FontSize.sm, .bold))
                .foregroundStyle(ThemeColor.violetText.color)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Capsule().fill(PaletteColor.violet500.opacity(0.12)))
                .overlay(Capsule().strokeBorder(PaletteColor.violet500.opacity(0.25), lineWidth: 1))
        }
        .padding(.top, 14)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    // MARK: Soru kartı
    private var questionCard: some View {
        let q = round.question
        let c = q.chord
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(round.typeTag)
                    .font(.ui(FontSize.xs, .bold))
                    .tracking(em: 0.1, size: FontSize.xs)
                    .foregroundStyle(ThemeColor.violetText.color)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(PaletteColor.violet500.opacity(0.14)))
                    .overlay(Capsule().strokeBorder(PaletteColor.violet500.opacity(0.3), lineWidth: 1))
                Spacer()
                Text(round.levelLabel).font(.ui(FontSize.xs, .semibold)).foregroundStyle(ThemeColor.textMuted.color)
                if timerOn {
                    CountdownRing(seconds: ChordRound.timerSeconds, running: round.pending) {
                        guard round.pending else { return }
                        round.timeout(timeMs: elapsed)
                        Haptics.error()
                    }
                        .id(round.index)
                }
            }
            .padding(.bottom, 10)
            HStack(alignment: .top, spacing: 8) {
                Text(round.prompt)
                    .font(.ui(FontSize.md, .bold))
                    .foregroundStyle(ThemeColor.textSecondary.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: listenChord) {
                    HStack(spacing: 6) {
                        Icon(.speaker, size: 16)
                        Text("Dinle").font(.ui(FontSize.sm, .bold))
                    }
                    .foregroundStyle(ThemeColor.violetText.color)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 12)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.violet500.opacity(playingChord ? 0.25 : 0.12)))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md).strokeBorder(PaletteColor.violet500.opacity(playingChord ? 0.55 : 0.25), lineWidth: 1))
                    .animation(.easeInOut(duration: 0.15), value: playingChord)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 10)
            switch q.type {
            case .staff:
                ChordStaffView(chord: c, color: .palette(round.state == .correct ? .green500 : .violet500))
                    .padding(.top, 6)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.bg.color))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            case .keys:
                MultiPianoView(keys: round.pianoKeys, disabled: true) { _ in }
                    .padding(.top, 4)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 10)
            case .build:
                VStack(spacing: 2) {
                    Text(c.name).font(.ui(FontSize.xxl, .heavy)).tracking(em: -0.02, size: FontSize.xxl).foregroundStyle(ThemeColor.text.color)
                    Text(c.symbol).font(.mono(FontSize.lg, .bold)).foregroundStyle(ThemeColor.violetText.color)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.bg.color))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            }
            if !round.pending {
                VStack(alignment: .leading, spacing: 8) {
                    Button { withAnimation(.easeOut(duration: 0.2)) { round.showFormula.toggle() } } label: {
                        HStack(spacing: 4) {
                            Icon(.bulb, size: 14)
                            Text(round.formulaTitle)
                        }
                        .font(.ui(FontSize.sm, .semibold))
                        .foregroundStyle(ThemeColor.amberText.color)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(PaletteColor.amber500.opacity(0.08)))
                        .overlay(Capsule().strokeBorder(PaletteColor.amber500.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    if round.showFormula {
                        (Text(c.label).bold() + Text(verbatim: " · \(c.noteNames.joined(separator: " – "))\n\(c.formula)"))
                            .font(.ui(FontSize.sm))
                            .foregroundStyle(ThemeColor.amberText.color)
                            .padding(.vertical, 9)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.amber500.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(PaletteColor.amber500.opacity(0.2), lineWidth: 1))
                            .slideUpOnAppear()
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding(.top, 14)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.surface.color))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }

    // MARK: Şıklar
    private var options: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)], spacing: 9) {
            ForEach(round.question.options, id: \.id) { opt in
                let st = round.optionState(opt.id)
                let (bg, border, fg, glow): (Color, Color, Color, Color) =
                    switch st {
                    case .chosen:
                        (PaletteColor.violet500.opacity(0.14), PaletteColor.violet500.opacity(0.4), ThemeColor.violetTextSoft.color, PaletteColor.violet500.opacity(0.25))
                    case .correct, .reveal:
                        (PaletteColor.green500.opacity(0.14), PaletteColor.green500.color, ThemeColor.greenText.color, PaletteColor.green500.opacity(0.3))
                    case .wrong: (PaletteColor.red500.opacity(0.12), PaletteColor.red500.color, ThemeColor.redText.color, PaletteColor.red500.opacity(0.3))
                    case .idle: (ThemeColor.fill.color, ThemeColor.border.color, ThemeColor.textSecondary.color, .clear)
                    }
                Button { round.choose(opt.id) } label: {
                    VStack(spacing: 2) {
                        Text(opt.name).font(.ui(FontSize.md, .bold))
                        Text(opt.symbol).font(.mono(FontSize.sm, .semibold)).opacity(0.7)
                    }
                    .multilineTextAlignment(.center)
                    .foregroundStyle(fg)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 12)
                    .background(RoundedRectangle(cornerRadius: Radius.lg).fill(bg))
                    .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(border, lineWidth: 1))
                    .shadow(color: glow, radius: 6)
                    .correctPulse(st == .correct, cornerRadius: Radius.lg)
                    .shake(st == .wrong)
                }
                .buttonStyle(.plain)
                .allowsHitTesting(round.pending)
            }
        }
        .id(round.index)
    }

    // MARK: Akoru bas
    private var pianoArea: some View {
        VStack(spacing: 10) {
            if !land && !tablet && rotateHint {
                RotateHintView { rotateHint = false }.padding(.bottom, -10)
            }
            HStack(spacing: 8) {
                Text("SEÇİLEN")
                    .font(.ui(FontSize.xs, .bold))
                    .tracking(em: 0.06, size: FontSize.xs)
                    .foregroundStyle(ThemeColor.textFaint.color)
                HStack(spacing: 5) {
                    if round.selectedKeys.isEmpty {
                        Text(round.emptyKeysText).font(.ui(FontSize.xs)).foregroundStyle(ThemeColor.textFaint.color)
                    } else {
                        ForEach(round.selectedKeys, id: \.self) { k in
                            Text(k)
                                .font(.mono(FontSize.sm, .bold))
                                .foregroundStyle(ThemeColor.violetText.color)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(Capsule().fill(PaletteColor.violet500.opacity(0.15)))
                                .overlay(Capsule().strokeBorder(PaletteColor.violet500.opacity(0.35), lineWidth: 1))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !round.selectedKeys.isEmpty && round.pending {
                    Button("✕ Temizle") { round.clearKeys() }
                        .font(.ui(FontSize.sm))
                        .foregroundStyle(ThemeColor.textFaint.color)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fill.color))
            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            MultiPianoView(keys: round.pianoKeys, disabled: !round.pending) { key in round.toggleKey(key.note) }
                .padding(.horizontal, 2)
                .padding(.bottom, 28)
        }
        .id(round.index)
    }

    // MARK: Alt çubuk
    private var bottomBar: some View {
        let active = !round.pending || round.canCheck
        return VStack(spacing: 10) {
            if round.state == .wrong || round.state == .timeout {
                let t = round.wrongTitle
                VStack(alignment: .leading, spacing: 2) {
                    (Text(t.prefix) + Text(t.label).foregroundStyle(ThemeColor.greenText.color))
                        .font(.ui(FontSize.md, .bold))
                        .foregroundStyle(ThemeColor.redText.color)
                    Text(round.notesLine).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.red500.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(PaletteColor.red500.opacity(0.22), lineWidth: 1))
                .slideUpOnAppear()
            }
            Button { mainAction() } label: {
                Text(round.buttonTitle)
                    .font(.ui(FontSize.md, .heavy))
                    .tracking(em: -0.01, size: FontSize.md)
                    .foregroundStyle(active ? Brand.onPrimary.color : ThemeColor.textFaint.color)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background {
                        if active {
                            CSSLinearGradient(.primaryFlat).clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                        } else {
                            RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.fill.color)
                        }
                    }
                    .shadow(color: active ? PaletteColor.violet600.opacity(0.45) : .clear, radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(active)
        }
        .padding(.top, 10)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .background(.ultraThinMaterial)
        .background(ThemeColor.overlay.color)
        .overlay(alignment: .top) { ThemeColor.border.color.frame(height: 1) }
    }

    private func mainAction() {
        if round.pending {
            let correct = round.check(timeMs: elapsed)
            if correct {
                Haptics.success()
                withAnimation(.easeOut(duration: 0.2)) { toast = round.successToast }
                let at = round.index
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(1500))
                    if round.index == at && !round.pending { advance() }
                }
            } else if round.state == .wrong {
                Haptics.error()
            }
        } else {
            advance()
        }
    }

    private func advance() {
        withAnimation(.easeOut(duration: 0.2)) { toast = nil }
        if let answers = round.advance() {
            model.completeSpecial(.chords, answers: answers)
        } else {
            shownAt = Date()
        }
    }
}

/// Akor turunda 15 sn geri sayım halkası (web CountdownRing)
private struct CountdownRing: View {
    let seconds: Int
    let running: Bool
    let onTimeout: () -> Void
    @State private var started = Date()
    @State private var fired = false
    /// Cevap verilince sayaç olduğu yerde durur
    @State private var frozen: Int?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { tl in
            let rem = frozen ?? max(0, seconds - Int(tl.date.timeIntervalSince(started)))
            let pct = Double(rem) / Double(seconds)
            let col = (pct > 0.5 ? PaletteColor.green500 : pct > 0.25 ? PaletteColor.amber500 : PaletteColor.red500).color
            ZStack {
                Circle().stroke(ThemeColor.fillStrong.color, lineWidth: 4).frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(col, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 40, height: 40)
                    .animation(.linear(duration: 1), value: rem)
                Text(verbatim: "\(rem)").font(.mono(FontSize.sm, .heavy)).foregroundStyle(col)
            }
            .frame(width: 52, height: 52)
            .onChange(of: running) { _, on in if !on && frozen == nil { frozen = rem } }
            .onChange(of: rem) { _, r in
                if r == 0 && running && !fired {
                    fired = true
                    onTimeout()
                }
            }
        }
    }
}
