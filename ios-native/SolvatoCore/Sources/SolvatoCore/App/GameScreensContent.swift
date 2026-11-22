// Oyunlar ekranlarının yazıları: liste, günün meydan okuması, arkadaşına meydan oku ve oyun sonucu (günlük / yeni kod /
// karşılaştırma). Web src/screens/GamesScreen.tsx, GameResultScreen.tsx, gameShared.ts. Altın tablo
// oyun-ekranlari.json ile web'le aynı; ekranlar Solvato/Screens/GamesScreen.swift.
import Foundation

public enum GameScreens {
    public static let invalidCode = "Kod geçersiz. 8 karakteri kontrol et."

    /// Listedeki günün meydan okuması satırı
    public static func dailySub(_ today: DailyInfo) -> String { "Herkese aynı \(Games.length) soru · bugün \(today.category.label)" }
    public static func dailyStatus(_ played: DailyRecord?) -> String {
        played.map { "Bugün oynandı · \($0.correct)/\(Games.length)" } ?? "Bugün henüz oynanmadı"
    }

    public static func dailyShareText(no: Int, category: GameCategory, correct: Int, sec: Int, marks: String) -> String {
        "🎹 Solvato · Günün meydan okuması #\(no)\n\(category.label) · \(correct)/\(Games.length) · \(Games.formatSeconds(sec))\n\(marks)"
    }

    public static func dailyFooter(streak: Int) -> String {
        "Yarın yeni sorular gelecek." + (streak > 1 ? " \(streak) gündür üst üste oynuyorsun." : "")
    }

    public static let dailyIntro =
        "Herkes bugün aynı \(Games.length) soruyu çözüyor. Günde bir kez oynanır, ilk denemen sayılır. Bitince sonucunu arkadaşlarına gönder, kim daha iyi yapmış görün."

    /// Meydan okuma kodu kutusu: büyük harf, en çok 9 karakter
    public static func sanitizeCode(_ s: String) -> String { String(s.uppercased().prefix(9)) }

    /// Ekran yazıları sırasıyla (altın tablo karşılaştırması için)
    public static func listTexts(today: DailyInfo, played: DailyRecord?) -> [String] {
        ["Oyunlar", "Bir oyun seç.", "Günün meydan okuması", dailySub(today), dailyStatus(played), "›", "Arkadaşına meydan oku",
         "Oyna, kodu gönder; o da aynı soruları çözsün. Sana kod geldiyse buradan gir.", "›", "Akor düellosu",
         "İki kişi, tek telefon: akoru ilk bilen kazanır", "›"]
    }

    public static func dailyTexts(today: DailyInfo, played: DailyRecord?, streak: Int) -> [String] {
        var t = ["Günün meydan okuması", "Bugün · #\(today.number)", today.category.label]
        if let p = played {
            t += ["\(p.correct)/\(Games.length)", Games.formatSeconds(p.sec), p.marks, dailyFooter(streak: streak), "Sonucu paylaş"]
        } else {
            t += [dailyIntro, "Oyna"]
        }
        return t
    }

    public static func challengeTexts(level: Int) -> [String] {
        ["Arkadaşına meydan oku", "Yeni meydan okuma", "Konuyu seç, \(Games.length) soruyu çöz. Sonunda arkadaşına göndereceğin bir kod çıkar."]
            + GameCategory.allCases.map(\.label)
            + ["Sorular senin seviyende gelir (\(QuestionLevel.label(level))).", "Başla", "Sana kod mu geldi?",
               "Arkadaşının gönderdiği 8 karakterlik kodu yaz; aynı soruları çöz, sonuçları karşılaştır.", "Kabul et"]
    }
}

/// Oyun sonucu ekranının içeriği (web GameResultScreen)
public struct GameResultContent: Sendable {
    public enum Kind: Sendable { case daily, newChallenge(code: String), compare(opponent: Challenge, win: Bool?) }
    public enum Badge: Sendable { case calendar, users, trophy }

    public let kind: Kind
    public let correct: Int
    public let sec: Int
    public let marks: [Bool]
    public let title: String
    public let categoryLabel: String
    public let badge: Badge
    public let badgeColor: PaletteColor
    public let shareLabel: String
    public let shareText: String
    public let dailyStreak: Int

