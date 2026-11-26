// Akor düellosu (web src/screens/ChordDuel.tsx): aynı telefonda iki kişi. 10 akor sorusu (çift sıradakiler sığarsa
// tuşlarla, diğerleri portede); doğru şıkka ilk basan puanı alır, yanlış basan o soruda kilitlenir, ikisi de yanlışsa
// doğru gösterilir. Gösterimden 1,6 sn sonra sıradaki soru. Ekran Solvato/Screens/ChordDuelScreen.swift.
import Foundation

public struct DuelQuestion: Equatable, Sendable {
    public enum Kind: String, Sendable { case staff, keys }
    public let chord: Chord
    public let type: Kind
    public let options: [Chord]
}

public struct DuelGame: Equatable, Sendable {
    public static let rounds = 10
    /// Doğru gösterildikten sonra sıradaki soruya geçiş (sn)
    public static let revealDelay = 1.6
    /// Oyuncu renkleri: 1. oyuncu (alt yarı) mor, 2. oyuncu (üst yarı, ters) amber
    public static let colors: [PaletteColor] = [.violet500, .amber500]
    public static let defaultNames = ["1. oyuncu", "2. oyuncu"]
    public static let nameLimit = 14
    public static let intro =
        "Telefonu ikinizin arasına, masaya koyun. Ekranın iki yarısı var, her biri bir oyuncunun. Doğru akora ilk basan puanı alır. Yanlış basan o soruda bir daha basamaz. \(rounds) soru."

    public let questions: [DuelQuestion]
    public private(set) var index = 0
    public private(set) var scores = [0, 0]
    public private(set) var locked = [false, false]
    public private(set) var picked: [String?] = [nil, nil]
    public private(set) var reveal = false

    public init(questions: [DuelQuestion]) { self.questions = questions }

    /// Web buildDuel: havuz karıştırılır, ilk 10; çift sıradakiler klavyeye sığarsa tuşlarla
    public static func build(level: Int, random r: @escaping RandomSource) -> [DuelQuestion] {
        let pool = Chords.upTo(level)
        return shuffled(pool, r).prefix(rounds).enumerated().map { i, chord in
            DuelQuestion(
                chord: chord, type: i % 2 == 0 && Chords.fitsKeyboard(chord) ? .keys : .staff,
                options: shuffled([chord] + Chords.distractors(chord, pool: pool, random: r), r))
        }
    }

    public var finished: Bool { index >= questions.count }
    /// Düello sürüyor ve bir oyuncu şıkka bastı mı (yoksa çıkış sormadan olur; sonuçta sorulmaz)
    public var hasAnswers: Bool { !finished && (index > 0 || picked.contains { $0 != nil }) }
    public var current: DuelQuestion? { finished ? nil : questions[index] }

    public enum PickResult: Equatable, Sendable {
        /// Kabul edilmedi (gösterim sırasında ya da oyuncu kilitli)
        case ignored
        case correct
        case wrong
        /// İkisi de yanlış: doğru gösterilir
        case bothWrong
    }

    /// Oyuncu (0: alt, 1: üst) bir şıkka bastı. correct / bothWrong sonrası `revealDelay` sonra `advance()`.
    public mutating func pick(_ p: Int, _ id: String) -> PickResult {
        guard let q = current, !reveal, !locked[p] else { return .ignored }
        picked[p] = id
        if id == q.chord.id {
            scores[p] += 1
            reveal = true
            return .correct
        }
        locked[p] = true
        if locked[0] && locked[1] {
            reveal = true
            return .bothWrong
        }
        return .wrong
    }

    /// Sıradaki soru
    public mutating func advance() {
        reveal = false
        locked = [false, false]
        picked = [nil, nil]
        index += 1
    }

    /// Alttaki sayaç: "3/10 · portedeki akor"
    public var counter: String {
        guard let q = current else { return "" }
        return "\(index + 1)/\(questions.count) · \(q.type == .staff ? "portedeki akor" : "basılı tuşlar")"
    }

    /// Kazanan: 0 / 1, berabere nil
    public var winner: Int? { scores[0] == scores[1] ? nil : scores[0] > scores[1] ? 0 : 1 }

    public func resultTitle(names: [String]) -> String { winner.map { "\(names[$0]) kazandı!" } ?? "Berabere!" }
    public var scoreText: String { "\(scores[0]) – \(scores[1])" }
    public var exitText: String { "Skor \(scoreText). Çıkarsan düello yarıda kalır." }
}
