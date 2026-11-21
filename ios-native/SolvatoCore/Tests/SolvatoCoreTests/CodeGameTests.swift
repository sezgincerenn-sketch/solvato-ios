// Kodlar ve oyunlar React'la aynı mı: öğretmen kodu (K-15), meydan okuma kodu, günün meydan okuması ve tohumlu
// oyun soruları (K-16), tur için soru seçimi ve kulak soruları (K-03, K-05).
import Foundation
import XCTest

@testable import SolvatoCore

final class CodeGameTests: XCTestCase {
    private func setup(_ j: JSON) -> TeacherSetup {
        TeacherSetup(
            notes: j["notes"]!.strings, clef: ClefChoice(rawValue: j["clef"]!.string!)!, level: j["level"]!.int!,
            dailyGoal: j["dailyGoal"]!.int!, keyLabels: j["keyLabels"]!.bool!, topics: j["topics"]!.strings)
    }

    private func checkTeacher(_ code: String, _ web: JSON, _ label: String) {
        let mine = TeacherCode.decode(code)
        if web.isNull { XCTAssertNil(mine, "\(label): \(code) reddedilmeliydi") } else { XCTAssertEqual(mine, setup(web), "\(label): \(code)") }
    }

    func testTeacherCode() throws {
        let g = try Golden.load("ogretmen-kodu")
        for row in g["valid"]!.array! {
            XCTAssertEqual(TeacherCode.encode(setup(row["setup"]!)), row["code"]?.string)
            checkTeacher(row["code"]!.string!, row["decoded"]!, "geçerli")
        }
        for row in g["random"]!.array! { checkTeacher(row["code"]!.string!, row["decoded"]!, "rastgele") }
        for row in g["odd"]!.array! { checkTeacher(row["code"]!.string!, row["decoded"]!, "bozuk") }
    }

    private func challenge(_ j: JSON) -> Challenge {
        Challenge(
            category: GameCategory(rawValue: j["cat"]!.string!)!, level: j["level"]!.int!, seed: j["seed"]!.int!,
            correct: j["correct"]!.int!, sec: j["sec"]!.int!)
    }

    private func checkChallenge(_ code: String, _ web: JSON) {
        let mine = ChallengeCode.decode(code)
        if web.isNull { XCTAssertNil(mine, code) } else { XCTAssertEqual(mine, challenge(web), code) }
    }

    func testChallengeCodes() throws {
        let g = try Golden.load("oyun")
        for row in g["codes"]!.array! {
            XCTAssertEqual(ChallengeCode.encode(challenge(row["input"]!)), row["code"]?.string)
            checkChallenge(row["code"]!.string!, row["decoded"]!)
        }
        for row in g["random"]!.array! { checkChallenge(row["code"]!.string!, row["decoded"]!) }
        for row in g["odd"]!.array! { checkChallenge(row["code"]!.string!, row["decoded"]!) }
    }

    func testDailyChallenge2026And2027() throws {
        let rows = try XCTUnwrap(Golden.load("oyun")["daily"]?.array)
        XCTAssertEqual(rows.count, 730)
        for row in rows {
            let d = Games.dailyInfo(row["date"]!.string!)
            XCTAssertEqual(d.category.rawValue, row["cat"]?.string, d.date)
            XCTAssertEqual(d.seed, row["seed"]?.int, d.date)
            XCTAssertEqual(d.number, row["no"]?.int, d.date)
        }
    }

    /// Web'deki iz: "id:şık|şık;id:…" → FNV-1a
    private func fnv(_ s: String) -> String {
        var h: UInt32 = 2_166_136_261
        for u in s.utf16 { h = (h ^ UInt32(u)) &* 16_777_619 }
        return String(format: "%08x", h)
    }

    func testGameQuestions() throws {
        let g = try Golden.load("oyun")
        for row in g["full"]!.array! {
            let qs = Games.questions(GameCategory(rawValue: row["cat"]!.string!)!, level: row["level"]!.int!, seed: row["seed"]!.int!)
            XCTAssertEqual(qs.map(\.id), row["ids"]?.ints)
            XCTAssertEqual(qs.map(\.options), row["options"]!.array!.map(\.strings))
        }
        let hashes = try XCTUnwrap(g["hashes"]?.object)
        XCTAssertEqual(hashes.count, 18000)
        for (key, hash) in hashes.entries {
            let p = key.split(separator: "/")
            let qs = Games.questions(GameCategory(rawValue: String(p[0]))!, level: Int(p[1])!, seed: Int(p[2])!)
            let trace = qs.map { "\($0.id):\($0.options.joined(separator: "|"))" }.joined(separator: ";")
            XCTAssertEqual(fnv(trace), hash.string, key)
        }
    }

    func testRoundPicking() throws {
        let g = try Golden.load("tur-secimi")
        for (i, row) in g["rows"]!.array!.enumerated() {
            let sj = row["settings"]!
            var s = Settings()
            s.level = sj["level"]!.int!
            s.clef = ClefChoice(rawValue: sj["clef"]!.string!)!
            s.notes = sj["notes"]!.strings
            s.topics = sj["topics"]!.strings
            let category = FilterCategory(rawValue: row["category"]!.string!)!
            let r = seededRandom(UInt32(row["seed"]!.int!))
            let label = "tur \(i) \(category)"
            if category == .ear {
                let mine = Ear.questions(settings: s, random: r)
                let web = row["questions"]!.array!
                XCTAssertEqual(mine.count, web.count, label)
                for (m, w) in zip(mine, web) {
                    XCTAssertEqual(m.id, w["id"]?.int, label)
                    XCTAssertEqual(m.options, w["options"]?.strings, label)
                    XCTAssertEqual(m.correctAnswer, w["correctAnswer"]?.string, label)
                    XCTAssertEqual(m.explanation, w["explanation"]?.string, label)
                    XCTAssertEqual(m.questionText, w["questionText"]?.string, label)
                    let ear = try JSON.parse(String(decoding: JSONEncoder().encode(m.ear), as: UTF8.self))
                    XCTAssertNil(Golden.diff(ear, w["ear"]!), label)
                }
            } else {
                let mine = Session.pick(category, settings: s, random: r)
                let web = row["questions"]!.array!
                XCTAssertEqual(mine.map(\.id), web.map { $0["id"]!.int! }, label)
                XCTAssertEqual(mine.map(\.options), web.map { $0["options"]!.strings }, label)
            }
        }
        for row in g["weak"]!.array! {
            let ids = Session.weakQuestions(row["keys"]!.strings, random: seededRandom(UInt32(row["seed"]!.int!))).map(\.id)
            XCTAssertEqual(ids, row["ids"]?.ints)
        }
    }

    /// Başlangıç seviyesinde hiçbir turda Orta/İleri soru gelmez (1.000 tur)
    func testBeginnerNeverGetsHarderQuestions() {
        var s = Settings()
        s.level = 1
        let r = seededRandom(42)
        for i in 0..<1000 {
            let cat: FilterCategory = [.all, .treble, .bass, .rhythm, .terms, .writing][i % 6]
            for q in Session.questions(cat, settings: s, random: r) {
                XCTAssertEqual(QuestionBank.level(of: q), 1, "\(cat) \(q.id)")
            }
        }
    }
}
