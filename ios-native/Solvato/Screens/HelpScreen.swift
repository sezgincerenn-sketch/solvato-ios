// Ayarlar › Yardım ve destek: kısa sık sorulan sorular, açılır-kapanır satırlar (kullanici-testi-revize.md madde 10).
// Başlık ve "‹ Ayarlar" geri düğmesi Apple'ın gezinme çubuğunda. En altta "Bize yaz": e-posta penceresini destek
// adresiyle açar (UI/MailSupport), e-posta hesabı yoksa adresi kopyalar. Metinler SolvatoCore HelpContent'te.
import SolvatoCore
import SwiftUI

struct HelpScreen: View {
    let model: AppModel
    @State private var open: Set<Int> = []
    @State private var toast = ToastModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("SIK SORULANLAR")
                    .font(.ui(FontSize.xs, .bold))
                    .tracking(em: 0.08, size: FontSize.xs)
                    .foregroundStyle(ThemeColor.violetText.color)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 6)
                    .accessibilityAddTraits(.isHeader)
                AppCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(HelpContent.items.enumerated()), id: \.offset) { i, item in
                            if i > 0 { SettingsDivider() }
                            row(i, item)
                        }
                    }
                }
                contact.padding(.top, Space.s6)
            }
            .padding(.horizontal, 20)
            .padding(.top, Space.s2)
            .padding(.bottom, 32)
            .remembersScroll(model, .help)
        }
        .scrollIndicators(.hidden)
        .background(ThemeColor.bg.color)
        .overlay { ToastView(model: toast) }
    }

    /// Bize yaz: kısa not, adres ve düğme
    private var contact: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            Text(HelpContent.mailNote)
                .font(.ui(FontSize.sm))
                .foregroundStyle(ThemeColor.textMuted.color)
                .fixedSize(horizontal: false, vertical: true)
            Text(verbatim: HelpContent.supportEmail)
                .font(.ui(FontSize.md, .semibold))
                .foregroundStyle(ThemeColor.text.color)
                .textSelection(.enabled)
            AppButton(HelpContent.mailTitle, block: true) {
                if !MailSupport.compose() { toast.show(HelpContent.copied) }
            }
        }
        .padding(.horizontal, 4)
    }

    private func row(_ i: Int, _ item: HelpItem) -> some View {
        let expanded = open.contains(i)
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                let change = { if expanded { open.remove(i) } else { open.insert(i) } }
                if reduceMotion { change() } else { withAnimation(.easeOut(duration: 0.18)) { change() } }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(item.question)
                        .font(.ui(FontSize.md, .semibold))
                        .foregroundStyle(ThemeColor.text.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("›")
                        .font(.ui(FontSize.lg))
                        .foregroundStyle(ThemeColor.textSubtle.color)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .frame(minHeight: 50)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(item.question)
            .accessibilityValue(AccessibilityText.disclosure(expanded: expanded))
            .accessibilityAddTraits(.isButton)
            if expanded {
                Text(item.answer)
                    .font(.ui(FontSize.sm))
                    .foregroundStyle(ThemeColor.textSecondary.color)
                    .lineHeight(1.55, size: FontSize.sm)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .transition(.opacity)
            }
        }
    }
}
