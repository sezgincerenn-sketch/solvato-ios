// Akor düellosu: kurulum (iki isim, akor seviyesi, Başlayalım) → oyun (ekran ikiye bölünür, üst yarı karşıdaki
// oyuncu için 180° ters; her yarıda akor ve şıklar) → sonuç (kazanan, skor, Çık / Rövanş). Web
// src/screens/ChordDuel.tsx. Kurallar SolvatoCore DuelGame'de (sorular web'le altın tabloyla aynı). Ses/titreşim 0.6'da.
import SolvatoCore
import SwiftUI

struct ChordDuelScreen: View {
    let model: AppModel
    @State private var names = DuelGame.defaultNames
    @State private var level: Int
    @State private var game: DuelGame?
    @State private var confirmExit = false

    init(model: AppModel) {
        self.model = model
        _level = State(initialValue: model.settings.effectiveChordLevel)
    }

    var body: some View {
        ZStack {
            ThemeColor.bg.color.ignoresSafeArea()
            if let g = game {
                if g.finished { result(g) } else { play(g) }
            } else {
                setup
            }
            if confirmExit, let g = game {
                exitDialog(g)
            }
        }
        .onChange(of: model.exitRequest) { _, _ in
            if let g = game, !g.finished { confirmExit = true } else { model.back() }
        }
    }

    private func start() {
        game = model.newDuel(level: level)
    }

    // MARK: Kurulum
    private var setup: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScreenHeader(title: "Akor düellosu", flush: true) { model.back() }
            Text(DuelGame.intro)
                .font(.ui(FontSize.sm))
                .foregroundStyle(ThemeColor.textMuted.color)
                .lineHeight(1.5, size: FontSize.sm)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(0..<2, id: \.self) { i in
                TextField("", text: Binding(get: { names[i] }, set: { names[i] = String($0.prefix(DuelGame.nameLimit)) }))
                    .font(.ui(FontSize.md))
                    .foregroundStyle(ThemeColor.text.color)
                    .autocorrectionDisabled()
                    .accessibilityLabel("\(i + 1). oyuncunun adı")
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fillStrong.color))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(DuelGame.colors[i].color, lineWidth: 1.5))
            }
            Text("Akor seviyesi").font(.ui(FontSize.md, .semibold)).foregroundStyle(ThemeColor.text.color).padding(.top, 6)
            Segmented(value: level, options: (1...4).map { ($0, Chords.levelLabels[$0]!) }, columns: 4, size: .sm) { level = $0 }
            Spacer(minLength: 0)
            Button(action: start) {
                Text("Başlayalım")
                    .font(.ui(FontSize.md, .bold))
                    .foregroundStyle(Brand.onPrimary.color)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(CSSLinearGradient(.primaryFlat).clipShape(RoundedRectangle(cornerRadius: Radius.lg)))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Oyun
    private func play(_ g: DuelGame) -> some View {
        let q = g.current!
        return VStack(spacing: 0) {
            DuelHalf(q: q, name: names[1], score: g.scores[1], color: DuelGame.colors[1], flipped: true, locked: g.locked[1], reveal: g.reveal, picked: g.picked[1]) {
                pick(1, $0)
            }
            HStack {
                Button("Bitir") { confirmExit = true }
                    .font(.ui(FontSize.xs))
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .padding(6)
                Spacer(minLength: 0)
                Text(g.counter).font(.mono(FontSize.xs, .bold)).foregroundStyle(ThemeColor.textMuted.color)
                Spacer(minLength: 0)
                Color.clear.frame(width: 40, height: 1)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 14)
            .background(ThemeColor.fill.color)
            DuelHalf(q: q, name: names[0], score: g.scores[0], color: DuelGame.colors[0], flipped: false, locked: g.locked[0], reveal: g.reveal, picked: g.picked[0]) {
                pick(0, $0)
            }
        }
    }

    private func pick(_ p: Int, _ id: String) {
        guard var g = game else { return }
        let r = g.pick(p, id)
        game = g
        guard r == .correct || r == .bothWrong else { return }
        let at = g.index
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(DuelGame.revealDelay))
            guard var cur = game, cur.index == at, cur.reveal else { return }
            cur.advance()
            game = cur
        }
    }

    // MARK: Sonuç
    private func result(_ g: DuelGame) -> some View {
        VStack(spacing: 10) {
            Text("Düello bitti").font(.ui(FontSize.md)).foregroundStyle(ThemeColor.textMuted.color)
            Text(g.resultTitle(names: names))
                .font(.ui(FontSize.xxl, .heavy))
                .foregroundStyle(g.winner.map { DuelGame.colors[$0].color } ?? ThemeColor.text.color)
                .multilineTextAlignment(.center)
            Text(g.scoreText).font(.mono(FontSize.xl, .heavy)).foregroundStyle(ThemeColor.text.color)
            HStack(spacing: 10) {
                Button { model.back() } label: {
                    Text("Çık").font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.textSecondary.color)
                        .frame(maxWidth: .infinity).padding(14)
                        .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fillStrong.color))
                        .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
                }
                Button(action: start) {
                    Text("Rövanş").font(.ui(FontSize.md, .bold)).foregroundStyle(Brand.onPrimary.color)
                        .frame(maxWidth: .infinity).padding(14)
                        .background(CSSLinearGradient(.primaryFlat).clipShape(RoundedRectangle(cornerRadius: Radius.md)))
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 320)
            .padding(.top, 16)
        }
        .padding(24)
    }

    private func exitDialog(_ g: DuelGame) -> some View {
        ZStack {
            ThemeColor.scrim.color.ignoresSafeArea().onTapGesture {}
            VStack(spacing: 0) {
                Text("Düellodan çıkılsın mı?").font(.ui(FontSize.lg, .heavy)).foregroundStyle(ThemeColor.text.color)
                Text(g.exitText)
                    .font(.ui(FontSize.sm))
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                    .padding(.bottom, 16)
                HStack(spacing: 10) {
                    AppButton("Devam et", block: true) { confirmExit = false }
                    AppButton("Çık", variant: .secondary, block: true) { model.back() }
                }
            }
            .padding(20)
            .frame(maxWidth: 340)
            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.surface.color))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            .padding(24)
            .accessibilityAddTraits(.isModal)
            .accessibilityLabel("Düellodan çık")
        }
    }
}

