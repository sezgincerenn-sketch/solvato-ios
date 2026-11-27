// Soru modeli ve soru bankası. Web karşılığı src/types.ts `Question` ve src/data/questions.ts.
// Banka Resources/soru-bankasi.json'da; React üreteçlerinin çıktısından döküldü (scripts/altin.mjs, `web-arsiv` dalı),
// bundan sonra soru eklemek ya da düzeltmek için JSON elle düzenlenir.
import Foundation

public enum QuestionCategory: String, Codable, Sendable, CaseIterable {
    case noteIdentification = "note_identification"
    case rhythm
    case musicalTerms = "musical_terms"
    case writing
    case ear
}

public enum Clef: String, Codable, Sendable, CaseIterable {
    case treble, bass
}

public enum Accidental: String, Codable, Sendable {
    case sharp, flat
}

/// Kulak sorusunda çalınacak ses
public struct Pitch: Codable, Equatable, Hashable, Sendable {
    public var name: String
    public var octave: Int
    public init(name: String, octave: Int) {
        self.name = name
        self.octave = octave
    }
}

/// Kulak sorusu: tek nota (önce referans Do) ya da akor
public enum EarPrompt: Equatable, Hashable, Sendable {
    case note(ref: Pitch, target: Pitch)
    case chord(notes: [Pitch])
}

extension EarPrompt: Codable {
    private enum Keys: String, CodingKey { case kind, ref, target, notes }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        switch try c.decode(String.self, forKey: .kind) {
        case "note": self = .note(ref: try c.decode(Pitch.self, forKey: .ref), target: try c.decode(Pitch.self, forKey: .target))
        default: self = .chord(notes: try c.decode([Pitch].self, forKey: .notes))
        }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        switch self {
        case let .note(ref, target):
            try c.encode("note", forKey: .kind)
            try c.encode(ref, forKey: .ref)
            try c.encode(target, forKey: .target)
        case let .chord(notes):
            try c.encode("chord", forKey: .kind)
            try c.encode(notes, forKey: .notes)
        }
    }
}

public struct Question: Codable, Equatable, Hashable, Sendable, Identifiable {
    public var id: Int
    public var category: QuestionCategory
    public var clef: Clef?
    public var noteName: String?
    public var noteY: Int?
    public var ledgerLines: [Int]?
    public var questionText: String
    public var displayText: String?
    public var options: [String]
    public var correctAnswer: String
    public var explanation: String
    public var rhythmType: String?
    /// Notation bileşeninin çizeceği nota dizisi
    public var score: String?
    /// Şıklar yazı yerine çizimse: şık → nota dizisi
    public var optionScores: [String: String]?
    public var accidental: Accidental?
    /// Piyanodaki karşılığı, ör. "Do#"
    public var keyName: String?
    public var ear: EarPrompt?

    public init(
        id: Int, category: QuestionCategory, questionText: String, options: [String], correctAnswer: String,
        explanation: String, ear: EarPrompt? = nil
    ) {
        self.id = id
        self.category = category
        self.questionText = questionText
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.ear = ear
    }

    /// Nota konumu anahtarı (`treble:70`, `bass:45:sharp`): noteStats ve zayıf notalar bununla tutulur
    public var noteKey: String? {
        guard category == .noteIdentification, let clef, let noteY else { return nil }
        return NoteKey.make(clef: clef.rawValue, noteY: noteY, accidental: accidental)
    }
}

enum NoteKey {
    static func make(clef: String, noteY: Int, accidental: Accidental?) -> String {
        "\(clef):\(noteY)" + (accidental.map { ":\($0.rawValue)" } ?? "")
    }
}

/// Soru seviyesi: 1 Başlangıç, 2 Orta, 3 İleri
public enum QuestionLevel {
    public static let labels: [Int: String] = [1: "Başlangıç", 2: "Orta", 3: "İleri"]
    public static func label(_ level: Int) -> String { labels[level] ?? "" }
}

public enum QuestionBank {
    /// 701 soru, web'deki ALL_QUESTIONS sırasıyla
    public static let all: [Question] = {
        guard let url = Bundle.module.url(forResource: "soru-bankasi", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let list = try? JSONDecoder().decode([Question].self, from: data)
        else { fatalError("soru-bankasi.json okunamadı") }
        return list
    }()

    public static let byId: [Int: Question] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    private static let rhythmL1 = ids("313 314 315 318 319 320 323 324 331 332 333 334 335 337 338 339 343 344 347 348 357 358 360 361 370 375 386 387")
    // İleri: bileşik ölçüler (6/8, 9/8, 12/8), alla breve, onaltılık hesapları, triole, ön vuruş, bağlı birlikler
    private static let rhythmL3 = ids("327 329 330 349 352 362 363 365 372 374 377 385 388 399")
    private static let termsL1 = ids("413 414 415 416 417 418 419 420 425 426 427 428 429 431 432 436 437 443 456 457 465")
    // İleri: sfz, fff/ppp, tenuto, espressivo, coda, poco/molto, rallentando
    private static let termsL3 = ids("421 423 424 438 444 458 476 477 486")
    private static func ids(_ s: String) -> Set<Int> { Set(s.split(separator: " ").compactMap { Int($0) }) }

    /// Web `questionLevel`
    public static func level(of q: Question) -> Int {
        switch q.category {
        case .noteIdentification:
            let y = q.noteY ?? 60
            // 2–3 ek çizgideki notalar (diyezli/bemollüler dahil) ileri
            if (q.ledgerLines?.count ?? 0) >= 2 || y > 95 || y < 25 { return 3 }
            if q.accidental != nil { return 2 }
            // Porte içi ve hemen üstü/altı + orta Do başlangıç; diğer ek çizgiler orta
            let middleC = (q.clef == .treble && y == 90) || (q.clef == .bass && y == 30)
            return (y >= 35 && y <= 85) || middleC ? 1 : 2
        case .rhythm: return rhythmL1.contains(q.id) ? 1 : rhythmL3.contains(q.id) ? 3 : 2
        case .musicalTerms: return termsL1.contains(q.id) ? 1 : termsL3.contains(q.id) ? 3 : 2
        case .writing: return q.id >= 1801 ? 2 : 1
        case .ear: return 1
        }
    }
}
