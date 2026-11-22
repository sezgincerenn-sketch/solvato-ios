// Oyunlar: liste (günün meydan okuması, arkadaşına meydan oku, akor düellosu), günün meydan okuması, arkadaşına meydan
// oku (konu + Başla; gelen kod) ve oyun sonucu (günlük / yeni kod / karşılaştırma). Web src/screens/GamesScreen.tsx,
// GameResultScreen.tsx. Yazılar SolvatoCore GameScreens / GameResultContent'ten (web'le altın tabloyla aynı).
import SolvatoCore
import SwiftUI

/// Oyun sayfalarının ortak iskeleti: başlık + kaydırılan gövde (web `page` + `body`)
private struct GamePage<C: View>: View {
    let title: String
    let model: AppModel
    @ViewBuilder let content: C

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: title) { model.back() }
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s3) { content }
                    .padding(.horizontal, Space.s4)
                    .padding(.top, Space.s2)
                    .padding(.bottom, Space.s6)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(ThemeColor.bg.color)
    }
}

@MainActor
private func muted(_ t: String) -> some View {
    Text(t)
        .font(.ui(FontSize.sm))
        .foregroundStyle(ThemeColor.textMuted.color)
        .lineHeight(1.5, size: FontSize.sm)
        .fixedSize(horizontal: false, vertical: true)
}

// MARK: - Liste
struct GamesListScreen: View {
    let model: AppModel

    var body: some View {
        let today = model.todayGame
        GamePage(title: "Oyunlar", model: model) {
            muted("Bir oyun seç.")
            row(.calendar, CategoryColor.games.base, "Günün meydan okuması", GameScreens.dailySub(today), GameScreens.dailyStatus(model.todayDaily)) {
                model.go(.gameDaily)
            }
            row(.users, .violet500, "Arkadaşına meydan oku", "Oyna, kodu gönder; o da aynı soruları çözsün. Sana kod geldiyse buradan gir.", nil) {
                model.go(.gameChallenge)
            }
            row(.flame, .amber500, "Akor düellosu", "İki kişi, tek telefon: akoru ilk bilen kazanır", nil) { model.go(.duel) }
        }
    }

