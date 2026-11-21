// Akor motoru: akorları kök + türden üretir, doğru yazımla (Do# minör = Do# Mi Sol#), porte konumu ve piyano tuşlarıyla.
// Akor turu: 10 soru, üç tür (porteden tanı, tuşlardan bul, akoru bas). Web karşılıkları src/data/chords.ts,
// src/data/chordQuiz.ts, ChordQuizSession.tsx `buildQuestions` ve components/piano/MultiPiano.tsx (litKeys, fitsKeyboard).
//
// Seviyeler: 1 Başlangıç doğal köklü majör/minör · 2 Orta ara seslerin majör/minörleri · 3 İleri 7'liler ·
// 4 Uzman dim, aug, m7♭5, dim7, sus2, sus4, 9'lu, 13'lü (yalnız Çalışma'da)

public struct ChordNote: Equatable, Sendable {
    /// 0…6 (Do…Si)
    public var letter: Int
    /// −2…2 (♭♭ … ##)
    public var acc: Int
    public var octave: Int
    /// Perde sınıfı 0…11
    public var pc: Int

    /// Sol anahtarında porte konumu: Do4 = y 90, her harf adımı 5 birim yukarı (web staffY)
    public var staffY: Int { 90 - (octave * 7 + letter - 28) * 5 }
    /// "Do#", "Mi♭"
    public var name: String { Chords.trLetters[letter] + (Chords.accText[acc] ?? "") }
}

public struct Chord: Equatable, Sendable, Identifiable {
    /// "C#min"
    public var id: String
    public var level: Int
    /// "C#"
    public var root: String
    /// "min", "maj7", "7" …
    public var quality: String
    /// "Do# minör"
    public var name: String
    /// "C#m"
    public var symbol: String
    /// "Do# minör (C#m)"
    public var label: String
    public var notes: [ChordNote]
    public var noteNames: [String]
    public var pcs: [Int]
    /// Kökten yarım ses uzaklıkları
    public var semis: [Int]
    public var rootPc: Int
    /// Piyano tuşları (oktavsız, siyahlar diyez adıyla)
    public var keys: [String]
    public var formula: String
}

public enum ChordQuestionType: String, Sendable {
    /// Portede yazılı akoru tanı (AKOR TANIMA)
    case staff
    /// Klavyede basılı akoru tanı (TUŞLARDAN BUL)
    case keys
    /// Adı verilen akoru klavyede bas (AKORU BAS)
    case build
}

public struct ChordQuestion: Equatable, Sendable {
    public var chord: Chord
    public var type: ChordQuestionType
    public var options: [Chord]
}

public enum Chords {
    public static let levelLabels = [1: "Başlangıç", 2: "Orta", 3: "İleri", 4: "Uzman"]
    static let letters = ["C", "D", "E", "F", "G", "A", "B"]
    static let letterPc = [0, 2, 4, 5, 7, 9, 11]
    static let trLetters = ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"]
    /// Piyano tuş adları (siyah tuşlar diyez adıyla)
    public static let pcKey = ["Do", "Do#", "Re", "Re#", "Mi", "Fa", "Fa#", "Sol", "Sol#", "La", "La#", "Si"]
    static let accText = [-2: "♭♭", -1: "♭", 0: "", 1: "#", 2: "##"]

    struct Quality {
        let key, tr, sym: String
        let semis, steps: [Int]
        let formula: String
    }

