// Öğretmen kodu ekranının kuralları (web TeacherScreen.tsx) ve Gizlilik/Lisanslar metinlerinin pakette olduğu.
import XCTest

@testable import SolvatoCore

final class TeacherLegalTests: XCTestCase {
    func testSanitize() {
        XCTAssertEqual(TeacherFlow.sanitize("abc-defgh"), "ABC-DEF")
        XCTAssertEqual(TeacherFlow.sanitize("k7m"), "K7M")
        // R31: tire kendiliğinden
        XCTAssertEqual(TeacherFlow.sanitize("k7m2"), "K7M-2")
        XCTAssertEqual(TeacherFlow.sanitize("K7M2QX"), "K7M-2QX")
        XCTAssertEqual(TeacherFlow.sanitize("K7M-"), "K7M")
        XCTAssertEqual(TeacherFlow.sanitize("ç7m 2qx!"), "7M2-QX")
    }

    /// R30: paylaşım mesajında kod en üstte; mesajın tamamı yapıştırılsa da kod bulunur
    func testShareAndPaste() {
        let setup = TeacherSetup(notes: ["Do", "Re", "Mi"], clef: .bass, level: 2, dailyGoal: 30, keyLabels: true, topics: ["rhythm"])
        let code = TeacherCode.encode(setup)
        let text = TeacherCode.shareText(code: code, setup)
        XCTAssertEqual(text.components(separatedBy: "\n").first, code)
        XCTAssertTrue(text.hasSuffix("Solfado'da Profil › Öğretmen kodu bölümüne bu kodu yapıştır."))
        XCTAssertEqual(TeacherFlow.pasted(text), code)
        XCTAssertEqual(TeacherFlow.pasted(code.lowercased()), code)
        XCTAssertEqual(TeacherFlow.pasted("🎹 Solvato · Öğretmen kodu\nKod: \(code)\n"), code, "eski mesaj biçimi")
        XCTAssertEqual(TeacherFlow.pasted("k7m2"), "K7M-2", "kod bulunmazsa metnin başı")
    }

    func testInitialSetupGoalFallback() {
        var s = Settings()
        s.dailyGoal = 15
        XCTAssertEqual(TeacherFlow.initialSetup(s).dailyGoal, 10)
        s.dailyGoal = 30
        XCTAssertEqual(TeacherFlow.initialSetup(s).dailyGoal, 30)
    }

    func testApply() {
        var s = Settings()
        s.level = 1
        s.levelProgress = LevelProgress(n: 8, c: 7)
        let setup = TeacherSetup(notes: ["Do", "Re", "Mi"], clef: .bass, level: 2, dailyGoal: 30, keyLabels: true, topics: ["rhythm"])
        let code = TeacherCode.encode(setup)
        // Küçük harf ve tiresiz yazılsa da uygulanır, kayıtlı kod temiz biçimdedir
        let r = TeacherFlow.apply(code.lowercased().replacingOccurrences(of: "-", with: ""), to: &s)
        XCTAssertEqual(r?.code, code)
        XCTAssertEqual(r?.setup, setup)
        XCTAssertEqual(s.teacherCode, code)
        XCTAssertEqual(s.notes, ["Do", "Re", "Mi"])
        XCTAssertEqual(s.clef, .bass)
        XCTAssertEqual(s.level, 2)
        XCTAssertEqual(s.dailyGoal, 30)
        XCTAssertTrue(s.keyLabels)
        XCTAssertEqual(s.topics, ["rhythm"])
        XCTAssertEqual(s.levelProgress, LevelProgress(n: 0, c: 0))

        // Seviye aynıysa ilerleme korunur
        s.levelProgress = LevelProgress(n: 3, c: 2)
        _ = TeacherFlow.apply(code, to: &s)
        XCTAssertEqual(s.levelProgress, LevelProgress(n: 3, c: 2))

        let before = s
        XCTAssertNil(TeacherFlow.apply("ZZZ-ZZZ", to: &s))
        XCTAssertEqual(s, before)
    }

    func testToggleTopic() {
        let keys = TeacherCode.topics.map(\.key)
        // Hepsi → birine dokun → yalnız o
        XCTAssertEqual(TeacherFlow.toggleTopic(keys[2], in: []), [keys[2]])
        // Sıra listedeki sıradır
        XCTAssertEqual(TeacherFlow.toggleTopic(keys[0], in: [keys[2]]), [keys[0], keys[2]])
        // Sonuncuyu kaldırınca Hepsi
        XCTAssertEqual(TeacherFlow.toggleTopic(keys[2], in: [keys[2]]), [])
        XCTAssertTrue(TeacherFlow.topicSelected(keys[2], in: [keys[2]]))
        XCTAssertFalse(TeacherFlow.topicSelected(keys[2], in: []))
        XCTAssertFalse(TeacherFlow.topicSelected(keys[2], in: keys))
    }

    func testLegalTexts() {
        XCTAssertEqual(Legal.privacy.map(\.title), ["Özet", "Cihazında tutulan bilgiler", "İzinler", "Paylaşım", "Çocuklar", "KVKK", "Değişiklikler"])
        XCTAssertEqual(Legal.licenses.map(\.name), ["Bravura", "Outfit", "JetBrains Mono"])
        XCTAssertTrue(Legal.licenses.allSatisfy { ($0.text ?? "").count > 500 })
    }
}

/// Ayarlar › Yardım ve destek (kullanici-testi-revize.md madde 10): sorular ve cevaplardaki kurallar uygulamayla aynı
final class HelpContentTests: XCTestCase {
    func testItems() {
        XCTAssertEqual(AppView.help.title, "Yardım ve destek")
        XCTAssertTrue(AppView.help.swipesBack)
        XCTAssertFalse(AppView.help.countsStudyTime)
        XCTAssertEqual(
            HelpContent.items.map(\.question),
            [
                "Günlük hedef ve seri nasıl işler?", "Seviyem nasıl yükselir?", "Öğretmen kodu nedir, nasıl kullanılır?",
                "Haftalık raporu öğretmenime nasıl gönderirim?", "Ses gelmiyor, ne yapmalıyım?", "Verilerim nerede, silinir mi?",
            ])
        XCTAssertTrue(HelpContent.items[1].answer.contains("son 50 sorunun en az %80'ini"))
        XCTAssertEqual(AccessibilityText.disclosure(expanded: true), "genişletilmiş")
        XCTAssertEqual(AccessibilityText.disclosure(expanded: false), "daraltılmış")
    }
}

/// "Bize yaz": adres, konu ve gövdedeki sürüm satırı
final class SupportMailTests: XCTestCase {
    func testMail() {
        XCTAssertEqual(HelpContent.supportEmail, "solfado.destek@gmail.com")
        XCTAssertEqual(HelpContent.mailSubject, "Solfado destek")
        XCTAssertEqual(HelpContent.copied, "E-posta adresi kopyalandı")
        XCTAssertEqual(
            HelpContent.mailBody(version: "1.0", build: "2017", system: "26.1", device: "iPhone"),
            "\n\n\n—\nSolfado 1.0 (2017) · iPhone · iOS 26.1")
    }
}
