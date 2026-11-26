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

/// Son turlar satırı (R17): kayıttaki addan aynı konudan yeni tur
final class RoundReplayTests: XCTestCase {
    func testReplay() {
        XCTAssertEqual(ProgressContent.replay(label: "Sol Anahtarı"), .quiz(.treble))
        XCTAssertEqual(ProgressContent.replay(label: "Karışık"), .quiz(.all))
        XCTAssertEqual(ProgressContent.replay(label: "Ritim"), .quiz(.rhythm))
        XCTAssertEqual(ProgressContent.replay(label: "Akorlar"), .chords)
        XCTAssertEqual(ProgressContent.replay(label: "Ritmi Tut"), .rhythmTap)
        XCTAssertEqual(ProgressContent.replay(label: "Zayıf notalar"), .weak)
        XCTAssertEqual(ProgressContent.replay(label: "Oyun · Ritim"), .games)
        XCTAssertEqual(ProgressContent.replay(label: "Hataların tekrarı"), .quiz(.all))
    }
}
