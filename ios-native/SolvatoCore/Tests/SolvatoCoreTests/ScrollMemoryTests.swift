// Kaydırma hafızası (G-10, web utils/scrollMemory.ts + App.tsx): ileri gidince saklanır, geri dönünce bir kez uygulanır,
// kaydırırken altta görünen ekranda da uygulanır; sekmeye geçmek ve sonuç ekranından gitmek hafızayı değiştirmez/siler.
import Foundation
import XCTest

@testable import SolvatoCore

@MainActor
final class ScrollMemoryTests: XCTestCase {
    private func model() -> AppModel {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("solvato-scroll-\(UUID().uuidString)")
        return AppModel(persistence: Persistence(store: FileStore(directory: dir)), random: seededRandom(3))
    }

    func testProfileKeepsPlaceAfterSettings() async {
        let m = model()
        m.go(.profile)
        m.scroll.report(.profile, slot: 0, y: 420)
        m.go(.settings)
        m.scroll.report(.settings, slot: 0, y: 900)
        // Kaydırarak geri dönerken altta görünen Profil kalınan yerde (her çizimde)
        XCTAssertEqual(m.scroll.restore(.profile, slot: 0, current: m.nav.current), 420)
        XCTAssertEqual(m.scroll.restore(.profile, slot: 0, current: m.nav.current), 420)
        // Ayarlar'ın kendisi baştan açılmıştı
        XCTAssertNil(m.scroll.restore(.settings, slot: 0, current: m.nav.current))
        m.back()
        XCTAssertEqual(m.nav.current, .profile)
        XCTAssertEqual(m.scroll.restore(.profile, slot: 0, current: .profile), 420)
        // Bir kez uygulanır
        XCTAssertNil(m.scroll.restore(.profile, slot: 0, current: .profile))
    }

    func testFreshOpenStartsAtTop() async {
        let m = model()
        m.go(.profile)
        m.scroll.report(.profile, slot: 0, y: 300)
        m.go(.settings)
        m.back()
        m.back()
        XCTAssertEqual(m.nav.current, .home)
        // Profil yeniden açılınca (geri dönüş değil) en üstten
        m.go(.profile)
        XCTAssertNil(m.scroll.restore(.profile, slot: 0, current: .profile))
    }

    func testTabClearsAndSlotsAreSeparate() async {
        let m = model()
        m.scroll.report(.home, slot: 0, y: 250)
        m.go(.games)
        m.scroll.report(.games, slot: 0, y: 10)
        m.scroll.report(.games, slot: 1, y: 80)
        m.go(.gameDaily)
        m.back()
        XCTAssertEqual(m.scroll.restore(.games, slot: 1, current: .games), 80)
        XCTAssertEqual(m.scroll.restore(.games, slot: 0, current: .games), 10)
        // Sekmeye geçmek hafızayı siler
        m.go(.study)
        m.go(.lesson)
        m.back()
        XCTAssertNil(m.scroll.restore(.study, slot: 0, current: .study))
        XCTAssertNil(m.scroll.restore(.home, slot: 0, current: .study))
    }

    func testResultScreenIsNotSaved() async {
        let m = model()
        m.scroll.report(.home, slot: 0, y: 500)
        m.startQuiz(.all)
        m.completeQuiz([])
        XCTAssertEqual(m.nav.current, .result)
        m.scroll.report(.result, slot: 0, y: 200)
        m.back()
        XCTAssertEqual(m.nav.current, .home)
        XCTAssertEqual(m.scroll.restore(.home, slot: 0, current: .home), 500)
        XCTAssertNil(m.scroll.restore(.result, slot: 0, current: .home))
    }
}
