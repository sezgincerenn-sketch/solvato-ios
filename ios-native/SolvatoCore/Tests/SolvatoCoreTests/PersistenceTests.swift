// Kalıcı depolama (G-09): web'le aynı anahtar ve biçim, bozuk kayıtta varsayılan, ilk deneme kuralı, sıfırlama,
// yedeğe girmeyen son ders. React'ın yazdığı istatistik JSON'u okunup yazılınca aynı kalır (sözlüklerin ekleme sırası dahil).
import Foundation
import XCTest

@testable import SolvatoCore

final class PersistenceTests: XCTestCase {
    private var dir: URL!
    private var p: Persistence!

    override func setUp() {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("solvato-test-\(UUID().uuidString)")
        p = Persistence(store: FileStore(directory: dir))
    }

    override func tearDown() { try? FileManager.default.removeItem(at: dir) }

    func testEmptyStoreGivesDefaults() {
        XCTAssertEqual(p.loadSettings(), Settings())
        XCTAssertEqual(p.loadStats(), AppStats())
        XCTAssertEqual(p.loadTheme(), .system)
        XCTAssertEqual(p.loadDaily(), [:])
        XCTAssertEqual(p.rotateHintCount(), 0)
        XCTAssertNil(p.lastLesson())
    }

    func testFileNamesAreWebKeys() {
        p.save(Settings())
        p.save(AppStats())
        p.save(ThemeMode.dark)
        p.saveDaily(DailyRecord(date: "2026-11-18", correct: 7, sec: 42, marks: "🟩🟥"))
        p.bumpRotateHint()
        p.setLastLesson("notes-1")
        let names = Set((try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? [])
        XCTAssertEqual(
            names, ["pianote_settings_v1", "notausta_stats_v1", "pianote_theme_v1", "notalik-daily", "notalik_rotate_hint_v1", "NoBackup"])
        XCTAssertEqual(try? FileManager.default.contentsOfDirectory(atPath: dir.appendingPathComponent("NoBackup").path), ["solvato_last_lesson_v1"])
        XCTAssertEqual(p.store.read("pianote_theme_v1"), "dark")
        XCTAssertEqual(p.store.read("notalik_rotate_hint_v1"), "1")
        XCTAssertEqual(p.store.read("solvato_last_lesson_v1"), "notes-1")
        #if canImport(Darwin)
            let v = try? dir.appendingPathComponent("NoBackup").resourceValues(forKeys: [.isExcludedFromBackupKey])
            XCTAssertEqual(v?.isExcludedFromBackup, true)
        #endif
    }

    /// React'ın yazdığı istatistikler (altın tablodan) okunup yazılınca aynı JSON (sözlüklerin ekleme sırası dahil)
    func testWebStatsRoundTrip() throws {
        var n = 0
        for sc in try XCTUnwrap(Golden.load("seri-Europe-Istanbul")["scenarios"]?.array) {
            for step in sc["steps"]!.array! {
                guard let web = step["stats"] else { continue }
                p.store.write(AppStats.storageKey, web.serialized)
                let loaded = p.loadStats()
                p.save(loaded)
                let saved = try XCTUnwrap(p.store.read(AppStats.storageKey).flatMap { try? JSON.parse($0) })
                XCTAssertNil(Golden.diff(saved, web))
                // Ekranda sırası görünen sözlükler aynı sırada (üst düzey alanların sırası bir şey değiştirmez)
                for k in ["dailyLog", "dailyQuestions", "noteStats", "dailyAccuracy", "bestStars", "dailyTopics"] {
                    XCTAssertEqual(saved[k]?.object?.keys, web[k]?.object?.keys, k)
                }
                for d in web["dailyTopics"]?.object?.keys ?? [] {
                    XCTAssertEqual(saved["dailyTopics"]?[d]?.object?.keys, web["dailyTopics"]?[d]?.object?.keys, d)
                }
                n += 1
            }
        }
        XCTAssertGreaterThan(n, 50)
    }

    func testBrokenOrPartialData() {
        p.store.write(Settings.storageKey, "{bozuk")
        XCTAssertEqual(p.loadSettings(), Settings())
        p.store.write(Settings.storageKey, #"{"level":3,"dailyGoal":30,"teacherCode":"K7M-2QX","sound":true}"#)
        let s = p.loadSettings()
        XCTAssertEqual([s.level, s.dailyGoal], [3, 30])
        XCTAssertEqual(s.teacherCode, "K7M-2QX")
        XCTAssertEqual(s.notes, allNotes)
        p.store.write(AppStats.storageKey, "null")
        XCTAssertEqual(p.loadStats(), AppStats())
        p.store.write(AppStats.storageKey, #"{"totalPoints":120,"categoryAccuracy":{"treble":{"correct":3,"total":4}}}"#)
        let st = p.loadStats()
        XCTAssertEqual(st.totalPoints, 120)
        XCTAssertEqual(st.categoryAccuracy.treble, Tally(correct: 3, total: 4))
        XCTAssertEqual(st.categoryAccuracy.ear, .zero)
        p.store.write(ThemeMode.storageKey, "mavi")
        XCTAssertEqual(p.loadTheme(), .system)
        p.store.write(Persistence.rotateHintKey, "abc")
        XCTAssertEqual(p.rotateHintCount(), 0)
    }

    func testSettingsRoundTrip() {
        var s = Settings()
        s.level = 2
        s.notes = ["Do", "Mi", "Sol"]
        s.clef = .bass
        s.name = "Ada"
        s.topics = ["rhythm", "ear"]
        s.levelProgress = LevelProgress(n: 23, c: 19)
        p.save(s)
        XCTAssertEqual(p.loadSettings(), s)
    }

    func testDailyFirstAttemptOnlyAndStreak() {
        p.saveDaily(DailyRecord(date: "2026-11-17", correct: 5, sec: 60, marks: "🟩"))
        p.saveDaily(DailyRecord(date: "2026-11-18", correct: 7, sec: 42, marks: "🟩🟥"))
        p.saveDaily(DailyRecord(date: "2026-11-18", correct: 10, sec: 30, marks: "🟩🟩"))
        XCTAssertEqual(p.loadDaily()["2026-11-18"]?.correct, 7, "yalnız ilk deneme")
        XCTAssertEqual(p.store.read(Games.dailyStorageKey).flatMap { try? JSON.parse($0) }?.object?.keys, ["2026-11-17", "2026-11-18"])
        let clock = DayClock(timeZone: TimeZone(identifier: "Europe/Istanbul")!)
        let wed = clock.date(year: 2026, month: 11, day: 18).addingTimeInterval(10 * 3600)
        XCTAssertEqual(p.dailyStreak(now: Now(wed, clock: clock)), 2)
        XCTAssertEqual(p.dailyStreak(now: Now(wed.addingTimeInterval(86400), clock: clock)), 2, "bugün oynanmadıysa dünden")
        XCTAssertEqual(p.dailyStreak(now: Now(wed.addingTimeInterval(2 * 86400), clock: clock)), 0)
    }

    func testResetKeepsSettingsAndDaily() {
        var s = Settings()
        s.level = 3
        p.save(s)
        var st = AppStats()
        st.totalPoints = 500
        st.bestStars = OrderedMap([("treble", 3)])
        p.save(st)
        p.saveDaily(DailyRecord(date: "2026-11-18", correct: 7, sec: 42, marks: ""))
        p.resetProgress()
        XCTAssertEqual(p.loadStats().totalPoints, 0)
        XCTAssertNil(p.loadStats().bestStars)
        XCTAssertEqual(p.loadStats().history, [])
        XCTAssertEqual(p.loadSettings().level, 3)
        XCTAssertEqual(p.loadDaily().count, 1)
    }

    func testRotateHint() {
        p.bumpRotateHint()
        p.bumpRotateHint()
        XCTAssertEqual(p.rotateHintCount(), 2)
        p.bumpRotateHint(done: true)
        XCTAssertEqual(p.rotateHintCount(), 99)
    }
}
