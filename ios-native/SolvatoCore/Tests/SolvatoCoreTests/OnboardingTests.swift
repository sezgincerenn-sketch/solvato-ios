// Tanıtım (docs/ozellikler/tanitim.md): adım sırası, öğretmen yolu, geri; öğretmen kodu ekranının role göre bölümü;
// hatırlatma saati alt yazısı ve reminderMinute varsayılanı.
import Foundation
import XCTest

@testable import SolvatoCore

@MainActor
final class OnboardingTests: XCTestCase {
    /// Öğrenci ve "kendi kendime": bütün adımlar sırayla; öğretmen: sorudan sonra biter
    func testStepOrder() async {
        func walk(_ role: TeacherRole) -> [OnboardingStep] {
            var out: [OnboardingStep] = [.intro]
            while let n = OnboardingFlow.next(after: out.last!, role: role) { out.append(n) }
            return out
        }
        XCTAssertEqual(walk(.student), [.intro, .hello, .try1, .try2, .teacher, .clef, .level, .reminder, .done])
        XCTAssertEqual(walk(.solo), OnboardingStep.allCases)
        XCTAssertEqual(walk(.teacher), [.intro, .hello, .try1, .try2, .teacher])
        XCTAssertNil(OnboardingFlow.next(after: .done, role: .student))
    }

    func testBack() async {
        XCTAssertEqual(OnboardingFlow.back(from: .hello), .intro)
        XCTAssertEqual(OnboardingFlow.back(from: .clef), .teacher)
        XCTAssertEqual(OnboardingFlow.back(from: .intro), .intro)
        XCTAssertFalse(OnboardingFlow.showsBack(.intro))
        XCTAssertTrue(OnboardingFlow.showsBack(.hello))
        XCTAssertTrue(OnboardingFlow.showsBack(.done))
    }

    /// Soru ilk kez: "Evet, öğretmenim var" işaretli; tekrar gösterilince önceki seçim
    func testInitialRole() async {
        var s = Settings()
        XCTAssertEqual(OnboardingFlow.initialRole(s), .student)
        s.teacherRole = .teacher
        XCTAssertEqual(OnboardingFlow.initialRole(s), .teacher)
        XCTAssertEqual(OnboardingFlow.roles.map(\.role), [.student, .solo, .teacher])
    }

    /// Öğretmen kodu ekranı: rol → başlık, bölüm, açıklama, geçiş bağlantısı
    func testTeacherSection() async {
        let enter = TeacherSection(.student)
        XCTAssertEqual(enter, .enter)
        XCTAssertEqual(enter.title, "Öğretmen kodunu gir")
        XCTAssertTrue(enter.showsEnter)
        XCTAssertFalse(enter.showsPrepare)
        XCTAssertEqual(enter.switchLink?.text, "Öğretmen misin? Öğrencin için kod hazırla")
        XCTAssertEqual(enter.switchLink?.role, .teacher)

        let prep = TeacherSection(.teacher)
        XCTAssertEqual(prep.title, "Öğrenci kodu hazırla")
        XCTAssertFalse(prep.showsEnter)
        XCTAssertTrue(prep.showsPrepare)
        XCTAssertEqual(prep.intro, "Öğrencin için konu, seviye, hedef ve notaları seç; kodu WhatsApp ya da mesajla gönder.")
        XCTAssertEqual(prep.switchLink?.text, "Öğrenci misin? Öğretmeninin kodunu gir")
        XCTAssertEqual(prep.switchLink?.role, .student)

        for r in [TeacherRole.solo, .unset] {
            let both = TeacherSection(r)
            XCTAssertEqual(both, .both)
            XCTAssertEqual(both.title, "Öğretmen kodu")
            XCTAssertTrue(both.showsEnter && both.showsPrepare)
            XCTAssertNil(both.switchLink)
            XCTAssertEqual(both.intro, enter.intro)
        }

        // Başlık Profil'deki kartla aynı (kod uygulanmamışken)
        var s = Settings()
        for r in TeacherRole.allCases {
            s.teacherRole = r
            XCTAssertEqual(TeacherSection(r).title, ProfileText.teacherCard(s).title)
        }
    }

    func testReminderText() async {
        var s = Settings()
        XCTAssertEqual(s.reminderMinute, 0)
        XCTAssertNil(SettingsText.reminderSub(s))
        s.reminder = true
        s.reminderHour = 7
        s.reminderMinute = 45
        XCTAssertEqual(SettingsText.reminderSub(s), "Her gün 07:45'te")
        let cases: [(Int, Int, String)] = [
            (19, 30, "19:30'da"), (19, 0, "19:00'da"), (20, 0, "20:00'de"), (9, 5, "09:05'te"), (0, 0, "00:00'da"),
            (13, 0, "13:00'te"), (21, 40, "21:40'ta"), (18, 50, "18:50'de"), (10, 0, "10:00'da"), (16, 0, "16:00'da"),
            (12, 0, "12:00'de"), (8, 1, "08:01'de"),
        ]
        for (h, m, t) in cases { XCTAssertEqual(SettingsText.timeText(hour: h, minute: m), t) }
    }

    /// Eski kayıtta reminderMinute yok: 0; yazılınca aynı adla saklanır
    func testReminderMinuteStorage() async throws {
        let old = try JSONDecoder().decode(Settings.self, from: Data(#"{"reminder":true,"reminderHour":18}"#.utf8))
        XCTAssertEqual(old.reminderMinute, 0)
        XCTAssertEqual(old.reminderHour, 18)
        var s = Settings()
        s.reminderMinute = 45
        let json = String(decoding: try JSONEncoder().encode(s), as: UTF8.self)
        XCTAssertTrue(json.contains(#""reminderMinute":45"#), json)
    }

    /// Tanıtım bitince Ana sayfa en üstte; öğretmen yolunda öğretmen kodu ekranı, geri → Profil
    func testFinish() async {
        let m = AppModel(persistence: Persistence(store: MemoryStore()))
        m.go(.settings)
        m.showTutorial()
        let top = m.scrollTopRequest
        m.finishOnboarding()
        XCTAssertFalse(m.showOnboarding)
        XCTAssertTrue(m.settings.onboarded)
        XCTAssertEqual(m.nav.current, .home)
        XCTAssertEqual(m.scrollTopRequest, top + 1, "Ana sayfa en üste")

        m.showTutorial()
        m.settings.teacherRole = .teacher
        m.finishOnboarding(openTeacher: true)
        XCTAssertEqual(m.nav.current, .teacher)
        m.back()
        XCTAssertEqual(m.nav.current, .profile)
    }
}
