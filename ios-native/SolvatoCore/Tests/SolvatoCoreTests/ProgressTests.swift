// Tur sonu kuralları React'la aynı mı: seri ve günlük hedef (K-07), istatistik güncellemesi (K-08), yıldız rekoru
// (K-09), kutlama (K-10), seviye atlama (K-04). Senaryolar iki saat diliminde (biri yaz saatli).
import Foundation
import XCTest

@testable import SolvatoCore

final class ProgressTests: XCTestCase {
    func testStreakScenariosIstanbul() throws { try runScenarios("seri-Europe-Istanbul", tz: "Europe/Istanbul") }
    func testStreakScenariosNewYork() throws { try runScenarios("seri-America-New_York", tz: "America/New_York") }

    private func results(_ j: JSON) -> [SessionResult] {
        j.array!.map { r in
            SessionResult(
                questionId: r["questionId"]!.int!, category: QuestionCategory(rawValue: r["category"]!.string!)!,
                clef: r["clef"]?.string.flatMap(Clef.init(rawValue:)), correct: r["correct"]!.bool!,
                timeMs: r["timeMs"]!.int!, hasLedger: r["hasLedger"]?.bool, noteY: r["noteY"]?.int,
                accidental: r["accidental"]?.string.flatMap(Accidental.init(rawValue:)))
        }
    }

    private func runScenarios(_ file: String, tz: String) throws {
        let g = try Golden.load(file)
        XCTAssertEqual(g["tz"]?.string, tz)
        for sc in try XCTUnwrap(g["scenarios"]?.array) {
            let name = sc["name"]!.string!
            var settings = Settings()
            settings.dailyGoal = sc["goal"]!.int!
            settings.level = sc["level"]!.int!
            var stats = AppStats()
            for (i, step) in sc["steps"]!.array!.enumerated() {
                let label = "\(name) adım \(i)"
                let now = Golden.now(step["now"]!.int!, tz)
                let before = step["settingsBefore"]!
                XCTAssertEqual(settings.level, before["level"]?.int, label)
                XCTAssertEqual(settings.levelProgress.n, before["levelProgress"]?["n"]?.int, label)
                let round = step["round"]!
                let out: RoundOutcome
                if round["kind"]?.string == "quiz" {
                    out = Progress.completeQuiz(
                        stats, settings: &settings, results: results(round["results"]!),
                        category: FilterCategory(rawValue: round["category"]!.string!)!,
                        label: round["label"]?.string, game: round["game"]?.string.flatMap(GameCategory.init(rawValue:)),
                        now: now)
                } else {
                    out = Progress.completeSpecial(
                        stats, settings: settings, kind: SpecialRound(rawValue: round["special"]!.string!)!,
                        answers: round["correct"]!.array!.map { $0.bool! }, now: now)
                }
                stats = out.stats
                let after = step["settingsAfter"]!
                XCTAssertEqual(settings.level, after["level"]?.int, label)
                XCTAssertEqual(settings.levelProgress.n, after["levelProgress"]?["n"]?.int, label)
                XCTAssertEqual(settings.levelProgress.c, after["levelProgress"]?["c"]?.int, label)
                XCTAssertEqual(out.points, step["points"]?.int, label)
                XCTAssertEqual(out.stars, step["stars"]?.int, label)
                XCTAssertEqual(out.previousBest, step["best"]?.int, label)
                XCTAssertEqual(stats.streak, step["streak"]?.int, label)
                XCTAssertEqual(stats.lastPlayDate, step["lastPlayDate"]?.string, label)
                XCTAssertEqual(stats.totalPoints, step["totalPoints"]?.int, label)
                XCTAssertEqual(Progress.currentStreak(stats, now: now), step["streakNow"]?.int, label)
                if let t = step["streakTomorrow"]?.int {
                    // Web: son turdan 24 ve 48 saat sonra
                    XCTAssertEqual(Progress.currentStreak(stats, now: Golden.now(now.ms + 86_400_000, tz)), t, label)
                    XCTAssertEqual(
                        Progress.currentStreak(stats, now: Golden.now(now.ms + 2 * 86_400_000, tz)), step["streakIn2Days"]?.int,
                        label)
                }
                for p in step["probe"]?.array ?? [] {
                    XCTAssertEqual(
                        Progress.currentStreak(stats, now: Golden.now(p["now"]!.int!, tz)), p["streak"]?.int, "\(label) sonra")
                }
                checkCelebration(out.celebration, step["celebration"]!, label)
                if let web = step["stats"] {
                    XCTAssertNil(Golden.diff(stats.json, web), label)
                    // Ekranda sıra görünen sözlükler: ekleme sırası da aynı olmalı
                    XCTAssertEqual(stats.noteStats.keys, web["noteStats"]?.object?.keys, "\(label) noteStats sırası")
                    XCTAssertEqual(stats.dailyTopics?.keys, web["dailyTopics"]?.object?.keys, label)
                    for (k, day) in (stats.dailyTopics?.entries ?? []) {
                        XCTAssertEqual(day.keys, web["dailyTopics"]?[k]?.object?.keys, "\(label) \(k) konu sırası")
                    }
                    // Kaydedilip yeniden okununca aynı
                    XCTAssertEqual(AppStats(json: try JSON.parse(stats.json.serialized)), stats, label)
                }
            }
        }
    }

