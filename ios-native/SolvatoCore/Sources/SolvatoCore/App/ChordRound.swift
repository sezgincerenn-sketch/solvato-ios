// Akor turu akışı (web src/screens/ChordQuizSession.tsx): 10 soru, üç tür (porteden tanı, tuşlardan bul, akoru bas).
// Şık seç ya da tuşlara bas → "Kontrol Et ✓"; doğruda +10 XP ve 1,5 sn sonra geçiş; yanlışta ya da süre dolunca doğru
// cevap ve "Sıradaki". Bütün yazılar burada; SwiftUI ekranı (Screens/ChordQuizScreen) yalnız çizer.
import Foundation

public struct ChordRound: Equatable, Sendable {
    public enum State: String, Sendable { case pending, correct, wrong, timeout }

    public let questions: [ChordQuestion]
    /// Akor seviyesi (1–3), sağ üstte adı
    public let level: Int
    public private(set) var index = 0
    public private(set) var state = State.pending
    /// Basılan tuşlar, basılma sırasıyla (oktavsız ad)
    public private(set) var selectedKeys: [String] = []
    /// Seçilen şıkkın akor kimliği
    public private(set) var choice: String?
    public private(set) var score = 0
    private var answers: [Int: RoundAnswer] = [:]
    public var showFormula = false

    public static let length = 10
    public static let pointsPerCorrect = 10
    /// Süre açıksa soru başına (sn)
    public static let timerSeconds = 15

    public init(level: Int, random: @escaping RandomSource = systemRandom) {
        self.level = level
        questions = Chords.roundQuestions(level: level, random: random)
    }

    public init(questions: [ChordQuestion], level: Int) {
        self.questions = questions
        self.level = level
    }

    public var question: ChordQuestion { questions[index] }
    /// En az bir soru cevaplandı ya da süresi doldu mu (yoksa çıkış sormadan olur)
    public var hasAnswers: Bool { !answers.isEmpty }
    /// Üstteki nokta (R2): geçilen soru doğruysa yeşil, yanlış ya da süresi dolduysa kırmızı
    public func dot(_ i: Int) -> RoundDot {
        i == index ? .current : i > index ? .upcoming : answers[i]?.correct == true ? .correct : .wrong
    }
    public var pending: Bool { state == .pending }
    public var usesPiano: Bool { question.type == .build }
    public var canCheck: Bool { usesPiano ? !selectedKeys.isEmpty : choice != nil }
    public var isLast: Bool { index + 1 >= questions.count }

    public mutating func toggleKey(_ name: String) {
        guard pending else { return }
        if let i = selectedKeys.firstIndex(of: name) { selectedKeys.remove(at: i) } else { selectedKeys.append(name) }
    }

    public mutating func clearKeys() { selectedKeys = [] }

    public mutating func choose(_ id: String) {
        guard pending else { return }
        choice = id
    }

    /// "Kontrol Et": doğru mu (yalnız ilk sonuç kaydedilir)
    @discardableResult
    public mutating func check(timeMs: Int) -> Bool {
        guard pending, canCheck else { return false }
        let c = question.chord
        let correct = usesPiano ? Chords.isCorrectBuild(Set(selectedKeys), c) : choice == c.id
        state = correct ? .correct : .wrong
        record(correct, timeMs)
        if correct { score += Self.pointsPerCorrect }
        return correct
    }

    public mutating func timeout(timeMs: Int) {
        guard pending else { return }
        state = .timeout
        record(false, timeMs)
    }

    private mutating func record(_ correct: Bool, _ timeMs: Int) {
        if answers[index] == nil { answers[index] = RoundAnswer(questionId: index, correct: correct, timeMs: timeMs) }
    }

    /// Sonraki soru; tur bittiyse cevaplar (cevapsız soru yanlış sayılır)
    public mutating func advance() -> [RoundAnswer]? {
        if isLast {
            return questions.indices.map { answers[$0] ?? RoundAnswer(questionId: $0, correct: false, timeMs: 0) }
        }
        index += 1
        state = .pending
        selectedKeys = []
        choice = nil
        showFormula = false
        return nil
    }

    // MARK: Yazılar
    public var typeTag: String {
        switch question.type {
        case .staff: "AKOR TANIMA"
        case .keys: "TUŞLARDAN BUL"
        case .build: "AKORU BAS"
        }
    }

    public var levelLabel: String { Chords.levelLabels[level] ?? "" }

    public var prompt: String {
        switch question.type {
        case .staff: "Portedeki akor hangisi?"
        case .keys: "Klavyede basılı akor hangisi?"
        case .build: "Bu akorun tuşlarına bas"
        }
    }

    public var buttonTitle: String {
        if !pending { return isLast ? "Turu bitir" : "Sıradaki" }
        if canCheck { return "Kontrol Et ✓" }
        return usesPiano ? "Tuşlara Bas..." : "Seçenek Seç..."
    }

    /// Doğruda alttaki bildirim
    public var successToast: String { "Harika! \(question.chord.label) (+\(Self.pointsPerCorrect) XP)" }
    /// Yanlışta / süre dolunca kutunun başlığı: (önek, akor etiketi)
    public var wrongTitle: (prefix: String, label: String) {
        ((state == .timeout ? "Süre doldu. " : "") + "Doğru cevap: ", question.chord.label)
    }

    public var notesLine: String { "Notalar: " + question.chord.noteNames.joined(separator: " – ") }
    public var formulaTitle: String { showFormula ? "Gizle" : "Formülü Göster" }
    public var emptyKeysText: String { "\(question.chord.keys.count) tuşa bas…" }

    public enum OptionState: Sendable { case idle, chosen, correct, wrong, reveal }
    public func optionState(_ id: String) -> OptionState {
        let isSel = choice == id
        if pending { return isSel ? .chosen : .idle }
        if isSel { return state == .correct ? .correct : .wrong }
        return id == question.chord.id ? .reveal : .idle
    }

    /// Akor klavyesi: "Akoru bas" sorusunda seçim ve sonuç; "Tuşlardan bul" sorusunda yalnız gösterim
    public var pianoKeys: [PianoKey] {
        let c = question.chord
        if question.type == .keys {
            return Piano.multiKeys(selected: [], correctKeys: [], showResult: false, lit: Chords.litKeys(c))
        }
        return Piano.multiKeys(selected: Set(selectedKeys), correctKeys: pending ? [] : c.keys, showResult: !pending)
    }
}