    static let qualities: [Quality] = [
        .init(key: "maj", tr: "majör", sym: "", semis: [0, 4, 7], steps: [0, 2, 4], formula: "Kök + büyük üçlü (4 yarım ses) + küçük üçlü (3 yarım ses)"),
        .init(key: "min", tr: "minör", sym: "m", semis: [0, 3, 7], steps: [0, 2, 4], formula: "Kök + küçük üçlü (3 yarım ses) + büyük üçlü (4 yarım ses)"),
        .init(key: "maj7", tr: "majör 7", sym: "maj7", semis: [0, 4, 7, 11], steps: [0, 2, 4, 6], formula: "Majör akor + büyük yedili (kökten 11 yarım ses)"),
        .init(key: "7", tr: "dominant 7", sym: "7", semis: [0, 4, 7, 10], steps: [0, 2, 4, 6], formula: "Majör akor + küçük yedili (kökten 10 yarım ses)"),
        .init(key: "m7", tr: "minör 7", sym: "m7", semis: [0, 3, 7, 10], steps: [0, 2, 4, 6], formula: "Minör akor + küçük yedili (kökten 10 yarım ses)"),
        .init(key: "dim", tr: "eksik", sym: "dim", semis: [0, 3, 6], steps: [0, 2, 4], formula: "İki küçük üçlü üst üste (3 + 3 yarım ses)"),
        .init(key: "aug", tr: "artık", sym: "aug", semis: [0, 4, 8], steps: [0, 2, 4], formula: "İki büyük üçlü üst üste (4 + 4 yarım ses)"),
        .init(key: "m7b5", tr: "yarı eksik", sym: "m7♭5", semis: [0, 3, 6, 10], steps: [0, 2, 4, 6], formula: "Eksik akor + küçük yedili (kökten 10 yarım ses)"),
        .init(key: "dim7", tr: "eksik 7", sym: "dim7", semis: [0, 3, 6, 9], steps: [0, 2, 4, 6], formula: "Dört küçük üçlü: her ses bir öncekinden 3 yarım ses yukarıda"),
        .init(key: "sus2", tr: "sus2", sym: "sus2", semis: [0, 2, 7], steps: [0, 1, 4], formula: "Üçlü yerine ikili: kök + 2 yarım ses + 5 yarım ses"),
        .init(key: "sus4", tr: "sus4", sym: "sus4", semis: [0, 5, 7], steps: [0, 3, 4], formula: "Üçlü yerine dörtlü: kök + 5 yarım ses + 2 yarım ses"),
        .init(key: "9", tr: "9'lu", sym: "9", semis: [0, 4, 7, 10, 14], steps: [0, 2, 4, 6, 8], formula: "Dominant 7 + büyük dokuzlu (kökün bir oktav üstündeki ikili)"),
        .init(key: "13", tr: "13'lü", sym: "13", semis: [0, 4, 10, 21], steps: [0, 2, 6, 12], formula: "Kök, üçlü, küçük yedili ve on üçlü (altılı); piyanoda genelde beşli ve dokuzlu atlanır"),
    ]

    /// Akor türünün rengi (Çalışma › Akorlar); web QUALITY_COLOR
    public static let qualityColor: [String: String] = [
        "maj": "#8B5CF6", "min": "#F87171", "maj7": "#60A5FA", "7": "#F59E0B", "m7": "#34D399", "dim": "#FB923C",
        "aug": "#EC4899", "m7b5": "#A78BFA", "dim7": "#F97316", "sus2": "#22D3EE", "sus4": "#2DD4BF", "9": "#FBBF24",
        "13": "#C084FC",
    ]

    static func spell(_ letterIdx: Int, _ acc: Int, _ q: Quality, _ octave: Int) -> [ChordNote] {
        let rootPc = (letterPc[letterIdx] + acc + 12) % 12
        return q.semis.enumerated().map { i, semi in
            let stepAbs = letterIdx + q.steps[i]
            let l = stepAbs % 7
            let targetAbs = letterPc[letterIdx] + acc + semi
            let natAbs = letterPc[l] + 12 * (stepAbs / 7)
            var a = targetAbs - natAbs
            while a > 6 { a -= 12 }
            while a < -6 { a += 12 }
            return ChordNote(letter: l, acc: a, octave: octave + stepAbs / 7, pc: (rootPc + semi) % 12)
        }
    }

