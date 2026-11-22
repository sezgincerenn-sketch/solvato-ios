// Kod giriş satırı: büyük harfli, harf aralıklı kod kutusu ve yanında düğme; hatalıysa kırmızı çerçeve ve altta
// açıklama. Öğretmen kodu (Uygula) ve Arkadaşına meydan oku (Kabul et) ekranlarında. Web'de iki ekranda aynı input.
import SolvatoCore
import SwiftUI

struct CodeField: View {
    @Binding var code: String
    @Binding var error: String
    let placeholder: String
    let label: String
    let button: String
    /// Yazılanı düzelt (büyük harf, en çok N karakter)
    let sanitize: (String) -> String
    let onSubmit: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            HStack(spacing: Space.s2) {
                TextField("", text: $code, prompt: Text(placeholder).foregroundStyle(ThemeColor.textMuted.color))
                    .font(.mono(FontSize.md))
                    .tracking(2)
                    .foregroundStyle(ThemeColor.text.color)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($focused)
                    .onSubmit(submit)
                    .onChange(of: code) { _, v in
                        let clean = sanitize(v)
                        if clean != v { code = clean }
                        error = ""
                    }
                    .accessibilityLabel(label)
                    .padding(.vertical, Space.s3)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fillStrong.color))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .strokeBorder(error.isEmpty ? ThemeColor.borderStrong.color : PaletteColor.red500.color, lineWidth: 1.5))
                AppButton(button, variant: .secondary, disabled: code.trimmingCharacters(in: .whitespaces).isEmpty, action: submit)
            }
            if !error.isEmpty {
                Text(error).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.redText.color)
            }
        }
    }

    private func submit() {
        onSubmit()
        if error.isEmpty { focused = false }
    }
}
