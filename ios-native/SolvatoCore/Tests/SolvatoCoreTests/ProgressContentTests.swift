// İlerleme sekmesi web'le aynı mı (E-10, K-11, K-12, K-14): 50 durumda ekrandaki yazılar ve erişilebilirlik adları.
import Foundation
import XCTest

@testable import SolvatoCore

final class ProgressContentTests: XCTestCase {
    func testProgressTexts() throws {
        for (i, r) in try XCTUnwrap(Golden.load("ilerleme").array).enumerated() {
            let s = try JSONDecoder().decode(Settings.self, from: Data(r["settings"]!.serialized.utf8))
            let c = ProgressContent(stats: AppStats(json: r["stats"]!), settings: s, now: Golden.now(r["now"]!.int!, "Europe/Istanbul"))
            let (texts, labels) = c.texts()
            let web = r["texts"]?.strings ?? []
            if let k = zip(texts, web).enumerated().first(where: { $0.element.0 != $0.element.1 })?.offset {
                XCTFail("durum \(i) yazı \(k): Swift «\(texts[k])» ≠ web «\(web[k])»")
            } else {
                XCTAssertEqual(texts.count, web.count, "durum \(i) yazı sayısı")
            }
            XCTAssertEqual(labels, r["labels"]?.strings, "durum \(i)")
        }
    }
}
