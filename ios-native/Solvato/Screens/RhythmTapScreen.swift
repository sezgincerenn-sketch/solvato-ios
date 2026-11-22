// Ritmi Tut: tek ölçülük ritim; metronomla dört vuruş sayılır, öğrenci ritmi dokunarak çalar. Üstte 6 bölüm ve tempo,
// partisyon ve zaman şeridi, vuruş ışıkları, büyük dokunma alanı, Dinle / Başla; sonuçta "5/6 vuruş yerinde · %72".
// Web src/screens/RhythmTapSession.tsx ve components/RhythmTimeline.tsx. Akış SolvatoCore RhythmTapRound'da (testli).
// Zaman ses saatiyle (Sound.now): metronom tıkları ve dinlerken ritmin notaları önceden zamanlanır, dokunuş aynı saatle
// ölçülür ve çıkış gecikmesi düşülür (web audioNow − audioLatency). Çıkış onayı açılınca deneme ve sesleri durur.
import SolvatoCore
import SwiftUI

struct RhythmTapScreen: View {
    let model: AppModel
    @State private var round: RhythmTapRound
    @State private var showExit = false
    @State private var loop: Task<Void, Never>?

    private let accent = CategoryColor.rhythm.base

    init(model: AppModel) {
        self.model = model
        _round = State(initialValue: model.newRhythmRound())
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: Space.s3) {
                topBar
                VStack(alignment: .leading, spacing: 4) {
                    Text(round.header.uppercased(with: Locale(identifier: "tr")))
                        .font(.ui(FontSize.xs, .bold))
                        .tracking(em: Tracking.label, size: FontSize.xs)
                        .foregroundStyle(CategoryColor.rhythm.text.color)
                    Text(round.title).font(.ui(FontSize.lg, .bold)).foregroundStyle(ThemeColor.text.color)
                }
                VStack(spacing: Space.s3) {
                    NotationView(score: round.notation, maxW: 340).padding(.horizontal, Space.s2)
                    RhythmTimelineView(score: round.score, result: round.result, bpm: round.bpm, progress: round.progress)
                        .padding(.horizontal, Space.s3)
                }
                .padding(.vertical, Space.s3)
                .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.fill.color))
                .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
                middle.frame(minHeight: 64)
                Spacer(minLength: 0)
                bottom
            }
            .padding(.top, Space.s3)
            .padding(.horizontal, Space.s4)
            .padding(.bottom, Space.s4)
            if showExit { ExitConfirm(onStay: { showExit = false }, onExit: { model.back() }) }
        }
        .background(ThemeColor.bg.color)
        .onChange(of: model.exitRequest) { _, _ in if showExit { showExit = false } else { askExit() } }
        .onDisappear {
            loop?.cancel()
            Sound.stopAll()
        }
    }

    // MARK: Üst bar
    private var topBar: some View {
        HStack(spacing: Space.s3) {
            Button(action: askExit) {
                Icon(.x, size: 18)
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fillStrong.color))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Turdan çık")
            HStack(spacing: 4) {
                ForEach(Array(round.segments.enumerated()), id: \.offset) { _, s in
                    Capsule().fill(segmentColor(s)).frame(height: 6)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(round.index + 1). ritim, \(RhythmTap.roundLength) ritimden")
            Text("\(round.bpm) BPM").font(.mono(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
        }
    }

    private func segmentColor(_ s: RhythmTapRound.Segment) -> Color {
        switch s {
        case .passed: PaletteColor.green500.color
        case .failed: PaletteColor.amber500.color
        case .current: accent.color
        case .upcoming: ThemeColor.fillStrong.color
        }
    }

    // MARK: Sonuç ya da sayma
    @ViewBuilder private var middle: some View {
        if round.phase == .result, let s = round.summary {
            VStack(alignment: .leading, spacing: 6) {
                (Text(s.main) + Text(s.pct).foregroundColor(round.result?.passed == true ? ThemeColor.greenText.color : ThemeColor.amberText.color))
                    .font(.ui(FontSize.md, .bold))
                    .foregroundStyle(ThemeColor.text.color)
                Text(round.hint ?? "")
                    .font(.ui(FontSize.sm))
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .lineHeight(1.4, size: FontSize.sm)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: Space.s3) {
                ForEach(1...4, id: \.self) { n in
                    let on = round.count == n
                    Text("\(n)")
                        .font(.mono(FontSize.md, .heavy))
                        .foregroundStyle(on ? PaletteColor.white.color : ThemeColor.textMuted.color)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(on ? accent.color : ThemeColor.fillStrong.color))
                        .scaleEffect(on ? 1.15 : 1)
                        .animation(.linear(duration: 0.08), value: on)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(round.count.map { "Vuruş \($0)" } ?? "")
        }
    }

    // MARK: Alt kısım
    @ViewBuilder private var bottom: some View {
        if !model.settings.soundKeys {
            VStack(spacing: Space.s2) {
                Text("Bu oyun metronomla oynanır; ses kapalı.")
                    .font(.ui(FontSize.sm))
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                AppButton("Sesi aç", block: true) { model.settings.soundKeys = true }
            }
        } else if round.phase == .result {
            HStack(spacing: Space.s2) {
                AppButton("Tekrar dene", variant: .secondary, block: true) { start(.play) }
                AppButton(round.isLast ? "Turu bitir" : "Sıradaki", block: true) {
                    if let answers = round.finishPattern() { model.completeSpecial(.rhythmtap, answers: answers) }
                }
            }
        } else {
            VStack(spacing: Space.s2) {
                tapArea
                HStack(spacing: Space.s2) {
                    AppButton("Dinle", variant: .secondary, block: true, disabled: round.busy) { start(.listen) }
                    AppButton("Başla", block: true, disabled: round.busy) { start(.play) }
                }
            }
        }
    }

    private var tapArea: some View {
        let active = round.phase == .play || round.phase == .countin
        let enabled = round.phase == .play || round.phase == .countin
        return Text(round.tapLabel)
            .font(.ui(FontSize.xl, .heavy))
            .foregroundStyle(active ? CategoryColor.rhythm.text.color : ThemeColor.textFaint.color)
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(active ? accent.opacity(0.16 + Double(round.pulse % 2) * 0.12) : ThemeColor.fill.color))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(round.busy && round.phase != .listen ? accent.color : ThemeColor.border.color, lineWidth: 2))
            .animation(.linear(duration: 0.06), value: round.pulse)
            .contentShape(Rectangle())
            // Parmak değdiği an sayılır (web onPointerDown)
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { v in
                    if v.translation == .zero, enabled { tap() }
                })
            .accessibilityElement()
            .accessibilityLabel("Dokun")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { tap() }
    }

    // MARK: Akış
    private func start(_ mode: RhythmTapRound.Mode) {
        loop?.cancel()
        Sound.stopAll()
        let plan = round.start(mode, now: Sound.now)
        for c in plan.clicks { Sound.play(Sounds.click(strong: c.accent), at: c.at) }
        for b in plan.beats { Sound.play(Sounds.beat, at: b) }
        // Görsel sayma ve oynatma çizgisi duyulan anı izler
        let lat = Sound.latency
        loop = Task { @MainActor in
            while !Task.isCancelled {
                if round.tick(now: Sound.now - lat) { break }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    /// Dokunuş: hafif titreşim; duyulan sese göre ölçülür (dokunuş anından ses gecikmesi düşülür)
    private func tap() {
        guard round.phase == .play || round.phase == .countin else { return }
        Haptics.tap()
        round.tap(now: Sound.now - Sound.latency)
    }

    private func askExit() {
        loop?.cancel()
        if round.busy { Sound.stopAll() }
        round.interrupt()
        showExit = true
    }
}

/// Ritim şeridi: vuruş çizgileri, olması gereken anlar (turkuaz), sonuçta dokunuşlar (yeşil tam, amber yakın), kaçan
/// nota (kesikli kırmızı halka), fazla dokunuş (×); çalarken oynatma çizgisi (web RhythmTimeline)
struct RhythmTimelineView: View {
    let score: String
    let result: TapResult?
    let bpm: Int
    let progress: Double?

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let x = { (b: Double) -> Double in max(-0.25, min(4.25, b)) / 4 * w }
            let beatMs = 60000 / Double(bpm)
            ZStack(alignment: .topLeading) {
                ForEach(1...3, id: \.self) { b in
                    ThemeColor.borderStrong.color.frame(width: 1, height: h - 16).offset(x: x(Double(b)), y: 8)
                }
                ForEach(RhythmTap.onsets(score), id: \.self) { b in
                    RoundedRectangle(cornerRadius: 2).fill(CategoryColor.rhythm.base.opacity(0.9))
                        .frame(width: 4, height: 18).offset(x: x(b) - 2, y: 6)
                }
                if let r = result {
                    ForEach(Array(r.notes.enumerated()), id: \.offset) { _, n in
                        if let d = n.deltaMs {
                            Circle().fill(gradeColor(n.grade)).frame(width: 14, height: 14)
                                .offset(x: x(n.beat + Double(d) / beatMs) - 7, y: h - 8 - 14)
                        }
                        if n.grade == .miss {
                            Circle().strokeBorder(PaletteColor.red500.color, style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
                                .frame(width: 14, height: 14).offset(x: x(n.beat) - 7, y: h - 8 - 14)
                        }
                    }
                    ForEach(Array(r.extra.enumerated()), id: \.offset) { _, b in
                        Text("×").font(.ui(FontSize.md, .heavy)).foregroundStyle(PaletteColor.red500.color)
                            .offset(x: x(b) - 7, y: h - 6 - 16)
                    }
                }
                if let p = progress {
                    ThemeColor.text.color.frame(width: 2, height: h).offset(x: x(p * 4) - 1)
                }
            }
        }
        .frame(height: 56)
        .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fill.color))
        .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
        .accessibilityHidden(true)
    }

    private func gradeColor(_ g: TapGrade) -> Color {
        switch g {
        case .perfect: PaletteColor.green500.color
        case .good: PaletteColor.amber500.color
        case .miss: PaletteColor.red500.color
        }
    }
}
