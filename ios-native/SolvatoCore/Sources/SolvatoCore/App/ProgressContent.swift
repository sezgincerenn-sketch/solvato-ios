// İlerleme sekmesi içeriği (web src/screens/ProgressScreen.tsx, progress/PathCard.tsx, progress/WeeklyReportCard.tsx,
// profile/RoundHistory.tsx): doğruluk (bu hafta / bu ay / tümü), bu hafta şeridi, öğrenme yolu, konular, zorlandığın
// notalar, son turlar. SwiftUI ekranı (Screens/ProgressScreen) bunu çizer; `texts(period:)` web'deki sırayla yazılar.
import Foundation

public enum AccuracyPeriod: String, CaseIterable, Sendable {
    case week, month, all
    public var label: String {
        switch self {
        case .week: "Bu hafta"
        case .month: "Bu ay"
        case .all: "Tümü"
        }
    }
    var prev: String {
        switch self {
        case .week: "geçen haftaya"
        case .month: "geçen aya"
        case .all: ""
        }
    }
}

public struct ProgressContent: Sendable {
    // MARK: Doğruluk kartı
    public struct Accuracy: Equatable, Sendable {
        public var correct: Int
        public var total: Int
        public var pct: Int?
        /// "10 sorudan 3 doğru"
        public var summary: String
        /// "Geçen haftaya göre +7 puan" (yalnız artış)
        public var delta: String?
        /// %60 altı: "Başta düşük olması normal…"
        public var lowNote: String?
        /// Hiç tur yoksa
        public var empty: String
    }

    public func accuracy(_ period: AccuracyPeriod) -> Accuracy {
        let cur = period == .all ? Progress.accuracy(stats, now: now) : Progress.accuracy(stats, period: period == .week ? .week : .month, now: now)
        let prev: Tally? = period == .all ? nil : Progress.accuracy(stats, period: period == .week ? .week : .month, offset: 1, now: now)
        let pct = cur.total > 0 ? jsRound(Double(cur.correct) / Double(cur.total) * 100) : nil
        let prevPct = prev.flatMap { $0.total >= 10 ? jsRound(Double($0.correct) / Double($0.total) * 100) : nil }
        let d = pct.flatMap { p in prevPct.map { p - $0 } }
        let prevText = period.prev
        return Accuracy(
            correct: cur.correct, total: cur.total, pct: pct, summary: "\(cur.total) sorudan \(cur.correct) doğru",
            delta: d.flatMap { $0 > 0 ? prevText.prefix(1).uppercased() + prevText.dropFirst() + " göre +\($0) puan" : nil },
            lowNote: pct.flatMap { $0 < 60 ? "Başta düşük olması normal; tekrar ettikçe yükselir." : nil },
            empty: "\(period.label) henüz tur yok. Bir tur çöz, doğruluğun burada görünsün.")
    }

    /// Varsayılan dönem: bu hafta tur varsa "Bu hafta", yoksa "Tümü"
    public var defaultPeriod: AccuracyPeriod { Progress.accuracy(stats, period: .week, now: now).total > 0 ? .week : .all }

    // MARK: Bu hafta kartı
    public struct WeekDay: Equatable, Sendable {
        public var label: String
        public var goalMet: Bool
        public var worked: Bool
        public var isToday: Bool
        public var future: Bool
    }
    public var report: WeeklyReport
    public var streakTitle: String
    public var streakNudge: String
    public var weekDays: [WeekDay]
    public var weekSummary: String
    public var weekLabel: String

    // MARK: Öğrenme yolu (web PathCard)
    public struct Stage: Equatable, Sendable {
        public var key: String
        public var label: String
        public var short: String
        public var done: Bool
        public var isCurrent: Bool
        /// Tur: konu ya da akor turu
        public var category: FilterCategory?
        public var accessibility: String
    }
    public static let pathNeed = 15
    public static let pathAcc = 0.7
    public var stages: [Stage]
    public var pathDone: String
    public var nextTitle: String
    public var nextSub: String
    /// Sıradaki adımın ilerleme çubuğu (0–100); doğruluk eksikse ya da yol bittiyse nil
    public var nextPct: Int?
    public var nextStage: Stage

    // MARK: Konular
    public struct Topic: Equatable, Sendable {
        public var key: String
        public var label: String
        public var pct: Int?
        public var note: String?
        public var color: CategoryColor
        public var accessibility: String
    }
    public var topics: [Topic]
    public var hasAnswers: Bool

