// Bir tur için soru seçimi (10 soru), kulak soruları ve zorlandığın notalar.
// Web karşılıkları src/data/session.ts, src/data/ear.ts, src/state/weakNotes.ts. Rastgelelik dışarıdan verilir;
// aynı sayı dizisiyle React'la aynı soruları aynı sırayla seçer (altın tablo).
import Foundation

public enum Session {
    public static let length = 10

    /// Turun soruları, şıkları karıştırılmış (web getQuestions)
    public static func questions(
        _ category: FilterCategory, settings: Settings, random r: @escaping RandomSource = systemRandom
    ) -> [Question] {
        if category == .ear { return Ear.questions(settings: settings, random: r) }
        return pick(category, settings: settings, random: r).map { shuffleOptions($0, r) }
    }

    /// Nota sorularında şıklar nota sırasıyla durur; diğerlerinde karıştırılır (yazımda çizim, sıra sabit)
    static func shuffleOptions(_ q: Question, _ r: RandomSource) -> Question {
        if q.category == .noteIdentification || q.optionScores != nil { return q }
        var c = q
        c.options = shuffled(q.options, r)
        return c
    }

    /// Orta/İleri'de soruların yarısı kendi seviyesinden
    static func sampleWeighted(_ pool: [Question], _ n: Int, _ lv: Int, _ r: RandomSource) -> [Question] {
        if lv <= 1 { return Array(shuffled(pool, r).prefix(n)) }
        let cur = shuffled(pool.filter { QuestionBank.level(of: $0) == lv }, r)
        let half = min(cur.count, (n + 1) / 2)
        let picked = Array(cur.prefix(half))
        let ids = Set(picked.map(\.id))
        let rest = shuffled(pool.filter { !ids.contains($0.id) }, r).prefix(n - picked.count)
        return shuffled(picked + rest, r)
    }

    /// Web pickQuestions
    public static func pick(
        _ category: FilterCategory, settings: Settings, random r: @escaping RandomSource = systemRandom,
        bank: [Question] = QuestionBank.all
    ) -> [Question] {
        let lv = settings.level
        let clefOk = { (q: Question) in
            category != .all || q.clef == nil || settings.clef == .both || q.clef?.rawValue == settings.clef.rawValue
        }
        let levelOk = { (q: Question) in QuestionBank.level(of: q) <= lv }
        let naturals = bank.filter { $0.accidental == nil && levelOk($0) && clefOk($0) }
        // Diyez & Bemol turunu kullanıcı kendisi seçtiyse seviyeden bağımsız
        let accidentals = bank.filter { $0.accidental != nil && clefOk($0) }

        // Çalışılacak notalar: nota sorularını süz, şıkları da bu notalardan kur
        let enabled = settings.notes.isEmpty ? allNotes : settings.notes
        let noteSet = Set(enabled)
        let limited = enabled.count < allNotes.count
        func limitNotes(_ qs: [Question]) -> [Question] {
            guard limited else { return qs }
            return qs.filter { $0.category != .noteIdentification || noteSet.contains($0.noteName ?? $0.correctAnswer) }
                .map { q in
                    guard q.category == .noteIdentification else { return q }
                    let others = shuffled(enabled.filter { $0 != q.correctAnswer }, r).prefix(3)
                    var c = q
                    c.options = stableSorted([q.correctAnswer] + others) { noteIndex($0) < noteIndex($1) }
                    return c
                }
        }
        // Diyez/bemolde temel nota seçili notalardan biri (çok az kalırsa kısıtlama yok)
        func limitAccidentals(_ qs: [Question]) -> [Question] {
            guard limited else { return qs }
            let f = qs.filter { noteSet.contains($0.noteName ?? "") }
            return f.count >= 6 ? f : qs
        }

        if category == .accidentals { return Array(shuffled(limitAccidentals(accidentals), r).prefix(length)) }

        var pool = naturals
        switch category {
        case .treble: pool = naturals.filter { $0.category == .noteIdentification && $0.clef == .treble }
        case .bass: pool = naturals.filter { $0.category == .noteIdentification && $0.clef == .bass }
        case .rhythm: pool = naturals.filter { $0.category == .rhythm }
        case .terms: pool = naturals.filter { $0.category == .musicalTerms }
        case .writing: pool = bank.filter { $0.category == .writing && levelOk($0) }
        default: break
        }
        pool = limitNotes(pool)

        // Öğretmen konu seçtiyse karışık tur yalnızca o konulardan (en az 5 soru kalırsa)
        if category == .all && !TeacherCode.allTopics(settings.topics) {
            let topicOf = { (q: Question) -> String in
                q.category == .noteIdentification
                    ? (q.clef?.rawValue ?? "") : q.category == .musicalTerms ? "terms" : q.category.rawValue
            }
            let picked = pool.filter { settings.topics.contains(topicOf($0)) }
            if picked.count >= 5 { pool = picked }
        }

        // Karışık turda Orta seviyeden itibaren 3 diyez/bemol sorusu
        if category == .all && lv >= 2 && !limited {
            let picked = Array(shuffled(limitAccidentals(accidentals), r).prefix(3))
            let rest = sampleWeighted(pool, length - picked.count, lv, r)
            return shuffled(picked + rest, r)
        }
        return sampleWeighted(pool, length, lv, r)
    }

