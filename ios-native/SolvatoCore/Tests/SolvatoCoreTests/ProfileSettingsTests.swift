// Profil ve Ayarlar yazıları web'deki kurallarla aynı mı.
import XCTest

@testable import SolvatoCore

final class ProfileSettingsTests: XCTestCase {
    func testTexts() {
        var s = Settings()
        s.level = 2
        s.levelProgress = LevelProgress(n: 31, c: 26)
        XCTAssertEqual(SettingsText.levelSub(s), "Sonraki seviyeye: 31/50 soru · %84 doğru")
        s.levelProgress = LevelProgress(n: 0, c: 0)
        XCTAssertEqual(SettingsText.levelSub(s), "Sonraki seviyeye: 0/50 soru")
        s.level = 3
        XCTAssertEqual(SettingsText.levelSub(s), "Tüm sorular açık.")
        XCTAssertEqual(SettingsText.teacherSub(s), "Öğretmeninin gönderdiği kodu gir ya da öğrencine kod hazırla")
        s.reminder = true
        s.reminderHour = 9
        XCTAssertEqual(SettingsText.reminderSub(s), "Her gün 09:00'de")
        XCTAssertEqual(SettingsText.notesSummary(["Do", "Re", "Mi"]), "Nota sorularında yalnızca Do Re Mi çıkar.")
        XCTAssertEqual(SettingsText.toggleNote("Mi", in: ["Do", "Re", "Mi"]), ["Do", "Re", "Mi"], "en az 3")
        XCTAssertEqual(SettingsText.toggleNote("Do", in: ["Re", "Mi", "Sol"]), ["Do", "Re", "Mi", "Sol"], "sıra Do…Si")
    }

    func testProfile() {
        let clock = DayClock(timeZone: TimeZone(identifier: "Europe/Istanbul")!)
        XCTAssertEqual(ProfileText.subtitle(rankLabel: "Porte Gezgini", joinedAt: "2026-11-03", clock: clock), "Porte Gezgini ünvanı · 3 Kasım 2026'den beri")
        XCTAssertEqual(ProfileText.subtitle(rankLabel: "Meraklı", joinedAt: "", clock: clock), "Meraklı ünvanı")
        let ny = DayClock(timeZone: TimeZone(identifier: "America/New_York")!)
        XCTAssertTrue(ProfileText.subtitle(rankLabel: "X", joinedAt: "2026-11-03", clock: ny).contains("2 Kasım"), "web gibi bir gün önce")
        XCTAssertEqual(ProfileText.visibleRanks(1), [0, 1, 2, 3, 14])
        XCTAssertEqual(ProfileText.visibleRanks(5), [3, 4, 5, 6, 7, 14])
        XCTAssertEqual(ProfileText.visibleRanks(14), [12, 13, 14])
    }
}
