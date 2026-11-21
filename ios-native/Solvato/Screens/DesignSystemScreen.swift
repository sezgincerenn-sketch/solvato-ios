// Tasarım sistemi önizlemesi: logo, ikonlar, seçim ve gösterim parçaları, renkler, yazı basamakları, düğme ve kart.
// Aşama 0.2'de uygulamanın tek ekranı; gerçek ekranlar gelince (0.5) yalnızca UI testlerinde açılır.
// Koyu / açık görüntüsü web'deki değerlerle göz kontrolü içindir; sayısal eşitliği SolvatoCore testleri doğrular.
import SolvatoCore
import SwiftUI

struct DesignSystemScreen: View {
    @Binding var themeMode: ThemeMode
    // Seçim parçalarının önizleme durumu
    @State private var chip = "Tümü"
    @State private var goal = 20
    @State private var level = "orta"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                header
                themePicker
                section("Nota çizimi") { notation }
                section("Logo ve ikonlar") { logoAndIcons }
                section("Seçim") { choices }
                section("Rozet ve göstergeler") { badges }
                section("Puan halkası") { rings }
                section("Konu renkleri") { categories }
                section("Tema renkleri") { themeColors }
                section("Palet") { palette }
                section("Yazı") { typography }
                section("Düğmeler") { buttons }
                section("Kart") { cards }
            }
            .padding(.horizontal, Space.s4)
            .padding(.vertical, Space.s6)
            .frame(maxWidth: Metrics.tabletColumn)
            .frame(maxWidth: .infinity)
        }
        .background(ThemeColor.bg.color.ignoresSafeArea())
        .accessibilityIdentifier("tasarim-sistemi")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.s1) {
            Logo(size: 34)
            Text("Tasarım sistemi")
                .font(.ui(FontSize.sm, .medium))
                .foregroundStyle(ThemeColor.textMuted.color)
        }
    }

    /// 0.4: nota çizimleri (web Notation, MusicalStaff, ChordStaffSvg, GoalStaff, ClefIcon)
    private var notation: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            HStack(spacing: Space.s3) {
                MusicalStaffView(clef: .treble, noteY: 90, ledgerLines: [90], showLabel: true)
                MusicalStaffView(clef: .bass, noteY: 45, accidental: .sharp, feedback: .correct)
            }
            GoalStaffView(done: 6, goal: 10)
            NotationView(score: "ts:4/4 q ee ssss q ||")
            NotationView(score: "ts:6/8 3eee e.s ses q~ q")
            NotationView(score: "dyn:mf (q q@1 q@2 q@3) hair:<")
            NotationView(score: "tx:Allegro q! q> q- h^ end:Fine")
            HStack(spacing: Space.s3) {
                ChordStaffView(chord: Chords.all.first { $0.id == "C#min" }!, color: .palette(.violet500))
                ChordStaffView(chord: Chords.all.first { $0.id == "C13" }!)
            }
            HStack(spacing: Space.s2) {
                ClefIconView(clef: .treble, size: 24)
                ClefIconView(clef: .bass, size: 24)
                Text("Sol ve Fa anahtarı")
                    .font(.ui(FontSize.sm, .medium))
            }
            .foregroundStyle(ThemeColor.violetText.color)
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
            ForEach(CategoryColor.allCases, id: \.self) { c in
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

    private var logoAndIcons: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            HStack(spacing: Space.s6) {
                LogoMark(size: 72)
                Logo(size: 28)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: Space.s10), spacing: Space.s2)], spacing: Space.s3) {
                ForEach(IconName.allCases, id: \.self) { name in
                    Icon(name, size: 24, fill: [.flame, .star, .heart].contains(name))
                        .foregroundStyle(ThemeColor.textSecondary.color)
                }
            }
        }
    }

    private var choices: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            HStack(spacing: Space.s2) {
                ForEach(["Tümü", "Sol", "Fa", "Ritim"], id: \.self) { title in
                    Chip(title, selected: chip == title) { chip = title }
                }
            }
            Segmented(value: goal, options: [(10, "10"), (20, "20"), (30, "30"), (50, "50")]) { goal = $0 }
            ChoiceCard(
                selected: level == "baslangic", title: "Yeni başladım", sub: "Temel notalar, ritim ve işaretler",
                action: { level = "baslangic" }
            ) { Icon(.leaf, size: 22) }
            ChoiceCard(
                selected: level == "orta", title: "Bir süredir çalıyorum", sub: "Tüm notalar, diyez/bemol, ek çizgiler",
                action: { level = "orta" }
            ) { Icon(.piano, size: 22) }
        }
    }

    private var badges: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            HStack(spacing: Space.s3) {
                IconBadge(name: .note, color: CategoryColor.treble.base, size: .sm)
                IconBadge(name: .target, color: CategoryColor.rhythm.base)
                IconBadge(name: .trophy, color: Brand.highlight, size: .lg, glow: true)
                VStack(alignment: .leading, spacing: Space.s2) {
                    ForEach(0..<4, id: \.self) { Stars(value: $0) }
                }
            }
            HStack(spacing: Space.s2) {
                StatPill(tone: .orange, value: "12", label: "12 gün seri", action: {}) { Icon(.flame, size: 18, fill: true) }
                StatPill(tone: .amber, value: "180 XP", label: "180 XP", action: {}) { Icon(.star, size: 18, fill: true) }
                StatPill(tone: .muted, value: "0", label: "Seri yok", action: {}) { Icon(.flame, size: 18) }
            }
            HStack(spacing: Space.s2) {
                StatTile(value: "%86", label: "Doğruluk")
                StatTile(value: "0,9 sn", label: "Ort. süre")
                StatTile(value: "1.270", label: "XP") { Icon(.star, size: 16, fill: true).foregroundStyle(PaletteColor.amber400.color) }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var rings: some View {
        HStack(spacing: Space.s4) {
            ScoreRing(value: 7, max: 10, caption: "doğru", detail: "%70")
            ScoreRing(value: 3, max: 4, size: 96, caption: "yıldız")
        }
    }

    private var cards: some View {
        VStack(spacing: Space.s3) {
            AppCard {
                Text("Düz kart: hafif dolgu ve ince kenarlık")
                    .font(.ui(FontSize.sm))
                    .foregroundStyle(ThemeColor.textSoft.color)
            }
            AppCard(tone: CategoryColor.rhythm.base) {
                Text("Konu tonlu kart (Ritim)")
                    .font(.ui(FontSize.sm, .semibold))
                    .foregroundStyle(CategoryColor.rhythm.text.color)
            }
        }
    }
}