    private func row(_ icon: IconName, _ color: PaletteColor, _ title: String, _ sub: String, _ status: String?, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Space.s3) {
                IconBadge(name: icon, color: color)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color).lineHeight(1.5, size: FontSize.md)
                    Text(sub).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color).lineHeight(1.5, size: FontSize.sm)
                        .fixedSize(horizontal: false, vertical: true)
                    if let status {
                        Text(status).font(.mono(FontSize.xs, .bold)).foregroundStyle(ThemeColor.textSubtle.color).padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("›").font(.ui(FontSize.lg)).foregroundStyle(ThemeColor.textMuted.color).accessibilityHidden(true)
            }
            .padding(Space.s4)
            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(color.opacity(Double(0x0F) / 255)))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(color.opacity(Double(0x4D) / 255), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Günün meydan okuması
struct DailyGameScreen: View {
    let model: AppModel

    var body: some View {
        let today = model.todayGame
        let played = model.todayDaily
        GamePage(title: "Günün meydan okuması", model: model) {
            AppCard(tone: CategoryColor.games.base) {
                VStack(alignment: .leading, spacing: Space.s3) {
                    Text("BUGÜN · #\(today.number)")
                        .font(.ui(FontSize.xs, .bold))
                        .tracking(em: Tracking.label, size: FontSize.xs)
                        .foregroundStyle(ThemeColor.textSubtle.color)
                    Text(today.category.label).font(.ui(FontSize.lg, .heavy)).foregroundStyle(ThemeColor.text.color)
                    if let p = played {
                        HStack(alignment: .firstTextBaseline, spacing: Space.s2) {
                            Text("\(p.correct)/\(Games.length)").font(.mono(FontSize.xl, .heavy)).foregroundStyle(ThemeColor.text.color)
                            Spacer(minLength: 0)
                            muted(Games.formatSeconds(p.sec))
                        }
                        Text(p.marks).font(.ui(FontSize.md)).tracking(1)
                        muted(GameScreens.dailyFooter(streak: model.gameStreak))
                        AppButton(
                            "Sonucu paylaş", variant: .success, block: true,
                            share: GameScreens.dailyShareText(no: today.number, category: today.category, correct: p.correct, sec: p.sec, marks: p.marks))
                    } else {
                        muted(GameScreens.dailyIntro)
                        AppButton("Oyna", variant: .success, block: true) {
                            model.startGame(.daily(date: today.date, category: today.category, seed: today.seed, number: today.number))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Arkadaşına meydan oku
struct ChallengeGameScreen: View {
    let model: AppModel
    @State private var category: GameCategory = .all
    @State private var code = ""
    @State private var err = ""

    var body: some View {
        let level = model.settings.level
        GamePage(title: "Arkadaşına meydan oku", model: model) {
            AppCard {
                VStack(alignment: .leading, spacing: Space.s3) {
                    Text("Yeni meydan okuma").font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color)
                    muted("Konuyu seç, \(Games.length) soruyu çöz. Sonunda arkadaşına göndereceğin bir kod çıkar.")
                    FlowLayout(spacing: 6) {
                        ForEach(GameCategory.allCases, id: \.self) { c in
                            Chip(c.label, selected: category == c) { category = c }
                        }
                    }
                    Text("Sorular senin seviyende gelir (\(QuestionLevel.label(level))).")
                        .font(.ui(FontSize.xs))
                        .foregroundStyle(ThemeColor.textFaint.color)
                    AppButton("Başla", block: true) { model.startNewChallenge(category) }
                }
            }
            AppCard {
                VStack(alignment: .leading, spacing: Space.s3) {
                    Text("Sana kod mu geldi?").font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color)
                    muted("Arkadaşının gönderdiği 8 karakterlik kodu yaz; aynı soruları çöz, sonuçları karşılaştır.")
                    CodeField(
                        code: $code, error: $err, placeholder: "ABCD-EFGH", label: "Meydan okuma kodu", button: "Kabul et",
                        sanitize: GameScreens.sanitizeCode, onSubmit: accept)
                }
            }
        }
    }

    private func accept() {
        guard let ch = ChallengeCode.decode(code) else {
            err = GameScreens.invalidCode
            return
        }
        model.startGame(.challenge(category: ch.category, level: ch.level, seed: ch.seed, opponent: ch))
    }
}

// MARK: - Oyun sonucu
struct GameResultScreen: View {
    let model: AppModel

    var body: some View {
        if let c = model.gameResult {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 14) {
                        IconBadge(name: icon(c.badge), color: c.badgeColor, size: .lg, glow: true)
                        VStack(spacing: Space.s1) {
                            Text(c.title)
                                .font(.ui(FontSize.xl, .heavy))
                                .tracking(em: Tracking.tight, size: FontSize.xl)
                                .foregroundStyle(ThemeColor.text.color)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                            Text(c.categoryLabel).font(.ui(FontSize.sm, .medium)).foregroundStyle(ThemeColor.textSubtle.color)
                        }
                        content(c)
                        Spacer(minLength: 0)
                        VStack(spacing: Space.s2) {
                            AppButton(c.shareLabel, block: true, share: c.shareText) { Icon(.share, size: 18) }
                            if case .compare = c.kind {
                                AppButton("Sen de ona meydan oku", variant: .secondary, block: true) {
                                    if let g = model.game { model.startNewChallenge(g.category) }
                                }
                            }
                            AppButton("Kapat", variant: .secondary, block: true) { model.back() }
                        }
                        .frame(maxWidth: 360)
                        .padding(.top, Space.s2)
                    }
                    .padding(.top, 36)
                    .padding(.horizontal, Space.s5)
                    .padding(.bottom, Space.s6)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollIndicators(.hidden)
            }
            .background(ThemeColor.bg.color)
        }
    }

    private func icon(_ b: GameResultContent.Badge) -> IconName {
        switch b {
        case .calendar: .calendar
        case .users: .users
        case .trophy: .trophy
        }
    }

    @ViewBuilder private func content(_ c: GameResultContent) -> some View {
        switch c.kind {
        case .daily:
            ScoreRing(value: c.correct, max: Games.length, caption: "doğru")
            Marks(results: c.marks)
            HStack(spacing: 10) {
                StatTile(value: Games.formatSeconds(c.sec), label: "Süre")
                StatTile(value: "\(c.dailyStreak) gün", label: "Seri")
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 360)
            Text(GameResultContent.dailyNote)
                .font(.ui(FontSize.sm))
                .foregroundStyle(ThemeColor.textMuted.color)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        case let .newChallenge(code):
            ScoreRing(value: c.correct, max: Games.length, caption: "doğru")
            Marks(results: c.marks)
            VStack(spacing: 2) {
                Text("MEYDAN OKUMA KODU")
                    .font(.ui(FontSize.xs, .bold))
                    .tracking(em: Tracking.label, size: FontSize.xs)
                    .foregroundStyle(ThemeColor.violetText.color)
                Text(code)
                    .font(.mono(FontSize.xxl, .heavy))
                    .tracking(3)
                    .foregroundStyle(ThemeColor.text.color)
                    .textSelection(.enabled)
                Text("\(Games.formatSeconds(c.sec)) · arkadaşın aynı soruları çözecek")
                    .font(.ui(FontSize.sm))
                    .foregroundStyle(ThemeColor.textMuted.color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, Space.s4)
            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(PaletteColor.violet500.opacity(0.1)))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(PaletteColor.violet400.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
            .frame(maxWidth: 360)
        case let .compare(o, win):
            HStack(spacing: 10) {
                player("Sen", c.correct, c.sec, win == true)
                player("Arkadaşın", o.correct, o.sec, win == false)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 360)
            Marks(results: c.marks)
            if c.showsTieBreak {
                Text(GameResultContent.tieBreakNote).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
            }
        }
    }

    private func player(_ label: String, _ correct: Int, _ sec: Int, _ winner: Bool) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.ui(FontSize.sm, .bold)).foregroundStyle(winner ? ThemeColor.violetTextSoft.color : ThemeColor.textMuted.color)
            ScoreRing(value: correct, max: Games.length, size: 104, caption: "doğru")
            Text(Games.formatSeconds(sec)).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
        }
        .padding(.vertical, Space.s3)
        .padding(.horizontal, Space.s2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: Radius.lg).fill(winner ? PaletteColor.violet500.opacity(0.14) : ThemeColor.fill.color))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(winner ? PaletteColor.violet500.color : ThemeColor.border.color, lineWidth: 1))
    }
}

/// Soru soru yeşil/kırmızı kutucuklar
private struct Marks: View {
    let results: [Bool]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(results.enumerated()), id: \.offset) { _, ok in
                RoundedRectangle(cornerRadius: Radius.xs)
                    .fill(ok ? PaletteColor.green500.color : PaletteColor.red500.color)
                    .opacity(ok ? 0.9 : 0.75)
                    .frame(width: 18, height: 18)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Soru soru sonuçlar: \(results.filter { $0 }.count) doğru, \(results.filter { !$0 }.count) yanlış")
    }
}
