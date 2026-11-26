// Ana sayfa: üst çubuk (seri, XP), seviye kartı, Bugün kartı (10 bölmeli hedef çubuğu, Bugünün çalışması),
// Oyunlar kartı, konu kartları (yüzde halkası). Gezinme revizesi: docs/ozellikler/gezinme.md. Web karşılığı
// src/screens/HomeScreen.tsx + profile/LevelCard.tsx. Hangi kartın görüneceği ve bütün yazılar SolvatoCore HomeContent'ten (web'le aynı olduğu testli); burada yalnızca çizim.
import SolvatoCore
import SwiftUI

struct HomeScreen: View {
    let model: AppModel
    /// Tanıtım sırasında aydınlatılan öğe: görünür alana kaydırılır
    var coachTarget: String?
    @Environment(\.horizontalSizeClass) private var sizeClass
    /// "Diğer konular" grubu; Profil'de "Diğer konuları da göster" açıksa açık gelir
    @State private var showRest: Bool

    init(model: AppModel, coachTarget: String? = nil) {
        self.model = model
        self.coachTarget = coachTarget
        _showRest = State(initialValue: model.settings.showRestTopics)
    }

    private var content: HomeContent {
        HomeContent(stats: model.stats, settings: model.settings, daily: model.todayDaily, now: model.now)
    }