/// Bir oyuncunun yarısı: ad ve skor, akor (porte ya da basılı tuşlar), 2×2 şık
private struct DuelHalf: View {
    let q: DuelQuestion
    let name: String
    let score: Int
    let color: PaletteColor
    let flipped: Bool
    let locked: Bool
    let reveal: Bool
    let picked: String?
    let onPick: (String) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(name).font(.ui(FontSize.md, .heavy)).foregroundStyle(color.color)
                Spacer(minLength: 0)
                Text("\(score)").font(.mono(FontSize.xl, .heavy)).foregroundStyle(ThemeColor.text.color)
            }
            ZStack {
                ThemeColor.bg.color
                if q.type == .staff {
                    ChordStaffView(chord: q.chord, color: .color((reveal ? PaletteColor.green500 : .violet500).rgba), maxWidth: 230)
                } else {
                    MultiPianoView(
                        keys: Piano.multiKeys(selected: [], correctKeys: [], showResult: false, lit: Chords.litKeys(q.chord)), disabled: true
                    ) { _ in }
                    .padding(.top, 4)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 18)
                    .scaleEffect(0.92)
                }
            }
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                ForEach(q.options, id: \.id) { o in option(o) }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .overlay(alignment: flipped ? .bottom : .top) { color.color.frame(height: 3) }
        .rotationEffect(.degrees(flipped ? 180 : 0))
        .frame(maxHeight: .infinity)
    }

    private func option(_ o: Chord) -> some View {
        let correct = o.id == q.chord.id
        let mine = picked == o.id
        let bg: Color = reveal && correct ? PaletteColor.green500.opacity(0.18) : mine ? PaletteColor.red500.opacity(0.15) : ThemeColor.fill.color
        let bd: Color = reveal && correct ? PaletteColor.green500.color : mine ? PaletteColor.red500.color : ThemeColor.border.color
        return Button { onPick(o.id) } label: {
            VStack(spacing: 0) {
                Text(o.name).font(.ui(FontSize.sm, .bold))
                Text(o.symbol).font(.mono(FontSize.xs)).opacity(0.7)
            }
            .foregroundStyle(ThemeColor.textSoft.color)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(RoundedRectangle(cornerRadius: Radius.md).fill(bg))
            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(bd, lineWidth: 1))
            .opacity(locked && !reveal ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(locked || reveal)
        .accessibilityLabel("\(o.name) \(o.symbol)")
    }
}
