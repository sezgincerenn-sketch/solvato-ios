// Tur ekranları (docs/ozellikler/tur-ekranlari.md): üstteki nokta renkleri (R2), "cevap verildi" kuralı ve çıkış isteği
// (R16, R34: ✕ ve kaydırma aynı; cevap yoksa sormadan çıkılır).
import XCTest

@testable import SolvatoCore

@MainActor
final class RoundExitTests: XCTestCase {
    private func q(_ id: Int) -> Question { QuestionBank.byId[id]! }

    func testQuizDots() async {
        var r = QuizRound(questions: [q(1), q(2), q(3)])
        XCTAssertFalse(r.hasAnswers)
        XCTAssertEqual((0..<3).map(r.dot), [.current, .upcoming, .upcoming])
        _ = r.answer(q(1).correctAnswer, timeMs: 500)
        XCTAssertTrue(r.hasAnswers)
        XCTAssertNil(r.advance())
        _ = r.answer("yanlış", timeMs: 500)
        XCTAssertNil(r.advance())
        XCTAssertEqual((0..<3).map(r.dot), [.correct, .wrong, .current])
    }

    func testChordDots() async {
        var r = ChordRound(level: 1, random: seededRandom(9))
        XCTAssertFalse(r.hasAnswers)
        r.choose(r.question.chord.id)
        XCTAssertTrue(r.check(timeMs: 400))
        XCTAssertTrue(r.hasAnswers)
        XCTAssertNil(r.advance())
        r.timeout(timeMs: 15000)
        XCTAssertNil(r.advance())
        XCTAssertEqual([0, 1, 2, 3].map(r.dot), [.correct, .wrong, .current, .upcoming], "süre dolan kırmızı")
    }

    func testDuelHasAnswers() async {
        var g = DuelGame(questions: DuelGame.build(level: 1, random: seededRandom(4)))
        XCTAssertFalse(g.hasAnswers)
        _ = g.pick(0, "yanlış")
        XCTAssertTrue(g.hasAnswers)
    }

    func testRhythmHasAnswers() async {
        let r = RhythmTapRound(level: 1, random: seededRandom(2))
        XCTAssertFalse(r.hasAnswers)
    }

    /// ✕ / kaydırma: cevap yoksa doğrudan geri, varsa onay; "Çık" geri döner, "Devam et" kalır
    func testRequestExit() async {
        let m = AppModel(persistence: Persistence(store: MemoryStore()), random: seededRandom(7))
        m.startQuiz(.all)
        XCTAssertEqual(m.nav.current, .quiz)
        XCTAssertFalse(m.requestExit(), "cevap yok: sormadan çıkılır")
        XCTAssertEqual(m.nav.current, .home)

        m.startQuiz(.all)
        m.roundHasAnswers = true
        XCTAssertTrue(m.requestExit())
        XCTAssertTrue(m.exitConfirmOpen)
        XCTAssertEqual(m.nav.current, .quiz)
        m.stayInRound()
        XCTAssertFalse(m.exitConfirmOpen)
        XCTAssertEqual(m.nav.current, .quiz)
        m.requestExit()
        m.leaveRound()
        XCTAssertEqual(m.nav.current, .home)
        XCTAssertFalse(m.exitConfirmOpen)
        XCTAssertFalse(m.roundHasAnswers, "yeni turda sıfırdan")
    }
}
