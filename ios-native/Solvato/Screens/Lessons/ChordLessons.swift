// Çalışma › Akorlar dersleri: "Majör ve minör nasıl kurulur" (web MemoVisuals ChordMemoVisual, KeyIntervals) ve
// "Akor kartları" (web study/ChordsStudy.tsx: kök filtresi, çevrilen kart, şerit klavye). İçerik ve kurallar
// SolvatoCore ChordStudy / Diagrams'da (web'le altın tabloyla aynı). Şema klavyeye ve kartlardaki düğmelere dokununca akor
// çalar (birlikte ya da 200 ms arayla arpej).
import SolvatoCore
import SwiftUI

private func hexA(_ c: RGBA, _ byte: Int) -> Color { c.opacity(Double(byte) / 255).color }

/// Şema klavye (web KeyIntervals): dokununca akor çalınır
struct KeyIntervalsView: View {
    let semis: [Int]
    let color: RGBA
    var names: [String]?

    var body: some View {
        Button {
            // Notalar 200 ms arayla (web MemoVisuals KeyIntervals)
            Sound.play(Sounds.notes(semis.map { Pitch(name: Chords.pcKey[$0 % 12], octave: 4 + $0 / 12) }, gap: 0.2))
        } label: {
            DrawingView(drawing: Diagrams.keyIntervals(semis: semis, color: color, names: names))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Akoru dinle")
    }
}

/// Ders: Majör ve minör nasıl kurulur
struct ChordBuildLesson: View {
    let level: Int

    var body: some View {
        VStack(spacing: 10) {
            MemoCard(title: "Majör ve minör") {
                MemoSub("Kökten başla, birer tuş atlayarak üç nota bas. Kemerdeki sayı iki nota arasındaki yarım ses.")
                chordRow("Do majör", "C", [0, 4, 7], ["Do", "Mi", "Sol"], .violet500, "4 + 3 · parlak")
                chordRow("Do minör", "Cm", [0, 3, 7], ["Do", "Mi♭", "Sol"], .red400, "3 + 4 · hüzünlü")
            }
            MemoCard(title: "Formüller") {
                MemoSub("Her kökte aynı sayıları say. Örnekler Do'dan.").padding(.bottom, 4)
                formula("Majör", "C", "4 + 3", "Do – Mi – Sol", .violet500)
                formula("Minör", "Cm", "3 + 4", "Do – Mi♭ – Sol", .red400)
                if level >= 3 {
                    formula("Majör 7", "Cmaj7", "4 + 3 + 4", "Do – Mi – Sol – Si", .blue400)
                    formula("Dominant 7", "C7", "4 + 3 + 3", "Do – Mi – Sol – Si♭", .amber500)
                    formula("Minör 7", "Cm7", "3 + 4 + 3", "Do – Mi♭ – Sol – Si♭", .green400)
                }
                if level >= 4 {
                    formula("Eksik", "Cdim", "3 + 3", "Do – Mi♭ – Sol♭", .orange400)
                    formula("Artık", "Caug", "4 + 4", "Do – Mi – Sol#", .pink500)
                    formula("Yarı eksik", "Cm7♭5", "3 + 3 + 4", "Do – Mi♭ – Sol♭ – Si♭", .violet400)
                    formula("Eksik 7", "Cdim7", "3 + 3 + 3", "Do – Mi♭ – Sol♭ – Si♭♭", .orange500)
                    formula("sus2 / sus4", "Csus2 · Csus4", "2 + 5 · 5 + 2", "Do – Re – Sol · Do – Fa – Sol", .cyan400)
                    formula("9'lu / 13'lü", "C9 · C13", "dom. 7 + 9 · + 13", "Do – Mi – Sol – Si♭ – Re · Do – Mi – Si♭ – La", .amber400)
                }
                if level >= 2 {
                    MemoSub("Kök siyah tuş olsa da aynı: Re♭ majör = Re♭ – Fa – La♭ (4 + 3).").padding(.top, 8)
                }
            }
            MemoCard(title: "Yarım ses") {
                MemoSub("Yan yana iki tuş arası 1 yarım ses. Mi–Fa ve Si–Do arasında siyah tuş yok, aralarında da 1 yarım ses var.")
            }
        }
    }

    private func nameSym(_ name: String, _ sym: String, _ color: PaletteColor, _ weight: FontWeight) -> Text {
        Text(name).font(.ui(FontSize.md, weight)).foregroundColor(color.color)
            + Text(" ") + Text(sym).font(.mono(FontSize.xs)).foregroundColor(color.opacity(0.8))
    }

