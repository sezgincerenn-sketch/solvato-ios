// Çalışma › Ritim dersleri: nota değerleri (temel fikir + vuruş çubukları), nota ağacı, sus işaretleri, noktalı nota.
// Web src/screens/study/RhythmStudy.tsx (RhythmMemo part="learn") ve src/components/MemoVisuals.tsx (NoteTree,
// RestsCard, DottedCard). Nota ve sus çizimleri NotationView ile (web Notation, altın tabloyla aynı).
import SolvatoCore
import SwiftUI

private struct NoteValue {
    let kind: String
    let n: Int
    let name: String
    let beats: Double
    /// Nota ağacı / sus kartındaki yazım
    let beatsShort: String
    let rest: String
    let color: PaletteColor
}

private let values: [NoteValue] = [
    NoteValue(kind: "whole", n: 1, name: "Birlik", beats: 4, beatsShort: "4", rest: "wr", color: .violet500),
    NoteValue(kind: "half", n: 2, name: "İkilik", beats: 2, beatsShort: "2", rest: "hr", color: .blue500),
    NoteValue(kind: "quarter", n: 4, name: "Dörtlük", beats: 1, beatsShort: "1", rest: "qr", color: .cyan500),
    NoteValue(kind: "eighth", n: 8, name: "Sekizlik", beats: 0.5, beatsShort: "½", rest: "er", color: .amber500),
    NoteValue(kind: "sixteenth", n: 16, name: "Onaltılık", beats: 0.25, beatsShort: "¼", rest: "sr", color: .pink500),
]

/// Basit nota simgesi (34×40 görünüm kutusu; web NoteIcon / NoteGlyph)
private struct NoteGlyph: View {
    let kind: String
    let color: Color
    var width: Double = 34
    var stroke: (head: Double, stem: Double) = (2.4, 2.2)

    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 34, y: size.height / 40)
            let hollow = kind == "whole" || kind == "half"
            var head = Path(ellipseIn: CGRect(x: 13 - 8, y: 31 - 5.5, width: 16, height: 11))
            head = head.applying(
                CGAffineTransform(translationX: 13, y: 31).rotated(by: -20 * .pi / 180).translatedBy(x: -13, y: -31))
            if !hollow { ctx.fill(head, with: .color(color)) }
            ctx.stroke(head, with: .color(color), lineWidth: stroke.head)
            if kind != "whole" {
                var stem = Path()
                stem.move(to: CGPoint(x: 20.5, y: 29))
                stem.addLine(to: CGPoint(x: 20.5, y: 4))
                ctx.stroke(stem, with: .color(color), lineWidth: stroke.stem)
            }
            let flags = kind == "eighth" ? 1 : kind == "sixteenth" ? 2 : 0
            for i in 0..<flags {
                let o = Double(i * 7)
                var f = Path()
                f.move(to: CGPoint(x: 20.5, y: 4 + o))
                f.addCurve(to: CGPoint(x: 26, y: 22 + o), control1: CGPoint(x: 27, y: 10 + o), control2: CGPoint(x: 29, y: 16 + o))
                ctx.stroke(f, with: .color(color), lineWidth: stroke.stem)
            }
        }
        .frame(width: width, height: width * 40 / 34)
        .accessibilityHidden(true)
    }
}

private func beatText(_ b: Double) -> String {
    if b == 0.5 { return "½ vuruş" }
    if b == 0.25 { return "¼ vuruş" }
    return "\(Int(b)) vuruş"
}

/// Ders: Nota değerleri (RhythmMemo learn + NoteTree)
struct RhythmValuesLesson: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            memo
            NoteTreeCard()
        }
    }

    private var memo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTA DEĞERLERİ VE VURUŞ SÜRELERİ")
                .font(.ui(FontSize.xs, .bold))
                .tracking(em: 0.08, size: FontSize.xs)
                .foregroundStyle(ThemeColor.textMuted.color)
            VStack(spacing: 8) {
                memoCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Temel fikir").font(.ui(FontSize.sm, .bold)).foregroundStyle(ThemeColor.textSoft.color)
                            .lineHeight(1.6, size: FontSize.sm)
                        (Text("Her nota ne kadar süreceğini söyler. Süre “vuruş” ile sayılır. Her nota bir öncekinin ")
                            + Text("yarısı").font(.ui(FontSize.sm, .bold))
                            + Text(" kadar sürer. Aşağıdaki örneklerde dörtlük nota = 1 vuruş kabul edilir (4/4 ölçüde)."))
                            .font(.ui(FontSize.sm))
                            .foregroundStyle(ThemeColor.textSecondary.color)
                            .lineHeight(1.6, size: FontSize.sm)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                ForEach(values, id: \.kind) { v in
                    memoCard {
                        HStack(spacing: 14) {
                            NoteGlyph(kind: v.kind, color: v.color.color).frame(width: 40)
                            VStack(spacing: 8) {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(v.name).font(.ui(FontSize.sm, .bold)).foregroundStyle(ThemeColor.textSoft.color)
                                    Spacer(minLength: 0)
                                    Text(beatText(v.beats)).font(.ui(FontSize.sm, .heavy)).foregroundStyle(v.color.color)
                                        .fixedSize()
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        PaletteColor.slate400.opacity(0.2)
                                        RoundedRectangle(cornerRadius: Radius.xs).fill(v.color.color)
                                            .frame(width: max(4, geo.size.width * v.beats / 4))
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(v.name), \(beatText(v.beats))")
                }
            }
        }
    }

    private func memoCard<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        c()
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.surface.color))
            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }
}