    // MARK: Zorlandığın notalar, son turlar
    public var weak: [WeakNote]
    public struct Round: Equatable, Sendable {
        public var stars: Int
        public var label: String
        public var when: String
        public var score: String
        public var time: String?
    }
    public var rounds: [Round]

    let stats: AppStats
    let now: Now

    public init(stats: AppStats, settings: Settings, now: Now) {
        self.stats = stats
        self.now = now
        let ca = stats.categoryAccuracy
        hasAnswers = ca.treble.total + ca.bass.total + ca.rhythm.total + ca.terms.total + ca.chords.total + ca.writing.total + ca.ear.total > 0

        // Bu hafta
        let r = WeeklyReport(stats: stats, settings: settings, now: now)
        report = r
        let todayKey = now.todayKey
        let todayQ = r.days.first { $0.key == todayKey }?.questions ?? 0
        let left = max(0, r.dailyGoal - todayQ)
        streakTitle = r.streak > 0 ? "\(r.streak) günlük seri" : "Seri yok"
        streakNudge =
            left == 0
            ? "Bugünün serisi tamam" : r.streak > 0 ? "Bugün \(left) soru daha, seri \(r.streak + 1) olsun" : "Bugün \(left) soru çöz, serin başlasın"
        weekDays = r.days.map { d in
            WeekDay(label: d.key == todayKey ? "Bugün" : d.label, goalMet: d.goalMet, worked: d.questions > 0, isToday: d.key == todayKey, future: d.future)
        }
        weekSummary =
            r.questions == 0
            ? "Bu hafta henüz çalışmadın."
            : "Bu hafta \(r.activeDays) gün çalıştın, \(r.questions) soru çözdün. Hedefi \(r.goalDays) gün tutturdun."
        weekLabel = "Son 7 günde \(r.activeDays) gün çalışıldı, \(r.goalDays) gün hedef tamamlandı"

        // Öğrenme yolu
        var accT = Tally.zero
        for e in stats.noteStats.entries where e.key.hasSuffix(":sharp") || e.key.hasSuffix(":flat") {
            accT = accT.adding(correct: e.value.correct, total: e.value.total)
        }
        var raw: [(String, String, String, Tally, FilterCategory?)] = [
            ("treble", "Sol Anahtarı", "Sol", ca.treble, .treble), ("bass", "Fa Anahtarı", "Fa", ca.bass, .bass),
        ]
        if settings.level >= 2 { raw.append(("acc", "Diyez & Bemol", "♯♭", accT, .accidentals)) }
        raw += [
            ("rhythm", "Ritim", "Ritim", ca.rhythm, .rhythm), ("terms", "Terimler", "Terim", ca.terms, .terms),
            ("chords", "Akorlar", "Akor", ca.chords, nil),
        ]
        func isDone(_ c: Tally) -> Bool { c.total >= Self.pathNeed && Double(c.correct) / Double(c.total) >= Self.pathAcc }
        let currentIdx = raw.firstIndex { !isDone($0.3) }
        stages = raw.enumerated().map { i, s in
            let done = isDone(s.3)
            let cur = i == currentIdx
            return Stage(
                key: s.0, label: s.1, short: s.2.count > 3 ? String(s.2.prefix(2)) : s.2, done: done, isCurrent: cur, category: s.4,
                accessibility: s.1 + (done ? " (tamam)" : cur ? " (sıradaki)" : ""))
        }
        let allDone = currentIdx == nil
        let ci = currentIdx ?? raw.count - 1
        let c = raw[ci].3
        nextStage = stages[ci]
        pathDone = "\(stages.filter(\.done).count)/\(stages.count) tamam"
        let needAcc = c.total >= Self.pathNeed && Double(c.correct) / Double(c.total) < Self.pathAcc
        let accPct = jsRound(Self.pathAcc * 100)
        nextTitle = (allDone ? "Yolu tamamladın. Bir tur daha: " : "Sıradaki: ") + raw[ci].1
        nextSub =
            allDone
            ? "Hızını ve doğruluğunu korumak için tekrar çalış."
            : needAcc
                ? "Doğruluğu %\(accPct) üzerine çıkar (şu an %\(jsRound(Double(c.correct) / Double(c.total) * 100)))"
                : "\(min(c.total, Self.pathNeed))/\(Self.pathNeed) soru · %\(accPct) doğruluk hedefi"
        nextPct = !allDone && !needAcc ? min(100, jsRound(Double(c.total) / Double(Self.pathNeed) * 100)) : nil

        // Konular
        func ledger(_ v: Tally) -> String? { v.total >= 5 ? "Ek çizgiler %\(jsRound(Double(v.correct) / Double(v.total) * 100))" : nil }
        topics = [
            ("treble", "Sol anahtarı", ca.treble, ledger(ca.trebleLedger), CategoryColor.treble),
            ("bass", "Fa anahtarı", ca.bass, ledger(ca.bassLedger), .bass), ("rhythm", "Ritim", ca.rhythm, nil, .rhythm),
            ("chords", "Akorlar", ca.chords, nil, .chords), ("ear", "Kulak", ca.ear, nil, .ear),
            ("writing", "Nota yazımı", ca.writing, nil, .writing), ("terms", "Müzik terimleri", ca.terms, nil, .terms),
        ].map { k, label, v, note, color in
            let pct = v.total > 0 ? jsRound(Double(v.correct) / Double(v.total) * 100) : nil
            return Topic(
                key: k, label: label, pct: pct, note: note, color: color,
                accessibility: "\(label): \(pct.map { "yüzde \($0)" } ?? "henüz çözülmedi"). Bu konuda tur başlat")
        }

        weak = WeakNotes.list(stats)
        rounds = (stats.history ?? []).map { h in
            Round(
                stars: Stars.forRound(correct: h.correct, total: h.total), label: h.label, when: Self.when(h.at, now: now),
                score: "\(h.correct)/\(h.total)", time: h.sec.map(Games.formatSeconds))
        }
    }

