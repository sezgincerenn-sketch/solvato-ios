// Haftalık rapor (öğretmene/veliye WhatsApp ile gider) ve dönem doğruluğu. Web karşılıkları
// src/utils/weeklyReport.ts ve src/state/stats.ts `accuracyFor`. Takvim haftası Pazartesi–Pazar; gelecek günler
// şeritte silik, metinde yok. Metin React'la karakter karakter aynı.
import Foundation

extension Progress {
    /// Doğruluk: dönem yoksa tüm zamanlar; "week"/"month" takvim dönemi, offset 1 = önceki dönem
    public static func accuracy(_ s: AppStats, period: Period? = nil, offset: Int = 0, now: Now) -> Tally {
        guard let period else {
            let ca = s.categoryAccuracy
            return [ca.treble, ca.bass, ca.rhythm, ca.terms, ca.chords, ca.writing, ca.ear].reduce(Tally.zero) {
                $0.adding(correct: $1.correct, total: $1.total)
            }
        }
        let r = now.clock.periodRange(period, offset: offset, now: now.date)
        var t = Tally.zero
        for day in now.clock.eachDay(from: r.from, to: r.to) {
            if let d = s.dailyAccuracy?[now.clock.dayKey(day)] { t = t.adding(correct: d.correct, total: d.total) }
        }
        return t
    }
}

public struct WeeklyReport: Equatable, Sendable {
    public struct Day: Equatable, Sendable {
        public var key: String
        /// "Pzt"
        public var label: String
        public var questions: Int
        public var goalMet: Bool
        public var future: Bool
    }
    public struct Topic: Equatable, Sendable {
        public var key: String
        public var label: String
        public var correct: Int
        public var total: Int
        public var pct: Int
    }

    public var name: String
    /// "16–22 Kasım", "30 Kasım – 6 Aralık"
    public var range: String
    public var days: [Day]
    public var activeDays: Int
    public var goalDays: Int
    public var questions: Int
    public var accuracy: Int?
    public var prevAccuracy: Int?
    /// Çok çözülenden aza
    public var topics: [Topic]
    public var weak: [WeakNote]
    public var streak: Int
    public var level: String
    public var dailyGoal: Int
    public var teacherCode: String

    public static let topicLabels: [String: String] = [
        "treble": "Sol anahtarı notaları", "bass": "Fa anahtarı notaları", "accidentals": "Diyez ve bemol",
        "rhythm": "Ritim", "terms": "Müzik terimleri", "writing": "Nota yazımı", "chords": "Akorlar",
        "ear": "Kulak (nota ve akor)",
    ]
    static let weekdays = ["Paz", "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt"]
    static let months = [
        "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık",
    ]

    static func pct(_ c: Int, _ t: Int) -> Int? { t > 0 ? jsRound(Double(c) / Double(t) * 100) : nil }

    public init(stats: AppStats, settings s: Settings, now: Now) {
        let clock = now.clock
        let (from, to) = clock.periodRange(.week, offset: 0, now: now.date)
        let dates = clock.eachDay(from: from, to: to)
        days = dates.map { d in
            let key = clock.dayKey(d)
            let q = stats.dailyQuestions[key] ?? 0
            return Day(
                key: key, label: Self.weekdays[clock.calendar.component(.weekday, from: d) - 1], questions: q,
                goalMet: q >= s.dailyGoal, future: clock.isFuture(d, now: now.date))
        }
        let week = Progress.accuracy(stats, period: .week, now: now)
        let prev = Progress.accuracy(stats, period: .week, offset: 1, now: now)

        var topicMap = OrderedMap<Tally>()
        for d in days {
            for e in stats.dailyTopics?[d.key]?.entries ?? [] {
                topicMap[e.key] = (topicMap[e.key] ?? .zero).adding(correct: e.value.correct, total: e.value.total)
            }
        }
        topics = stableSorted(
            topicMap.entries.map { e in
                Topic(
                    key: e.key, label: Self.topicLabels[e.key] ?? "", correct: e.value.correct, total: e.value.total,
                    pct: Self.pct(e.value.correct, e.value.total) ?? 0)
            }
        ) { $0.total > $1.total }

        func fmt(_ d: Date, _ withMonth: Bool) -> String {
            let c = clock.calendar.dateComponents([.day, .month], from: d)
            return withMonth ? "\(c.day!) \(Self.months[c.month! - 1])" : "\(c.day!)"
        }
        let first = dates[0]
        let last = dates[6]
        range =
            clock.calendar.component(.month, from: first) == clock.calendar.component(.month, from: last)
            ? "\(fmt(first, false))–\(fmt(last, true))" : "\(fmt(first, true)) – \(fmt(last, true))"

        name = s.name.trimmingCharacters(in: .whitespacesAndNewlines)
        activeDays = days.filter { $0.questions > 0 }.count
        goalDays = days.filter(\.goalMet).count
        questions = days.reduce(0) { $0 + $1.questions }
        accuracy = Self.pct(week.correct, week.total)
        prevAccuracy = Self.pct(prev.correct, prev.total)
        weak = WeakNotes.list(stats, limit: 4)
        streak = Progress.currentStreak(stats, now: now)
        level = QuestionLevel.label(s.level)
        dailyGoal = s.dailyGoal
        teacherCode = s.teacherCode
    }

    /// WhatsApp'a uygun düz metin
    public var text: String {
        var lines = ["🎹 Solvato · Haftalık rapor", (name.isEmpty ? "" : name + " · ") + range, ""]
        if questions == 0 {
            lines.append("Bu hafta çalışma yapılmadı.")
        } else {
            let past = days.filter { !$0.future }
            lines.append("Çalıştığı gün: \(activeDays)/\(past.count) (hedef tutturulan: \(goalDays))")
            lines.append(past.map { "\($0.label) \($0.goalMet ? "✅" : $0.questions > 0 ? "🟡" : "⬜")" }.joined(separator: "  "))
            lines.append("✅ hedef tamam · 🟡 çalıştı · ⬜ çalışmadı")
            var acc = "Çözülen soru: \(questions)"
            if let accuracy {
                acc += " · Doğruluk %\(accuracy)"
                if let prevAccuracy { acc += " (geçen hafta %\(prevAccuracy))" }
            }
            lines.append(acc)
            if !topics.isEmpty {
                lines += ["", "Konular:"]
                lines += topics.map { "• \($0.label): \($0.total) soru, %\($0.pct)" }
            }
            if !weak.isEmpty {
                lines += [
                    "",
                    "Zorlandığı notalar: " + weak.map { "\($0.note) (\($0.clef == .treble ? "sol" : "fa"))" }.joined(separator: ", "),
                ]
            }
        }
        lines += ["", "Seviye: \(level) · Günlük hedef: \(dailyGoal) soru · Seri: \(streak) gün"]
        if !teacherCode.isEmpty { lines.append("Öğretmen kodu: \(teacherCode)") }
        return lines.joined(separator: "\n")
    }
}