    private func chordRow(_ name: String, _ sym: String, _ semis: [Int], _ names: [String], _ color: PaletteColor, _ note: String) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                nameSym(name, sym, color, .heavy)
                Spacer(minLength: 0)
                Text(note).font(.ui(FontSize.xs)).foregroundStyle(ThemeColor.textMuted.color)
            }
            KeyIntervalsView(semis: semis, color: color.rgba, names: names)
        }
        .padding(.top, 10)
    }

    private func formula(_ name: String, _ sym: String, _ gaps: String, _ notes: String, _ color: PaletteColor) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                nameSym(name, sym, color, .bold).frame(maxWidth: .infinity, alignment: .leading)
                Text(gaps).font(.mono(FontSize.sm, .bold)).foregroundStyle(ThemeColor.textSoft.color).multilineTextAlignment(.trailing)
            }
            Text(notes).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .top) { ThemeColor.border.color.frame(height: 1) }
    }
}

/// Ders: Akor kartları (seviye sabit): kök filtresi ve kartlar; iPad'de iki sütun
struct ChordCardsLesson: View {
    let level: Int
    @State private var rootFilter: String?
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let active = ChordStudy.activeRoot(level: level, rootFilter: rootFilter)
        let cards = ChordStudy.filtered(level: level, rootFilter: rootFilter)
        VStack(alignment: .leading, spacing: 12) {
            FlowLayout(spacing: 6) {
                pill("Tümü", on: active == nil, hPad: 12, offColor: ThemeColor.textMuted.color) { rootFilter = "*" }
                ForEach(ChordStudy.roots(level: level), id: \.self) { r in
                    pill(r, on: active == r, hPad: 11, offColor: ThemeColor.textFaint.color) { rootFilter = r }
                }
            }
            if sizeClass == .regular {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(cards, id: \.chord.id) { ChordCardView(card: $0) }
                }
            } else {
                ForEach(cards, id: \.chord.id) { ChordCardView(card: $0) }
            }
        }
    }

    private func pill(_ t: String, on: Bool, hPad: Double, offColor: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(t)
                .font(.mono(FontSize.sm, .bold))
                .foregroundStyle(on ? ThemeColor.violetText.color : offColor)
                .padding(.vertical, 5)
                .padding(.horizontal, hPad)
                .background(Capsule().fill(on ? PaletteColor.violet500.opacity(0.2) : ThemeColor.fill.color))
                .overlay(Capsule().strokeBorder(on ? PaletteColor.violet500.opacity(0.4) : ThemeColor.border.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// Çevrilen akor kartı: önde porte, şerit klavye, formül, parmak; arkada akor yapısı ve örnek diziler
struct ChordCardView: View {
    let card: ChordCardInfo
    @State private var flipped = false
    @State private var playing = false

    private var c: RGBA { card.color }

    var body: some View {
        FlipCard(flipped: flipped, front: front, back: back)
            .frame(height: 470)
        .contentShape(Rectangle())
        .onTapGesture { flipped.toggle() }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(flipped ? "Kartın önüne dön" : "Örnek diziler için çevir")
        .padding(.bottom, 4)
    }

    /// Akoru çalar: birlikte ya da 200 ms arayla arpej (web ChordCard playChord); çalarken düğme renklenir
    private func play(arpeggio: Bool) {
        guard !playing else { return }
        playing = true
        let n = card.chord.notes
        Sound.play(Sounds.notes(zip(card.playKeys, n).map { Pitch(name: $0, octave: $1.octave) }, gap: arpeggio ? 0.2 : 0))
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(arpeggio ? n.count * 200 + 300 : 600))
            playing = false
        }
    }

    private func face<C: View>(border: Int, glow: Int, glowRadius: Double, padding: Double, spacing: Double, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: spacing) { content() }
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.surface.color))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(hexA(c, border), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .shadow(color: hexA(c, glow), radius: glowRadius / 2)
    }

    private func caption(_ t: String, tracking: Double = 0.07) -> some View {
        Text(t.uppercased(with: Locale(identifier: "tr")))
            .font(.ui(FontSize.xs, .bold))
            .tracking(em: tracking, size: FontSize.xs)
            .foregroundStyle(ThemeColor.textMuted.color)
    }

    private func inset<C: View>(h: Double, v: Double, @ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, h)
            .padding(.vertical, v)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.bg.color))
            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }

    private var front: some View {
        face(border: 0x33, glow: 0x18, glowRadius: 24, padding: 16, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                (Text("\(card.rootTR) \(card.nameTR) ").font(.ui(FontSize.md, .heavy)).foregroundColor(ThemeColor.text.color)
                    + Text("(\(card.chord.symbol))").font(.ui(FontSize.xs, .semibold)).foregroundColor(ThemeColor.textMuted.color))
                    .tracking(em: -0.02, size: FontSize.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    play(arpeggio: false)
                } label: {
                    Canvas { ctx, size in
                        let s = size.width / 24
                        var p = Path()
                        p.move(to: CGPoint(x: 5 * s, y: 3 * s))
                        p.addLine(to: CGPoint(x: 19 * s, y: 12 * s))
                        p.addLine(to: CGPoint(x: 5 * s, y: 21 * s))
                        p.closeSubpath()
                        ctx.fill(p, with: .color(playing ? c.color : ThemeColor.textFaint.color))
                    }
                    .frame(width: 13, height: 13)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: Radius.sm).fill(playing ? hexA(c, 0x33) : ThemeColor.fillStrong.color))
                    .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(playing ? c.color : ThemeColor.fillStronger.color, lineWidth: 1))
                    .animation(.easeInOut(duration: 0.15), value: playing)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Akoru dinle")
            }
            ChordStaffView(chord: card.chord, color: .color(c), maxWidth: 280)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.horizontal, 8)
                .padding(.bottom, 2)
                .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.bg.color))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            inset(h: 12, v: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    caption("Piyano Tuşları", tracking: 0.08)
                    ChordPianoStrip(card: card)
                }
            }
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    caption("Formül")
                    Text(card.interval).font(.ui(FontSize.sm, .semibold)).foregroundStyle(c.color)
                        .lineHeight(1.4, size: FontSize.sm)
                }
                .padding(.vertical, 9)
                .padding(.horizontal, 11)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(RoundedRectangle(cornerRadius: Radius.md).fill(hexA(c, 0x0E)))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(hexA(c, 0x22), lineWidth: 1))
                VStack(spacing: 3) {
                    caption("Parmak")
                    HStack(spacing: 4) {
                        ForEach(Array(card.fingers.enumerated()), id: \.offset) { _, f in
                            Text(f).font(.monoFixed(FontSize.sm, .heavy)).foregroundStyle(c.color)
                                .frame(width: 22, height: 22)
                                .background(RoundedRectangle(cornerRadius: Radius.sm).fill(hexA(c, 0x22)))
                                .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(hexA(c, 0x44), lineWidth: 1))
                        }
                    }
                }
                .padding(.vertical, 9)
                .padding(.horizontal, 11)
                .frame(minWidth: 72)
                .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fill.color))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            }
            .fixedSize(horizontal: false, vertical: true)
            Text("Örnek diziler için çevir →")
                .font(.ui(FontSize.xs))
                .foregroundStyle(ThemeColor.textMuted.color)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, -4)
        }
    }

    private var back: some View {
        face(border: 0x44, glow: 0x28, glowRadius: 28, padding: 18, spacing: 12) {
            HStack {
                Text("Akor yapısı ve örnek diziler").font(.ui(FontSize.md, .heavy)).foregroundStyle(ThemeColor.text.color)
                Spacer(minLength: 0)
                Text("← geri").font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
            }
            inset(h: 14, v: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    caption("Akor Yapısı").padding(.bottom, 8)
                    FlowLayout(spacing: 6) {
                        ForEach(Array(zip(card.chord.noteNames, card.intervalNames).enumerated()), id: \.offset) { _, pair in
                            let nc = NoteColors.byName[pair.0]?.rgba ?? c
                            VStack(spacing: 3) {
                                Text(pair.0).font(.mono(FontSize.md, .heavy)).foregroundStyle(nc.color)
                                if !pair.1.isEmpty {
                                    Text(pair.1).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                            .background(RoundedRectangle(cornerRadius: Radius.md).fill(hexA(nc, 0x18)))
                            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(hexA(nc, 0x35), lineWidth: 1))
                        }
                    }
                    .padding(.bottom, 8)
                    Text("\(card.chord.formula) · \(card.interval)")
                        .font(.ui(FontSize.sm))
                        .foregroundStyle(ThemeColor.textSubtle.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            inset(h: 14, v: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    caption("Sık kullanılan diziler").padding(.bottom, 2)
                    ForEach(Array(card.progressions.enumerated()), id: \.offset) { i, p in
                        HStack(spacing: 8) {
                            Text("\(i + 1)").font(.ui(FontSize.sm, .bold)).foregroundStyle(c.color)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 6)
                                .background(RoundedRectangle(cornerRadius: Radius.xs).fill(hexA(c, 0x18)))
                                .overlay(RoundedRectangle(cornerRadius: Radius.xs).strokeBorder(hexA(c, 0x33), lineWidth: 1))
                            Text(p).font(.mono(FontSize.sm, .bold)).tracking(em: 0.05, size: FontSize.sm)
                                .foregroundStyle(ThemeColor.textSecondary.color)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxHeight: .infinity)
            Button {
                play(arpeggio: true)
            } label: {
                HStack(spacing: 7) {
                    Icon(.speaker, size: 15).padding(.trailing, 6)
                    Text("Arpej Dinle").font(.ui(FontSize.sm, .bold))
                }
                .foregroundStyle(c.color)
                .frame(maxWidth: .infinity)
                .padding(11)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(LinearGradient(colors: [hexA(c, 0x33), hexA(c, 0x18)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(hexA(c, 0x44), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}

/// İki yüzlü kart: dönüş web'deki eğriyle; yüzler dönüşün yarısında (90°) yer değiştirir (web backface-visibility)
private struct FlipCard<Front: View, Back: View>: View {
    let flipped: Bool
    let front: Front
    let back: Back

    private static var curve: Curve { Curve(0.16, 1, 0.3, 1) }
    private static var duration: Double { 0.55 }

    var body: some View {
        let turn = Animation.timingCurve(0.16, 1, 0.3, 1, duration: Self.duration)
        let swap = Animation.linear(duration: 0).delay(Self.duration * Self.curve.time(reaching: 0.5))
        ZStack {
            front
                .animation(swap) { $0.opacity(flipped ? 0 : 1) }
                .animation(turn) { $0.rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.5) }
            back
                .animation(swap) { $0.opacity(flipped ? 1 : 0) }
                .animation(turn) { $0.rotation3DEffect(.degrees(flipped ? 0 : -180), axis: (x: 0, y: 1, z: 0), perspective: 0.5) }
        }
    }
}

/// Bir oktavlık şerit klavye: akorun tuşları renkli ve adlı (web ChordPianoStrip)
private struct ChordPianoStrip: View {
    let card: ChordCardInfo

    var body: some View {
        let c = card.color
        let labels = card.keyLabels
        let keys = card.chord.keys
        GeometryReader { geo in
            let w = geo.size.width / 7
            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(Array(["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"].enumerated()), id: \.offset) { i, n in
                        let on = keys.contains(n)
                        let shape = UnevenRoundedRectangle(bottomLeadingRadius: 5, bottomTrailingRadius: 5)
                        ZStack(alignment: .bottom) {
                            shape.fill(
                                on
                                    ? LinearGradient(colors: [hexA(c, 0x44), hexA(c, 0x22)], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [PaletteColor.slate50.color, PaletteColor.slate200.color], startPoint: .top, endPoint: .bottom))
                            if !on {
                                // inset 0 -3px 0 rgba(0,0,0,0.15)
                                Color.black.opacity(0.15).frame(height: 3).clipShape(shape)
                            }
                            if on {
                                Text(labels[n] ?? n).font(.uiFixed(FontSize.xs, .heavy)).foregroundStyle(c.color).padding(.bottom, 4)
                            }
                        }
                        .overlay(shape.stroke(PaletteColor.slate800.color, lineWidth: 1))
                        .overlay { if on { shape.stroke(c.color, lineWidth: 1.5) } }
                        .shadow(color: on ? hexA(c, 0x66) : .clear, radius: 6)
                        .frame(width: w)
                        .zIndex(on ? 1 : 0)
                    }
                }
                ForEach(Array([("Do#", 0), ("Re#", 1), ("Fa#", 3), ("Sol#", 4), ("La#", 5)].enumerated()), id: \.offset) { _, bk in
                    let on = keys.contains(bk.0)
                    let shape = UnevenRoundedRectangle(bottomLeadingRadius: 4, bottomTrailingRadius: 4)
                    ZStack(alignment: .bottom) {
                        shape.fill(on ? c.color : Piano.diagramBlack.color)
                        if on {
                            Text(labels[bk.0] ?? bk.0).font(.uiFixed(FontSize.xs, .heavy)).foregroundStyle(PaletteColor.slate900.color)
                                .fixedSize()
                                .padding(.bottom, 2)
                        }
                    }
                    .overlay(shape.stroke(on ? c.color : PaletteColor.slate900.color, lineWidth: 1))
                    .shadow(color: on ? hexA(c, 0x88) : .clear, radius: 5)
                    .frame(width: w * 0.62, height: geo.size.height * 0.6)
                    .offset(x: (Double(bk.1) + 1) * w - w * 0.32)
                    .zIndex(2)
                }
            }
        }
        .frame(height: 56)
        .frame(maxWidth: 280)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Piyano tuşları: " + card.stripLabels.joined(separator: ", "))
    }
}
