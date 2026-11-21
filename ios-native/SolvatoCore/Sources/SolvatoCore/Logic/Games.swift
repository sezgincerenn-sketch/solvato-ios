// Oyunlar: günün meydan okuması ve kodla arkadaşa meydan okuma. Web karşılığı src/utils/games.ts.
// Aynı tohum (seed) React'ta ve burada aynı soruları aynı sırayla, aynı şıklarla üretir.
import Foundation

public enum GameCategory: String, CaseIterable, Sendable {
    case all, treble, bass, rhythm, terms, writing

    public var label: String {
        switch self {
        case .all: "Karışık"
        case .treble: "Sol anahtarı"
        case .bass: "Fa anahtarı"
        case .rhythm: "Ritim"
        case .terms: "Terimler"
        case .writing: "Nota yazımı"
        }
    }
}

public struct DailyInfo: Equatable, Sendable {
    public var date: String
    public var category: GameCategory
    public var seed: Int
    /// "Günün meydan okuması #N"
    public var number: Int
}

/// Günün meydan okuması kaydı (`notalik-daily`: tarih → kayıt)
public struct DailyRecord: Equatable, Sendable {
    public var date: String
    public var correct: Int
    public var sec: Int
    /// "🟩🟥…"
    public var marks: String
}

public enum Games {
    public static let length = 10
    public static let dailyStorageKey = "notalik-daily"
    static let dailyOrder: [GameCategory] = [.all, .treble, .bass, .rhythm, .all, .terms, .writing]

    /// Oyun soruları: kategori + seviye + tohum (ipucu ve süre yok)
    public static func questions(_ cat: GameCategory, level: Int, seed: Int, bank: [Question] = QuestionBank.all) -> [Question] {
        let r = seededRandom(UInt32(truncatingIfNeeded: seed))
        var pool = bank.filter { QuestionBank.level(of: $0) <= level }
        switch cat {
        case .treble, .bass:
            pool = pool.filter { $0.category == .noteIdentification && $0.clef?.rawValue == cat.rawValue }
        case .rhythm: pool = pool.filter { $0.category == .rhythm }
        case .terms: pool = pool.filter { $0.category == .musicalTerms }
        case .writing: pool = pool.filter { $0.category == .writing }
        case .all:
            // Karışık: yarısı nota, yarısı diğer konular
            let notes = Array(shuffled(pool.filter { $0.category == .noteIdentification }, r).prefix(5))
            let other = Array(shuffled(pool.filter { $0.category != .noteIdentification }, r).prefix(length - notes.count))
            pool = notes + other
        }
        // Sıralama her iki telefonda aynı olsun diye önce kimliğe göre diz
        pool = stableSorted(pool) { $0.id < $1.id }
        return shuffled(pool, r).prefix(length).map { q in
            guard q.category != .noteIdentification, q.optionScores == nil else { return q }
            var c = q
            c.options = shuffled(q.options, r)
            return c
        }
    }

    /// Tarih ("2026-11-18") → kategori (7 günlük döngü), tohum (FNV-1a), numara
    public static func dailyInfo(_ date: String) -> DailyInfo {
        let p = date.split(separator: "-").compactMap { Int($0) }
        let dayNo = daysFromCivil(p[0], p[1], p[2])
        var h: UInt32 = 2_166_136_261
        for u in date.utf16 { h = (h ^ UInt32(u)) &* 16_777_619 }
        return DailyInfo(date: date, category: dailyOrder[((dayNo % 7) + 7) % 7], seed: Int(h & 0xFFFF), number: dayNo - 20774)
    }

    /// 1970-01-01'den bu yana gün (Date.UTC / 86400000)
    static func daysFromCivil(_ y0: Int, _ m: Int, _ d: Int) -> Int {
        let y = m <= 2 ? y0 - 1 : y0
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    /// Oyun serisi: bugünden (oynanmadıysa dünden) geriye ardışık oynanan gün
    public static func dailyStreak(_ played: Set<String>, now: Now) -> Int {
        let clock = now.clock
        var d = clock.startOfDay(now.date)
        func back(_ x: Date) -> Date {
            let c = clock.calendar.dateComponents([.year, .month, .day], from: x)
            return clock.date(year: c.year!, month: c.month!, day: c.day! - 1)
        }
        if !played.contains(clock.dayKey(d)) { d = back(d) }
        var n = 0
        while played.contains(clock.dayKey(d)) {
            n += 1
            d = back(d)
        }
        return n
    }

    public static func summarize(_ results: [(correct: Bool, timeMs: Int)]) -> (correct: Int, sec: Int, marks: String) {
        (
            results.filter(\.correct).count,
            jsRound(Double(results.reduce(0) { $0 + $1.timeMs }) / 1000),
            results.map { $0.correct ? "🟩" : "🟥" }.joined()
        )
    }

    /// "42 sn", "1 dk 5 sn"
    public static func formatSeconds(_ sec: Int) -> String {
        sec >= 60 ? "\(sec / 60) dk \(sec % 60) sn" : "\(sec) sn"
    }

    public static func newSeed() -> Int { Int.random(in: 0..<65536) }
}
