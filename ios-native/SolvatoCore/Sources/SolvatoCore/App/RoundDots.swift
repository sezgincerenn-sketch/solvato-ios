// Tur ekranlarının üstündeki adım noktaları (R2): cevaplanan soru yeşil (doğru) ya da kırmızı (yanlış); şimdiki soru
// uzun mor, kalanlar gri. Şimdiki soru cevaplanınca o da renk alır (uzun kalır). Soru turu, oyun turları ve akor turu.

public enum RoundDot: Equatable, Sendable {
    case correct, wrong, current, upcoming

    /// Kısa yazı (testlerde): ✓ ✗ ● ·
    public var mark: Character {
        switch self {
        case .correct: "✓"
        case .wrong: "✗"
        case .current: "●"
        case .upcoming: "·"
        }
    }
}

public enum RoundDots {
    /// `answered(i)`: i. soru cevaplandıysa doğru mu, cevaplanmadıysa nil
    public static func states(count: Int, index: Int, answered: (Int) -> Bool?) -> [RoundDot] {
        (0..<count).map { i in
            if let ok = answered(i) { return ok ? .correct : .wrong }
            return i == index ? .current : i < index ? .wrong : .upcoming
        }
    }
}

extension QuizRound {
    public var dots: [RoundDot] {
        RoundDots.states(count: questions.count, index: index) { i in i < results.count ? results[i].correct : nil }
    }
}

extension ChordRound {
    public var dots: [RoundDot] { RoundDots.states(count: questions.count, index: index) { answers[$0]?.correct } }
}
