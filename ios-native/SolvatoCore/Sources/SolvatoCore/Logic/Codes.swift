// Öğretmen kodu (6 karakter, K7M-2QX) ve meydan okuma kodu (8 karakter, ABCD-EFGH). Sunucu yok: ayarlar ve oyun
// bilgisi kodun içinde. Web karşılıkları src/utils/teacherCode.ts ve src/utils/games.ts; iki sürüm birbirinin
// kodunu okur. Dışarıdan gelen her kod doğrulanır (uzunluk, harf, kontrol, işaret, alan sınırları).

/// 0/O ve 1/I karışmasın diye 32 harflik alfabe
let codeAlphabet = Array("23456789ABCDEFGHJKLMNPQRSTUVWXYZ")

/// Girişi düzeltir: büyük harf, harf/rakam dışını at, O→0, I→1
func normalizeCode(_ code: String) -> [Character] {
    code.uppercased().filter { ("0"..."9").contains($0) || ("A"..."Z").contains($0) && $0.isASCII }
        .map { $0 == "O" ? "0" : $0 == "I" ? "1" : $0 }
}

func readCode(_ s: [Character], length: Int) -> Int? {
    guard s.count == length else { return nil }
    var n = 0
    for ch in s {
        guard let v = codeAlphabet.firstIndex(of: ch) else { return nil }
        n = n * 32 + v
    }
    return n
}

func writeCode(_ value: Int, length: Int, split: Int) -> String {
    var n = value
    var out: [Character] = []
    for _ in 0..<length {
        out.insert(codeAlphabet[n % 32], at: 0)
        n /= 32
    }
    return String(out[..<split]) + "-" + String(out[split...])
}

// MARK: - Öğretmen kodu
public struct TeacherSetup: Equatable, Sendable {
    public var notes: [String]
    public var clef: ClefChoice
    public var level: Int
    public var dailyGoal: Int
    public var keyLabels: Bool
    /// Boş = tüm konular
    public var topics: [String]

    public init(notes: [String], clef: ClefChoice, level: Int, dailyGoal: Int, keyLabels: Bool, topics: [String]) {
        self.notes = notes
        self.clef = clef
        self.level = level
        self.dailyGoal = dailyGoal
        self.keyLabels = keyLabels
        self.topics = topics
    }
}

public enum TeacherCode {
    static let mark = 0b1011
    static let clefs: [ClefChoice] = [.treble, .bass, .both]
    public static let goals = [10, 20, 30, 50]
    public static let minNotes = 3
    /// Öğretmenin seçebildiği konular, koddaki bit sırasıyla (sıra değişmez!)
    public static let topics: [(key: String, label: String)] = [
        ("treble", "Sol anahtarı"), ("bass", "Fa anahtarı"), ("rhythm", "Ritim"), ("terms", "Müzik terimleri"),
        ("writing", "Nota yazımı"), ("ear", "Kulak"), ("chords", "Akorlar"),
    ]
    public static func allTopics(_ t: [String]) -> Bool { t.isEmpty || t.count >= topics.count }

    // 25 bitlik gövde karıştırılır: tek sayıyla çarpım + xorshift (ikisi de geri alınabilir)
    static let mod = 1 << 25
    static let mul = 30_647_735
    static let mulInv = 4_016_135
    static let add = 0x0ABCDE
    static func scramble(_ v: Int) -> Int {
        let x = (v * mul + add) % mod
        return x ^ (x >> 12)
    }
    static func unscramble(_ y: Int) -> Int {
        let x = y ^ (y >> 12) ^ (y >> 24)
        return (((x - add + mod) % mod) * mulInv) % mod
    }
    static func checksum(_ v: Int) -> Int {
        var s = 13
        var x = v
        while x > 0 {
            s = (s * 29 + x % 32) % 32
            x /= 32
        }
        return s
    }

    public static func encode(_ t: TeacherSetup) -> String {
        let notesMask = allNotes.enumerated().reduce(0) { m, e in t.notes.contains(e.element) ? m | (1 << e.offset) : m }
        var n = mark
        n = n * 128 + notesMask
        n = n * 4 + (clefs.firstIndex(of: t.clef) ?? 0)
        n = n * 4 + (t.level - 1)
        n = n * 4 + (goals.firstIndex(of: t.dailyGoal) ?? 0)
        n = n * 2 + (t.keyLabels ? 1 : 0)
        let topicsMask =
            allTopics(t.topics)
            ? 0 : topics.enumerated().reduce(0) { m, e in t.topics.contains(e.element.key) ? m | (1 << e.offset) : m }
        n = n * 128 + topicsMask
        n = scramble(n)
        n = n * 32 + checksum(n)
        return writeCode(n, length: 6, split: 3)
    }

