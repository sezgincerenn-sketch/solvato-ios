// İlerleme sekmesi içeriği (web src/screens/ProgressScreen.tsx, progress/WeeklyReportCard.tsx, profile/RoundHistory.tsx):
// başlık, doğruluk (bu hafta / bu ay / tümü), bu hafta şeridi, konular ("Çalış ▶"), zorlandığın notalar, son turlar.
// Öğrenme yolu kartı gezinme revizesiyle kalktı (docs/ozellikler/gezinme.md); altın tablo ilerleme.json revize
// önizleme dalından (revize-onizleme) üretildi. SwiftUI ekranı (Screens/ProgressScreen) bunu çizer; `texts(period:)` web'deki sırayla yazılar.
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
        /// Satıra dokununca başlayan tur (R17)
        public var replay: RoundReplay
    }
    public var rounds: [Round]

    // MARK: Başlangıç listesi (R7, Ceren 26 Kasım)
    public struct StartStep: Equatable, Sendable {
        public var title: String
        public var done: Bool
    }

    /// İlk turunu bitir · Günlük hedefini tamamla · 2 gün üst üste çalış. Tamamlanan madde bir daha geri dönmez:
    /// hedef "seri sayılan gün" (lastPlayDate) ile, iki gün tur kaydındaki (dailyLog) art arda iki günle ölçülür.
    public static func startSteps(_ s: AppStats) -> [StartStep] {
        [
            StartStep(title: "İlk turunu bitir", done: s.totalSessions > 0 || !s.dailyLog.isEmpty),
            StartStep(title: "Günlük hedefini tamamla", done: !s.lastPlayDate.isEmpty),
            StartStep(title: "2 gün üst üste çalış", done: s.streak >= 2 || hasConsecutiveDays(s.dailyLog.keys)),
        ]
    }

    /// "2026-11-25" ve "2026-11-26" gibi art arda iki gün var mı
    static func hasConsecutiveDays(_ keys: [String]) -> Bool {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let days = Set(keys.compactMap { k -> Int? in
            let p = k.split(separator: "-").compactMap { Int($0) }
            guard p.count == 3, let d = utc.date(from: DateComponents(year: p[0], month: p[1], day: p[2])) else { return nil }
            return Int(d.timeIntervalSince1970 / 86400)
        })
        return days.contains { days.contains($0 + 1) }
    }

    /// Gösterilecek liste: bitti olarak kaydedildiyse ya da üçü de tamamsa nil (sessizce kaybolur)
    public static func startChecklist(_ s: AppStats, settings: Settings) -> [StartStep]? {
        guard !settings.startChecklistDone else { return nil }
        let steps = startSteps(s)
        return steps.allSatisfy(\.done) ? nil : steps
    }

    /// Son turlar satırına dokununca (R17, Ceren 26 Kasım): aynı konudan yeni tur
    public enum RoundReplay: Equatable, Sendable {
        case quiz(FilterCategory)
        case chords, rhythmTap
        /// "Zayıf notalar": şimdiki zorlanılan notalar (yoksa karma tur)
        case weak
        /// "Oyun · …": Oyunlar listesi
        case games
    }

    /// Kayıttaki addan tur: konu adı o konu; "Hataların tekrarı" ve tanınmayan ad karma tur
    public static func replay(label: String) -> RoundReplay {
        if label.hasPrefix("Oyun · ") { return .games }
        switch label {
        case "Akorlar": return .chords
        case "Ritmi Tut": return .rhythmTap
        case "Zayıf notalar": return .weak
        default: return .quiz(FilterCategory.allCases.first { $0.roundLabel == label } ?? .all)
        }
    }

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
                score: "\(h.correct)/\(h.total)", time: h.sec.map(Games.formatSeconds), replay: Self.replay(label: h.label))
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
        var t = ["İlerleme"]
        var l: [String] = []
        if !hasAnswers {
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
        t.append("Konular")
        for x in topics {
            t.append(x.label)
            if let n = x.note { t.append(n) }
            t += [x.pct.map { "%\($0)" } ?? "—", "Çalış"]
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

extension ProgressContent {
    /// İlerleme'nin üstündeki üç kutu: Toplam süre · Tamamlanan tur · Çözülen soru (kullanici-testi-revize.md madde 8)
    public static func totals(_ stats: AppStats) -> [(value: String, label: String)] {
        [(studyTime(stats.studySeconds), "Toplam süre"), ("\(stats.totalSessions)", "Tamamlanan tur"),
         ("\(ProfileText.solved(stats))", "Çözülen soru")]
    }

    /// Çalışma süresi: 1 saatin altında "35 dk", üstünde "2 sa 15 dk" (tam saatte "2 sa"); 1 dakikanın altında "0 dk"
    public static func studyTime(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        guard m >= 60 else { return "\(m) dk" }
        return m % 60 == 0 ? "\(m / 60) sa" : "\(m / 60) sa \(m % 60) dk"
    }
}
