// Çalışma › Notalar dersleri: Sol/Fa anahtarı notaları ve Diyez-bemol (‹ › ile gezinme, porte, mini piyano), ezber
// cümleleri (renkli porte, tekerleme, aynı renkte klavye), diyez/bemol ezber kartları. Web src/screens/study/
// NotesStudy.tsx ve shared.tsx (MiniPiano). Kurallar ve veri SolvatoCore NoteStudy / Mnemonics'te. Oklarla geçince,
// tuşlara ve "Dinle"ye dokununca notalar çalar.
import SolvatoCore
import SwiftUI

/// Ders: Sol / Fa anahtarı notaları ve Diyez-bemol (web StaffStudy)
struct StaffStudyLesson: View {
    @State private var st: StaffStudyState

    init(clef: Clef, accidentals: Bool) {
        _st = State(initialValue: StaffStudyState(clef: clef, accidentalsMode: accidentals))
    }

    var body: some View {
        let color = NoteColors.byName[st.note.name]
        VStack(spacing: 16) {
            if st.accidentalsMode {
                Segmented(value: st.acc ?? .sharp, options: [(Accidental.sharp, "♯ Diyez"), (.flat, "♭ Bemol")], size: .sm) { st.setAcc($0) }
            }
            HStack(spacing: 10) {
                arrow("‹", "Önceki nota") { go(-1) }
                VStack(spacing: 0) {
                    Text(st.counter).font(.mono(FontSize.xs)).foregroundStyle(ThemeColor.textSubtle.color)
                    Text("Oklarla ya da piyanoda bir tuşa basarak gez")
                        .font(.ui(FontSize.sm))
                        .foregroundStyle(ThemeColor.textMuted.color)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                arrow("›", "Sonraki nota") { go(1) }
            }
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Text(st.badge)
                        .font(.ui(FontSize.lg, .heavy))
                        .foregroundStyle(color?.color ?? ThemeColor.violetText.color)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: Radius.md).fill((color ?? .violet600).opacity(Double(0x22) / 255)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(st.title).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.textSoft.color)
                        Text(st.desc).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                MusicalStaffView(clef: st.clef, noteY: st.note.y, ledgerLines: st.note.ledger, accidental: st.acc)
                    .frame(maxWidth: .infinity)
                    .background(ThemeColor.staffPanel.color)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
                MiniPiano(st: st, color: (color ?? .violet400).rgba) { n, o, sharp in st.pick(n, o, sharp: sharp) }
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.surface.color))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
        }
    }

    /// ‹ › ile geçer ve yeni notayı çalar (web go)
    private func go(_ delta: Int) {
        st.go(delta)
        Sound.note(st.playPitch.name, octave: st.playPitch.octave)
    }

    private func arrow(_ t: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(t)
                .font(.ui(FontSize.xl))
                .foregroundStyle(ThemeColor.textSecondary.color)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fillStrong.color))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Seçili notayı gösteren sabit klavye (web shared.tsx MiniPiano)
private struct MiniPiano: View {
    let st: StaffStudyState
    let color: RGBA
    let onPick: (String, Int, Bool) -> Void

    /// Tuşun sesi her zaman; geçilebilen tuşta o notaya geçilir (web shared.tsx press)
    private func press(_ n: String, _ o: Int, _ sharp: Bool) {
        Sound.note(sharp ? n + "#" : n, octave: o)
        if st.available(n, o, sharp: sharp) { onPick(n, o, sharp) }
    }

