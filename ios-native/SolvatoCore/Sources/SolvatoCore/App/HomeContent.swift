// Pratik (ana sayfa) içeriği: hangi kart görünür, hangi yazı yazar. Web karşılığı src/screens/HomeScreen.tsx ve
// screens/profile/LevelCard.tsx. SwiftUI ekranı (Screens/HomeScreen) yalnızca bunu çizer. `texts` / `labels` ekranda
// görünen yazıları ve erişilebilirlik adlarını web'deki sırayla verir; altın tabloyla karşılaştırılır.
import Foundation

public struct HomeContent: Equatable, Sendable {
    public struct Category: Equatable, Sendable {
        public enum IconKind: Equatable, Sendable {
            case clef(Clef)
            case speaker
            case symbol(String)
        }
        public var key: FilterCategory
        public var label: String
        public var sub: String
        public var color: CategoryColor
        public var icon: IconKind
        /// Bu konudaki en iyi tur yıldızı (bir kez oynanınca)
        public var stars: Int?
    }

    public struct Link: Equatable, Sendable {
        public var round: SpecialRound
        public var color: CategoryColor
        public var icon: IconName
        public var title: String
        public var sub: String
        public var stars: Int?
    }

    public enum Row: Equatable, Sendable {
        case category(Category)
        case link(Link)
    }

    public struct Group: Equatable, Sendable {
        /// "Diğer konular (4)" başlığı; ana grupta nil
        public var restTitle: String?
        public var rows: [Row]
    }

    // Üst çubuk
    public var streak: Int
    public var streakLabel: String
    public var rank: RankInfo
    public var xpValue: String
    public var xpLabel: String
    public var name: String
    public var avatarColor: String
    public var avatarInitial: String
    public var greeting: String?
    // Seviye kartı
    public var level: Int
    public var levelLabel: String
    /// 0–100; en üst seviyede nil (çubuk yok)
    public var levelPct: Double?
    public var levelNote: String
    // Bugün
    public var dailyText: String
    public var goalDone: Bool
    /// Hedefe kalan yazısı; hedef tamamsa "Bugünün serisi tamam" (önünde alev)
    public var goalFooter: String
    public var dailySolved: Int
    public var dailyGoal: Int
    public var todayTitle: String
    public var todaySub: String
    // Oyunlar kartı
    public var gamesBadge: String
    public var gamesDone: Bool
    // Konular
    public var sectionTitle: String
    public var groups: [Group]

    static let baseCategories: [(FilterCategory, String, String, CategoryColor, Category.IconKind)] = [
        (.treble, "Sol Anahtarı", "Sağ el notaları", .treble, .clef(.treble)),
        (.bass, "Fa Anahtarı", "Sol el notaları", .bass, .clef(.bass)),
        (.accidentals, "Diyez & Bemol", "Siyah tuşlar: ♯ yukarı, ♭ aşağı", .accidentals, .symbol("♯")),
        (.rhythm, "Ritim & Ölçü", "Nota değerleri, ölçüler", .rhythm, .symbol("♩")),
        (.ear, "Kulak", "Dinle, notayı ve akoru bul", .ear, .speaker),
        (.writing, "Nota Yazımı", "Hangisi doğru yazılmış?", .writing, .symbol("✎")),
        (.terms, "Müzik Terimleri", "Dinamik, tempo, artikülasyon", .terms, .symbol("𝄆")),
    ]

    /// "Günaydın" … saat yerel
    public static func greeting(hour: Int) -> String {
        hour < 6 ? "İyi geceler" : hour < 12 ? "Günaydın" : hour < 18 ? "Merhaba" : "İyi akşamlar"
    }