    /// Zayıf notalar turu: seçilen nota konumlarından en çok 10 soru
    public static func weakQuestions(
        _ keys: [String], random r: @escaping RandomSource = systemRandom, bank: [Question] = QuestionBank.all
    ) -> [Question] {
        let set = Set(keys)
        let pool = bank.filter { q in q.noteKey.map(set.contains) ?? false }
        return Array(shuffled(pool, r).prefix(length))
    }

    static func noteIndex(_ n: String) -> Int { allNotes.firstIndex(of: n) ?? -1 }
}

// MARK: - Kulak soruları
public enum Ear {
    static let round = 10
    static let idBase = 900_000
    static let chromatic = ["Do", "Do#", "Re", "Re#", "Mi", "Fa", "Fa#", "Sol", "Sol#", "La", "La#", "Si"]
    static let chordTypes = ["Majör", "Minör", "Eksik", "Artık"]
    static let chordSteps: [String: (Int, Int)] = ["Majör": (4, 7), "Minör": (3, 7), "Eksik": (3, 6), "Artık": (4, 8)]
    static let chordFeel: [String: String] = [
        "Majör": "Majör parlak ve neşeli duyulur.",
        "Minör": "Minör daha hüzünlü, karanlık duyulur.",
        "Eksik": "Eksik akor gergin duyulur, sanki bir yere çözülmek ister.",
        "Artık": "Artık akor belirsiz, havada asılı gibi duyulur.",
    ]
    /// Kök → [majör, minör, eksik, artık] doğru yazılışı (web'deki sırayla)
    static let roots = ["Do", "Re", "Mi", "Fa", "Sol", "La"]
    static let spelling: [String: [String]] = [
        "Do": ["Do–Mi–Sol", "Do–Mi♭–Sol", "Do–Mi♭–Sol♭", "Do–Mi–Sol♯"],
        "Re": ["Re–Fa♯–La", "Re–Fa–La", "Re–Fa–La♭", "Re–Fa♯–La♯"],
        "Mi": ["Mi–Sol♯–Si", "Mi–Sol–Si", "Mi–Sol–Si♭", "Mi–Sol♯–Si♯"],
        "Fa": ["Fa–La–Do", "Fa–La♭–Do", "Fa–La♭–Do♭", "Fa–La–Do♯"],
        "Sol": ["Sol–Si–Re", "Sol–Si♭–Re", "Sol–Si♭–Re♭", "Sol–Si–Re♯"],
        "La": ["La–Do♯–Mi", "La–Do–Mi", "La–Do–Mi♭", "La–Do♯–Mi♯"],
    ]

    static func pitch(_ s: Int) -> Pitch { Pitch(name: chromatic[s % 12], octave: 4 + s / 12) }

    static func noteQuestion(_ id: Int, _ target: String, _ pool: [String], _ level: Int, _ r: RandomSource) -> Question {
        let n = 4
        // Havuz 4'ten azsa eksik şıklar diğer notalardan tamamlanır
        var distractors = pool.filter { $0 != target }
        if distractors.count < n - 1 {
            let extra = shuffled(allNotes.filter { $0 != target && !pool.contains($0) }, r)
            distractors = Array((distractors + extra).prefix(max(n - 1, distractors.count)))
        }
        if level >= 3 {
            // İleri: şıklar hedefin komşularından
            let i = Session.noteIndex(target)
            distractors = stableSorted(distractors) { abs(Session.noteIndex($0) - i) < abs(Session.noteIndex($1) - i) }
        } else {
            distractors = shuffled(distractors, r)
        }
        let options = shuffled([target] + distractors.prefix(n - 1), r)
        let step = Session.noteIndex(target)
        var q = Question(
            id: id, category: .ear, questionText: "Önce Do çalınıyor, sonra bir nota. İkinci nota hangisi?",
            options: options, correctAnswer: target,
            explanation: step == 0
                ? "İki kez aynı nota çalındı: Do."
                : "İkinci nota \(target) idi: Do'dan \(step) basamak yukarıda (\(allNotes.prefix(step + 1).joined(separator: "–"))).",
            ear: .note(ref: Pitch(name: "Do", octave: 4), target: Pitch(name: target, octave: 4)))
        q.options = options
        return q
    }