    var body: some View {
        let c = content
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topBar(c).padding(.bottom, 20).id("top")
                if let g = c.greeting {
                    Text(g)
                        .font(.ui(FontSize.lg, .heavy))
                        .tracking(em: -0.02, size: FontSize.lg)
                        .foregroundStyle(ThemeColor.text.color)
                        .padding(.horizontal, 2)
                        .padding(.top, -4)
                        .padding(.bottom, 12)
                }
                LevelCardView(content: c) { model.selectTab(.profile) }.coachTarget("level").id("level").padding(.bottom, Space.s3)
                todayCard(c).padding(.bottom, Space.s4)
                gamesCard(c).coachTarget("games").id("games").padding(.bottom, 20)
                Text(c.sectionTitle.uppercased(with: Locale(identifier: "tr")))
                    .font(.ui(FontSize.xs, .bold))
                    .tracking(em: 0.08, size: FontSize.xs)
                    .foregroundStyle(ThemeColor.textSubtle.color)
                    .padding(.bottom, 12)
                ForEach(Array(c.groups.enumerated()), id: \.offset) { _, g in
                    if let title = g.restTitle {
                        restHeader(title)
                        if showRest { topicList(g.rows) }
                    } else {
                        topicList(g.rows)
                    }
                }
            }
            .padding(.horizontal, Space.s4)
            .padding(.top, Space.s6)
            .remembersScroll(model, .home)
        }
        .scrollIndicators(.hidden)
        .onChange(of: coachTarget, initial: true) { old, t in
            // İpuçları bitince (Atla / Anladım) sayfa başa kayar (web Coachmark)
            guard let t else {
                if old != nil { withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("top", anchor: .top) } }
                return
            }
            guard t != "nav" else { return }
            withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(t, anchor: .center) }
        }
        }
        .background(alignment: .topLeading) {
            // Solda hafif ortam rengi (web radial-gradient rgba(99,102,241,0.12))
            // CSS radial-gradient(circle): yarıçap en uzak köşe (110·√2), %70te saydam
            RadialGradient(colors: [PaletteColor.indigo500.opacity(0.12), .clear], center: .center, startRadius: 0, endRadius: 110 * 2.0.squareRoot() * 0.7)
                .frame(width: 220, height: 220)
                .offset(x: -60, y: 180)
                .allowsHitTesting(false)
        }
        .background(ThemeColor.bg.color)
    }

    // MARK: Üst çubuk
    private func topBar(_ c: HomeContent) -> some View {
        HStack {
            Logo(size: 30).accessibilityAddTraits(.isHeader).layoutPriority(-1)
            Spacer(minLength: Space.s2)
            HStack(spacing: Space.s2) {
                // Seri hapı basılmaz (yalnız bilgi); XP hapı Profil sekmesini açar
                StatPill(tone: c.streak > 0 ? .orange : .muted, value: String(c.streak), label: c.streakLabel, action: nil) {
                    Icon(.flame, size: 17, fill: c.streak > 0).opacity(c.streak > 0 ? 1 : 0.6).flameFlicker(c.streak > 0)
                }
                StatPill(tone: .amber, value: c.xpValue, label: c.xpLabel, action: { model.selectTab(.profile) }) {
                    Text(String(c.rank.rank))
                        .font(.ui(FontSize.sm, .heavy))
                        .foregroundStyle(PaletteColor.black.color)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(PaletteColor.amber400.color))
                }
            }
        }
    }

    // MARK: Bugün
    private func todayCard(_ c: HomeContent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("BUGÜN")
                    .font(.ui(FontSize.xs, .semibold))
                    .tracking(em: 0.06, size: FontSize.xs)
                    .foregroundStyle(ThemeColor.textMuted.color)
                Spacer()
                Text(c.dailyText).font(.mono(FontSize.sm, .bold)).foregroundStyle(ThemeColor.violetTextSoft.color)
            }
            .padding(.bottom, Space.s2)
            GoalBar(filled: c.goalSegments, done: c.goalDone, label: c.goalLabel)
            HStack(spacing: 4) {
                if c.goalDone { Icon(.flame, size: 13, fill: true).foregroundStyle(ThemeColor.orangeText.color) }
                Text(c.goalFooter)
            }
            .font(.ui(FontSize.sm))
            .foregroundStyle(ThemeColor.textMuted.color)
            .padding(.top, Space.s2)
            .padding(.bottom, Space.s4)

            Button { model.startQuiz(.all) } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.todayTitle).font(.ui(FontSize.md, .heavy)).foregroundStyle(PaletteColor.white.color)
                        Text(c.todaySub).font(.ui(FontSize.sm)).foregroundStyle(PaletteColor.violet100.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    PlayShape()
                        .fill(PaletteColor.white.color)
                        .frame(width: 16, height: 16)
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fillStronger.color))
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(CSSLinearGradient(.primary).clipShape(RoundedRectangle(cornerRadius: 16)))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(PaletteColor.violet300.opacity(0.35), lineWidth: 1))
                .shadow(color: PaletteColor.violet600.opacity(0.38), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .coachTarget("today")
            .id("today")
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(ThemeColor.fill.color))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }

    // MARK: Oyunlar
    private func gamesCard(_ c: HomeContent) -> some View {
        Button { model.go(.games) } label: {
            HStack(spacing: 12) {
                Icon(.trophy, size: 19)
                    .foregroundStyle(ThemeColor.greenText.color)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.green500.opacity(0.14)))
                VStack(alignment: .leading, spacing: 0) {
                    Text("Oyunlar").font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color)
                    Text("Meydan okuma ve düello").font(.ui(FontSize.xs)).foregroundStyle(ThemeColor.textMuted.color).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(c.gamesBadge)
                    .font(.ui(FontSize.xs, .bold))
                    .lineLimit(1)
                    .foregroundStyle((c.gamesDone ? ThemeColor.textMuted : ThemeColor.greenText).color)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(c.gamesDone ? ThemeColor.fillStrong.color : PaletteColor.green500.opacity(0.14)))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 16).fill(PaletteColor.green500.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(PaletteColor.green500.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Konular
    private func restHeader(_ title: String) -> some View {
        Button { showRest.toggle() } label: {
            HStack {
                Text(title)
                Spacer()
                Text(showRest ? "▴" : "▾").accessibilityHidden(true)
            }
            .font(.ui(FontSize.sm, .semibold))
            .foregroundStyle(ThemeColor.textMuted.color)
            .padding(.top, Space.s2)
            .frame(minHeight: 44)
            .overlay(alignment: .top) { ThemeColor.border.color.frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 10)
        .accessibilityValue(showRest ? "Açık" : "Kapalı")
    }

    @ViewBuilder
    private func topicList(_ rows: [HomeContent.Row]) -> some View {
        let columns = sizeClass == .regular ? [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)] : [GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: sizeClass == .regular ? 12 : 10) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                switch row {
                case let .category(cat):
                    CategoryCard(cat: cat) { model.startQuiz(cat.key) }
                        .modifier(CoachIf(on: cat.key == .treble, name: "categories"))
                case let .link(l):
                    TopicLink(color: l.color, icon: l.icon, title: l.title, sub: l.sub, acc: l.acc) {
                        model.go(l.round == .chords ? .chordquiz : .rhythmtap)
                    }
                }
            }
        }
        .padding(.bottom, Space.s6)
    }
}

