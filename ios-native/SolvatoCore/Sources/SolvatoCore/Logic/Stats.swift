// İstatistikler (XP, seri, günlük hedef, doğruluk, son turlar). Web karşılığı src/types.ts `AppStats` ve
// src/state/stats.ts. Depolama anahtarı ve JSON biçimi aynı (`notausta_stats_v1`); sözlükler ekleme sırasını korur.
import Foundation

public struct Tally: Equatable, Sendable {
    public var correct: Int
    public var total: Int
    public init(correct: Int = 0, total: Int = 0) {
        self.correct = correct
        self.total = total
    }
    public static let zero = Tally()
    func adding(_ ok: Bool) -> Tally { Tally(correct: correct + (ok ? 1 : 0), total: total + 1) }
    func adding(correct c: Int, total t: Int) -> Tally { Tally(correct: correct + c, total: total + t) }
    /// Doğruluk yüzdesi `round(doğru / toplam × 100)`; hiç çözülmediyse nil (Ana sayfa yüzde halkası)
    public var percent: Int? { total > 0 ? jsRound(Double(correct) / Double(total) * 100) : nil }
}

public struct CategoryAccuracy: Equatable, Sendable {
    public var treble = Tally.zero
    public var bass = Tally.zero
    public var trebleLedger = Tally.zero
    public var bassLedger = Tally.zero
    public var rhythm = Tally.zero
    public var terms = Tally.zero
    public var chords = Tally.zero
    public var writing = Tally.zero
    public var ear = Tally.zero
    public init() {}

    static let keys = ["treble", "bass", "trebleLedger", "bassLedger", "rhythm", "terms", "chords", "writing", "ear"]
    subscript(key: String) -> Tally {
        get {
            switch key {
            case "treble": treble
            case "bass": bass
            case "trebleLedger": trebleLedger
            case "bassLedger": bassLedger
            case "rhythm": rhythm
            case "terms": terms
            case "chords": chords
            case "writing": writing
            default: ear
            }
        }
        set {
            switch key {
            case "treble": treble = newValue
            case "bass": bass = newValue
            case "trebleLedger": trebleLedger = newValue
            case "bassLedger": bassLedger = newValue
            case "rhythm": rhythm = newValue
            case "terms": terms = newValue
            case "chords": chords = newValue
            case "writing": writing = newValue
            default: ear = newValue
            }
        }
    }
}

/// Tamamlanan bir tur (İlerleme › Son turlar)
public struct RoundRecord: Equatable, Sendable {
    /// Bitiş zamanı (ms)
    public var at: Int
    /// Ekranda görünen ad: "Sol Anahtarı", "Akorlar", "Oyun · Ritim"
    public var label: String
    public var correct: Int
    public var total: Int
    /// Toplam cevap süresi (sn); akor turunda yok
    public var sec: Int?
}

public struct AppStats: Equatable, Sendable {
    public static let storageKey = "notausta_stats_v1"
    static let historyMax = 100
    static let topicDays = 60

    public var streak = 0
    public var totalPoints = 0
    public var totalSessions = 0
    /// Seri sayılan son gün, JS toDateString biçiminde ("Wed Nov 18 2026")
    public var lastPlayDate = ""
    /// Gün (YYYY-MM-DD) → tamamlanan tur
    public var dailyLog = OrderedMap<Int>()
    /// Gün → çözülen soru (günlük hedef)
    public var dailyQuestions = OrderedMap<Int>()
    /// Nota konumu ('treble:70') → doğruluk
    public var noteStats = OrderedMap<Tally>()
    public var categoryAccuracy = CategoryAccuracy()
    /// Son turlar, en yenisi başta (en çok 100)
    public var history: [RoundRecord]?
    /// Gün → doğruluk
    public var dailyAccuracy: OrderedMap<Tally>?
    /// Konu → en iyi tur yıldızı (0–3)
    public var bestStars: OrderedMap<Int>?
    /// Gün → konu → doğruluk (son 60 gün)
    public var dailyTopics: OrderedMap<OrderedMap<Tally>>?

