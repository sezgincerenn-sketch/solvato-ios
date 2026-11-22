// Pratik sayfası içeriği React'la aynı mı (E-04): 60 durumda (seviye, ad, öğretmen konuları, sınırlı notalar, hedef,
// saat, günün oyunu) ekranda görünen yazılar ve erişilebilirlik adları sırasıyla aynı.
import Foundation
import XCTest

@testable import SolvatoCore

final class HomeContentTests: XCTestCase {
    func testHomeTexts() throws {
        for (i, r) in try XCTUnwrap(Golden.load("ana-sayfa").array).enumerated() {
            let s = try JSONDecoder().decode(Settings.self, from: Data(r["settings"]!.serialized.utf8))
            let stats = AppStats(json: r["stats"]!)
            let daily = r["daily"].flatMap { d -> DailyRecord? in
                guard let date = d["date"]?.string else { return nil }
                return DailyRecord(date: date, correct: d["correct"]!.int!, sec: d["sec"]!.int!, marks: "")
            }
            let c = HomeContent(stats: stats, settings: s, daily: daily, now: Golden.now(r["now"]!.int!, "Europe/Istanbul"))
            let (texts, labels) = c.texts
            XCTAssertEqual(texts, r["texts"]?.strings, "durum \(i)")
            XCTAssertEqual(labels, r["labels"]?.strings, "durum \(i)")
        }
    }

    func testGreeting() {
        XCTAssertEqual([0, 5, 6, 11, 12, 17, 18, 23].map(HomeContent.greeting), [
            "İyi geceler", "İyi geceler", "Günaydın", "Günaydın", "Merhaba", "Merhaba", "İyi akşamlar", "İyi akşamlar",
        ])
    }
}