    public init(stats: AppStats, settings s: Settings, daily: DailyRecord?, now: Now) {
        let lv = s.level
        let rank = Ranks.from(xp: stats.totalPoints)
        let streak = Progress.currentStreak(stats, now: now)
        self.streak = streak
        streakLabel = streak > 0 ? "\(streak) gün seri. Haftanı gör" : "Seri yok. Bugün bir tur çözünce başlar"
        self.rank = rank
        xpValue = "\(stats.totalPoints) XP"
        xpLabel = "\(stats.totalPoints) XP, \(rank.rank). ünvan: \(rank.label). Profili aç"
        let trimmed = s.name.trimmingCharacters(in: .whitespacesAndNewlines)
        name = s.name
        avatarColor = s.avatarColor
        avatarInitial = String(trimmed.prefix(1)).uppercased(with: Locale(identifier: "tr"))
        greeting = trimmed.isEmpty ? nil : "\(Self.greeting(hour: now.clock.calendar.component(.hour, from: now.date))), \(trimmed)"

        // Seviye kartı (LevelCard)
        level = lv
        levelLabel = QuestionLevel.label(lv)
        let n = s.levelProgress.n, c = s.levelProgress.c
        let acc = n > 0 ? jsRound(Double(c) / Double(n) * 100) : nil
        let need = Progress.levelNeed
        let accNeed = jsRound(Progress.levelAcc * 100)
        if lv >= 3 {
            levelPct = nil
            levelNote = "En üst seviyedesin. Ek çizgili zor notalar açık."
        } else {
            levelPct = min(100, Double(n) / Double(need) * 100)
            let next = QuestionLevel.label(lv + 1)
            levelNote =
                n == 0
                ? "\(next) için bu seviyede \(need) soru çöz, %\(accNeed) doğru yap."
                : "\(next) seviyesine: \(min(n, need))/\(need) soru · %\(acc!) doğru"
                    + (acc! >= accNeed ? "" : " (en az %\(accNeed))")
        }

        // Bugün
        let solved = stats.dailyQuestions[now.todayKey] ?? 0
        dailySolved = solved
        dailyGoal = s.dailyGoal
        goalDone = solved >= s.dailyGoal
        dailyText = (goalDone ? "Hedef tamam · " : "") + "\(min(solved, 9999))/\(s.dailyGoal) soru"
        goalFooter = goalDone ? "Bugünün serisi tamam" : "Hedefi tamamlayınca serin +1 olur · \(max(0, s.dailyGoal - solved)) soru kaldı"
        todayTitle = goalDone ? "Bir tur daha" : solved > 0 ? "Devam et" : "Bugünün çalışması"
        let teacherPick = !TeacherCode.allTopics(s.topics)
        todaySub = teacherPick ? "Karma 10 soru · öğretmeninin seçtiği konulardan" : "Karma 10 soru · nota, ritim ve terimler"
        gamesDone = daily != nil
        gamesBadge = daily.map { "Bugün \($0.correct)/10" } ?? "Günün oyunu"
        sectionTitle = teacherPick ? "Öğretmeninin seçtiği konular" : "Pratik Kategorileri"

        // Konular: öğretmen konu seçtiyse seçilenler üstte, diğerleri "Diğer konular" altında
        let limitedNotes = s.notes.count < 7
        func assigned(_ k: String) -> Bool {
            !teacherPick || s.topics.contains(k) || (k == "accidentals" && (s.topics.contains("treble") || s.topics.contains("bass")))
        }
        let cats = Self.baseCategories.map { key, label, sub, color, icon in
            Category(
                key: key, label: label,
                sub: (key == .treble || key == .bass) && limitedNotes ? "Sadece \(s.notes.joined(separator: " "))" : sub,
                color: color, icon: icon, stars: stats.bestStars?[key.rawValue])
        }
        let allKeys = cats.map(\.key.rawValue) + ["chords"]
        func rows(_ has: (String) -> Bool) -> [Row] {
            var out: [Row] = []
            for c in cats {
                if has(c.key.rawValue) && !(c.key == .accidentals && lv < 2) { out.append(.category(c)) }
                if c.key == .accidentals && has("chords") {
                    out.append(
                        .link(Link(round: .chords, color: .chords, icon: .piano, title: "Akor", sub: "Tanı, tuşlara bas", stars: stats.bestStars?["chords"])))
                }
                // Web'de olduğu gibi Ritmi Tut her grupta ritmin ardından (konu seçiminden bağımsız)
                if c.key == .rhythm {
                    out.append(
                        .link(Link(round: .rhythmtap, color: .rhythm, icon: .note, title: "Ritmi Tut", sub: "Metronomla dokunarak çal", stars: stats.bestStars?["rhythmtap"])))
                }
            }
            return out
        }
        var groups = [Group(restTitle: nil, rows: rows(assigned))]
        if teacherPick {
            let count = allKeys.filter { !assigned($0) && !($0 == "accidentals" && lv < 2) }.count
            groups.append(Group(restTitle: "Diğer konular (\(count))", rows: rows { !assigned($0) }))
        }
        self.groups = groups
    }

    /// Ekranda görünen yazılar ve erişilebilirlik adları, web'deki sırayla (diğer konular kapalıyken)
    public var texts: (texts: [String], labels: [String]) {
        var t = ["Solv", "ato", String(streak), String(rank.rank), xpValue]
        var l = ["Solvato", streakLabel, xpLabel, "Profil", "Seviye: \(levelLabel). Profili aç", "3 seviyeden \(level)."]
        if !avatarInitial.isEmpty { t.append(avatarInitial) }
        if let greeting { t.append(greeting) }
        t += ["Seviye", levelLabel] + [1, 2, 3].map(QuestionLevel.label) + [levelNote]
        t += ["Bugün", dailyText, goalFooter, todayTitle, todaySub, "Oyunlar", "Meydan okuma ve düello", gamesBadge, sectionTitle]
        for g in groups {
            if let r = g.restTitle {
                t += [r, "▾"]
                continue
            }
            for row in g.rows {
                switch row {
                case let .category(c):
                    if case let .symbol(s) = c.icon { t.append(s) }
                    t += [c.label, c.sub]
                    if let s = c.stars { l.append("3 yıldızdan \(s)") }
                case let .link(k):
                    t += [k.title, k.sub]
                    if let s = k.stars { l.append("3 yıldızdan \(s)") }
                }
            }
        }
        return (t, l)
    }
}