    public init(ctx: GameContext, results: [RoundAnswer], name: String, dailyStreak: Int) {
        let sum = Games.summarize(results.map { ($0.correct, $0.timeMs) })
        correct = sum.correct
        sec = sum.sec
        marks = results.map(\.correct)
        self.dailyStreak = dailyStreak
        let cat = ctx.category.label
        categoryLabel = cat
        let n = Games.length
        let fmt = Games.formatSeconds
        switch ctx {
        case let .daily(_, category, _, no):
            kind = .daily
            badge = .calendar
            badgeColor = .green500
            title = "Günün meydan okuması #\(no)"
            shareLabel = "Sonucu paylaş"
            shareText = GameScreens.dailyShareText(no: no, category: category, correct: sum.correct, sec: sum.sec, marks: sum.marks)
        case let .challenge(category, level, seed, nil):
            let code = ChallengeCode.encode(Challenge(category: category, level: level, seed: seed, correct: sum.correct, sec: sum.sec))
            kind = .newChallenge(code: code)
            badge = .users
            badgeColor = .violet500
            title = "Meydan okuman hazır"
            shareLabel = "Kodu gönder"
            let who = name.trimmingCharacters(in: .whitespacesAndNewlines)
            shareText =
                "\(who.isEmpty ? "Bir arkadaşın" : who) sana meydan okuyor! 🎹\n\(cat): \(sum.correct)/\(n) · \(fmt(sum.sec))\nGeçebilir misin? Solvato'da Oyunlar › \"Sana kod mu geldi?\" kısmına yaz:\n\(code)"
        case let .challenge(_, _, _, o?):
            // Önce doğru sayısı, eşitse süre; ikisi de eşitse berabere
            let win: Bool? = sum.correct != o.correct ? sum.correct > o.correct : sum.sec != o.sec ? sum.sec < o.sec : nil
            kind = .compare(opponent: o, win: win)
            if win == false {
                badge = .users
                badgeColor = .amber500
            } else {
                badge = .trophy
                badgeColor = win == true ? .amber400 : .violet500
            }
            title = win == nil ? "Berabere!" : win! ? "Kazandın!" : "Bu sefer o kazandı"
            shareLabel = "Sonucu gönder"
            func score(_ c: Int, _ s: Int) -> String { "\(c)/\(n) (\(fmt(s)))" }
            switch win {
            case nil: shareText = "\(cat) meydan okumasında berabere kaldık: ikimiz de \(sum.correct)/\(n), \(fmt(sum.sec)) 🤝"
            case true?: shareText = "\(cat) meydan okumanı geçtim: \(score(sum.correct, sum.sec)), sen \(score(o.correct, o.sec)) 😎"
            case false?:
                shareText = "\(cat) meydan okumanda \(score(sum.correct, sum.sec)) yaptım. Sen \(o.correct)/\(n) ile kazandın, rövanş istiyorum!"
            }
        }
    }

    public static let dailyNote = "Arkadaşların da bugün aynı soruları çözüyor. Sonucunu gönder, kim daha iyi yapmış görün."
    public static let tieBreakNote = "Doğru sayısı eşit, hızlı olan kazandı."

    /// "Doğru sayısı eşit, hızlı olan kazandı." görünsün mü
    public var showsTieBreak: Bool {
        if case let .compare(o, win) = kind { return win != nil && correct == o.correct }
        return false
    }

    /// Ekrandaki yazılar sırasıyla (halka içindeki sayılar hariç; altın tablo karşılaştırması için)
    public var texts: [String] {
        var t = [title, categoryLabel]
        switch kind {
        case .daily:
            t += [Games.formatSeconds(sec), "Süre", "\(dailyStreak) gün", "Seri", Self.dailyNote]
        case let .newChallenge(code):
            t += ["Meydan okuma kodu", code, "\(Games.formatSeconds(sec)) · arkadaşın aynı soruları çözecek"]
        case let .compare(o, _):
            t += ["Sen", Games.formatSeconds(sec), "Arkadaşın", Games.formatSeconds(o.sec)]
            if showsTieBreak { t.append(Self.tieBreakNote) }
        }
        t.append(shareLabel)
        if case .compare = kind { t.append("Sen de ona meydan oku") }
        return t + ["Kapat"]
    }
}
