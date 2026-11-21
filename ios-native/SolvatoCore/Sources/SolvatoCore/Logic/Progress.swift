// Tur sonu kuralları: XP, seri, günlük hedef, kutlama, seviye atlama, konu kaydı, yıldız rekoru.
// Web karşılığı src/state/stats.ts ve App.tsx `handleComplete` / `handleSpecialComplete` (istatistik kısmı).
import Foundation

/// Tur türleri (web FilterCategory)
public enum FilterCategory: String, Sendable, CaseIterable {
    case all, treble, bass, rhythm, terms, accidentals, writing, ear

    /// Kısa adlar (Son turlar listesi, kartlar); web ROUND_LABELS
    public var roundLabel: String {
        switch self {
        case .all: "Karışık"
        case .treble: "Sol Anahtarı"
        case .bass: "Fa Anahtarı"
        case .accidentals: "Diyez & Bemol"
        case .rhythm: "Ritim"
        case .writing: "Nota Yazımı"
        case .terms: "Müzik Terimleri"
        case .ear: "Kulak"
        }
    }
}

/// Soru bankası dışındaki turlar
public enum SpecialRound: String, Sendable {
    case chords, rhythmtap
}

/// Bir sorunun sonucu (web SessionResult)
public struct SessionResult: Equatable, Sendable {
    public var questionId: Int
    public var category: QuestionCategory
    public var clef: Clef?
    public var correct: Bool
    public var timeMs: Int
    public var hasLedger: Bool?
    public var noteY: Int?
    public var accidental: Accidental?

    public init(
        questionId: Int, category: QuestionCategory, clef: Clef? = nil, correct: Bool, timeMs: Int,
        hasLedger: Bool? = nil, noteY: Int? = nil, accidental: Accidental? = nil
    ) {
        self.questionId = questionId
        self.category = category
        self.clef = clef
        self.correct = correct
        self.timeMs = timeMs
        self.hasLedger = hasLedger
        self.noteY = noteY
        self.accidental = accidental
    }

    /// Sorudan sonuç (QuizSession'daki gibi)
    public init(question q: Question, correct: Bool, timeMs: Int) {
        self.init(
            questionId: q.id, category: q.category, clef: q.clef, correct: correct, timeMs: timeMs,
            hasLedger: (q.ledgerLines?.count ?? 0) > 0, noteY: q.noteY, accidental: q.accidental)
    }

    /// Haftalık rapordaki konu (web topicOf)
    public var topic: String {
        switch category {
        case .noteIdentification: accidental != nil ? "accidentals" : clef == .bass ? "bass" : "treble"
        case .musicalTerms: "terms"
        default: category.rawValue  // rhythm | writing | ear
        }
    }
}

public struct Celebration: Equatable, Sendable {
    public struct RankUp: Equatable, Sendable {
        public var rank: Int
        public var label: String
        public var nextLabel: String?
    }
    public var rankUp: RankUp?
    public var goalDone = false
    public var streak: Int?
    /// Açılan seviyenin adı ("Orta")
    public var unlocked: String?
}

/// Tarih ve saat dilimi: kuralların "bugün"ü. Uygulamada `.init()`, testlerde sabit.
public struct Now: Sendable {
    public var date: Date
    public var clock: DayClock
    public init(_ date: Date = Date(), clock: DayClock = DayClock()) {
        self.date = date
        self.clock = clock
    }
    var ms: Int { epochMs(date) }
    var todayKey: String { clock.dayKey(date) }
    var todayString: String { clock.dateString(date) }
    /// Web: new Date(Date.now() - 86400000).toDateString() (yaz saatinde de 24 saat; bilerek korunuyor)
    var yesterdayString: String { clock.dateString(date.addingTimeInterval(-86400)) }
}

public enum Progress {
    public static let levelNeed = 50
    public static let levelAcc = 0.8

    /// Gösterilen seri: son seri günü bugün ya da dün değilse 0
    public static func currentStreak(_ s: AppStats, now: Now) -> Int {
        guard !s.lastPlayDate.isEmpty else { return 0 }
        return s.lastPlayDate == now.todayString || s.lastPlayDate == now.yesterdayString ? s.streak : 0
    }

