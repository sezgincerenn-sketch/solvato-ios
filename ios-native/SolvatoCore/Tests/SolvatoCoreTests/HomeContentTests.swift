// Ana sayfa içeriği React'la aynı mı (E-04): 60 durumda (seviye, ad, öğretmen konuları, sınırlı notalar, hedef,
// saat, günün oyunu) ekranda görünen yazılar ve erişilebilirlik adları sırasıyla aynı. Altın tablo gezinme revizesinin
// web önizlemesinden (revize-onizleme dalı) üretildi; hedef çubuğu ve yüzde halkası kuralları ayrıca (gezinme.md).
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

    /// Bugün çubuğu: hedef 10/20/30/50 için dolu bölme `floor(min(çözülen, hedef) × 10 / hedef)`
    func testGoalSegments() {
        XCTAssertEqual([0, 1, 2, 3, 9, 10, 25].map { HomeContent.goalSegments(done: $0, goal: 10) }, [0, 1, 2, 3, 9, 10, 10])
        XCTAssertEqual([1, 2, 3, 12, 19, 20].map { HomeContent.goalSegments(done: $0, goal: 20) }, [0, 1, 1, 6, 9, 10])
        XCTAssertEqual([2, 3, 29, 30, 31].map { HomeContent.goalSegments(done: $0, goal: 30) }, [0, 1, 9, 10, 10])
        XCTAssertEqual([4, 5, 49, 50, 99].map { HomeContent.goalSegments(done: $0, goal: 50) }, [0, 1, 9, 10, 10])
        XCTAssertEqual(HomeContent.goalSegments(done: 5, goal: 0), 0)
    }

    /// Yüzde halkası: round(doğru / toplam × 100); toplam 0 ise boş. Diyez & Bemol nota konumlarından, Ritmi Tut
    /// oynanmadıysa boş, akor satırı akor doğruluğu.
    func testPercentRing() {
        XCTAssertNil(Tally.zero.percent)
        XCTAssertEqual(Tally(correct: 4, total: 5).percent, 80)
        XCTAssertEqual(Tally(correct: 1, total: 8).percent, 13, "12,5 yukarı yuvarlanır")
        XCTAssertEqual(Tally(correct: 0, total: 3).percent, 0)

        var stats = AppStats()
        stats.categoryAccuracy.treble = Tally(correct: 8, total: 10)
        stats.categoryAccuracy.rhythm = Tally(correct: 3, total: 4)
        stats.categoryAccuracy.chords = Tally(correct: 1, total: 2)
        stats.noteStats = try! AppStats(json: JSON.parse(#"{"noteStats":{"treble:50:sharp":{"correct":2,"total":3},"bass:30:flat":{"correct":1,"total":1},"treble:50":{"correct":0,"total":5}}}"#)).noteStats
        var s = Settings()
        s.level = 2
        let c = HomeContent(stats: stats, settings: s, daily: nil, now: Now())
        var cats: [FilterCategory: Tally] = [:]
        var links: [SpecialRound: Tally] = [:]
        for case let .category(x) in c.groups[0].rows { cats[x.key] = x.acc }
        for case let .link(x) in c.groups[0].rows { links[x.round] = x.acc }
        XCTAssertEqual(cats.count, 7, "dokuz satır: yedi konu + Akor + Ritmi Tut")
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(cats[.treble]?.percent, 80)
        XCTAssertEqual(cats[.accidentals], Tally(correct: 3, total: 4))
        XCTAssertNil(cats[.ear]?.percent)
        XCTAssertEqual(links[.chords]?.percent, 50)
        XCTAssertNil(links[.rhythmtap]?.percent, "Ritmi Tut hiç oynanmadı")
        stats.bestStars = OrderedMap([("rhythmtap", 2)])
        let c2 = HomeContent(stats: stats, settings: s, daily: nil, now: Now())
        for case let .link(x) in c2.groups[0].rows where x.round == .rhythmtap { XCTAssertEqual(x.acc.percent, 75) }
    }

    func testTodaySubAndGoalLabel() {
        var stats = AppStats()
        let now = Now()
        stats.dailyQuestions = OrderedMap([(now.todayKey, 12)])
        var s = Settings()
        s.dailyGoal = 20
        var c = HomeContent(stats: stats, settings: s, daily: nil, now: now)
        XCTAssertEqual(c.todaySub, "Karma · 10 soru · ~3 dk")
        XCTAssertEqual(c.goalLabel, "20 soruluk hedefin 12 sorusu çözüldü")
        XCTAssertEqual(c.goalSegments, 6)
        s.topics = ["treble"]
        c = HomeContent(stats: stats, settings: s, daily: nil, now: now)
        XCTAssertEqual(c.todaySub, "Karma · 10 soru · ~3 dk · öğretmeninin konuları")
        XCTAssertEqual(c.streakLabel, "Seri yok. Bugün bir tur çözünce başlar")
    }

    /// Seri balonu metni (kullanici-testi-revize.md madde 3)
    func testStreakTip() {
        XCTAssertEqual(HomeContent.streakTip(5), "5 günlük seri. Her gün günlük hedefini tamamlayınca 1 artar.")
        XCTAssertEqual(HomeContent.streakTip(0), "Bugün hedefini tamamlayınca serin başlar.")
        XCTAssertEqual(HomeContent.streakTipSeconds, 3)
        XCTAssertEqual(AccessibilityText.streakHint, "Seri hakkında bilgi")
    }
}
