// Dışarıdan gelen girdiler (0.8 güvenlik denetimi, erisilebilirlik-ipad.md §5): öğretmen kodu, meydan okuma kodu ve
// panodan yapıştırma rastgele ve bozuk girdilerle (çok uzun metin, emoji, boşluk, eksik/fazla karakter) denenir.
// Beklenen: çökme yok; geçersiz kod hiçbir ayarı değiştirmez; kabul edilen kod hep geçerli alanlarla gelir.
// Ayrıca kayıt dosyalarının veri koruması (G-09) ve VoiceOver metinleri (AccessibilityText).
import Foundation
import XCTest

@testable import SolvatoCore

final class InputFuzzTests: XCTestCase {
    /// Elle seçilmiş bozuk girdiler
    private let odd: [String] = [
        "", " ", "\n\t", "-", "---", "ABC", "ABC-", "ABC-DE", "ABC-DEFG", "ABCD-EFG", "ABCD-EFGHI", "abc-def", "  K7M-2QX  ",
        "K7M 2QX", "K7M–2QX", "🎹🎹🎹-🎹🎹🎹", "ÇĞİ-ÖŞÜ", "ışık", "0O0-1I1", "١٢٣-٤٥٦", "ＡＢＣ-ＤＥＦ", "\u{0}\u{0}\u{0}", "Kod: ",
        String(repeating: "A", count: 10_000), String(repeating: "🎵", count: 5_000), String(repeating: "K7M-2QX ", count: 2_000),
    ]

    /// Tohumlu rastgele metin: alfabe harfleri, küçük harf, tire, boşluk, emoji, Türkçe harf karışık
    private func randomStrings(count: Int, seed: UInt32) -> [String] {
        let r = seededRandom(seed)
        let pool = Array("23456789ABCDEFGHJKLMNPQRSTUVWXYZabcxyz01OI- \n🎹éşğİı")
        return (0..<count).map { _ in
            let n = Int(r() * 14)
            return String((0..<n).map { _ in pool[Int(r() * Double(pool.count))] })
        }
    }

    private func checkTeacher(_ input: String) {
        // Yazma ve yapıştırma kutusu hiçbir girdide çökmez, en çok 7 karakter (6 + tire) verir
        let typed = TeacherFlow.sanitize(input)
        let pasted = TeacherFlow.pasted(input)
        XCTAssertLessThanOrEqual(typed.count, 7)
        XCTAssertLessThanOrEqual(pasted.count, 7)
        for code in [input, typed, pasted] {
            var s = Settings()
            s.level = 2
            let before = s
            if let applied = TeacherFlow.apply(code, to: &s) {
                // Kabul edildiyse ayarlar kodun söylediği, alanlar sınır içinde
                let t = applied.setup
                XCTAssertTrue((1...3).contains(t.level))
                XCTAssertTrue(TeacherCode.goals.contains(t.dailyGoal))
                XCTAssertGreaterThanOrEqual(t.notes.count, TeacherCode.minNotes)
                XCTAssertTrue(t.notes.allSatisfy { allNotes.contains($0) })
                XCTAssertTrue(t.topics.allSatisfy { k in TeacherCode.topics.contains { $0.key == k } })
                XCTAssertEqual(TeacherCode.decode(applied.code), t)
                XCTAssertEqual(s.teacherCode, applied.code)
            } else {
                XCTAssertEqual(s, before, "geçersiz kod ayarları değiştirdi: \(code.prefix(40))")
            }
        }
    }

    private func checkChallenge(_ input: String) {
        let typed = GameScreens.sanitizeCode(input)
        let pasted = GameScreens.pastedCode(input)
        XCTAssertLessThanOrEqual(typed.count, 9)
        XCTAssertLessThanOrEqual(pasted.count, 9)
        for code in [input, typed, pasted] {
            guard let c = ChallengeCode.decode(code) else { continue }
            XCTAssertTrue((1...3).contains(c.level))
            XCTAssertTrue((0...Games.length).contains(c.correct))
            XCTAssertTrue((0...1023).contains(c.sec))
            XCTAssertTrue((0..<65536).contains(c.seed))
        }
    }

    func testOddInputsDoNotCrashOrApply() {
        for s in odd {
            checkTeacher(s)
            checkChallenge(s)
        }
        // Hiçbiri geçerli bir kod değil
        for s in odd where !s.contains("K7M") {
            XCTAssertNil(TeacherCode.decode(s), s.prefix(30).description)
        }
    }

    func testRandomInputs() {
        var accepted = 0
        for s in randomStrings(count: 20_000, seed: 20_261_127) {
            checkTeacher(s)
            checkChallenge(s)
            if TeacherCode.decode(s) != nil { accepted += 1 }
        }
        // Kontrol karakteri ve işaret rastgele metnin çok azını geçirir (kabul edilenler de geçerli alanlı, yukarıda)
        XCTAssertLessThan(accepted, 200)
    }