/// Ezber görsellerinin ortak kartı (web MemoVisuals `card`, `title`, `sub`)
struct MemoCard<C: View>: View {
    let title: String
    @ViewBuilder let content: C

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color)
            content
        }
        .padding(.top, 14)
        .padding(.horizontal, 14)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.surface.color))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }
}

/// MemoVisuals açıklama yazısı (sm, soluk, satır yüksekliği 1.5)
struct MemoSub: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.ui(FontSize.sm))
            .foregroundStyle(ThemeColor.textMuted.color)
            .lineHeight(1.5, size: FontSize.sm)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Nota ağacı: her satır bir öncekinin iki katı nota, toplam süre aynı
struct NoteTreeCard: View {
    var body: some View {
        MemoCard(title: "Nota ağacı") {
            MemoSub("Her satırın toplam süresi aynı: 4 vuruş. Aşağı indikçe nota sayısı ikiye katlanır.").padding(.bottom, 10)
            VStack(spacing: 6) {
                ForEach(values, id: \.kind) { v in
                    HStack(spacing: 8) {
                        Text("\(v.n) \(v.name.lowercased(with: Locale(identifier: "tr")))")
                            .font(.ui(FontSize.sm, .bold))
                            .foregroundStyle(v.color.color)
                            // Büyük yazıda sütun genişler, yazı kesilmez
                            .frame(minWidth: 74, alignment: .leading)
                        HStack(spacing: v.n >= 16 ? 1 : 2) {
                            ForEach(0..<v.n, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: Radius.xs)
                                    .fill(v.color.opacity(0x1F / 255))
                                    .overlay(RoundedRectangle(cornerRadius: Radius.xs).strokeBorder(v.color.opacity(0x55 / 255), lineWidth: 1))
                                    .overlay {
                                        NoteGlyph(kind: v.kind, color: v.color.color, width: v.n >= 16 ? 11 : v.n >= 8 ? 16 : 22, stroke: (2.6, 2.4))
                                    }
                                    .clipped()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 34)
                            }
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(v.n) \(v.name.lowercased(with: Locale(identifier: "tr")))")
                }
            }
        }
    }
}

/// Ders: Sus işaretleri
struct RestsCard: View {
    var body: some View {
        MemoCard(title: "Sus işaretleri") {
            MemoSub("Her notanın aynı süren bir susu var.").padding(.bottom, 6)
            HStack(alignment: .top, spacing: 4) {
                ForEach(values, id: \.kind) { v in
                    VStack(spacing: 0) {
                        NotationView(score: v.rest, maxW: 64)
                        Text(v.name).font(.ui(FontSize.xs, .bold)).foregroundStyle(v.color.color)
                        Text("\(v.beatsShort) vuruş").font(.ui(FontSize.xs)).foregroundStyle(ThemeColor.textMuted.color)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

/// Ders: Noktalı notalar
struct DottedCard: View {
    var body: some View {
        MemoCard(title: "Noktalı nota") {
            MemoSub("Nokta, notaya kendi yarısı kadar süre ekler.")
            NotationView(score: "h. = h + q", maxW: 200).frame(maxWidth: .infinity)
            (Text("Noktalı ikilik = 2 + 1 = ")
                + Text("3 vuruş").font(.ui(FontSize.sm, .bold)).foregroundColor(ThemeColor.violetText.color)
                + Text(" · Noktalı dörtlük = ")
                + Text("1½ vuruş").font(.ui(FontSize.sm, .bold)).foregroundColor(ThemeColor.violetText.color))
                .font(.ui(FontSize.sm))
                .foregroundStyle(ThemeColor.textMuted.color)
                .multilineTextAlignment(.center)
                .lineHeight(1.5, size: FontSize.sm)
                .frame(maxWidth: .infinity)
                .padding(.top, -6)
        }
    }
}