    public init() {}
}

// MARK: - JSON (web `loadStats` / `saveStats` ile aynı biçim)
extension AppStats {
    /// Bozuk ya da eksik kayıt varsayılanlarla tamamlanır (web loadStats)
    public init(json: JSON) {
        self.init()
        guard case .object = json else { return }
        func tally(_ j: JSON?) -> Tally? {
            guard let j, let c = j["correct"]?.int, let t = j["total"]?.int else { return nil }
            return Tally(correct: c, total: t)
        }
        func ints(_ j: JSON?) -> OrderedMap<Int>? {
            j?.object.map { o in OrderedMap(o.entries.compactMap { e in e.value.int.map { (e.key, $0) } }) }
        }
        func tallies(_ j: JSON?) -> OrderedMap<Tally>? {
            j?.object.map { o in OrderedMap(o.entries.compactMap { e in tally(e.value).map { (e.key, $0) } }) }
        }
        streak = json["streak"]?.int ?? 0
        totalPoints = json["totalPoints"]?.int ?? 0
        totalSessions = json["totalSessions"]?.int ?? 0
        lastPlayDate = json["lastPlayDate"]?.string ?? ""
        dailyLog = ints(json["dailyLog"]) ?? OrderedMap()
        dailyQuestions = ints(json["dailyQuestions"]) ?? OrderedMap()
        noteStats = tallies(json["noteStats"]) ?? OrderedMap()
        if let ca = json["categoryAccuracy"] {
            for k in CategoryAccuracy.keys { if let t = tally(ca[k]) { categoryAccuracy[k] = t } }
        }
        history = json["history"]?.array?.compactMap { r in
            guard let at = r["at"]?.int, let label = r["label"]?.string, let c = r["correct"]?.int,
                let t = r["total"]?.int
            else { return nil }
            return RoundRecord(at: at, label: label, correct: c, total: t, sec: r["sec"]?.int)
        }
        dailyAccuracy = tallies(json["dailyAccuracy"])
        bestStars = ints(json["bestStars"])
        dailyTopics = json["dailyTopics"]?.object.map { o in
            OrderedMap(o.entries.map { ($0.key, tallies($0.value) ?? OrderedMap()) })
        }
    }

    public var json: JSON {
        func tally(_ t: Tally) -> JSON {
            .object(OrderedMap([("correct", .number(Double(t.correct))), ("total", .number(Double(t.total)))]))
        }
        func ints(_ m: OrderedMap<Int>) -> JSON { .object(m.mapValues { .number(Double($0)) }) }
        func tallies(_ m: OrderedMap<Tally>) -> JSON { .object(m.mapValues(tally)) }
        var o = OrderedMap<JSON>()
        o["streak"] = .number(Double(streak))
        o["totalPoints"] = .number(Double(totalPoints))
        o["totalSessions"] = .number(Double(totalSessions))
        o["lastPlayDate"] = .string(lastPlayDate)
        o["dailyLog"] = ints(dailyLog)
        o["dailyQuestions"] = ints(dailyQuestions)
        o["noteStats"] = tallies(noteStats)
        o["categoryAccuracy"] = .object(OrderedMap(CategoryAccuracy.keys.map { ($0, tally(categoryAccuracy[$0])) }))
        if let dailyAccuracy { o["dailyAccuracy"] = tallies(dailyAccuracy) }
        if let history {
            o["history"] = .array(
                history.map { r in
                    var h = OrderedMap<JSON>()
                    h["label"] = .string(r.label)
                    h["correct"] = .number(Double(r.correct))
                    h["total"] = .number(Double(r.total))
                    if let sec = r.sec { h["sec"] = .number(Double(sec)) }
                    h["at"] = .number(Double(r.at))
                    return .object(h)
                })
        }
        if let bestStars { o["bestStars"] = ints(bestStars) }
        if let dailyTopics { o["dailyTopics"] = .object(dailyTopics.mapValues(tallies)) }
        return .object(o)
    }
}