/// Konu kartı: renkli ikon kutusu, ad ve alt yazı, konudaki doğruluk (yüzde halkası); kartın tamamı turu başlatır
private struct CategoryCard: View {
    let cat: HomeContent.Category
    let action: () -> Void

    var body: some View {
        let base = cat.color.base
        Button(action: action) {
            HStack(spacing: 14) {
                Group {
                    switch cat.icon {
                    case let .clef(c): ClefIconView(clef: c, size: 24)
                    case .speaker: Icon(.speaker, size: 22)
                    case let .symbol(s): Text(s).font(.ui(FontSize.lg))
                    }
                }
                .foregroundStyle(base.color)
                .frame(width: 44, height: 44)
                .background(CSSLinearGradient([base.opacity(0x28 / 255), base.opacity(0x14 / 255)]).clipShape(RoundedRectangle(cornerRadius: Radius.md)))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(base.opacity(0x33 / 255), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(cat.label).font(.ui(FontSize.md, .semibold)).foregroundStyle(ThemeColor.text.color)
                    Text(cat.sub).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                PercentRing(acc: cat.acc, color: base)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColor.fill.color))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Seviye kartı (web LevelCard): Başlangıç / Orta / İleri ve bir sonraki seviyeye ilerleme
struct LevelCardView: View {
    let content: HomeContent
    var detailed = false
    var action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) { card }.buttonStyle(.plain).accessibilityLabel("Seviye: \(content.levelLabel). Profili aç")
        } else {
            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Space.s2) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("SEVİYE")
                        .font(.ui(FontSize.xs, .bold))
                        .tracking(em: Tracking.label, size: FontSize.xs)
                        .foregroundStyle(ThemeColor.textSubtle.color)
                    Text(content.levelLabel)
                        .font(.ui(FontSize.lg, .heavy))
                        .tracking(em: -0.02, size: FontSize.lg)
                        .foregroundStyle(ThemeColor.text.color)
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    ForEach(1...3, id: \.self) { k in
                        let lv = content.level
                        Text(QuestionLevel.label(k))
                            .font(.ui(FontSize.xs, .bold))
                            .foregroundStyle(k == lv ? PaletteColor.white.color : k < lv ? ThemeColor.violetTextSoft.color : ThemeColor.textMuted.color)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(
                                Capsule().fill(
                                    k == lv ? PaletteColor.violet600.color : k < lv ? PaletteColor.violet500.opacity(0.25) : ThemeColor.fillStrong.color))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("3 seviyeden \(content.level).")
            }
            if let pct = content.levelPct {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ThemeColor.fillStrong.color)
                        Capsule()
                            .fill(LinearGradient(colors: [PaletteColor.violet600.color, PaletteColor.violet400.color], startPoint: .leading, endPoint: .trailing))
                            .frame(width: g.size.width * pct / 100)
                    }
                }
                .frame(height: 6)
                .padding(.top, Space.s3)
            }
            Text(content.levelNote)
                .font(.ui(FontSize.sm))
                .foregroundStyle(ThemeColor.textMuted.color)
                .padding(.top, Space.s2)
            if detailed {
                Text("Seviye, gelen soruların zorluğunu belirler. Ayarlar'dan elle de değiştirebilirsin.")
                    .font(.ui(FontSize.sm))
                    .foregroundStyle(ThemeColor.textFaint.color)
                    .padding(.top, Space.s2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.s4)
        .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.fill.color))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }
}

/// Oynat üçgeni (web <path d="M5 3l14 9-14 9V3z" />)
struct PlayShape: Shape {
    func path(in r: CGRect) -> Path {
        let s = r.width / 24
        var p = Path()
        p.move(to: CGPoint(x: r.minX + 5 * s, y: r.minY + 3 * s))
        p.addLine(to: CGPoint(x: r.minX + 19 * s, y: r.minY + 12 * s))
        p.addLine(to: CGPoint(x: r.minX + 5 * s, y: r.minY + 21 * s))
        p.closeSubpath()
        return p
    }
}

/// Yalnız seçili öğeyi tanıtım hedefi yapar (web data-coach yalnız Sol anahtarı kartında)
private struct CoachIf: ViewModifier {
    let on: Bool
    let name: String
    func body(content: Content) -> some View {
        if on { content.coachTarget(name).id(name) } else { content }
    }
}
