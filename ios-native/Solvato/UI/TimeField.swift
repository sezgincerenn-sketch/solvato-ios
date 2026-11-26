// Saat satırı (tanitim.md R9; web revize ui/TimeField.tsx): ortalı büyük "19:00"; dokununca iPhone'un saat çarkı açılır
// (24 saat, bütün saatler ve dakikalar). Tanıtımın hatırlatma adımında ve Ayarlar › Hatırlatma'da kullanılır.
// iPad'de çark küçük açılır pencerede, iPhone'da alttan kısa sayfada. Seçim pencere kapanınca bildirilir.
import SolvatoCore
import SwiftUI

struct TimeField: View {
    let hour: Int
    let minute: Int
    var label = "Hatırlatma saati"
    let onChange: (_ hour: Int, _ minute: Int) -> Void

    @State private var open = false
    @State private var draft = Date()

    /// Çark her zaman 24 saat (uygulama Türkçe; cihaz 12 saat biçiminde olsa da)
    private static let locale = Locale(identifier: "tr_TR")

    var body: some View {
        let text = SettingsText.clock(hour: hour, minute: minute)
        Button {
            draft = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
            open = true
        } label: {
            Text(verbatim: text)
                .font(.ui(FontSize.xl, .bold))
                .monospacedDigit()
                .foregroundStyle(ThemeColor.text.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.fillStrong.color))
                .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.borderStrong.color, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "\(label), \(text)"))
        .popover(isPresented: $open) {
            VStack(spacing: Space.s3) {
                DatePicker(label, selection: $draft, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Self.locale)
                AppButton("Tamam", block: true) { open = false }
            }
            .padding(Space.s4)
            .frame(minWidth: 300)
            .background(ThemeColor.bg.color)
            .presentationCompactAdaptation(.sheet)
            .presentationDetents([.height(320)])
            .presentationBackground(ThemeColor.bg.color)
        }
        .onChange(of: open) { _, isOpen in
            // Kapanınca (Tamam ya da aşağı kaydırma) seçilen saat bildirilir
            guard !isOpen else { return }
            let c = Calendar.current.dateComponents([.hour, .minute], from: draft)
            let h = c.hour ?? hour
            let m = c.minute ?? minute
            if h != hour || m != minute { onChange(h, m) }
        }
    }
}
