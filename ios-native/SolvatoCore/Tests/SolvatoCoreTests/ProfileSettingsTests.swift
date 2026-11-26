// Profil ve Ayarlar yazıları web'deki kurallarla aynı mı.
import Foundation
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
        s.reminder = true
        s.reminderHour = 9
        XCTAssertEqual(SettingsText.reminderSub(s), "Her gün 09:00'da")
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

    /// Öğretmen kodu kartı (gezinme.md): üç tanıtım seçimi + kodlu durum
    func testTeacherCard() {
        var s = Settings()
        let solo = ProfileText.teacherCard(s)
        XCTAssertEqual([solo.title, solo.sub], ["Öğretmen kodu", "Öğretmeninin kodunu gir ya da öğrencine kod hazırla"])
        XCTAssertFalse(solo.highlight)
        s.teacherRole = .solo
        XCTAssertEqual(ProfileText.teacherCard(s), solo, "kendi kendime = atlandı")
        s.teacherRole = .student
        let st = ProfileText.teacherCard(s)
        XCTAssertEqual([st.title, st.sub], ["Öğretmen kodunu gir", "Öğretmeninin gönderdiği kodu yaz"])
        XCTAssertTrue(st.highlight)
        s.teacherRole = .teacher
        let te = ProfileText.teacherCard(s)
        XCTAssertEqual([te.title, te.sub], ["Öğrenci kodu hazırla", "Öğrencilerine konu, seviye ve hedef gönder"])
        XCTAssertTrue(te.highlight)
        s.teacherCode = "K7M-2QX"
        let ap = ProfileText.teacherCard(s)
        XCTAssertEqual([ap.title, ap.sub], ["Öğretmen kodu", "Uygulandı · K7M-2QX"])
        XCTAssertTrue(ap.applied)
        XCTAssertFalse(ap.highlight, "kod varken öne çıkmaz")
        XCTAssertEqual([false, true].map(ProfileText.showRestLabel), ["Diğer konuları da göster", "Diğer konular açık ✓"])
    }

    /// "Kodu kaldır": yalnız konu seçimi kalkar; seviye, hedef, notalar, anahtar kalır
    func testRemoveTeacherCode() throws {
        var s = Settings()
        s.teacherCode = "K7M-2QX"
        s.topics = ["treble", "rhythm"]
        s.showRestTopics = true
        s.level = 2
        s.dailyGoal = 30
        s.notes = ["Do", "Re", "Mi"]
        s.clef = .treble
        var before = s
        s.removeTeacherCode()
        XCTAssertEqual([s.teacherCode], [""])
        XCTAssertEqual(s.topics, [])
        XCTAssertFalse(s.showRestTopics)
        before.teacherCode = ""
        before.topics = []
        before.showRestTopics = false
        XCTAssertEqual(s, before, "başka hiçbir ayar değişmez")
        let home = HomeContent(stats: AppStats(), settings: s, daily: nil, now: Now())
        XCTAssertEqual(home.sectionTitle, "Pratik Kategorileri")
        XCTAssertEqual(home.groups.count, 1, "Diğer konular grubu yok")
    }

    /// Yeni ayarlar eski kayıtlarda yoksa varsayılan; kaydedilip geri okunur
    func testNewSettingsDefaultsAndRoundTrip() throws {
        let old = try JSONDecoder().decode(Settings.self, from: Data(#"{"level":2,"teacherCode":"K7M-2QX"}"#.utf8))
        XCTAssertFalse(old.showRestTopics)
        XCTAssertEqual(old.teacherRole, .unset)
        let bad = try JSONDecoder().decode(Settings.self, from: Data(#"{"teacherRole":"mavi","showRestTopics":"evet"}"#.utf8))
        XCTAssertEqual(bad.teacherRole, .unset)
        XCTAssertFalse(bad.showRestTopics)
        var s = Settings()
        s.showRestTopics = true
        s.teacherRole = .solo
        let json = String(decoding: try JSONEncoder().encode(s), as: UTF8.self)
        XCTAssertTrue(json.contains(#""teacherRole":"self""#), json)
        XCTAssertEqual(try JSONDecoder().decode(Settings.self, from: Data(json.utf8)), s)
    }
}

/// Ayarlar düzeni (ayarlar.md): satır değerleri ve seviye kuralı
final class SettingsRowsTests: XCTestCase {
    func testValues() {
        XCTAssertEqual(SettingsText.goalValue(20), "20 soru")
        XCTAssertEqual(SettingsText.goalOptions.map(\.value), [10, 20, 30, 50])
        XCTAssertEqual(SettingsText.goalOptions.map(\.sub), ["rahat tempo", "düzenli çalışma", "hızlı ilerleme", "yoğun tempo"])
        XCTAssertEqual([1, 2, 3].map(SettingsText.levelValue), ["Başlangıç", "Orta", "İleri"])
        XCTAssertEqual(ClefChoice.allCases.map(SettingsText.clefValue), ["Sol", "Fa", "İkisi de"])
        XCTAssertEqual([InputMode.piano, .choice].map(SettingsText.inputValue), ["Klavye", "Şıklar"])
        XCTAssertEqual(ThemeMode.allCases.map(SettingsText.themeValue), ["Sistem", "Koyu", "Açık"])
        XCTAssertEqual(SettingsText.notesValue(allNotes), "Hepsi")
        XCTAssertEqual(SettingsText.notesValue(["Sol", "Do", "Mi", "Re"]), "Do Re Mi Sol", "sıra Do…Si")
    }

    func testSetLevel() {
        var s = Settings()
        s.level = 2
        s.levelProgress = LevelProgress(n: 12, c: 9)
        SettingsText.setLevel(2, in: &s)
        XCTAssertEqual(s.levelProgress, LevelProgress(n: 12, c: 9), "aynı seviye: sayaç kalır")
        SettingsText.setLevel(3, in: &s)
        XCTAssertEqual(s.level, 3)
        XCTAssertEqual(s.levelProgress, LevelProgress(n: 0, c: 0))
    }
}
