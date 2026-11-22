// Oyunlar ekranlarının yazıları web'le aynı mı (altın tablo oyun-ekranlari.json): 60 durumda liste, günün meydan okuması,
// meydan oku ve üç tür oyun sonucu (günlük, yeni kod, karşılaştırma), günlük paylaşım metni.
import XCTest

@testable import SolvatoCore

final class GameScreensTests: XCTestCase {
    func testTextsMatchWeb() throws {
        for (i, r) in try XCTUnwrap(Golden.load("oyun-ekranlari").array).enumerated() {
            let now = Golden.now(try XCTUnwrap(r["now"]?.int), "Europe/Istanbul")
            var daily: [String: DailyRecord] = [:]
            for (k, v) in r["daily"]?.object?.entries ?? [] {
                daily[k] = DailyRecord(date: k, correct: v["correct"]!.int!, sec: v["sec"]!.int!, marks: v["marks"]!.string!)
            }
            let today = Games.dailyInfo(now.todayKey)
            let played = daily[today.date]
            let streak = Games.dailyStreak(Set(daily.keys), now: now)
            let level = try XCTUnwrap(r["level"]?.int)
            XCTAssertEqual(GameScreens.listTexts(today: today, played: played), r["list"]?["texts"]?.strings, "\(i) liste")
            XCTAssertEqual(GameScreens.dailyTexts(today: today, played: played, streak: streak), r["dailyScreen"]?["texts"]?.strings, "\(i) günlük")
            XCTAssertEqual(GameScreens.challengeTexts(level: level), r["challenge"]?["texts"]?.strings, "\(i) meydan oku")
            if let p = played {
                XCTAssertEqual(
                    GameScreens.dailyShareText(no: today.number, category: today.category, correct: p.correct, sec: p.sec, marks: p.marks),
                    r["dailyShare"]?.string, "\(i) paylaşım")
            }
            let correct = r["results"]!.array!.map { $0.bool! }
            let times = r["timesMs"]!.ints
            let results = zip(correct, times).enumerated().map { RoundAnswer(questionId: $0.offset, correct: $0.element.0, timeMs: $0.element.1) }
            let cat = try XCTUnwrap(GameCategory(rawValue: r["cat"]!.string!))
            let seed = r["seed"]!.int!
            let opp = Challenge(category: cat, level: level, seed: seed, correct: r["opp"]!["correct"]!.int!, sec: r["opp"]!["sec"]!.int!)
            let ctxs: [GameContext] = [
                .daily(date: today.date, category: today.category, seed: today.seed, number: today.number),
                .challenge(category: cat, level: level, seed: seed, opponent: nil),
                .challenge(category: cat, level: level, seed: seed, opponent: opp),
            ]
            for (k, ctx) in ctxs.enumerated() {
                let c = GameResultContent(ctx: ctx, results: results, name: r["name"]!.string!, dailyStreak: streak)
                XCTAssertEqual(c.texts, r["result"]?.array?[k]["texts"]?.strings, "\(i) sonuç \(k)")
            }
        }
    }

    func testShareTexts() {
        let rs = (0..<10).map { RoundAnswer(questionId: $0, correct: $0 < 7, timeMs: 4200) }
        let o = Challenge(category: .rhythm, level: 2, seed: 9, correct: 6, sec: 50)
        let win = GameResultContent(ctx: .challenge(category: .rhythm, level: 2, seed: 9, opponent: o), results: rs, name: "", dailyStreak: 0)
        XCTAssertEqual(win.title, "Kazandın!")
        XCTAssertEqual(win.shareText, "Ritim meydan okumanı geçtim: 7/10 (42 sn), sen 6/10 (50 sn) 😎")
        let mine = GameResultContent(ctx: .challenge(category: .rhythm, level: 2, seed: 9, opponent: nil), results: rs, name: " Ayşe ", dailyStreak: 0)
        XCTAssertTrue(mine.shareText.hasPrefix("Ayşe sana meydan okuyor! 🎹\nRitim: 7/10 · 42 sn\n"))
        guard case let .newChallenge(code) = mine.kind else { return XCTFail() }
        XCTAssertEqual(ChallengeCode.decode(code)?.correct, 7)
    }
}
