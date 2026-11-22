// Soru turu akışı (web src/screens/QuizSession.tsx): sıradaki soru, cevap kontrolü (eş sesli siyah tuş, çok oktavlı
// klavyede oktav), doğru cevapta 0,7 sn sonra geçiş, yanlışta açıklama ve "Sıradaki", ipucu, süre, üç doğruda alev.
// Ekranda gösterilecek her yazı ve durum buradan; SwiftUI ekranı (Screens/QuizScreen) çizer, ses ve titreşimi
// çalar.
import Foundation

public enum AnswerState: String, Sendable { case pending, correct, wrong }

public struct QuizRound: Equatable, Sendable {
    public let questions: [Question]
    /// Klavye oktav sayısı: telefonda dikey 1, iPad 2, yan ekran 3
    public var octaves: Int
    /// Ayarlardaki giriş: piyano ya da şıklar (yalnız nota sorularında)
    public let prefersPiano: Bool
    public let keyLabels: Bool
    /// Oyunlarda ipucu yok
    public let noHints: Bool

    public private(set) var index = 0
    public private(set) var answerState = AnswerState.pending
    public private(set) var selected: String?
    public private(set) var results: [SessionResult] = []
    public private(set) var correctStreak = 0
    public var showHint = false

    public init(questions: [Question], octaves: Int = 1, prefersPiano: Bool = true, keyLabels: Bool = false, noHints: Bool = false) {
        self.questions = questions
        self.octaves = octaves
        self.prefersPiano = prefersPiano
        self.keyLabels = keyLabels
        self.noHints = noHints
    }

    public var question: Question { questions[index] }
    public var isNote: Bool { question.category == .noteIdentification }
    public var isLast: Bool { index + 1 >= questions.count }
    public var score: Int { results.filter(\.correct).count }
    /// Klavye mi şıklar mı
    public var usesPiano: Bool { isNote && prefersPiano }
    public var showExplanation: Bool { answerState == .wrong }

    // MARK: Klavye
    public var window: (start: Int, octaveMode: Bool) { Piano.window(for: question, octaves: octaves) }
    /// Çok oktavlı klavyede doğru tuş ("Do#4")
    public var target: (key: String, octave: Int)? { isNote ? Piano.noteKey(question) : nil }

    public var pianoKeys: [PianoKey] {
        let w = window
        let octaveMode = w.octaveMode && target != nil
        return Piano.quizKeys(
            octaves: octaves, startOctave: w.start, octaveMode: octaveMode, answerState: answerState.rawValue,
            selectedNote: selected, correctAnswer: octaveMode ? target?.key : (question.keyName ?? question.correctAnswer),
            showLabels: keyLabels)
    }

    // MARK: Cevap
    public enum Outcome: Equatable, Sendable {
        /// Doğru: 0,7 sn sonra `advance()`; `flare` üç doğruda bir alev
        case correct(flare: Bool)
        case wrong
        case ignored
    }

    /// Klavye tuşu ya da şık. Çok oktavlı klavyede oktav da doğru olmalı; tek oktavda siyah tuşun diyez adı bemol
    /// yazımını da doğru sayar.
    public mutating func answer(_ answer: String, timeMs: Int) -> Outcome {
        guard answerState == .pending else { return .ignored }
        let q = question
        let correct: Bool
        if usesPiano, window.octaveMode, let t = target {
            correct = answer == t.key
        } else {
            correct = answer == q.correctAnswer || (q.keyName != nil && answer == q.keyName)
        }
        selected = answer
        answerState = correct ? .correct : .wrong
        results.append(SessionResult(question: q, correct: correct, timeMs: timeMs))
        if correct {
            correctStreak += 1
            return .correct(flare: correctStreak % 3 == 0)
        }
        correctStreak = 0
        return .wrong
    }

    /// Süre doldu: yanlış sayılır
    public mutating func timeout(timeMs: Int) -> Outcome { answer("__timeout__", timeMs: timeMs) }

    /// Sonraki soru; tur bittiyse sonuçlar
    public mutating func advance() -> [SessionResult]? {
        if isLast { return results }
        index += 1
        answerState = .pending
        selected = nil
        showHint = false
        return nil
    }