    static func chordQuestion(_ id: Int, _ root: String, _ type: String) -> Question {
        let s = chromatic.firstIndex(of: root)!
        let (third, fifth) = chordSteps[type]!
        return Question(
            id: id, category: .ear, questionText: "Bu akorun türü ne?", options: chordTypes, correctAnswer: type,
            explanation:
                "\(root) \(type.lowercased()) çalındı (\(spelling[root]![chordTypes.firstIndex(of: type)!])). \(chordFeel[type]!)",
            ear: .chord(notes: [s, s + third, s + fifth].map(pitch)))
    }

    /// Tur: Başlangıç 6 nota + 4 akor, Orta/İleri 5 + 5
    public static func questions(settings s: Settings, random r: @escaping RandomSource = systemRandom) -> [Question] {
        let level = s.level
        // Başlangıçta Do–Sol; öğretmenin seçtiği notalarla kesişir, en az 3 nota kalır
        let base = level <= 1 ? Array(allNotes.prefix(5)) : allNotes
        var pool = base.filter { s.notes.contains($0) }
        if pool.count < 3 { pool = s.notes.count >= 3 ? s.notes : base }
        let noteCount = level <= 1 ? 6 : 5
        var qs: [Question] = []
        var last = ""
        for i in 0..<noteCount {
            let choices = pool.filter { $0 != last }
            let t = choices[Int((r() * Double(choices.count)).rounded(.down))]
            last = t
            qs.append(noteQuestion(idBase + i, t, pool, level, r))
        }
        for i in noteCount..<round {
            // Başlangıç: yalnız majör/minör çalınır. Orta/İleri: dört tür, majör/minör biraz daha sık
            let types = level <= 1 ? ["Majör", "Minör"] : ["Majör", "Majör", "Minör", "Minör", "Eksik", "Artık"]
            let type = types[Int((r() * Double(types.count)).rounded(.down))]
            let root = roots[Int((r() * Double(roots.count)).rounded(.down))]
            qs.append(chordQuestion(idBase + i, root, type))
        }
        return shuffled(qs, r)
    }
}

// MARK: - Zorlandığın notalar
public struct WeakNote: Equatable, Sendable {
    public var key: String
    /// Oktavlı ad: "Fa4"
    public var note: String
    public var clef: Clef
    public var pct: Int
    public var total: Int
    public var noteY: Int
    public var ledgerLines: [Int]
    public var accidental: Accidental?
}

public enum WeakNotes {
    /// En az 3 kez sorulmuş, %70'in altında bilinen konumlar; en kötüden iyiye
    public static func list(_ stats: AppStats, limit: Int = 6, bank: [Question] = QuestionBank.all) -> [WeakNote] {
        let octave = try! Regex(#"\(([A-G])[♯♭]?(\d)\)"#)
        let items = stats.noteStats.entries
            .filter { $0.value.total >= 3 && Double($0.value.correct) / Double($0.value.total) < 0.7 }
            .map { e -> WeakNote in
                let parts = e.key.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
                let clef = parts[0]
                let y = parts.count > 1 ? parts[1] : ""
                let acc = parts.count > 2 ? parts[2] : ""
                let sample = bank.first {
                    $0.clef?.rawValue == clef && $0.noteY.map(String.init) == y && ($0.accidental?.rawValue ?? "") == acc
                }
                let name = sample?.correctAnswer ?? "?"
                var note = name
                if let s = sample, let m = s.explanation.firstMatch(of: octave), let d = m.output[2].substring {
                    note = name + d
                }
                return WeakNote(
                    key: e.key, note: note, clef: clef == "bass" ? .bass : .treble,
                    pct: jsRound(Double(e.value.correct) / Double(e.value.total) * 100), total: e.value.total,
                    noteY: Int(y) ?? 0, ledgerLines: sample?.ledgerLines ?? [], accidental: sample?.accidental)
            }
        return Array(stableSorted(items) { $0.pct < $1.pct }.prefix(limit))
    }
}
