// Akor motoru ve akor turu React'la aynı mı (K-17): 94 akorun adı, sembolü, yazımı, porte konumu, tuşları, örnek
// dizileri; aynı rastgele sayı dizisiyle aynı 10 soru, aynı soru türleri ve aynı şıklar.
import Foundation
import XCTest

@testable import SolvatoCore

final class ChordTests: XCTestCase {
    func testChordTable() throws {
        let g = try Golden.load("akorlar")
        let web = try XCTUnwrap(g["chords"]?.array)
        XCTAssertEqual(Chords.all.count, 94)
        XCTAssertEqual(Chords.all.map(\.id), web.map { $0["id"]!.string! })
        XCTAssertEqual([1, 2, 3, 4].map { lv in Chords.all.filter { $0.level == lv }.count }, [14, 10, 23, 47])
        for (c, w) in zip(Chords.all, web) {
            let id = c.id
            XCTAssertEqual(c.level, w["level"]?.int, id)
            XCTAssertEqual(c.root, w["root"]?.string, id)
            XCTAssertEqual(c.quality, w["quality"]?.string, id)
            XCTAssertEqual(c.name, w["name"]?.string, id)
            XCTAssertEqual(c.symbol, w["symbol"]?.string, id)
            XCTAssertEqual(c.label, w["label"]?.string, id)
            XCTAssertEqual(c.noteNames, w["noteNames"]?.strings, id)
            XCTAssertEqual(c.pcs, w["pcs"]?.ints, id)
            XCTAssertEqual(c.semis, w["semis"]?.ints, id)
            XCTAssertEqual(c.rootPc, w["rootPc"]?.int, id)
            XCTAssertEqual(c.keys, w["keys"]?.strings, id)
            XCTAssertEqual(c.formula, w["formula"]?.string, id)
            XCTAssertEqual(c.notes.map(\.staffY), w["staffY"]?.ints, id)
            let notes = w["notes"]!.array!
            XCTAssertEqual(c.notes.map(\.letter), notes.map { $0["letter"]!.int! }, id)
            XCTAssertEqual(c.notes.map(\.acc), notes.map { $0["acc"]!.int! }, id)
            XCTAssertEqual(c.notes.map(\.octave), notes.map { $0["octave"]!.int! }, id)
            XCTAssertEqual(Chords.litKeys(c), Set(w["lit"]!.strings), id)
            XCTAssertEqual(Chords.fitsKeyboard(c), w["fits"]?.bool, id)
            XCTAssertEqual(Chords.progressions(c), w["progressions"]?.strings, id)
            XCTAssertEqual(Chords.qualityColor[c.quality], g["colors"]?[c.quality]?.string, id)
            XCTAssertTrue(Chords.isCorrectBuild(Set(c.keys.reversed()), c), id)
            XCTAssertFalse(Chords.isCorrectBuild(Set(c.keys.dropLast()), c), id)
        }
        var same: [[String]] = []
        for a in Chords.all { for b in Chords.all where a.id < b.id && Chords.samePcs(a, b) { same.append([a.id, b.id]) } }
        XCTAssertEqual(same, g["same"]!.array!.map(\.strings))
        for (lv, ids) in g["upTo"]!.array!.enumerated() { XCTAssertEqual(Chords.upTo(lv + 1).map(\.id), ids.strings) }
    }

    func testChordRounds() throws {
        let g = try Golden.load("akor-turu")
        for (i, row) in g["rounds"]!.array!.enumerated() {
            let qs = Chords.roundQuestions(level: row["level"]!.int!, random: seededRandom(UInt32(row["seed"]!.int!)))
            let web = row["questions"]!.array!
            let label = "tur \(i)"
            XCTAssertEqual(qs.map(\.chord.id), web.map { $0["id"]!.string! }, label)
            XCTAssertEqual(qs.map(\.type.rawValue), web.map { $0["type"]!.string! }, label)
            XCTAssertEqual(qs.map { $0.options.map(\.id) }, web.map { $0["options"]!.strings }, label)
        }
        for row in g["distractors"]!.array! {
            let c = Chords.all.first { $0.id == row["chord"]!.string! }!
            let ids = Chords.distractors(c, pool: Chords.upTo(row["level"]!.int!), random: seededRandom(UInt32(row["seed"]!.int!)))
                .map(\.id)
            XCTAssertEqual(ids, row["ids"]?.strings, c.id)
        }
    }
}
