// Çalışma › Terimler dersleri: tek bir terim grubunun listesi (sembol italik, ad, anlamı). Web
// src/screens/study/TermsStudy.tsx (ders içinde `group` verili hali: başlık yok, liste hep açık). Veri SolvatoCore Terms.
import SolvatoCore
import SwiftUI

struct TermsLesson: View {
    let group: TermGroup

    var body: some View {
        VStack(spacing: 1) {
            ForEach(group.items, id: \.symbol) { item in
                HStack(alignment: .center, spacing: 14) {
                    Text(item.symbol)
                        .font(.custom("Georgia-BoldItalic", size: FontSize.md))
                        .tracking(em: 0.01, size: FontSize.md)
                        .foregroundStyle(group.color.color)
                        .lineHeight(1.5, size: FontSize.md, natural: 1.14)
                        .frame(minWidth: 52, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        if item.name.lowercased() != item.symbol.lowercased() {
                            Text(item.name).font(.ui(FontSize.sm, .semibold)).foregroundStyle(ThemeColor.textSecondary.color)
                                .lineHeight(1.5, size: FontSize.sm)
                        }
                        Text(item.meaning).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
                            .lineHeight(1.5, size: FontSize.sm)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .overlay(alignment: .bottom) { ThemeColor.border.color.frame(height: 1) }
                .accessibilityElement(children: .combine)
            }
        }
        .background(ThemeColor.surface.color)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }
}