    /// Tur sonrası ortak güncelleme: XP, tur sayısı, günlük kayıt, son turlar, seri (yalnız hedef tamamlanınca)
    public static func apply(
        _ prev: AppStats, points: Int, questionCount: Int = 0,
        round: (label: String, correct: Int, total: Int, sec: Int?)?, dailyGoal: Int, now: Now
    ) -> AppStats {
        var next = prev
        next.dailyAccuracy = prev.dailyAccuracy ?? OrderedMap()
        let k = now.todayKey
        if let round {
            let rec = RoundRecord(at: now.ms, label: round.label, correct: round.correct, total: round.total, sec: round.sec)
            next.history = Array(([rec] + (prev.history ?? [])).prefix(AppStats.historyMax))
            let d = next.dailyAccuracy![k] ?? .zero
            next.dailyAccuracy![k] = d.adding(correct: round.correct, total: round.total)
        }
        next.totalPoints += points
        next.totalSessions += 1
        next.dailyLog[k] = (next.dailyLog[k] ?? 0) + 1
        next.dailyQuestions[k] = (next.dailyQuestions[k] ?? 0) + questionCount
        let today = now.todayString
        if next.dailyQuestions[k]! >= dailyGoal && next.lastPlayDate != today {
            next.streak = next.lastPlayDate == now.yesterdayString ? next.streak + 1 : 1
            next.lastPlayDate = today
        }
        return next
    }

    /// Tur öncesi ve sonrası karşılaştırması: yeni ünvan, hedef tamamlandı, seri arttı
    public static func detectCelebration(prev: AppStats, next: AppStats, dailyGoal: Int, now: Now) -> Celebration? {
        var data = Celebration()
        let before = Ranks.from(xp: prev.totalPoints)
        let after = Ranks.from(xp: next.totalPoints)
        if after.rank > before.rank {
            data.rankUp = .init(rank: after.rank, label: after.label, nextLabel: after.nextLabel)
        }
        let k = now.todayKey
        if (prev.dailyQuestions[k] ?? 0) < dailyGoal && (next.dailyQuestions[k] ?? 0) >= dailyGoal { data.goalDone = true }
        if next.lastPlayDate != prev.lastPlayDate { data.streak = next.streak }
        return data.rankUp != nil || data.goalDone || (data.streak ?? 0) != 0 ? data : nil
    }

    /// Seviye atlama: bu seviyede ≥50 soru ve ≥%80 doğru → üst seviye. Açılan seviyenin adını döner.
    public static func recordLevelProgress(_ settings: inout Settings, count: Int, correct: Int) -> String? {
        if settings.level >= 3 || count == 0 { return nil }
        let n = settings.levelProgress.n + count
        let c = settings.levelProgress.c + correct
        if n >= levelNeed && Double(c) / Double(n) >= levelAcc {
            settings.level += 1
            settings.levelProgress = LevelProgress(n: 0, c: 0)
            return QuestionLevel.label(settings.level)
        }
        // Eski denemeler sonsuza dek ağırlık taşımasın: son ~50 soruya bak
        let k = n > levelNeed ? Double(levelNeed) / Double(n) : 1
        settings.levelProgress = LevelProgress(n: jsRound(Double(n) * k), c: jsRound(Double(c) * k))
        return nil
    }

    /// Bugünün konu sayılarına ekler; 60 günden eski günleri siler
    public static func recordTopics(_ s: inout AppStats, _ items: [(topic: String, correct: Int, total: Int)], now: Now) {
        let k = now.todayKey
        var all = s.dailyTopics ?? OrderedMap()
        var day = all[k] ?? OrderedMap()
        for it in items { day[it.topic] = (day[it.topic] ?? .zero).adding(correct: it.correct, total: it.total) }
        all[k] = day
        let cutoff = now.clock.dayKey(now.date.addingTimeInterval(-Double(AppStats.topicDays) * 86400))
        for d in all.keys where d < cutoff { all[d] = nil }
        s.dailyTopics = all
    }

    /// Konunun en iyi yıldızını günceller; önceki en iyiyi döner. İlk tur 0 yıldız olsa da kaydedilir.
    @discardableResult
    public static func recordStars(_ s: inout AppStats, key: String, stars: Int) -> Int {
        let had = s.bestStars?[key]
        if had == nil || stars > had! {
            var b = s.bestStars ?? OrderedMap()
            b[key] = stars
            s.bestStars = b
        }
        return had ?? 0
    }
}