    private func checkCelebration(_ c: Celebration?, _ web: JSON, _ label: String) {
        guard let c else {
            XCTAssertTrue(web.isNull, "\(label): kutlama bekleniyordu")
            return
        }
        XCTAssertEqual(c.rankUp?.rank, web["rankUp"]?["rank"]?.int, label)
        XCTAssertEqual(c.rankUp?.label, web["rankUp"]?["label"]?.string, label)
        XCTAssertEqual(c.rankUp?.nextLabel, web["rankUp"]?["nextLabel"]?.string, label)
        XCTAssertEqual(c.goalDone, web["goalDone"]?.bool ?? false, label)
        XCTAssertEqual(c.streak, web["streak"]?.int, label)
        XCTAssertEqual(c.unlocked, web["unlocked"]?.string, label)
    }

    func testLevelProgress() throws {
        for (i, row) in try XCTUnwrap(Golden.load("seviye").array).enumerated() {
            var s = Settings()
            s.level = row["level"]!.int!
            s.levelProgress = LevelProgress(n: row["start"]!["n"]!.int!, c: row["start"]!["c"]!.int!)
            for (k, step) in row["steps"]!.array!.enumerated() {
                let answers = step["correct"]!.array!.map { $0.bool! }
                let unlocked = Progress.recordLevelProgress(&s, count: answers.count, correct: answers.filter { $0 }.count)
                let label = "dizi \(i) adım \(k)"
                XCTAssertEqual(unlocked, step["unlocked"]?.string, label)
                XCTAssertEqual(s.level, step["level"]?.int, label)
                XCTAssertEqual(s.levelProgress.n, step["levelProgress"]?["n"]?.int, label)
                XCTAssertEqual(s.levelProgress.c, step["levelProgress"]?["c"]?.int, label)
            }
        }
    }

    func testSettingsDefaultsAndPartialJSON() throws {
        let s = try JSONDecoder().decode(Settings.self, from: Data(#"{"level":2,"soundFx":false,"notes":["Do","Re","Mi"]}"#.utf8))
        XCTAssertEqual(s.level, 2)
        XCTAssertEqual(s.notes, ["Do", "Re", "Mi"])
        XCTAssertEqual(s.dailyGoal, 10)
        XCTAssertEqual(s.clef, .both)
        XCTAssertTrue(s.soundKeys)
        XCTAssertEqual(s.avatarColor, "violet")
    }
}