    public static func decode(_ code: String) -> TeacherSetup? {
        guard var n = readCode(normalizeCode(code), length: 6) else { return nil }
        let ck = n % 32
        n /= 32
        guard checksum(n) == ck else { return nil }
        n = unscramble(n)
        let topicsMask = n % 128
        n /= 128
        let keyLabels = n % 2 == 1
        n /= 2
        let goal = n % 4
        n /= 4
        let level = n % 4 + 1
        n /= 4
        let clef = n % 4
        n /= 4
        let notesMask = n % 128
        let m = n / 128
        let notes = allNotes.enumerated().filter { notesMask & (1 << $0.offset) != 0 }.map(\.element)
        guard m == mark, level <= 3, clef <= 2, notes.count >= minNotes else { return nil }
        let t = topicsMask == 0 ? [] : topics.enumerated().filter { topicsMask & (1 << $0.offset) != 0 }.map(\.element.key)
        return TeacherSetup(notes: notes, clef: clefs[clef], level: level, dailyGoal: goals[goal], keyLabels: keyLabels, topics: t)
    }

    /// Kodun içeriği okunur satırlar (öğrenciye gösterilir, paylaşım metnine girer)
    public static func describe(_ t: TeacherSetup) -> [String] {
        let clefLabel: [ClefChoice: String] = [.treble: "Sol anahtarı", .bass: "Fa anahtarı", .both: "Sol ve fa anahtarı"]
        return [
            allTopics(t.topics)
                ? "Tüm konular" : "Konular: " + topics.filter { t.topics.contains($0.key) }.map(\.label).joined(separator: ", "),
            clefLabel[t.clef]!,
            "\(QuestionLevel.label(t.level)) seviye",
            t.notes.count >= allNotes.count ? "Tüm notalar" : "Notalar: " + t.notes.joined(separator: " "),
            "Günde \(t.dailyGoal) soru",
            t.keyLabels ? "Tuşlarda nota adları görünür" : "Tuşlarda nota adları gizli",
        ]
    }

    public static func shareText(code: String, _ t: TeacherSetup) -> String {
        (["🎹 Solvato · Öğretmen kodu", "Kod: \(code)", ""] + describe(t).map { "• \($0)" }
            + ["", "Solvato'da Ayarlar › Öğretmen kodu bölümüne bu kodu yaz."]).joined(separator: "\n")
    }
}

// MARK: - Meydan okuma kodu
public struct Challenge: Equatable, Sendable {
    public var category: GameCategory
    public var level: Int
    public var seed: Int
    public var correct: Int
    public var sec: Int
    public init(category: GameCategory, level: Int, seed: Int, correct: Int, sec: Int) {
        self.category = category
        self.level = level
        self.seed = seed
        self.correct = correct
        self.sec = sec
    }
}

public enum ChallengeCode {
    static func checksum(_ v: Int) -> Int {
        var s = 7
        var x = v
        while x > 0 {
            s = (s * 31 + x % 32) % 32
            x /= 32
        }
        return s
    }

    /// 40 bit: kategori 3 · seviye 2 · tohum 16 · doğru 4 · süre(sn) 10 · kontrol 5
    public static func encode(_ c: Challenge) -> String {
        var n = GameCategory.allCases.firstIndex(of: c.category)!
        n = n * 4 + (c.level - 1)
        n = n * 65536 + (c.seed & 0xFFFF)
        n = n * 16 + min(15, c.correct)
        n = n * 1024 + min(1023, c.sec)
        n = n * 32 + checksum(n)
        return writeCode(n, length: 8, split: 4)
    }

    public static func decode(_ code: String) -> Challenge? {
        guard var n = readCode(normalizeCode(code), length: 8) else { return nil }
        let ck = n % 32
        n /= 32
        guard checksum(n) == ck else { return nil }
        let sec = n % 1024
        n /= 1024
        let correct = n % 16
        n /= 16
        let seed = n % 65536
        n /= 65536
        let level = n % 4 + 1
        let ci = n / 4
        guard ci < GameCategory.allCases.count, level <= 3, correct <= Games.length else { return nil }
        return Challenge(category: GameCategory.allCases[ci], level: level, seed: seed, correct: correct, sec: sec)
    }
}
