// Akor turu akışı web ChordQuizSession ile aynı mı: kontrol, puan, süre, cevapsız sorular, yazılar.
import XCTest

@testable import SolvatoCore

final class ChordRoundTests: XCTestCase {
    func testFlow() throws {
        var r = ChordRound(level: 2, random: seededRandom(3))
        XCTAssertEqual(r.questions.count, 10)
        XCTAssertEqual(r.levelLabel, "Orta")
        XCTAssertFalse(r.canCheck)
        for i in 0..<10 {
            let q = r.question
            if q.type == .build {
                XCTAssertEqual(r.buttonTitle, "Tuşlara Bas...")
                XCTAssertEqual(r.emptyKeysText, "\(q.chord.keys.count) tuşa bas…")
                for k in q.chord.keys.reversed() { r.toggleKey(k) }
                if i % 2 == 1 { r.toggleKey("Si"); r.toggleKey("Si") }
            } else {
                XCTAssertEqual(r.buttonTitle, "Seçenek Seç...")
                r.choose(i < 6 ? q.chord.id : q.options.first { $0.id != q.chord.id }!.id)
            }
            XCTAssertEqual(r.buttonTitle, "Kontrol Et ✓")
            if i == 9 {
                r.timeout(timeMs: 15000)
                XCTAssertEqual(r.wrongTitle.prefix, "Süre doldu. Doğru cevap: ")
            } else {
                r.check(timeMs: 1000)
            }
            XCTAssertFalse(r.pending)
            // R2: noktalar cevap sırasıyla birebir
            XCTAssertEqual(r.dots[i], i < 6 || (i < 9 && q.type == .build) ? .correct : .wrong, "\(i)")
            XCTAssertEqual(r.dots.dropFirst(i + 1).allSatisfy { $0 == .upcoming }, true)
            XCTAssertEqual(r.buttonTitle, i == 9 ? "Turu bitir" : "Sıradaki")
            if let answers = r.advance() {
                XCTAssertEqual(answers.count, 10)
                XCTAssertEqual(answers.map(\.questionId), Array(0..<10))
                XCTAssertFalse(answers[9].correct)
                XCTAssertEqual(r.score, answers.filter(\.correct).count * 10)
            }
        }
    }

    func testOptionStatesAndTexts() {
        var r = ChordRound(level: 1, random: seededRandom(9))
        while r.question.type == .build { _ = r.advance() }
        let c = r.question.chord
        let wrong = r.question.options.first { $0.id != c.id }!.id
        r.choose(wrong)
        XCTAssertEqual(r.optionState(wrong), .chosen)
        r.check(timeMs: 1)
        XCTAssertEqual(r.optionState(wrong), .wrong)
        XCTAssertEqual(r.optionState(c.id), .reveal)
        XCTAssertEqual(r.wrongTitle.prefix, "Doğru cevap: ")
        XCTAssertEqual(r.notesLine, "Notalar: " + c.noteNames.joined(separator: " – "))
        XCTAssertTrue(r.successToast.hasSuffix("(+10 XP)"))
        r.showFormula = true
        XCTAssertEqual(r.formulaTitle, "Gizle")
        r.toggleKey("Do")
        XCTAssertTrue(r.selectedKeys.isEmpty, "cevaptan sonra tuş seçilmez")
    }

    func testBuildCorrectAnyOrder() {
        let c = Chords.all.first { $0.id == "Ebmaj7" }!
        var r = ChordRound(questions: [ChordQuestion(chord: c, type: .build, options: [c])], level: 3)
        for k in c.keys.shuffled() { r.toggleKey(k) }
        XCTAssertTrue(r.check(timeMs: 1))
        XCTAssertEqual(r.pianoKeys.filter { $0.state == .correct }.map(\.note).count, c.keys.count * 2, "iki oktavda yeşil")
    }
}
