// Soru turu akışı web QuizSession ile aynı mı: eş sesli siyah tuş, çok oktavlı klavyede oktav, yanlışta açıklama,
// üç doğruda alev, süre, ipucu yazıları, terim gösterimi.
import XCTest

@testable import SolvatoCore

final class QuizRoundTests: XCTestCase {
    private func q(_ id: Int) -> Question { QuestionBank.byId[id]! }

    func testEnharmonicBlackKeyAndFlow() throws {
        // Bemol sorusu: siyah tuşun diyez adı da doğru
        let flat = try XCTUnwrap(QuestionBank.all.first { $0.accidental == .flat && $0.keyName != nil })
        var r = QuizRound(questions: [flat, q(1), q(2)])
        XCTAssertEqual(r.answer(flat.keyName!, timeMs: 1200), .correct(flare: false))
        XCTAssertTrue(r.results[0].correct)
        XCTAssertNil(r.advance())
        XCTAssertEqual(r.answer("yanlış", timeMs: 900), .wrong)
        XCTAssertTrue(r.showExplanation)
        XCTAssertEqual(r.answer(q(1).correctAnswer, timeMs: 1), .ignored, "cevaptan sonra yok sayılır")
        XCTAssertEqual(r.nextTitle, "Sıradaki")
        XCTAssertNil(r.advance())
        XCTAssertEqual(r.nextTitle, "Turu bitir")
        _ = r.timeout(timeMs: 5000)
        XCTAssertEqual(r.results.map(\.correct), [true, false, false])
        XCTAssertEqual(r.advance()?.count, 3, "son soruda tur biter")
        XCTAssertEqual(r.score, 1)
    }

    /// R2: cevaplanan noktalar doğru/yanlış renginde, şimdiki ve kalanlar bugünkü gibi
    func testDots() {
        let qs = Array(QuestionBank.all.prefix(4))
        var r = QuizRound(questions: qs, prefersPiano: false)
        func marks() -> String { String(r.dots.map(\.mark)) }
        XCTAssertEqual(marks(), "●···")
        _ = r.answer(qs[0].correctAnswer, timeMs: 1)
        XCTAssertEqual(marks(), "✓···", "cevaplanan şimdiki soru da renk alır")
        _ = r.advance()
        XCTAssertEqual(marks(), "✓●··")
        _ = r.answer("yanlış", timeMs: 1)
        _ = r.advance()
        _ = r.timeout(timeMs: 1)
        _ = r.advance()
        XCTAssertEqual(marks(), "✓✗✗●")
        XCTAssertEqual(r.dots.filter { $0 == .correct }.count, r.score, "tur sonucu sayısıyla tutarlı")
    }

    func testFlareEveryThirdCorrect() {
        let qs = Array(QuestionBank.all.prefix(6))
        var r = QuizRound(questions: qs, prefersPiano: false)
        var flares: [Bool] = []
        for x in qs {
            if case let .correct(f) = r.answer(x.correctAnswer, timeMs: 1) { flares.append(f) }
            _ = r.advance()
        }
        XCTAssertEqual(flares, [false, false, true, false, false, true])
    }

    func testOctaveModeOnTablet() throws {
        // Sol anahtarı Do4 (orta Do): iki oktavlı klavyede "Do4" doğru, "Do5" oktav yanlış
        let c4 = try XCTUnwrap(QuestionBank.all.first { $0.clef == .treble && $0.noteY == 90 && $0.accidental == nil })
        var r = QuizRound(questions: [c4], octaves: 2)
        XCTAssertEqual(r.window.start, 4)
        XCTAssertTrue(r.window.octaveMode)
        XCTAssertEqual(r.answer("Do5", timeMs: 1), .wrong)
        XCTAssertTrue(r.wrongOctave)
        XCTAssertEqual(r.wrongOctaveText, "Nota doğru, oktav yanlış: bu nota Do (4. oktav).")
        let keys = r.pianoKeys
        XCTAssertEqual(keys.first { $0.answer == "Do5" }?.state, .wrong)
        XCTAssertEqual(keys.first { $0.answer == "Do4" }?.state, .reveal)
        var t = QuizRound(questions: [c4], octaves: 2)
        XCTAssertEqual(t.answer("Do4", timeMs: 1), .correct(flare: false))
        var phone = QuizRound(questions: [c4])
        XCTAssertEqual(phone.answer("Do", timeMs: 1), .correct(flare: false), "tek oktavda yalnız ad")
    }

    func testTextsAndTimer() throws {
        let rhythm = try XCTUnwrap(QuestionBank.all.first { $0.category == .rhythm })
        let term = try XCTUnwrap(QuestionBank.all.first { $0.category == .musicalTerms })
        let bass = try XCTUnwrap(QuestionBank.all.first { $0.clef == .bass && $0.accidental == nil })
        let sharp = try XCTUnwrap(QuestionBank.all.first { $0.accidental == .sharp })
        XCTAssertEqual(QuizRound(questions: [rhythm]).seconds(base: 5), 8)
        XCTAssertEqual(QuizRound(questions: [term]).seconds(base: 5), 10)
        XCTAssertEqual(QuizRound(questions: [bass]).seconds(base: 5), 5)
        XCTAssertEqual(QuizRound(questions: [rhythm]).categoryLabel, "RİTİM & ÖLÇÜ")
        XCTAssertEqual(QuizRound(questions: [sharp]).categoryColor, .accidentals)
        XCTAssertTrue(QuizRound(questions: [bass]).hintText.hasPrefix("Fa anahtarında"))
        XCTAssertFalse(QuizRound(questions: [bass], noHints: true).hintAvailable)
        XCTAssertFalse(QuizRound(questions: [rhythm]).hintAvailable)
        XCTAssertFalse(QuizRound(questions: [rhythm]).usesPiano)
        for t in QuestionBank.all where t.category == .musicalTerms {
            let r = QuizRound(questions: [t])
            XCTAssertFalse(r.termText.isEmpty && r.termScore == nil, "terim \(t.id) gösterilebilir")
        }
    }

    func testOptionStates() {
        let x = QuestionBank.all[0]
        var r = QuizRound(questions: [x], prefersPiano: false)
        let wrong = x.options.first { $0 != x.correctAnswer }!
        _ = r.answer(wrong, timeMs: 1)
        XCTAssertEqual(r.optionState(wrong), .wrong)
        XCTAssertEqual(r.optionState(x.correctAnswer), .reveal)
    }
}
