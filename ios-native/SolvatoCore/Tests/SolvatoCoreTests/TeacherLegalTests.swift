// Öğretmen kodu ekranının kuralları (web TeacherScreen.tsx) ve Gizlilik/Lisanslar metinlerinin pakette olduğu.
import XCTest

@testable import SolvatoCore

final class TeacherLegalTests: XCTestCase {
    func testSanitize() {
        XCTAssertEqual(TeacherFlow.sanitize("abc-defgh"), "ABC-DEF")
        XCTAssertEqual(TeacherFlow.sanitize("k7m"), "K7M")
    }

    func testInitialSetupGoalFallback() {
        var s = Settings()
        s.dailyGoal = 15
        XCTAssertEqual(TeacherFlow.initialSetup(s).dailyGoal, 10)
        s.dailyGoal = 30
        XCTAssertEqual(TeacherFlow.initialSetup(s).dailyGoal, 30)
    }

    func testApply() {
        var s = Settings()
        s.level = 1
        s.levelProgress = LevelProgress(n: 8, c: 7)
        let setup = TeacherSetup(notes: ["Do", "Re", "Mi"], clef: .bass, level: 2, dailyGoal: 30, keyLabels: true, topics: ["rhythm"])
        let code = TeacherCode.encode(setup)
        // Küçük harf ve tiresiz yazılsa da uygulanır, kayıtlı kod temiz biçimdedir
        let r = TeacherFlow.apply(code.lowercased().replacingOccurrences(of: "-", with: ""), to: &s)
        XCTAssertEqual(r?.code, code)
        XCTAssertEqual(r?.setup, setup)
        XCTAssertEqual(s.teacherCode, code)
        XCTAssertEqual(s.notes, ["Do", "Re", "Mi"])
        XCTAssertEqual(s.clef, .bass)
        XCTAssertEqual(s.level, 2)
        XCTAssertEqual(s.dailyGoal, 30)
        XCTAssertTrue(s.keyLabels)
        XCTAssertEqual(s.topics, ["rhythm"])
        XCTAssertEqual(s.levelProgress, LevelProgress(n: 0, c: 0))

        // Seviye aynıysa ilerleme korunur
        s.levelProgress = LevelProgress(n: 3, c: 2)
        _ = TeacherFlow.apply(code, to: &s)
        XCTAssertEqual(s.levelProgress, LevelProgress(n: 3, c: 2))

        let before = s
        XCTAssertNil(TeacherFlow.apply("ZZZ-ZZZ", to: &s))
        XCTAssertEqual(s, before)
    }

    func testToggleTopic() {
        let keys = TeacherCode.topics.map(\.key)
        // Hepsi → birine dokun → yalnız o
        XCTAssertEqual(TeacherFlow.toggleTopic(keys[2], in: []), [keys[2]])
        // Sıra listedeki sıradır
        XCTAssertEqual(TeacherFlow.toggleTopic(keys[0], in: [keys[2]]), [keys[0], keys[2]])
        // Sonuncuyu kaldırınca Hepsi
        XCTAssertEqual(TeacherFlow.toggleTopic(keys[2], in: [keys[2]]), [])
        XCTAssertTrue(TeacherFlow.topicSelected(keys[2], in: [keys[2]]))
        XCTAssertFalse(TeacherFlow.topicSelected(keys[2], in: []))
        XCTAssertFalse(TeacherFlow.topicSelected(keys[2], in: keys))
    }

    func testLegalTexts() {
        XCTAssertEqual(Legal.privacy.map(\.title), ["Özet", "Cihazında tutulan bilgiler", "İzinler", "Paylaşım", "Çocuklar", "KVKK", "Değişiklikler"])
        XCTAssertEqual(Legal.licenses.map(\.name), ["Bravura", "Outfit", "JetBrains Mono"])
        XCTAssertTrue(Legal.licenses.allSatisfy { ($0.text ?? "").count > 500 })
    }
}
