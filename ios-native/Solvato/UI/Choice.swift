// Seçim parçaları: uygulamadaki tüm "birini/birkaçını seç" düğmeleri bunlardan gelir. Web karşılığı src/ui/Choice.tsx + Chip.tsx.
// Tek kural: seçili = mor dolgu + beyaz yazı; seçili değil = açık zemin + ince çerçeve.
//   Chip         hap biçimi, tek satır (filtreler, saat, hazır ayar)
//   Segmented    eşit genişlikte düğme sırası (hedef, seviye, tema, ♯/♭)
//   ChoiceCard   başlık + açıklama satırı olan büyük seçenek (tanıtım)
import SolvatoCore
import SwiftUI

/// Seçili / seçili değil görünümü (web: choiceStyle)
struct ChoiceStyle {
    let selected: Bool
    var background: Color { selected ? PaletteColor.violet600.color : ThemeColor.fillStrong.color }
    var foreground: Color { selected ? PaletteColor.white.color : ThemeColor.textMuted.color }
    var border: Color { selected ? PaletteColor.violet500.color : ThemeColor.border.color }
    /// CSS "transition: .15s ease"
    static let animation = Animation.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.15)
}

extension View {
    /// Seçim düğmesi zemini, çerçevesi ve yazı rengi
    func choiceStyle(_ selected: Bool, radius: Double) -> some View {
        let style = ChoiceStyle(selected: selected)
        let shape = RoundedRectangle(cornerRadius: radius, style: .circular)
        return
            self
            .foregroundStyle(style.foreground)
            .background(style.background, in: shape)
            .overlay(shape.strokeBorder(style.border, lineWidth: 1))
            .contentShape(shape)
            .animation(ChoiceStyle.animation, value: selected)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Seçilebilir hap
struct Chip<Label: View>: View {
    var selected = false
    let action: () -> Void
    @ViewBuilder let label: Label

    /// Web'deki değerler: en az 36 yükseklik, 8/12 iç boşluk
    private static var minHeight: Double { 36 }

    var body: some View {
        Button(action: action) {
            label
                .font(.ui(FontSize.sm, .semibold))
                .padding(.vertical, Space.s2)
                .padding(.horizontal, Space.s3)
                .frame(minHeight: Self.minHeight)
                .choiceStyle(selected, radius: Radius.pill)
        }
        .buttonStyle(.plain)
    }
}

extension Chip where Label == Text {
    init(_ title: String, selected: Bool = false, action: @escaping () -> Void) {
        self.init(selected: selected, action: action) { Text(title) }
    }
}

/// Eşit genişlikte seçenek sırası. `columns` verilirse ızgara (web: grid, 6 aralık).
struct Segmented<Value: Hashable>: View {
    enum Size { case sm, md }

    let options: [(Value, String)]
    let isSelected: (Value) -> Bool
    let onChange: (Value) -> Void
    var columns: Int?
    var size: Size = .md

    /// Tek seçim
    init(value: Value, options: [(Value, String)], columns: Int? = nil, size: Size = .md, onChange: @escaping (Value) -> Void) {
        self.options = options
        self.isSelected = { $0 == value }
        self.onChange = onChange
        self.columns = columns
        self.size = size
    }

    /// Çoklu seçim (ör. nota listesi)
    init(
        options: [(Value, String)], isSelected: @escaping (Value) -> Bool, columns: Int? = nil, size: Size = .md,
        onChange: @escaping (Value) -> Void
    ) {
        self.options = options
        self.isSelected = isSelected
        self.onChange = onChange
        self.columns = columns
        self.size = size
    }

    /// Web'deki ızgara aralığı
    private static var gridGap: Double { 6 }

    var body: some View {
        if let columns {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Self.gridGap), count: columns),
                spacing: Self.gridGap
            ) { buttons }
        } else {
            HStack(spacing: Space.s2) { buttons }
        }
    }

    private var buttons: some View {
        ForEach(options.indices, id: \.self) { i in
            let (value, label) = options[i]
            Button {
                onChange(value)
            } label: {
                Text(label)
                    .font(.ui(size == .sm ? FontSize.sm : FontSize.md, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.vertical, size == .sm ? 8 : 10)
                    .padding(.horizontal, size == .sm ? 2 : 6)
                    .frame(maxWidth: .infinity, minHeight: Touch.min)
                    .choiceStyle(isSelected(value), radius: Radius.md)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Başlık + açıklamalı büyük seçenek
struct ChoiceCard<Leading: View>: View {
    var selected = false
    let title: String
    var sub: String?
    let action: () -> Void
    /// Soldaki simge; seçilince beyaza döner
    @ViewBuilder var leading: Leading

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                leading
                    .foregroundStyle(selected ? PaletteColor.white.color : ThemeColor.violetText.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.ui(FontSize.md, .bold))
                        .foregroundStyle(selected ? PaletteColor.white.color : ThemeColor.text.color)
                    if let sub {
                        Text(sub)
                            .font(.ui(FontSize.sm))
                            .foregroundStyle(selected ? PaletteColor.white.opacity(0.82) : ThemeColor.textMuted.color)
                    }
                }
                Spacer(minLength: 0)
            }
            .multilineTextAlignment(.leading)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .choiceStyle(selected, radius: Radius.lg)
        }
        .buttonStyle(.plain)
    }
}
