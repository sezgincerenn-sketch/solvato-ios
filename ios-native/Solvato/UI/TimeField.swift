// Saat seçimi (tanitim.md R9; web revize ui/TimeField.tsx). İki parça:
// - `timeWheel`: iPhone'un saat çarkını açan pencere (24 saat, bütün saatler ve dakikalar; iPad'de küçük açılır pencere,
//   iPhone'da alttan kısa sayfa). Seçim pencere kapanınca bildirilir. Ayarlar'daki "Hatırlatma saati" satırı bunu açar.
// - `TimeField`: tanıtımın hatırlatma adımındaki ortalı büyük "19:00" kutusu; dokununca aynı çark.
import SolvatoCore
import SwiftUI

struct TimeField: View {
    let hour: Int
    let minute: Int
    var label = "Hatırlatma saati"
    let onChange: (_ hour: Int, _ minute: Int) -> Void

    @State private var open = false

    var body: some View {
        let text = SettingsText.clock(hour: hour, minute: minute)
        Button { open = true } label: {
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
        .timeWheel(isPresented: $open, hour: hour, minute: minute, label: label, onChange: onChange)
    }
}

extension View {
    /// Saat çarkı penceresi; kapanınca seçilen saat farklıysa `onChange`
    func timeWheel(
        isPresented: Binding<Bool>, hour: Int, minute: Int, label: String, onChange: @escaping (_ hour: Int, _ minute: Int) -> Void
    ) -> some View {
        modifier(TimeWheel(open: isPresented, hour: hour, minute: minute, label: label, onChange: onChange))
    }
}

private struct TimeWheel: ViewModifier {
    @Binding var open: Bool
    let hour: Int
    let minute: Int
    let label: String
    let onChange: (_ hour: Int, _ minute: Int) -> Void
    @State private var draft = Date()

    /// Çark her zaman 24 saat (uygulama Türkçe; cihaz 12 saat biçiminde olsa da)
    private static let locale = Locale(identifier: "tr_TR")

    func body(content: Content) -> some View {
        content
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
                if isOpen {
                    draft = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
                    return
                }
                // Kapanınca (Tamam ya da aşağı kaydırma) seçilen saat bildirilir
                let c = Calendar.current.dateComponents([.hour, .minute], from: draft)
                let h = c.hour ?? hour
                let m = c.minute ?? minute
                if h != hour || m != minute { onChange(h, m) }
            }
    }
}
