// Piyano klavyeleri ekranda: soru turu klavyesi (QuizPianoView) ve akor klavyesi (MultiPianoView).
// Tuş listesi, konumlar, renkler ve yazılar SolvatoCore/Piano'dan gelir (web'le aynı olduğu testli); burada yalnızca
// çizilir ve dokunma iletilir. Tuşa basınca notası çalar (soru klavyesinde hafif titreşim de).
import SolvatoCore
import SwiftUI

/// Alt köşeleri yuvarlak dikdörtgen (CSS border-radius: 0 0 r r)
private struct KeyShape: Shape {
    let radius: Double
    func path(in rect: CGRect) -> Path {
        Path(
            roundedRect: rect,
            cornerRadii: RectangleCornerRadii(topLeading: 0, bottomLeading: radius, bottomTrailing: radius, topTrailing: 0))
    }
}

/// Bir tuşun yüzeyi: gradyan, iç basma gölgeleri, kenarlık, dış parıltı
private struct KeyFace: View {
    let look: KeyLook
    let radius: Double

    var body: some View {
        let shape = KeyShape(radius: radius)
        shape
            .fill(LinearGradient(colors: [look.top.color, look.bottom.color], startPoint: .top, endPoint: .bottom))
            .overlay {
                // CSS inset gölge (bulanıksız): kenarda düz bir şerit
                ZStack {
                    ForEach(Array(look.shadows.filter(\.inset).enumerated()), id: \.offset) { _, s in
                        GeometryReader { g in
                            let c = s.color.color
                            if s.y != 0 {
                                c.frame(height: abs(s.y)).frame(maxHeight: .infinity, alignment: s.y < 0 ? .bottom : .top)
                            }
                            if s.x != 0 {
                                c.frame(width: abs(s.x)).frame(maxWidth: .infinity, alignment: s.x < 0 ? .trailing : .leading)
                            }
                            Color.clear.frame(width: g.size.width, height: g.size.height)
                        }
                    }
                }
                .clipShape(shape)
            }
            .overlay { if let b = look.border { shape.stroke(b.color, lineWidth: 1) } }
            .background {
                ForEach(Array(look.shadows.filter { !$0.inset }.enumerated()), id: \.offset) { _, s in
                    shape.fill(s.color.color).blur(radius: s.blur / 2).opacity(1)
                }
            }
    }
}

/// Tuş yazıları. Web'deki gibi yalnız boşlukta alt satıra geçer ("Orta Do" → "Orta / Do"), kelimenin ortasında
/// bölünmez ("Ort / a / Do" olmaz); dar tuşta kelime sığmazsa taşar.
private struct KeyLabels: View {
    let labels: [KeyLabel]
    var body: some View {
        ForEach(Array(labels.enumerated()), id: \.offset) { _, l in
            let font = Font.uiFixed(l.size, FontWeight(rawValue: l.weight) ?? .regular)
            ViewThatFits(in: .horizontal) {
                Text(l.text).fixedSize()
                VStack(spacing: 0) {
                    ForEach(Array(l.text.split(whereSeparator: { $0 == " " || $0 == "\n" }).enumerated()), id: \.offset) { _, w in
                        Text(String(w)).fixedSize()
                    }
                }
            }
            .font(font)
            .foregroundStyle(l.color.color)
            .multilineTextAlignment(.center)
            .lineSpacing(0)
        }
    }
}

/// Soru turu klavyesi (web QuizPiano): 1–3 oktav, oktavlı cevap, ipucu / doğru / yanlış / gösterilen doğru tuş
struct QuizPianoView: View {
    let keys: [PianoKey]
    let height: Double
    var disabled = false
    let onTap: (PianoKey) -> Void

