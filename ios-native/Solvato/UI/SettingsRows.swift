// Ayarlar parçaları (docs/ozellikler/ayarlar.md): kartın üstünde mor grup adı + yuvarlak köşeli kart; kart içinde ince
// çizgiyle ayrılan satırlar. Satır türleri: değerli (sağda soluk değer ve "›", dokununca seçim penceresi), anahtarlı
// (mor anahtar), bağlantı ("›", başka ekran). Seçim penceresi iPhone'da alttan kısa sayfa, iPad'de satırın yanında küçük
// açılır pencere. Ayarlar ekranında kullanılır.
import SolvatoCore
import SwiftUI

/// Grup: büyük harfli küçük mor başlık ve altında kart. Satırlar arasına çizgiyi satırlar kendisi çizer (üst kenar);
/// ilk satırın çizgisi kartın kenarında kırpılır.
struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.md, style: .circular)
        VStack(alignment: .leading, spacing: Space.s2) {
            Text(title.uppercased(with: Locale(identifier: "tr")))
                .font(.ui(FontSize.xs, .bold))
                .tracking(em: Tracking.label, size: FontSize.xs)
                .foregroundStyle(ThemeColor.violetText.color)
                .padding(.horizontal, Space.s1)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) { content }
                .padding(.top, -1)
                .frame(maxWidth: .infinity)
                .background(ThemeColor.surface.color)
                .clipShape(shape)
                .overlay(shape.strokeBorder(ThemeColor.border.color, lineWidth: 1))
        }
    }
}

/// Satırın ortak düzeni: solda başlık (+ alt yazı), sağda öğe; üstte ayırıcı çizgi
private struct RowLayout<Trailing: View>: View {
    let title: String
    var sub: String?
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: Space.s3) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.ui(FontSize.md, .semibold))
                    .foregroundStyle(ThemeColor.text.color)
                    .fixedSize(horizontal: false, vertical: true)
                if let sub {
                    Text(sub)
                        .font(.ui(FontSize.sm))
                        .foregroundStyle(ThemeColor.textMuted.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .frame(minHeight: 32)
        .padding(.vertical, Space.s3)
        .padding(.horizontal, Space.s4)
        .overlay(alignment: .top) { ThemeColor.border.color.frame(height: 1) }
        .contentShape(Rectangle())
    }
}

/// Sağdaki soluk "›"
private struct Chevron: View {
    var body: some View {
        Text("›").font(.ui(FontSize.lg)).foregroundStyle(ThemeColor.textSubtle.color).accessibilityHidden(true)
    }
}

/// Değerli satır: sağda o anki değer ve "›". VoiceOver: "Günlük hedef, 10 soru, düğme".
struct SettingsValueRow: View {
    let title: String
    var sub: String?
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RowLayout(title: title, sub: sub) {
                HStack(spacing: Space.s2) {
                    Text(value)
                        .font(.ui(FontSize.md))
                        .foregroundStyle(ThemeColor.textMuted.color)
                        .lineLimit(1)
                    Chevron()
                }
                .layoutPriority(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityHint(sub ?? "")
        .accessibilityAddTraits(.isButton)
    }
}

/// Değerli satır + seçim penceresi: seçenek dokununca hemen uygulanır ve pencere kapanır; değer seçilenin adı
struct SettingsPickerRow<Value: Hashable>: View {
    let title: String
    var sub: String?
    let options: [OptionItem<Value>]
    let selected: Value
    let onSelect: (Value) -> Void

    @State private var open = false

    var body: some View {
        SettingsValueRow(title: title, sub: sub, value: options.first { $0.value == selected }?.label ?? "") { open = true }
            .optionSheet(isPresented: $open, title: title, options: options, selected: selected, onSelect: onSelect)
    }
}

/// Anahtarlı satır: sağda açma/kapama anahtarı. VoiceOver açık/kapalı okur.
struct SettingsToggleRow: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RowLayout(title: title) { SwitchKnob(isOn: isOn) }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "Açık" : "Kapalı")
        .accessibilityAddTraits([.isButton, .isToggle])
    }
}

/// Mor açma/kapama anahtarı (yalnız görünüm; dokunuş satırda)
struct SwitchKnob: View {
    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule().fill(isOn ? PaletteColor.violet600.color : ThemeColor.fillStronger.color)
            Circle().fill(PaletteColor.white.color).frame(width: 26, height: 26).padding(3)
        }
        .frame(width: 52, height: 32)
        .animation(.easeOut(duration: 0.18), value: isOn)
    }
}

/// Bağlantı satırı: sağda "›", başka ekran açar
struct SettingsLinkRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RowLayout(title: title) { Chevron() }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Seçim penceresi

/// Penceredeki seçenek: ad ve isteğe bağlı açıklama ("10 soru" · "rahat tempo")
struct OptionItem<Value: Hashable> {
    let value: Value
    let label: String
    var note: String?
}

extension View {
    /// Alttan kısa sayfa (iPad'de açılır pencere): tutma çizgisi, başlık, seçenek kartları; seçili mor çerçeveli ve "✓"li
    func optionSheet<Value: Hashable>(
        isPresented: Binding<Bool>, title: String, options: [OptionItem<Value>], selected: Value, onSelect: @escaping (Value) -> Void
    ) -> some View {
        popover(isPresented: isPresented) {
            OptionSheet(title: title, options: options, selected: selected) {
                onSelect($0)
                isPresented.wrappedValue = false
            }
        }
    }
}

private struct OptionSheet<Value: Hashable>: View {
    let title: String
    let options: [OptionItem<Value>]
    let selected: Value
    let onSelect: (Value) -> Void

    /// Seçenek kartının yüksekliği ve aralar; sayfa yüksekliği bunlardan hesaplanır
    private static var optionHeight: Double { 48 }
    private var height: Double {
        Double(options.count) * (Self.optionHeight + Space.s2) + Space.s6 + FontSize.lg + Space.s3 + Space.s8
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            Text(title)
                .font(.ui(FontSize.lg, .bold))
                .foregroundStyle(ThemeColor.text.color)
                .padding(.bottom, Space.s1)
                .accessibilityAddTraits(.isHeader)
            ForEach(options, id: \.value) { o in
                let on = o.value == selected
                let shape = RoundedRectangle(cornerRadius: Radius.md, style: .circular)
                Button {
                    onSelect(o.value)
                } label: {
                    HStack(spacing: Space.s2) {
                        Text(o.label).font(.ui(FontSize.md, .semibold)).foregroundStyle(ThemeColor.text.color)
                        if let note = o.note {
                            Text(note).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
                        }
                        Spacer(minLength: 0)
                        if on {
                            Text("✓").font(.ui(FontSize.md, .heavy)).foregroundStyle(ThemeColor.violetText.color).accessibilityHidden(true)
                        }
                    }
                    .lineLimit(1)
                    .padding(.horizontal, Space.s4)
                    .frame(maxWidth: .infinity, minHeight: Self.optionHeight)
                    .background(ThemeColor.surface.color, in: shape)
                    .overlay(shape.strokeBorder(on ? PaletteColor.violet600.color : ThemeColor.border.color, lineWidth: on ? 2 : 1))
                    .contentShape(shape)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(o.note.map { "\(o.label), \($0)" } ?? o.label)
                .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, Space.s4)
        .padding(.top, Space.s6)
        .padding(.bottom, Space.s4)
        .frame(minWidth: 300, maxHeight: .infinity, alignment: .top)
        .background(ThemeColor.bg.color)
        .presentationCompactAdaptation(.sheet)
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.visible)
        .presentationBackground(ThemeColor.bg.color)
    }
}