    static let shortMonths = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"]

    /// "Bugün 09:15", "Dün 18:40", "17 Kas 03:24" (web RoundHistory when)
    public static func when(_ at: Int, now: Now) -> String {
        let d = dateFromMs(at)
        let c = now.clock.calendar.dateComponents([.day, .month, .hour, .minute], from: d)
        let hm = String(format: "%02d:%02d", c.hour!, c.minute!)
        let ds = now.clock.dateString(d)
        if ds == now.todayString { return "Bugün \(hm)" }
        if ds == now.yesterdayString { return "Dün \(hm)" }
        return "\(c.day!) \(shortMonths[c.month! - 1]) \(hm)"
    }

    /// Ekrandaki yazılar ve erişilebilirlik adları web'deki sırayla (telefon düzeni, son turlar kapalı)
    public func texts(period: AccuracyPeriod? = nil) -> (texts: [String], labels: [String]) {
        var t: [String] = []
        var l: [String] = []
        func path() {
            // Tamamlanan aşamada kısaltma yerine ✓ ikonu
            t += ["Öğrenme yolu", pathDone] + stages.filter { !$0.done }.map(\.short) + [nextTitle, nextSub]
            l += stages.map(\.accessibility)
        }
        if !hasAnswers {
            path()
            t += ["İstatistiklerin burada görünecek", "İlk turunu çöz; doğruluğun, serin ve zorlandığın notalar burada görünsün.", "İlk tura başla"]
            return (t, l)
        }
        let p = period ?? defaultPeriod
        let a = accuracy(p)
        t += ["Doğruluk"] + AccuracyPeriod.allCases.map(\.label)
        if a.pct == nil {
            t.append(a.empty)
        } else {
            t.append(a.summary)
            if let d = a.delta { t.append(d) }
            if let n = a.lowNote { t.append(n) }
        }
        t += ["Bu hafta", report.range, streakTitle, streakNudge] + weekDays.map(\.label) + [weekSummary, "Öğretmenine haftalık rapor gönder"]
        l.append(weekLabel)
        path()
        t.append("Konular")
        for x in topics {
            t.append(x.label)
            if let n = x.note { t.append(n) }
            t += [x.pct.map { "%\($0)" } ?? "—", "›"]
            l.append(x.accessibility)
        }
        if !weak.isEmpty {
            t.append("Zorlandığın notalar")
            for w in weak {
                t += [w.note, "%\(w.pct)"]
                l.append("\(w.clef == .treble ? "Sol" : "Fa") anahtarında \(w.note), yüzde \(w.pct)")
            }
            t.append("Bu notaları çalış")
        }
        if !rounds.isEmpty {
            t.append("Son turlar")
            if rounds.count > 3 { t.append("Tümünü göster") }
            for r in rounds.prefix(3) {
                t += [r.label, r.when, r.score]
                if let s = r.time { t.append(s) }
                l.append("3 yıldızdan \(r.stars)")
            }
        }
        return (t, l)
    }
}