    var body: some View {
        let hi = st.highlighted
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Piyanoda:").font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
                Spacer(minLength: 0)
                Text(st.keyName)
                    .font(.ui(FontSize.sm, .bold))
                    .foregroundStyle(color.color)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 10)
                    .background(RoundedRectangle(cornerRadius: Radius.sm).fill(color.opacity(Double(0x22) / 255).color))
                    .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(color.opacity(Double(0x55) / 255).color, lineWidth: 1))
            }
            GeometryReader { geo in
                let kw = geo.size.width / Double(st.whites)
                ZStack(alignment: .topLeading) {
                    ForEach(0..<st.whites, id: \.self) { i in
                        let n = NoteStudy.pianoOrder[i % 7]
                        let o = st.startOctave + i / 7
                        let on = hi.name == n && hi.octave == o && !hi.black
                        let ok = st.available(n, o, sharp: false)
                        Button { press(n, o, false) } label: {
                            ZStack(alignment: .bottom) {
                                Rectangle().fill(on ? color.color : ok ? PaletteColor.slate50.color : PaletteColor.slate300.color)
                                Text(n == "Do" ? "\(n)\(o)" : n)
                                    .font(.ui(FontSize.xs, .bold))
                                    .foregroundStyle(on ? PaletteColor.white.color : ok ? PaletteColor.slate600.color : PaletteColor.slate500.color)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .padding(.bottom, 4)
                            }
                            .overlay(SidesAndBottom().stroke(PaletteColor.slate400.color, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .frame(width: kw, height: geo.size.height)
                        .offset(x: Double(i) * kw)
                        .accessibilityLabel("\(n)\(o)")
                    }
                    ForEach((0..<(st.whites - 1)).filter { NoteStudy.blackAfter.contains($0 % 7) }, id: \.self) { i in
                        let n = NoteStudy.pianoOrder[i % 7]
                        let o = st.startOctave + i / 7
                        let on = hi.name == n && hi.octave == o && hi.black
                        let ok = st.available(n, o, sharp: true)
                        let shape = UnevenRoundedRectangle(bottomLeadingRadius: 4, bottomTrailingRadius: 4)
                        Button { press(n, o, true) } label: {
                            shape.fill(on ? color.color : Piano.diagramBlack.color)
                                .overlay { if on { shape.stroke(PaletteColor.white.color, lineWidth: 2) } }
                        }
                        .buttonStyle(.plain)
                        .shadow(color: on ? color.color : .clear, radius: 5)
                        .opacity(on || ok || !st.accidentalsMode ? 1 : 0.55)
                        .frame(width: kw * 0.6, height: geo.size.height * 0.6)
                        .offset(x: Double(i + 1) * kw - kw * 0.3)
                        .accessibilityLabel("\(n)#\(o)")
                    }
                }
            }
            .frame(height: 96)
            .background(ThemeColor.bg.color)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            Text(st.hint)
                .font(.ui(FontSize.xs))
                .foregroundStyle(ThemeColor.textFaint.color)
                .lineHeight(1.5, size: FontSize.xs)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Üst kenarı olmayan çerçeve (web border-top: none)
private struct SidesAndBottom: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let i = 0.5
        p.move(to: CGPoint(x: r.minX + i, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX + i, y: r.maxY - i))
        p.addLine(to: CGPoint(x: r.maxX - i, y: r.maxY - i))
        p.addLine(to: CGPoint(x: r.maxX - i, y: r.minY))
        return p
    }
}

/// Ders: Ezber cümleleri (web MnemonicsStudy)
struct MnemonicsLesson: View {
    let clef: Clef

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Mnemonics.cards(clef), id: \.title) { MnemonicCardView(card: $0, clef: clef) }
        }
    }
}

