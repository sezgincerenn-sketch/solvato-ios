// Ayarlar'ın parçaları (docs/ozellikler/ayarlar.md): grup başlığı + kart, satır çizgisi, değerli satır (dokununca seçim
// penceresi), saat satırı (saat çarkı), anahtarlı satır, bağlantı satırı. Kullanıldığı yer: Screens/SettingsScreen.swift.
import SolvatoCore
import SwiftUI

/// Mor, büyük harfli grup adı ve altında kart; satırlar arasına `SettingsDivider` konur
struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased(with: Locale(identifier: "tr")))
                .font(.ui(FontSize.xs, .bold))
                .tracking(em: 0.08, size: FontSize.xs)
                .foregroundStyle(ThemeColor.violetText.color)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)
            AppCard(padding: 0) {
                VStack(spacing: 0) { content }
            }
        }
        .padding(.top, 20)
    }
}

/// Kart içindeki satırları ayıran ince çizgi
struct SettingsDivider: View {
    var body: some View { ThemeColor.border.color.frame(height: 1).padding(.leading, 14) }
}

/// Satırın sol tarafı: başlık ve isteğe bağlı alt yazı
private struct RowTitle: View {
    let title: String
    let sub: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.ui(FontSize.md, .semibold)).foregroundStyle(ThemeColor.text.color)
                .fixedSize(horizontal: false, vertical: true)
            if let sub {
                Text(sub).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color).fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Başlık + sağda değer ve "›"; dokunulabilir satırların ortak görünümü
private struct ValueRowLabel: View {
    let title: String
    let sub: String?
    let value: String?

    var body: some View {
        HStack(spacing: 10) {
            RowTitle(title: title, sub: sub).layoutPriority(1)
            if let value {
                Text(value)
                    .font(.ui(FontSize.md))
                    .monospacedDigit()
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Text("›").font(.ui(FontSize.lg)).foregroundStyle(ThemeColor.textSubtle.color)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(minHeight: 50)
        .contentShape(Rectangle())
    }
}

/// Seçim penceresi açan satır ("Günlük hedef  10 soru ›"). Seçilince ayar hemen değişir ve pencere kapanır.
struct ChoiceRow<Value: Hashable>: View {
    let title: String
    var sub: String?
    let value: Value
    /// Seçenekler: değer, satırda ve pencerede görünen ad, penceredeki açıklama
    let options: [(value: Value, label: String, sub: String?)]
    let onChange: (Value) -> Void
    @State private var open = false

    var body: some View {
        let current = options.first { $0.value == value }?.label ?? ""
        Button { open = true } label: { ValueRowLabel(title: title, sub: sub, value: current) }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(current)
            .accessibilityAddTraits(.isButton)
            .popover(isPresented: $open) {
                ChoiceSheet(title: title, value: value, options: options) { v in
                    open = false
                    if v != value { onChange(v) }
                }
            }
    }
}

/// Seçim penceresinin içi: başlık ve seçenek kartları; seçili olan mor çerçeveli ve "✓"li
private struct ChoiceSheet<Value: Hashable>: View {
    let title: String
    let value: Value
    let options: [(value: Value, label: String, sub: String?)]
    let onPick: (Value) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.ui(FontSize.lg, .bold)).foregroundStyle(ThemeColor.text.color).padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(options.enumerated()), id: \.offset) { _, o in
                let on = o.value == value
                Button { onPick(o.value) } label: {
                    HStack(spacing: 10) {
                        Text(o.label).font(.ui(FontSize.md, .semibold)).foregroundStyle(ThemeColor.text.color)
                        if let s = o.sub { Text(s).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color) }
                        Spacer(minLength: 0)
                        if on { Text("✓").font(.ui(FontSize.md, .heavy)).foregroundStyle(ThemeColor.violetText.color) }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fill.color))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .strokeBorder(on ? PaletteColor.violet600.color : ThemeColor.border.color, lineWidth: on ? 2 : 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(Space.s4)
        .frame(minWidth: 300, alignment: .topLeading)
        .background(ThemeColor.bg.color)
        .presentationCompactAdaptation(.sheet)
        .presentationDetents([.height(Double(84 + options.count * 54))])
        .presentationDragIndicator(.visible)
        .presentationBackground(ThemeColor.bg.color)
    }
}

/// "Hatırlatma saati  19:00 ›": dokununca saat çarkı
struct TimeRow: View {
    let title: String
    let hour: Int
    let minute: Int
    let onChange: (_ hour: Int, _ minute: Int) -> Void
    @State private var open = false

    var body: some View {
        let text = SettingsText.clock(hour: hour, minute: minute)
        Button { open = true } label: { ValueRowLabel(title: title, sub: nil, value: text) }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(text)
            .accessibilityAddTraits(.isButton)
            .timeWheel(isPresented: $open, hour: hour, minute: minute, label: title, onChange: onChange)
    }
}

/// Başka ekran açan satır ("Gizlilik ›")
struct LinkRow: View {
    let title: String
    var sub: String?
    var value: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) { ValueRowLabel(title: title, sub: sub, value: value) }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isButton)
    }
}

/// Açma/kapama anahtarlı satır
struct ToggleRow: View {
    let title: String
    var sub: String?
    let on: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RowTitle(title: title, sub: sub)
            Button(action: action) {
                ZStack(alignment: on ? .trailing : .leading) {
                    Capsule().fill(on ? PaletteColor.violet600.color : ThemeColor.fillStronger.color)
                    Circle().fill(PaletteColor.white.color).frame(width: 26, height: 26).padding(3)
                }
                .frame(width: 52, height: 32)
                .animation(.easeOut(duration: 0.18), value: on)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(on ? "Açık" : "Kapalı")
            .accessibilityAddTraits(.isToggle)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 14)
        .frame(minHeight: 50)
    }
}