    var body: some View {
        let whites = keys.filter { !$0.isBlack }
        let blacks = keys.filter(\.isBlack)
        GeometryReader { g in
            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(Array(whites.enumerated()), id: \.offset) { _, k in
                        Button { press(k) } label: {
                            KeyFace(look: k.look, radius: 8)
                                .overlay(alignment: .bottom) {
                                    VStack(spacing: 0) { KeyLabels(labels: k.labels) }.padding(.bottom, k.labels.first?.weight == 800 ? 6 : 8)
                                }
                        }
                        .buttonStyle(.plain)
                        .allowsHitTesting(!disabled)
                        .accessibilityLabel(k.accessibilityLabel ?? k.note)
                    }
                }
                ForEach(Array(blacks.enumerated()), id: \.offset) { _, k in
                    Button { press(k) } label: {
                        KeyFace(look: k.look, radius: 6)
                            .overlay(alignment: .bottom) { KeyLabels(labels: k.labels).padding(.bottom, 6) }
                    }
                    .buttonStyle(.plain)
                    .allowsHitTesting(!disabled)
                    .accessibilityLabel(k.accessibilityLabel ?? k.note)
                    .frame(width: g.size.width * (k.widthPct ?? 0) / 100, height: g.size.height * 0.62)
                    .offset(x: g.size.width * (k.leftPct ?? 0) / 100)
                }
            }
        }
        .frame(height: height)
    }

    /// Tuşun sesi, hafif titreşim, cevap (web QuizPiano onClick)
    private func press(_ k: PianoKey) {
        guard !disabled else { return }
        Sound.note(k.note, octave: k.octave)
        Haptics.tap()
        onTap(k)
    }
}

/// Akor klavyesi (web MultiPiano): Do3–Si4, çoklu seçim ya da yalnız gösterim, altında oktav adları
struct MultiPianoView: View {
    let keys: [PianoKey]
    var disabled = false
    let onTap: (PianoKey) -> Void

    /// Tuşun sesi ve seçim (web MultiPiano onClick)
    private func press(_ k: PianoKey) {
        guard !disabled else { return }
        Sound.note(k.note, octave: k.octave)
        onTap(k)
    }

    var body: some View {
        let whites = keys.filter { !$0.isBlack }
        let blacks = keys.filter(\.isBlack)
        VStack(spacing: 2) {
            GeometryReader { g in
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 0) {
                        ForEach(Array(whites.enumerated()), id: \.offset) { _, k in
                            Button { press(k) } label: {
                                KeyFace(look: k.look, radius: 8)
                                    .overlay(alignment: .bottom) {
                                        ZStack(alignment: .bottom) {
                                            if k.dot {
                                                Circle()
                                                    .fill(PaletteColor.violet500.color)
                                                    .frame(width: 8, height: 8)
                                                    .shadow(color: PaletteColor.violet500.color, radius: 3)
                                                    .padding(.bottom, 8 + 18)
                                            }
                                            KeyLabels(labels: k.labels).padding(.bottom, 4)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .allowsHitTesting(!disabled)
                            .accessibilityLabel("\(k.note)\(k.octave)")
                            .accessibilityValue(k.stateAccessibilityValue ?? "")
                        }
                    }
                    ForEach(Array(blacks.enumerated()), id: \.offset) { _, k in
                        Button { press(k) } label: { KeyFace(look: k.look, radius: 5) }
                            .buttonStyle(.plain)
                            .allowsHitTesting(!disabled)
                            .accessibilityLabel("\(k.note)\(k.octave)")
                            .accessibilityValue(k.stateAccessibilityValue ?? "")
                            .frame(width: g.size.width * (k.widthPct ?? 0) / 100, height: g.size.height * 0.62)
                            .offset(x: g.size.width * (k.leftPct ?? 0) / 100)
                    }
                }
            }
            .frame(height: Piano.multiHeight)
            HStack(spacing: 0) {
                ForEach(Piano.octaveMarkers, id: \.self) { m in
                    Text(m)
                        .font(.monoFixed(FontSize.xs))
                        .foregroundStyle(PaletteColor.slate700.color)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