private struct MnemonicCardView: View {
    let card: MnemonicCard
    let clef: Clef

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(card.cardTitle).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color)
                Spacer(minLength: 0)
                Button {
                    // Notalar 260 ms arayla (web MemoCard playAll)
                    Sound.play(Sounds.notes(card.pitches(clef), gap: 0.26))
                } label: {
                    HStack(spacing: 5) {
                        Icon(.speaker, size: 14)
                        Text("Dinle").font(.ui(FontSize.sm, .bold))
                    }
                    .foregroundStyle(ThemeColor.violetText.color)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(RoundedRectangle(cornerRadius: Radius.sm).fill(PaletteColor.violet500.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(PaletteColor.violet500.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Notaları sırayla çal")
            }
            .padding(.bottom, 4)
            DrawingView(drawing: Mnemonics.staff(card, clef: clef))
                // Notaya dokununca çalar (web MemoCard: her notanın <g onClick>'i); çizim 300×118 kutuya sığdırılmış
                .overlay {
                    GeometryReader { g in
                        Color.clear.contentShape(Rectangle()).onTapGesture { p in
                            let k = min(g.size.width / 300, g.size.height / 118)
                            let x = (Double(p.x) - (Double(g.size.width) - 300 * k) / 2) / k
                            if let i = Mnemonics.noteIndex(card, x: x) {
                                let pitch = card.pitches(clef)[i]
                                Sound.note(pitch.name, octave: pitch.octave)
                            }
                        }
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("\(card.title): \(card.noteNames.joined(separator: ", "))")
            mnemonicLine
                .font(.ui(FontSize.md))
                .foregroundStyle(ThemeColor.textSecondary.color)
                .lineHeight(1.4, size: FontSize.md)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            keyboard.padding(.top, 10)
        }
        .padding(.top, 14)
        .padding(.horizontal, 14)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.surface.color))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }

    /// Tekerleme: her kelimenin notayı veren hecesi o notanın renginde, kalın
    private var mnemonicLine: Text {
        var out = Text("")
        var c = 0
        for (i, w) in card.words.enumerated() {
            if i > 0 { out = out + Text(" ") }
            if !w.0.isEmpty {
                let color = c < card.letterColors.count ? card.letterColors[c] : .violet400
                c += 1
                out = out + Text(w.0).font(.ui(FontSize.md, .heavy)).foregroundColor(color.color)
            }
            out = out + Text(w.1)
        }
        return out
    }

    private var keyboard: some View {
        GeometryReader { geo in
            let w = geo.size.width / 7
            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(NoteStudy.pianoOrder, id: \.self) { n in
                        let i = card.noteNames.firstIndex(of: n)
                        let c = i.map { card.color($0) }
                        Button {
                            Sound.note(n, octave: 4)
                        } label: {
                            ZStack(alignment: .bottom) {
                                Rectangle().fill(c?.color ?? PaletteColor.slate50.color)
                                Text(n).font(.ui(FontSize.xs, .heavy))
                                    .foregroundStyle(c != nil ? PaletteColor.slate900.color : ThemeColor.textMuted.color)
                                    .padding(.bottom, 3)
                            }
                            .overlay(SidesAndBottom().stroke(PaletteColor.slate400.color, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .frame(width: w)
                        .accessibilityLabel("\(n) tuşu")
                    }
                }
                ForEach(NoteStudy.blackAfter, id: \.self) { b in
                    UnevenRoundedRectangle(bottomLeadingRadius: 3, bottomTrailingRadius: 3)
                        .fill(Piano.diagramBlack.color)
                        .frame(width: w * 0.6, height: geo.size.height * 0.52)
                        .offset(x: Double(b + 1) * w - w * 0.3)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(height: 46)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
    }
}

/// Diyez ve bemol dersinin alt kısmı (web AccidentalMemo)
struct AccidentalMemoView: View {
    @State private var active: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DİYEZ ♯ VE BEMOL ♭")
                .font(.ui(FontSize.xs, .bold))
                .tracking(em: 0.08, size: FontSize.xs)
                .foregroundStyle(ThemeColor.textMuted.color)
            VStack(spacing: 8) {
                card {
                    cardTitle("Kural")
                    (Text("♯ diyez notayı yarım ses ") + Text("yükseltir").font(.ui(FontSize.sm, .bold))
                        + Text(" (sağdaki tuşa), ♭ bemol ") + Text("alçaltır").font(.ui(FontSize.sm, .bold))
                        + Text(" (soldaki tuşa). İşaret notanın önüne yazılır. Mi–Fa ve Si–Do arasında siyah tuş yoktur."))
                        .modifier(BodyText())
                }
                card {
                    cardTitle("Diyez ve bemol sırası")
                    order(AccidentalMemoContent.sharpOrder, "♯")
                    order(AccidentalMemoContent.flatOrder, "♭")
                    Text("Bemol sırası, diyez sırasının tersidir.").modifier(BodyText(color: ThemeColor.textMuted.color)).padding(.top, 6)
                }
                card {
                    cardTitle("Siyah tuşlar — dokun ve dinle")
                    Text("Her siyah tuşun iki adı vardır (aynı ses).").modifier(BodyText())
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(AccidentalMemoContent.blackKeys, id: \.self) { k in
                            Button {
                                active = k
                                Sound.note(k, octave: 4)
                            } label: {
                                Text(Accidentals.blackKeyLabel(k))
                                    .font(.ui(FontSize.sm, .bold))
                                    .foregroundStyle(ThemeColor.textSoft.color)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: Radius.md)
                                            .fill(active == k ? PaletteColor.violet600.opacity(0.3) : ThemeColor.bg.color))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Radius.md)
                                            .strokeBorder(active == k ? PaletteColor.violet400.color : ThemeColor.border.color, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private struct BodyText: ViewModifier {
        var color: Color?
        func body(content: Content) -> some View {
            content
                .font(.ui(FontSize.sm))
                .foregroundStyle(color ?? ThemeColor.textSecondary.color)
                .lineHeight(1.6, size: FontSize.sm)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func cardTitle(_ t: String) -> some View {
        Text(t).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.textSoft.color).lineHeight(1.6, size: FontSize.md)
    }

    private func card<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) { c() }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.surface.color))
            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }

    private func order(_ names: [String], _ sym: String) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(names, id: \.self) { n in
                Text(n + sym)
                    .font(.ui(FontSize.sm, .bold))
                    .foregroundStyle(ThemeColor.violetTextSoft.color)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(RoundedRectangle(cornerRadius: Radius.sm).fill(PaletteColor.violet600.opacity(0.18)))
            }
        }
        .padding(.top, 6)
    }
}