    static func make(_ root: String, _ qKey: String, _ level: Int) -> Chord {
        let q = qualities.first { $0.key == qKey }!
        let first = String(root.prefix(1))
        let letterIdx = letters.firstIndex(of: first)!
        let acc = root.contains("#") ? 1 : root.contains("b") ? -1 : 0
        // Porteye sığsın: yüksek köklerde bir oktav aşağıdan başla
        let octave = letterIdx >= 4 && q.semis.last! > 12 ? 3 : 4
        let notes = spell(letterIdx, acc, q, octave)
        let accMark = acc == 1 ? "#" : acc == -1 ? "♭" : ""
        let name = "\(trLetters[letterIdx])\(accMark) \(q.tr)"
        let symbol = first + accMark + q.sym
        let pcs = notes.map(\.pc)
        var seen = Set<Int>()
        return Chord(
            id: root + qKey, level: level, root: root, quality: qKey, name: name, symbol: symbol,
            label: "\(name) (\(symbol))", notes: notes, noteNames: notes.map(\.name), pcs: pcs, semis: q.semis,
            rootPc: notes[0].pc, keys: pcs.filter { seen.insert($0).inserted }.map { pcKey[$0] }, formula: q.formula)
    }

    /// 94 akor, web ALL_CHORDS sırasıyla
    public static let all: [Chord] = {
        let naturals = letters
        let groups: [([String], String, Int)] = [
            (naturals, "maj", 1), (naturals, "min", 1),
            (["Db", "Eb", "F#", "Ab", "Bb"], "maj", 2), (["C#", "Eb", "F#", "G#", "Bb"], "min", 2),
            (["C", "D", "E", "F", "G", "A", "Bb", "Eb"], "maj7", 3), (["C", "D", "E", "F", "G", "A", "B", "Bb"], "7", 3),
            (["C", "D", "E", "F", "G", "A", "B"], "m7", 3),
            (["C", "D", "E", "F#", "G", "A", "B"], "dim", 4), (["C", "D", "E", "F", "G", "A"], "aug", 4),
            (["C", "D", "E", "F#", "G", "A", "B"], "m7b5", 4), (["C", "D", "E", "G", "A", "B"], "dim7", 4),
            (["C", "D", "E", "F", "G", "A"], "sus2", 4), (["C", "D", "E", "F", "G", "A"], "sus4", 4),
            (["C", "D", "F", "G", "A"], "9", 4), (["C", "D", "F", "G"], "13", 4),
        ]
        return groups.flatMap { roots, q, lv in roots.map { make($0, q, lv) } }
    }()

    public static func upTo(_ level: Int) -> [Chord] { all.filter { $0.level <= level } }

    /// Aynı tuş kümesine sahip farklı adlı akorlar (C6 / Am7 gibi) birbirinin yanlış şıkkı olmaz
    public static func samePcs(_ a: Chord, _ b: Chord) -> Bool { Set(a.pcs) == Set(b.pcs) }

    // MARK: Klavye (Do3–Si4, iki oktav; kök 3. oktavda)
    static let keyboardLow = 48

    /// Klavyede yanacak tuşlar: "Do3", "Mi3", "Sol3"
    public static func litKeys(_ c: Chord) -> Set<String> {
        Set(c.semis.map { semi in
            let abs = keyboardLow + c.rootPc + semi
            return "\(pcKey[abs % 12])\(abs / 12 - 1)"
        })
    }

    /// Akor iki oktavlık klavyeye sığıyor mu (sığmazsa "Tuşlardan bul" yerine porte sorulur)
    public static func fitsKeyboard(_ c: Chord) -> Bool { c.rootPc + c.semis.max()! <= 23 }

    /// "Akoru bas" cevabı: seçilen tuş adları (oktavsız) akorun tuşlarıyla aynı küme mi
    public static func isCorrectBuild(_ selected: Set<String>, _ c: Chord) -> Bool {
        selected.sorted() == c.keys.sorted()
    }

    // MARK: Örnek diziler (Çalışma › Akorlar)
    static let sharpSym = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    static let flatSym = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

