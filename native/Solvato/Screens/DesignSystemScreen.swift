// Tasarım sistemi önizlemesi: palet, tema renkleri, konu renkleri, yazı basamakları, düğme ve kart.
// Aşama 0.2'de uygulamanın tek ekranı; gerçek ekranlar gelince (0.5) yalnızca UI testlerinde açılır.
// Koyu / açık görüntüsü web'deki değerlerle göz kontrolü içindir; sayısal eşitliği SolvatoCore testleri doğrular.
import SolvatoCore
import SwiftUI

struct DesignSystemScreen: View {
    @Binding var themeMode: ThemeMode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                header
                themePicker
                section("Konu renkleri") { categories }
                section("Tema renkleri") { themeColors }
                section("Palet") { palette }
                section("Yazı") { typography }
                section("Düğmeler") { buttons }
                section("Kart") { cards }
            }
            .padding(.horizontal, Space.s4)
            .padding(.vertical, Space.s6)
            .frame(maxWidth: Layout.tabletColumn)
            .frame(maxWidth: .infinity)
        }
        .background(ThemeColor.bg.color.ignoresSafeArea())
        .accessibilityIdentifier("tasarim-sistemi")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.s1) {
            (Text("Solv").foregroundStyle(ThemeColor.text.color)
                + Text("ato").foregroundStyle(Brand.accent.color))
                .font(.ui(FontSize.xxl, .heavy))
                .tracking(em: -0.02, size: FontSize.xxl)
            Text("Tasarım sistemi")
                .font(.ui(FontSize.sm, .medium))
                .foregroundStyle(ThemeColor.textMuted.color)
        }
    }

    private var themePicker: some View {
        Picker("Tema", selection: $themeMode) {
            Text("Sistem").tag(ThemeMode.system)
            Text("Koyu").tag(ThemeMode.dark)
            Text("Açık").tag(ThemeMode.light)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("tema-secimi")
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            Text(title.uppercased(with: Locale(identifier: "tr")))
                .font(.ui(FontSize.xs, .bold))
                .tracking(em: Tracking.label, size: FontSize.xs)
                .foregroundStyle(ThemeColor.textSubtle.color)
            content()
        }
    }

    private var categories: some View {
        VStack(spacing: Space.s2) {
            ForEach(Category.allCases, id: \.self) { c in
                HStack(spacing: Space.s3) {
                    Text(c.rawValue)
                        .font(.ui(FontSize.sm, .semibold))
                        .foregroundStyle(c.text.color)
                        .frame(width: Space.s12 * 2, alignment: .leading)
                    c.bar
                        .frame(height: Space.s2)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private let swatchGrid = [GridItem(.adaptive(minimum: Space.s12 + Space.s4), spacing: Space.s2)]

    private var themeColors: some View {
        LazyVGrid(columns: swatchGrid, alignment: .leading, spacing: Space.s2) {
            ForEach(ThemeColor.allCases, id: \.self) { c in
                swatch(c.color, label: c.rawValue.replacingOccurrences(of: "c-", with: ""))
            }
        }
    }

    private var palette: some View {
        LazyVGrid(columns: swatchGrid, alignment: .leading, spacing: Space.s2) {
            ForEach(PaletteColor.allCases, id: \.self) { c in
                swatch(c.color, label: c.rawValue)
            }
        }
    }

    private func swatch(_ color: Color, label: String) -> some View {
        VStack(alignment: .leading, spacing: Space.s1) {
            RoundedRectangle(cornerRadius: Radius.sm)
                .fill(color)
                .frame(height: Space.s10)
                .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            Text(label)
                .font(.mono(FontSize.xs))
                .foregroundStyle(ThemeColor.textFaint.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var typography: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            Text("Büyük sayı 32").font(.ui(FontSize.xxl, .heavy)).tracking(em: Tracking.tight, size: FontSize.xxl)
            Text("Başlık 24").font(.ui(FontSize.xl, .bold))
            Text("Alt başlık 20").font(.ui(FontSize.lg, .semibold))
            Text("Ana metin 16 · Çğıİöşü").font(.ui(FontSize.md))
            Text("Gövde ve alt yazı 14").font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
            Text("Etiket 12").font(.ui(FontSize.xs, .medium)).foregroundStyle(ThemeColor.textSubtle.color)
            Text("0,4 sn · %40 · 1234").font(.mono(FontSize.md, .semibold))
            Text("Allegro moderato").font(.term(FontSize.lg)).foregroundStyle(ThemeColor.termSymbol.color)
        }
        .foregroundStyle(ThemeColor.text.color)
    }

    private var buttons: some View {
        VStack(spacing: Space.s3) {
            AppButton("Başla", size: .lg, block: true, action: {})
            AppButton("Devam et", variant: .success, block: true, action: {})
            HStack(spacing: Space.s3) {
                AppButton("İkincil", variant: .secondary, action: {})
                AppButton("Vazgeç", variant: .ghost, action: {})
                AppButton("Pasif", disabled: true, action: {})
            }
        }
    }

    private var cards: some View {
        VStack(spacing: Space.s3) {
            AppCard {
                Text("Düz kart: hafif dolgu ve ince kenarlık")
                    .font(.ui(FontSize.sm))
                    .foregroundStyle(ThemeColor.textSoft.color)
            }
            AppCard(tone: Category.rhythm.base) {
                Text("Konu tonlu kart (Ritim)")
                    .font(.ui(FontSize.sm, .semibold))
                    .foregroundStyle(Category.rhythm.text.color)
            }
        }
    }
}