    /// Geçerli koddan tek karakteri değiştirmek çoğunlukla reddedilir; kabul edilirse yine geçerli ayardır
    func testMutatedValidCodes() throws {
        let setup = TeacherSetup(notes: ["Do", "Re", "Mi", "Fa"], clef: .both, level: 3, dailyGoal: 30, keyLabels: true, topics: ["treble", "ear"])
        let code = TeacherCode.encode(setup)
        XCTAssertEqual(TeacherCode.decode(code), setup)
        let chars = Array(code)
        var rejected = 0
        var total = 0
        for i in chars.indices where chars[i] != "-" {
            for ch in codeAlphabet where ch != chars[i] {
                var m = chars
                m[i] = ch
                total += 1
                let s = String(m)
                checkTeacher(s)
                if TeacherCode.decode(s) == nil { rejected += 1 }
            }
        }
        XCTAssertGreaterThan(Double(rejected) / Double(total), 0.9)
        // Eksik ve fazla karakter
        XCTAssertNil(TeacherCode.decode(String(code.dropLast())))
        XCTAssertNil(TeacherCode.decode(code + "A"))

        let ch = Challenge(category: GameCategory.allCases[0], level: 2, seed: 4321, correct: 7, sec: 95)
        let cc = ChallengeCode.encode(ch)
        XCTAssertEqual(ChallengeCode.decode(cc), ch)
        XCTAssertNil(ChallengeCode.decode(String(cc.dropLast())))
        XCTAssertNil(ChallengeCode.decode(cc + "A"))
    }

    /// Paylaşım mesajının tamamı yapıştırılınca kod bulunur; mesajın içinde emoji ve uzun metin olsa da
    func testPasteFromShareMessage() {
        let setup = TeacherSetup(notes: allNotes, clef: .treble, level: 1, dailyGoal: 10, keyLabels: false, topics: [])
        let code = TeacherCode.encode(setup)
        let message = TeacherCode.shareText(code: code, setup) + "\n" + String(repeating: "🎹 ", count: 500)
        XCTAssertEqual(TeacherFlow.pasted(message), code)
    }

    /// G-09: kayıtlar atomik ve kilitliyken şifreli yazılır
    func testFileProtection() {
        XCTAssertTrue(FileStore.writeOptions.contains(.atomic))
        XCTAssertTrue(FileStore.writeOptions.contains(.completeFileProtectionUnlessOpen))
    }
}

/// VoiceOver metinleri (erisilebilirlik-ipad.md §2)
final class AccessibilityTextTests: XCTestCase {
    func testTexts() {
        XCTAssertEqual(AccessibilityText.roundPosition(index: 2, count: 10), "3. soru, 10 sorudan")
        XCTAssertEqual(AccessibilityText.noteStaff(.treble), "Porte: Sol anahtarı, bir nota")
        XCTAssertEqual(AccessibilityText.noteStaff(.bass), "Porte: Fa anahtarı, bir nota")
        XCTAssertEqual(AccessibilityText.chordStaff(), "Porte: Sol anahtarı, bir akor")
        XCTAssertEqual(AccessibilityText.answerResult(correct: true, timedOut: false, correctAnswer: "Sol"), "Doğru")
        XCTAssertEqual(AccessibilityText.answerResult(correct: false, timedOut: false, correctAnswer: "Sol"), "Yanlış. Doğru cevap: Sol")
        XCTAssertEqual(AccessibilityText.answerResult(correct: false, timedOut: true, correctAnswer: "Sol"), "Süre doldu. Doğru cevap: Sol")
        XCTAssertEqual(AccessibilityText.timeLeft(5), "Kalan süre 5 saniye")
        XCTAssertEqual((0...6).filter(AccessibilityText.announcesTime), [1, 2, 3])
        XCTAssertEqual(AccessibilityText.stars(2), "3 yıldızdan 2")
        XCTAssertEqual(AccessibilityText.join(["Sol Anahtarı", nil, " ", "%72", "10 soru"]), "Sol Anahtarı, %72, 10 soru")
    }

    /// Soru turunda porte okunurken notanın adı hiçbir zaman söylenmez
    func testNoteNameNeverInPromptLabel() {
        let notes = QuestionBank.all.filter { $0.category == .noteIdentification }
        XCTAssertFalse(notes.isEmpty)
        for q in notes {
            var round = QuizRound(questions: [q])
            // Yalnız anahtar ve "bir nota": notanın adı ya da yeri yok
            XCTAssertEqual(round.promptAccessibilityLabel, AccessibilityText.noteStaff(q.clef ?? .treble), "\(q.id)")
            // Cevaptan sonra duyuru doğru cevabı söyler
            _ = round.answer(q.correctAnswer, timeMs: 1000)
            XCTAssertEqual(round.answerAnnouncement, "Doğru")
        }
    }

    func testAnnouncements() throws {
        let q = try XCTUnwrap(QuestionBank.all.first { $0.category == .noteIdentification })
        let wrong = q.options.first { $0 != q.correctAnswer } ?? "x"
        var r = QuizRound(questions: [q], prefersPiano: false)
        XCTAssertNil(r.answerAnnouncement)
        _ = r.answer(wrong, timeMs: 500)
        XCTAssertEqual(r.answerAnnouncement, "Yanlış. Doğru cevap: \(q.correctAnswer)")
        var t = QuizRound(questions: [q], prefersPiano: false)
        _ = t.timeout(timeMs: 5000)
        XCTAssertEqual(t.answerAnnouncement, "Süre doldu. Doğru cevap: \(q.correctAnswer)")
        let rhythm = try XCTUnwrap(QuestionBank.all.first { $0.category == .rhythm })
        XCTAssertEqual(QuizRound(questions: [rhythm]).promptAccessibilityLabel, "Porte: bir ritim")
    }
}