    static func symAt(_ c: Chord, _ semi: Int) -> String {
        let flat = c.root.contains("b") || c.root == "F" || (c.quality == "min" && ["D", "G", "C", "F"].contains(c.root))
        return (flat ? flatSym : sharpSym)[(c.rootPc + semi + 12) % 12]
    }

    public static func progressions(_ c: Chord) -> [String] {
        func r(_ s: Int, _ suf: String = "") -> String { symAt(c, s) + suf }
        switch c.quality {
        case "maj": return ["\(r(0)) – \(r(7)) – \(r(9, "m")) – \(r(5))", "\(r(0)) – \(r(5)) – \(r(7)) – \(r(0))"]
        case "min": return ["\(r(0, "m")) – \(r(8)) – \(r(3)) – \(r(10))", "\(r(0, "m")) – \(r(5, "m")) – \(r(7)) – \(r(0, "m"))"]
        case "maj7": return ["\(r(0, "maj7")) – \(r(9, "m7")) – \(r(2, "m7")) – \(r(7, "7"))"]
        case "7": return ["\(r(0, "7")) → \(r(5))  (dominant çözülür)", "\(r(-5, "m7")) – \(r(0, "7")) – \(r(5, "maj7"))"]
        case "m7": return ["\(r(0, "m7")) – \(r(5, "7")) – \(r(10, "maj7"))  (ii–V–I)"]
        case "dim": return ["\(r(0, "dim")) → \(r(1))  (yarım ses yukarı çözülür)"]
        case "m7b5": return ["\(r(0, "m7♭5")) – \(r(5, "7")) – \(r(10, "m"))  (minör ii–V–i)"]
        case "sus4": return ["\(r(0, "sus4")) → \(r(0))  (dörtlü üçlüye iner)"]
        case "sus2": return ["\(r(0, "sus2")) → \(r(0))"]
        default: return []
        }
    }

    // MARK: Akor turu
    /// Yanlış şıklar: biri aynı kökün başka türü, diğerleri aynı türün başka kökleri
    public static func distractors(_ c: Chord, pool: [Chord], random r: RandomSource) -> [Chord] {
        let ok = { (x: Chord) in x.id != c.id && !samePcs(x, c) }
        let sameRoot = shuffled(pool.filter { ok($0) && $0.root == c.root }, r)
        let sameQual = shuffled(pool.filter { ok($0) && $0.quality == c.quality }, r)
        let any = shuffled(pool.filter(ok), r)
        var picks: [Chord] = []
        for x in Array(sameRoot.prefix(1)) + sameQual + any {
            if picks.count >= 3 { break }
            if !picks.contains(where: { $0.id == x.id || samePcs($0, x) }) { picks.append(x) }
        }
        return picks
    }

    /// 10 soru; seviye = soru seviyesi (en çok İleri). Yeni seviye ile önceki seviyeler yarı yarıya.
    public static func roundQuestions(level: Int, random r: @escaping RandomSource = systemRandom) -> [ChordQuestion] {
        let session = 10
        let pool = upTo(level)
        let current = shuffled(pool.filter { $0.level == level }, r)
        let earlier = shuffled(pool.filter { $0.level < level }, r)
        let nCur = earlier.isEmpty ? min(session, current.count) : min(5, current.count)
        var picked = Array(current.prefix(nCur)) + earlier.prefix(session - nCur)
        if picked.count < session { picked = Array((picked + shuffled(pool, r)).prefix(session)) }
        let types = shuffled((0..<session).map { [ChordQuestionType.staff, .keys, .build][$0 % 3] }, r)
        let distractorPool = level == 1 ? upTo(1) : pool
        return shuffled(picked, r).enumerated().map { i, chord in
            ChordQuestion(
                chord: chord, type: types[i] == .keys && !fitsKeyboard(chord) ? .staff : types[i],
                options: shuffled([chord] + distractors(chord, pool: distractorPool, random: r), r))
        }
    }
}