// MARK: - Tur bitişi
public struct RoundOutcome: Equatable, Sendable {
    public var stats: AppStats
    public var points: Int
    public var stars: Int
    /// Konunun önceki en iyi yıldızı; oyun, hata tekrarı ve zayıf notalarda nil (yazılmaz)
    public var previousBest: Int?
    public var celebration: Celebration?
}

extension Progress {
    /// Soru turu bitti (web handleComplete). `label`: "Zayıf notalar" / "Hataların tekrarı"; `game`: oyun turu.
    public static func completeQuiz(
        _ stats: AppStats, settings: inout Settings, results: [SessionResult], category: FilterCategory,
        label: String? = nil, game: GameCategory? = nil, now: Now
    ) -> RoundOutcome {
        let correct = results.filter(\.correct).count
        let points = correct * 10
        let name = game.map { "Oyun · \($0.label)" } ?? label ?? category.roundLabel
        let secMs = results.reduce(0) { $0 + $1.timeMs }
        var next = apply(
            stats, points: points, questionCount: results.count,
            round: (name, correct, results.count, jsRound(Double(secMs) / 1000)), dailyGoal: settings.dailyGoal, now: now)

        for r in results where r.category == .noteIdentification {
            guard let y = r.noteY else { continue }
            let key = NoteKey.make(clef: r.clef?.rawValue ?? "undefined", noteY: y, accidental: r.accidental)
            next.noteStats[key] = (next.noteStats[key] ?? .zero).adding(r.correct)
        }
        var acc = next.categoryAccuracy
        for r in results {
            switch r.category {
            case .noteIdentification:
                let ledger = r.hasLedger ?? false
                if r.clef == .treble {
                    acc.treble = acc.treble.adding(r.correct)
                    if ledger { acc.trebleLedger = acc.trebleLedger.adding(r.correct) }
                } else if r.clef == .bass {
                    acc.bass = acc.bass.adding(r.correct)
                    if ledger { acc.bassLedger = acc.bassLedger.adding(r.correct) }
                }
            case .ear: acc.ear = acc.ear.adding(r.correct)
            case .writing: acc.writing = acc.writing.adding(r.correct)
            case .rhythm: acc.rhythm = acc.rhythm.adding(r.correct)
            case .musicalTerms: acc.terms = acc.terms.adding(r.correct)
            }
        }
        next.categoryAccuracy = acc
        // Yıldız: yalnızca normal konu turlarında (oyun, hata tekrarı, zayıf notalar sayılmaz)
        let stars = Stars.forRound(correct: correct, total: results.count)
        let best = game == nil && label == nil ? recordStars(&next, key: category.rawValue, stars: stars) : nil
        recordTopics(&next, results.map { ($0.topic, $0.correct ? 1 : 0, 1) }, now: now)
        var cel = detectCelebration(prev: stats, next: next, dailyGoal: settings.dailyGoal, now: now)
        if let unlocked = recordLevelProgress(&settings, count: results.count, correct: correct) {
            var c = cel ?? Celebration()
            c.unlocked = unlocked
            cel = c
        }
        return RoundOutcome(stats: next, points: points, stars: stars, previousBest: best, celebration: cel)
    }

    /// Akor turu ya da Ritmi Tut bitti (web handleSpecialComplete). Akor doğruluğu "chords"a, Ritmi Tut "rhythm"a.
    public static func completeSpecial(
        _ stats: AppStats, settings: Settings, kind: SpecialRound, answers: [Bool], now: Now
    ) -> RoundOutcome {
        let correct = answers.filter { $0 }.count
        let total = answers.count
        let points = correct * 10
        let topic = kind == .chords ? "chords" : "rhythm"
        var next = apply(
            stats, points: points, questionCount: total,
            round: (kind == .chords ? "Akorlar" : "Ritmi Tut", correct, total, nil), dailyGoal: settings.dailyGoal,
            now: now)
        next.categoryAccuracy[topic] = next.categoryAccuracy[topic].adding(correct: correct, total: total)
        recordTopics(&next, [(topic, correct, total)], now: now)
        let stars = Stars.forRound(correct: correct, total: total)
        let best = recordStars(&next, key: kind.rawValue, stars: stars)
        let cel = detectCelebration(prev: stats, next: next, dailyGoal: settings.dailyGoal, now: now)
        return RoundOutcome(stats: next, points: points, stars: stars, previousBest: best, celebration: cel)
    }
}
