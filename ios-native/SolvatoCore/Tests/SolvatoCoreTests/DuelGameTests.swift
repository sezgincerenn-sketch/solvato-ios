// Akor düellosu: sorular web'le aynı (altın tablo duello.json, 200 tohum) ve puan/kilit/gösterim kuralları.
import XCTest

@testable import SolvatoCore

final class DuelGameTests: XCTestCase {
    func testBuildMatchesWeb() throws {
        for r in try XCTUnwrap(Golden.load("duello").array) {
            let qs = DuelGame.build(level: r["level"]!.int!, random: seededRandom(UInt32(r["seed"]!.int!)))
            let web = try XCTUnwrap(r["questions"]?.array)
            XCTAssertEqual(qs.map(\.chord.id), web.map { $0["id"]!.string! })
            XCTAssertEqual(qs.map(\.type.rawValue), web.map { $0["type"]!.string! })
            XCTAssertEqual(qs.map { $0.options.map(\.id) }, web.map { $0["options"]!.strings })
        }
    }

    func testRules() {
        var g = DuelGame(questions: DuelGame.build(level: 1, random: seededRandom(3)))
        let q = g.current!
        let wrong = q.options.first { $0.id != q.chord.id }!.id
        XCTAssertEqual(g.counter, "1/10 · \(q.type == .staff ? "portedeki akor" : "basılı tuşlar")")
        XCTAssertEqual(g.pick(1, wrong), .wrong)
        XCTAssertEqual(g.pick(1, q.chord.id), .ignored)  // kilitli
        XCTAssertEqual(g.pick(0, q.chord.id), .correct)
        XCTAssertEqual(g.scores, [1, 0])
        XCTAssertEqual(g.pick(1, q.chord.id), .ignored)  // gösterimde
        g.advance()
        let q2 = g.current!
        let w2 = q2.options.first { $0.id != q2.chord.id }!.id
        XCTAssertEqual(g.pick(0, w2), .wrong)
        XCTAssertEqual(g.pick(1, w2), .bothWrong)
        XCTAssertTrue(g.reveal)
        for _ in 0..<9 { g.advance() }
        XCTAssertTrue(g.finished)
        XCTAssertEqual(g.resultTitle(names: ["Ayşe", "Can"]), "Ayşe kazandı!")
        XCTAssertEqual(g.scoreText, "1 – 0")
        XCTAssertEqual(g.exitText, "Skor 1 – 0. Çıkarsan düello yarıda kalır.")
    }

    /// Ad kutuları boş gelir; boş ya da yalnız boşluk olan ad varsayılan
    func testPlayerNames() {
        XCTAssertEqual(DuelGame.playerNames(["", ""]), ["1. oyuncu", "2. oyuncu"])
        XCTAssertEqual(DuelGame.playerNames(["Ada", "  "]), ["Ada", "2. oyuncu"])
        XCTAssertEqual(DuelGame.playerNames([" Ali ", "Can"]), ["Ali", "Can"])
    }
}
