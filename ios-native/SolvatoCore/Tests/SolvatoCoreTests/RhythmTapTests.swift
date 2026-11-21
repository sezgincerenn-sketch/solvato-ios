// Ritmi Tut React'la aynı mı (K-18): ritim metninin ayrıştırılması, 1.500 dokunuş dizisinin puanı, pencereler,
// fazla dokunuşlar, erken/geç uyarısı ve turdaki ritimlerin seçimi.
import Foundation
import XCTest

@testable import SolvatoCore

final class RhythmTapTests: XCTestCase {
    func testTablesAndParsing() throws {
        let g = try Golden.load("ritmi-tut")
        for lv in 1...3 { XCTAssertEqual(RhythmTap.tempo[lv], g["tempo"]?[String(lv)]?.int) }
        XCTAssertEqual(RhythmTap.pass, g["pass"]?.double)
        let pats = g["patterns"]!.array!
        XCTAssertEqual(pats.prefix(30).map { $0["score"]!.string! }, (1...3).flatMap { RhythmTap.patterns[$0]! })
        for p in pats {
            let score = p["score"]!.string!
            let parsed = RhythmTap.parse(score)
            let web = p["parsed"]!.array!
            XCTAssertEqual(parsed.map(\.at), web.map { $0["at"]!.double! }, score)
            XCTAssertEqual(parsed.map(\.rest), web.map { $0["rest"]!.bool! }, score)
            XCTAssertEqual(parsed.map(\.dur), web.map { $0["dur"]!.double! }, score)
            XCTAssertEqual(RhythmTap.onsets(score), p["onsets"]!.array!.map { $0.double! }, score)
        }
    }

    func testGrading() throws {
        let g = try Golden.load("ritmi-tut")
        for (i, c) in g["cases"]!.array!.enumerated() {
            let score = c["score"]!.string!
            let r = RhythmTap.grade(
                score, taps: c["taps"]!.array!.map { $0.double! }, bpm: c["bpm"]!.int!, level: c["level"]!.int!)
            let w = c["result"]!
            let label = "durum \(i) \(score)"
            let notes = w["notes"]!.array!
            XCTAssertEqual(r.notes.map(\.beat), notes.map { $0["beat"]!.double! }, label)
            XCTAssertEqual(r.notes.map(\.deltaMs), notes.map { $0["deltaMs"]!.int }, label)
            XCTAssertEqual(r.notes.map(\.grade.rawValue), notes.map { $0["grade"]!.string! }, label)
            XCTAssertEqual(r.extra, w["extra"]!.array!.map { $0.double! }, label)
            XCTAssertEqual(r.score, w["score"]?.double, label)
            XCTAssertEqual(r.meanAbsMs, w["meanAbsMs"]?.int, label)
            XCTAssertEqual(r.biasMs, w["biasMs"]?.int, label)
            XCTAssertEqual(r.passed, c["passed"]?.bool, label)
            XCTAssertEqual(r.biasHint, c["bias"]?.string, label)
        }
    }

    func testPickPatterns() throws {
        for row in try XCTUnwrap(Golden.load("ritmi-tut")["picks"]?.array) {
            let mine = RhythmTap.pickPatterns(level: row["level"]!.int!, random: seededRandom(UInt32(row["seed"]!.int!)))
            XCTAssertEqual(mine, row["patterns"]?.strings)
        }
    }

    /// Metronomla tam zamanında çalınan her ritim %100 alır
    func testPerfectTapsScoreFull() {
        for lv in 1...3 {
            for p in RhythmTap.patterns[lv]! {
                let bpm = RhythmTap.tempo[lv]!
                let taps = RhythmTap.onsets(p).map { $0 * 60 / Double(bpm) }
                XCTAssertEqual(RhythmTap.grade(p, taps: taps, bpm: bpm, level: lv).score, 1, p)
            }
        }
    }
}
