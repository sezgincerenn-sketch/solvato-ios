// Profil: ad ve renk, ünvan ve "…'den beri", seviye kartı (açıklamalı), ünvan kartı (liste), seri / tur / soru,
// haftalık rapor, Tüm ilerleme, Ayarlar. Web src/screens/profile/ProfileScreen.tsx.
import SolvatoCore
import SwiftUI

struct ProfileScreen: View {
    let model: AppModel
    @State private var name = ""

    var body: some View {
        let stats = model.stats
        let s = model.settings
        let rank = Ranks.from(xp: stats.totalPoints)
        let home = HomeContent(stats: stats, settings: s, daily: nil, now: model.now)
        VStack(spacing: 0) {
            ScreenHeader(title: "Profil", onBack: { model.back() }) {
                Button { model.go(.settings) } label: {
                    Icon(.settings, size: 20)
                        .foregroundStyle(ThemeColor.textSecondary.color)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fillStrong.color))
                        .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ayarlar")
            }
            ScrollView {
                VStack(spacing: Space.s3) {
                    VStack(spacing: Space.s3) {
                        Avatar(name: name, color: s.avatarColor, size: 80)
                        TextField("", text: $name, prompt: Text("İsmin").foregroundStyle(ThemeColor.textMuted.color))
                            .font(.ui(FontSize.lg, .heavy))
                            .foregroundStyle(ThemeColor.text.color)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, Space.s2)
                            .padding(.horizontal, Space.s3)
                            .frame(maxWidth: 260)
                            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.borderStrong.color, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                            .accessibilityLabel("İsim")
                            .onChange(of: name) { _, v in
                                let cut = String(v.prefix(24))
                                if cut != v { name = cut }
                                model.settings.name = cut.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        HStack(spacing: Space.s2) {
                            ForEach(Avatar.colors, id: \.key) { c in
                                Button { model.settings.avatarColor = c.key } label: {
                                    CSSLinearGradient([c.stops.0.color, c.stops.1.color])
                                        .clipShape(Circle())
                                        .frame(width: 28, height: 28)
                                        // Web outline 2 px, outlineOffset 2: halka renkten 2 pt açıkta
                                        .padding(4)
                                        .overlay(Circle().strokeBorder(s.avatarColor == c.key ? ThemeColor.text.color : .clear, lineWidth: 2))
                                        // Web'de halka yer kaplamaz: yerleşimde 28 pt
                                        .padding(-4)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(c.key)
                                .accessibilityAddTraits(s.avatarColor == c.key ? .isSelected : [])
                            }
                        }
                        Text(ProfileText.subtitle(rankLabel: rank.label, joinedAt: s.joinedAt, clock: model.now.clock))
                            .font(.ui(FontSize.sm))
                            .foregroundStyle(ThemeColor.textMuted.color)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Space.s5)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.fill.color))
                    .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))

                    LevelCardView(content: home, detailed: true)
                    RankCardView(xp: stats.totalPoints, detailed: true)
                    HStack(spacing: Space.s2) {
                        StatTile(value: "\(model.streak) gün", label: "Seri")
                        StatTile(value: "\(stats.totalSessions)", label: "Tamamlanan tur")
                        StatTile(value: "\(ProfileText.solved(stats))", label: "Çözülen soru")
                    }
                    ShareLink(item: WeeklyReport(stats: stats, settings: s, now: model.now).text) {
                        HStack(spacing: Space.s2) {
                            Icon(.share, size: 18)
                            Text("Haftalık raporu öğretmenine gönder")
                        }
                        .font(.ui(FontSize.md, .bold))
                        .foregroundStyle(Brand.onPrimary.color)
                        .frame(maxWidth: .infinity, minHeight: Touch.min)
                        .background(CSSLinearGradient(.primaryFlat).clipShape(RoundedRectangle(cornerRadius: Radius.md)))
                        // Web birincil Button: shadow.glow
                        .shadow(BoxShadow.glow(Brand.primary, strength: 0.45))
                    }
                    AppButton("Tüm ilerleme", variant: .secondary, block: true) { model.go(.dashboard) }
                    AppButton("Ayarlar", variant: .secondary, block: true, action: { model.go(.settings) }) {
                        Icon(.settings, size: 18)
                    }
                }
                .padding(.top, Space.s2)
                .padding(.horizontal, Space.s4)
                .padding(.bottom, Space.s8)
                .remembersScroll(model, .profile)
            }
            .scrollIndicators(.hidden)
        }
        .background(ThemeColor.bg.color)
        .onAppear { name = model.settings.name }
    }
}
