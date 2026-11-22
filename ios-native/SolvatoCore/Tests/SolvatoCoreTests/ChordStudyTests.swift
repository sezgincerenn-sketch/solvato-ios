// Çalışma › Akor kartları: 4 seviyenin açılış hali ve bütün kartların yazıları web'le aynı (altın tablo akor-kartlari.json).
import XCTest

@testable import SolvatoCore

final class ChordStudyTests: XCTestCase {
    func testTextsMatchWeb() throws {
        for r in try XCTUnwrap(Golden.load("akor-kartlari").array) {
            let level = try XCTUnwrap(r["level"]?.int)
            XCTAssertEqual(ChordStudy.texts(level: level, rootFilter: nil), r["initial"]?.strings, "seviye \(level) açılış")
            let all = ChordStudy.texts(level: level, rootFilter: "*")
            let web = r["all"]?.strings ?? []
            XCTAssertEqual(all.count, web.count, "seviye \(level) tümü")
            if let i = zip(all, web).enumerated().first(where: { $0.element.0 != $0.element.1 })?.offset {
                XCTFail("seviye \(level) yazı \(i): \(all[i]) ≠ \(web[i])")
            }
        }
        XCTAssertEqual(ChordStudy.cards.count, 94)
    }
}
