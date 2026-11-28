// Toplam çalışma süresi (kullanici-testi-revize.md madde 8): hangi ekranlar sayılır, arka planda sayılmaz, eski kayıtta
// son turların süreleriyle başlar, sıfırlamada sıfırlanır; İlerleme'deki "35 dk" / "2 sa 15 dk" biçimi.
import XCTest

@testable import SolvatoCore

@MainActor
final class StudyTimeTests: XCTestCase {
    func testFormat() async {
        XCTAssertEqual(ProgressContent.studyTime(0), "0 dk")
        XCTAssertEqual(ProgressContent.studyTime(59), "0 dk")
        XCTAssertEqual(ProgressContent.studyTime(35 * 60 + 20), "35 dk")
        XCTAssertEqual(ProgressContent.studyTime(59 * 60 + 59), "59 dk")
        XCTAssertEqual(ProgressContent.studyTime(3600), "1 sa")
        XCTAssertEqual(ProgressContent.studyTime(2 * 3600 + 15 * 60), "2 sa 15 dk")
    }

    func testTotalsTiles() async {
        var s = AppStats()
        s.studySeconds = 35 * 60
        s.totalSessions = 4
        s.dailyQuestions["2026-11-27"] = 40
        XCTAssertEqual(ProgressContent.totals(s).map(\.label), ["Toplam süre", "Tamamlanan tur", "Çözülen soru"])
        XCTAssertEqual(ProgressContent.totals(s).map(\.value), ["35 dk", "4", "40"])
    }

    func testCountedScreens() async {
        let counted = AppView.allCases.filter(\.countsStudyTime)
        XCTAssertEqual(Set(counted), [.quiz, .chordquiz, .rhythmtap, .duel, .lesson])
    }

    /// Eski kayıtta alan yok: son turların süreleri; yazılınca aynı adla saklanır
    func testSeedAndStorage() async throws {
        let old = AppStats(json: try JSON.parse(#"{"history":[{"label":"A","correct":5,"total":10,"sec":40,"at":1},{"label":"Akorlar","correct":3,"total":5,"at":2},{"label":"B","correct":9,"total":10,"sec":65,"at":3}]}"#))
        XCTAssertEqual(old.studySeconds, 105)
        var s = old
        s.studySeconds = 500
        let back = AppStats(json: try JSON.parse(s.json.serialized))
        XCTAssertEqual(back.studySeconds, 500)
        XCTAssertEqual(AppStats().studySeconds, 0)
    }

    func testClock() async {
        let m = AppModel(persistence: Persistence(store: MemoryStore()), random: seededRandom(7))
        // Ana sayfada sayılmaz
        m.updateStudyClock(active: true, now: 0)
        m.updateStudyClock(active: true, now: 100)
        XCTAssertEqual(m.stats.studySeconds, 0)
        // Derste 90 sn
        m.go(.study)
        m.go(.lesson)
        m.updateStudyClock(active: true, now: 100)
        m.updateStudyClock(active: true, now: 190)
        XCTAssertEqual(m.stats.studySeconds, 90)
        // Arka planda geçen süre sayılmaz
        m.updateStudyClock(active: false, now: 200)
        XCTAssertEqual(m.stats.studySeconds, 100)
        m.updateStudyClock(active: true, now: 5000)
        XCTAssertEqual(m.stats.studySeconds, 100)
        // Dersten çıkınca durur
        m.back()
        m.updateStudyClock(active: true, now: 5030)
        XCTAssertEqual(m.stats.studySeconds, 130)
        m.updateStudyClock(active: true, now: 9000)
        XCTAssertEqual(m.stats.studySeconds, 130)
        // Unutulan ekran: tek parça en çok 30 dk
        m.go(.lesson)
        m.updateStudyClock(active: true, now: 10000)
        m.updateStudyClock(active: true, now: 20000)
        XCTAssertEqual(m.stats.studySeconds, 130 + 1800)
        // Sıfırlama
        m.resetProgress()
        XCTAssertEqual(m.stats.studySeconds, 0)
    }
}
