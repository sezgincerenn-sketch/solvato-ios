// Ayarlar › Gizlilik ve Ayarlar › Lisanslar: düz metin sayfaları (internet gerektirmez). Web src/screens/LegalScreen.tsx;
// metinler SolvatoCore Legal'da (web src/data/legal.ts'den birebir aktarılır).
import SolvatoCore
import SwiftUI

enum LegalPage { case privacy, licenses }

struct LegalScreen: View {
    let model: AppModel
    let page: LegalPage

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: page == .privacy ? "Gizlilik" : "Lisanslar") { model.back() }
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s4) {
                    if page == .privacy {
                        ForEach(Legal.privacy, id: \.title) { s in
                            VStack(alignment: .leading, spacing: Space.s2) {
                                legalHeading(s.title).accessibilityAddTraits(.isHeader)
                                ForEach(s.body, id: \.self) { legalBody($0) }
                            }
                        }
                    } else {
                        legalBody(Legal.licensesIntro)
                        ForEach(Legal.licenses, id: \.name) { LicenseCard(license: $0) }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Space.s5)
                .padding(.bottom, Space.s6 * 2)
            }
            .scrollIndicators(.hidden)
        }
        .background(ThemeColor.bg.color)
    }
}

@MainActor private func legalHeading(_ t: String) -> some View {
    Text(t).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color).lineHeight(1.5, size: FontSize.md)
}

@MainActor private func legalBody(_ t: String, color: Color? = nil) -> some View {
    Text(t)
        .font(.ui(FontSize.sm))
        .foregroundStyle(color ?? ThemeColor.textSecondary.color)
        .lineHeight(1.55, size: FontSize.sm)
        .fixedSize(horizontal: false, vertical: true)
}

private struct LicenseCard: View {
    let license: License
    @State private var open = false

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: Space.s2) {
                legalHeading(license.name)
                legalBody(license.use, color: ThemeColor.textMuted.color)
                legalBody(license.notice)
                if let text = license.text {
                    Button { open.toggle() } label: {
                        Text(open ? "Lisans metnini gizle" : "Lisans metnini göster")
                            .font(.ui(FontSize.sm, .semibold))
                            .foregroundStyle(ThemeColor.violetText.color)
                            .padding(.vertical, Space.s2)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(open ? "Açık" : "Kapalı")
                    if open {
                        Text(text)
                            .font(.mono(FontSize.xs))
                            .foregroundStyle(ThemeColor.textMuted.color)
                            .lineHeight(1.5, size: FontSize.xs, natural: 1.32)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(Space.s3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: Radius.sm).fill(ThemeColor.fill.color))
                    }
                }
            }
        }
    }
}