    // MARK: Yazılar
    /// Konu etiketi ve rengi
    public var categoryLabel: String {
        switch question.category {
        case .noteIdentification: question.clef == .treble ? "SOL ANAHTARI" : "FA ANAHTARI"
        case .rhythm: "RİTİM & ÖLÇÜ"
        case .writing: "NOTA YAZIMI"
        case .ear: "KULAK"
        case .musicalTerms: "MÜZİK TERİMİ"
        }
    }

    public var categoryColor: CategoryColor {
        switch question.category {
        case .noteIdentification: question.accidental != nil ? .accidentals : question.clef == .bass ? .bass : .treble
        case .rhythm: .rhythm
        case .writing: .writing
        case .ear: .ear
        case .musicalTerms: .terms
        }
    }

    /// Soru türüne göre süre: ritim 1,6 kat, terim 2 kat (en az 10 sn)
    public func seconds(base: Int) -> Int {
        switch question.category {
        case .musicalTerms: max(base * 2, 10)
        case .rhythm: Int((Double(base) * 1.6).rounded(.up))
        default: base
        }
    }

    /// Nota doğru, oktav yanlış (çok oktavlı klavye)
    public var wrongOctave: Bool {
        guard window.octaveMode, answerState == .wrong, let t = target, let s = selected else { return false }
        func strip(_ x: String) -> String { String(x.reversed().drop { $0.isNumber }.reversed()) }
        return strip(s) == strip(t.key)
    }

    /// "Nota doğru, oktav yanlış: bu nota Do (4. oktav)."
    public var wrongOctaveText: String? {
        guard wrongOctave, let t = target else { return nil }
        let name = String(t.key.reversed().drop { $0.isNumber }.reversed())
        return "Nota doğru, oktav yanlış: bu nota \(name) (\(t.octave). oktav)."
    }

    /// İpucu (yalnız nota sorularında, oyunlarda yok)
    public var hintAvailable: Bool { isNote && !noHints && answerState == .pending }
    public var hintText: String {
        if question.accidental != nil {
            return "♯ (diyez) notayı yarım ses yükseltir, ♭ (bemol) yarım ses alçaltır. İkisi de piyanoda siyah tuşa denk gelir; Do♯ ile Re♭ aynı tuştur."
        }
        return question.clef == .treble
            ? "Sol anahtarında çizgiler aşağıdan yukarı: Mi–Sol–Si–Re–Fa. Aralıklar: Fa–La–Do–Mi."
            : "Fa anahtarında çizgiler aşağıdan yukarı: Sol–Si–Re–Fa–La. Aralıklar: La–Do–Mi–Sol."
    }

    public var nextTitle: String { isLast ? "Turu bitir" : "Sıradaki" }

    public enum OptionState: Sendable { case idle, correct, wrong, reveal }
    /// Şıkkın rengi: seçilen doğru yeşil, seçilen yanlış kırmızı, yanlıştan sonra doğru şık yeşil ve ✓
    public func optionState(_ opt: String) -> OptionState {
        guard answerState != .pending else { return .idle }
        if selected == opt { return answerState == .correct ? .correct : .wrong }
        if answerState == .wrong && opt == question.correctAnswer { return .reveal }
        return .idle
    }

    /// Terim sorusu partisyonda çizilebiliyorsa nota metni ("Hangi terim …" sorularında çizim yok)
    public var termScore: String? {
        let q = question
        guard q.category == .musicalTerms, !q.questionText.hasPrefix("Hangi"), let d = q.displayText else { return nil }
        return NotationLayout.termScore(d)
    }

    /// Çizim yoksa büyük yazıyla gösterilen terim (web TermDisplay: displayText ya da tırnak içindeki kelime,
    /// `questionText.slice(1, indexOf("'", 1))`)
    public var termText: String {
        let q = question
        if let d = q.displayText { return d }
        let u = Array(q.questionText.utf16)
        guard u.count > 1 else { return "" }
        let end = u[1...].firstIndex(of: UInt16(UInt8(ascii: "'"))) ?? (u.count - 1)
        return end > 1 ? String(decoding: u[1..<end], as: UTF16.self) : ""
    }
}
