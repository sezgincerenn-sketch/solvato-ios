// Çalışma sekmesi: ders listesi, arama ve terim tablosu web'le aynı (altın tablo calisma.json).
import XCTest

@testable import SolvatoCore

final class StudyContentTests: XCTestCase {
    func testLessonsMatchWeb() throws {
        let g = try Golden.load("calisma")
        let web = try XCTUnwrap(g["lessons"]?.array)
        XCTAssertEqual(web.count, Lessons.all.count)
        for (w, l) in zip(web, Lessons.all) {
            XCTAssertEqual(w["id"]?.string, l.id)
            XCTAssertEqual(w["section"]?.string, l.section.rawValue)
            XCTAssertEqual(w["title"]?.string, l.title)
            XCTAssertEqual(w["sub"]?.string, l.sub)
            XCTAssertEqual(w["icon"]?.string, l.icon.rawValue)
            XCTAssertEqual(w["color"]?.string, l.color.rawValue)
        }
    }

    func testTermsMatchWeb() throws {
        let web = try XCTUnwrap(Golden.load("calisma")["terms"]?.array)
        XCTAssertEqual(web.count, Terms.groups.count)
        for (w, g) in zip(web, Terms.groups) {
            XCTAssertEqual(w["group"]?.string, g.group)
            XCTAssertEqual(w["color"]?.string, g.color.rawValue)
            let items = try XCTUnwrap(w["items"]?.array)
            XCTAssertEqual(items.count, g.items.count, g.group)
            for (wi, t) in zip(items, g.items) {
                XCTAssertEqual(wi["symbol"]?.string, t.symbol)
                XCTAssertEqual(wi["name"]?.string, t.name)
                XCTAssertEqual(wi["meaning"]?.string, t.meaning)
            }
        }
    }

    func testSearchMatchesWeb() throws {
        for s in try XCTUnwrap(Golden.load("calisma")["searches"]?.array) {
            let q = try XCTUnwrap(s["query"]?.string)
            XCTAssertEqual(Lessons.groups(query: q).flatMap { $0.items.map(\.id) }, s["ids"]?.strings, "arama: \(q)")
        }
        XCTAssertEqual(Lessons.emptyText(" xyz "), "“xyz” için konu bulunamadı. Başka bir kelime dene.")
    }
}
