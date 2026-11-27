// Küçük gösterim parçaları. Web karşılıkları: src/ui/IconBadge.tsx, Stars.tsx, StatTile.tsx, StatPill.tsx.
// Ölçüler web'dekiyle aynı; tasarım basamağı dışındaki sayılar (36, 26, 6…) web'den birebir alınmıştır.
import SolvatoCore
import SwiftUI

/// Renkli kare zemin üstünde ikon (kart başlıkları, sonuç rozetleri)
struct IconBadge: View {
    enum Size { case sm, md, lg }

    let name: IconName
    let color: PaletteColor
    var size: Size = .md
    var glow = false

    private var box: Double { size == .sm ? 36 : size == .md ? 44 : 72 }
    private var iconSize: Double { size == .sm ? 19 : size == .md ? 22 : 36 }
    private var radius: Double { size == .lg ? Radius.lg : Radius.md }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .circular)
        Icon(name, size: iconSize)
            .foregroundStyle(color.color)
            .frame(width: box, height: box)
            .background {
                if size == .lg {
                    CSSLinearGradient([color.opacity(0.25), color.opacity(0.08)]).clipShape(shape)
                } else {
                    shape.fill(color.opacity(0.14))
                }
            }
            .overlay {
                if size == .lg { shape.strokeBorder(color.opacity(0.33), lineWidth: 1) }
            }
            // web: box-shadow 0 0 28px → yarıçap 14
            .shadow(color: glow ? color.opacity(0.27) : .clear, radius: 14)
            .accessibilityHidden(true)
    }
}

/// 0–3 yıldız (tur sonucu, ana sayfa konu kartları, son turlar). Tur sonucunda `animate`: yıldızlar sırayla büyüyerek
/// belirir (web Stars animate, G-06).
struct Stars: View {
    let value: Int
    var size: Double = 14
    var animate = false

    var body: some View {
        HStack(spacing: size * 0.15) {
            ForEach(0..<3, id: \.self) { i in
                let on = i < value
                let shape = SVGShape(commands: ParsedPaths.star)
                let line = 1.2 * size / IconMetrics.viewBox
                ZStack {
                    shape.fill(on ? PaletteColor.amber400.color : ThemeColor.fillStronger.color)
                    shape.stroke(
                        on ? PaletteColor.amber500.color : ThemeColor.border.color,
                        style: StrokeStyle(lineWidth: line, lineJoin: .round))
                }
                .frame(width: size, height: size)
                .modifier(StarEntrance(animate: animate, delay: 0.15 + Double(i) * 0.18))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("3 yıldızdan \(value)")
    }
}

/// Küçük istatistik kutusu: büyük değer + altında etiket. Yan yana kutular eşit boyda olsun diye satırı
/// `.fixedSize(horizontal: false, vertical: true)` ile sarın (web'de flex satırı aynı şeyi yapar).
struct StatTile<IconView: View>: View {
    let value: String
    let label: String
    @ViewBuilder var icon: IconView
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.lg, style: .circular)
        VStack(spacing: 0) {
            if IconView.self != EmptyView.self {
                icon.padding(.bottom, Space.s1)
            }
            // Büyük yazıda yan yana kutular alta geçmez; sayı gerekirse %80'e kadar küçülür
            Text(value)
                .font(.mono(FontSize.lg, .heavy))
                .foregroundStyle(ThemeColor.text.color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            // Büyütülmüş yazıda kelime ortadan bölünmesin ("Tamamlana / n tur"): tek satıra sığmazsa kelimeler alt
            // alta, o da sığmazsa küçülür. Varsayılan ve daha küçük boyutlarda bugünkü Text aynen.
            Group {
                if typeSize > .large {
                    ViewThatFits(in: .horizontal) {
                        Text(label)
                        VStack(spacing: 0) { ForEach(label.split(separator: " ").map(String.init), id: \.self) { Text($0).lineLimit(1) } }
                        Text(label).lineLimit(1).minimumScaleFactor(0.6)
                    }
                } else {
                    Text(label)
                }
            }
                .font(.ui(FontSize.xs))
                .foregroundStyle(ThemeColor.textSubtle.color)
                .padding(.top, 2)
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, Space.s3)
        .padding(.horizontal, Space.s2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ThemeColor.fill.color, in: shape)
        .overlay(shape.strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }
}

extension StatTile where IconView == EmptyView {
    init(value: String, label: String) {
        self.init(value: value, label: label) { EmptyView() }
    }
}

/// Üst bardaki gösterge hapı: seri, XP. Renk anlamı sabit: seri = turuncu, XP = amber, henüz yok = soluk.
struct StatPill<Leading: View>: View {
    enum Tone {
        case orange, amber, muted
        var base: PaletteColor { self == .orange ? .orange500 : self == .amber ? .amber500 : .slate400 }
        var text: ThemeColor { self == .orange ? .orangeText : self == .amber ? .amberText : .textMuted }
    }

    let tone: Tone
    /// Sayı (mono yazılır), ör. "12" ya da "180 XP"
    let value: String
    /// Ekran okuyucu için tam cümle, ör. "12 gün seri. Haftanı gör"
    let label: String
    /// Verilmezse hap basılmaz, yalnız bilgi verir (seri hapı)
    let action: (() -> Void)?
    /// Soldaki ikon ya da rozet; hap rengini alır
    @ViewBuilder var leading: Leading

    var body: some View {
        if let action {
            Button(action: action) { pill }
                .buttonStyle(.plain)
                .accessibilityLabel(label)
        } else {
            pill
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
        }
    }

    private var pill: some View {
        let shape = Capsule()
        return HStack(spacing: 6) {
            leading.frame(width: 26, height: 26)
            Text(value).font(.mono(FontSize.sm, .bold)).lineLimit(1).fixedSize()
        }
        .foregroundStyle(tone.text.color)
        .padding(.leading, 6)
        .padding(.trailing, 12)
        .frame(minHeight: 36)
        .background(tone.base.opacity(0.12), in: shape)
        .overlay(shape.strokeBorder(tone.base.opacity(0.3), lineWidth: 1))
        .contentShape(shape)
    }
}

/// Yıldızın girişi: yalnız `animate` açıkken
private struct StarEntrance: ViewModifier {
    let animate: Bool
    let delay: Double
    func body(content: Content) -> some View {
        if animate { content.starPopIn(delay: delay) } else { content }
    }
}
