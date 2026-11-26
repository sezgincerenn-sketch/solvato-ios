// Tur sonucu ve kutlama yazıları web ResultScreen / RankCard / Celebration ile aynı mı (E-08, E-09, K-09, K-10).
import XCTest

@testable import SolvatoCore

final class ResultContentTests: XCTestCase {
    private func answers(_ c: [Bool], ms: Int = 2400) -> [RoundAnswer] {
        c.enumerated().map { RoundAnswer(questionId: QuestionBank.all[$0.offset].id, correct: $0.element, timeMs: ms) }
    }

    func testTrNumber() {
        XCTAssertEqual(trNumber(2.4), "2,4")
        XCTAssertEqual(trNumber(2), "2")
        XCTAssertEqual(trNumber(12.5), "12,5")
        XCTAssertEqual(trNumber(1234.5), "1.234,5")
        XCTAssertEqual(trNumber(22000), "22.000")
        XCTAssertEqual(trNumber(0), "0")
    }

    func testQuizResult() {
        let a = answers([true, true, true, true, true, true, true, false, false, false], ms: 2440)
        let r = ResultContent(answers: a, key: "treble", points: 70, stars: 2, previousBest: 1, totalXp: 1340, questions: QuestionBank.all)
        XCTAssertEqual(r.title, "Tur bitti · Çok iyi!")
        XCTAssertEqual(r.categoryLabel, "Sol Anahtarı Pratiği")
        XCTAssertTrue(r.newBest)
        XCTAssertEqual(r.solfieText, "Bu konuda yeni rekor!")
        XCTAssertEqual(r.pct, 70)
        XCTAssertEqual(r.timeValue, "2,4 sn")
        XCTAssertEqual(r.timeLabel, "Ort. Süre")
        XCTAssertEqual(r.primaryTitle, "Hatalarını tekrar et · 3 soru")
        XCTAssertEqual(r.rank.label, "Porte Gezgini")
        XCTAssertEqual(r.rankNote, "Bu turda +70 XP. Ritim Tutan ünvanına 160 XP kaldı.")
    }

    func testSpecialAndPerfect() {
        let chords = ResultContent(
            answers: answers(Array(repeating: true, count: 10), ms: 0), key: "chords", points: 100, stars: 3, previousBest: 3,
            totalXp: 23000, questions: [])
        XCTAssertEqual(chords.title, "Tur bitti · Harika iş!")
        XCTAssertFalse(chords.newBest)
        XCTAssertEqual(chords.solfieText, "Tam puan: 3 yıldız")
        XCTAssertEqual(chords.primaryTitle, "Yeni tur")
        XCTAssertEqual(chords.rankNote, "Bu turda +100 XP. En üst ünvandasın.")
        let tap = ResultContent(
            answers: answers([true, false, false, false, true, false], ms: 38), key: "rhythmtap", points: 20, stars: 0, previousBest: nil,
            totalXp: 50, questions: [])
        XCTAssertEqual(tap.title, "Tur bitti · Tekrarla, oturacak")
        XCTAssertEqual(tap.solfieText, "1. yıldız için %50 doğru yap")
        XCTAssertEqual(tap.timeValue, "38 ms")
        XCTAssertEqual(tap.timeLabel, "Ort. Sapma")
        XCTAssertEqual(tap.primaryTitle, "Yeni tur", "akor ve Ritmi Tut'ta hata tekrarı yok")
    }

    func testCelebrationRowsOrder() {
        var c = Celebration()
        c.rankUp = .init(rank: 5, label: "Porte Gezgini", nextLabel: "Ritim Tutan")
        c.unlocked = "Orta"
        c.goalDone = true
        c.streak = 1
        XCTAssertEqual(c.rows.map(\.title), ["Yeni ünvan: Porte Gezgini", "Yeni seviye: Orta", "Günlük hedef tamam", "1 günlük seri"])
        XCTAssertEqual(c.rows.map(\.sub), ["5. ünvan · sırada Ritim Tutan", "Turlarda artık yeni sorular da var", "Bugünkü çalışmanı bitirdin", "Yeni bir seri başladı"])
        XCTAssertFalse(c.rows[2].filled)
        c.streak = 4
        XCTAssertEqual(c.rows.last?.sub, "Devam, bozma!")
    }

    /// R8: hatırlatma kapalı, seri 1 ve daha önce sorulmadıysa bir kez
    func testReminderOffer() throws {
        var s = Settings()
        XCTAssertTrue(ReminderOffer.shouldOffer(s, streak: 1))
        XCTAssertFalse(ReminderOffer.shouldOffer(s, streak: 0))
        XCTAssertFalse(ReminderOffer.shouldOffer(s, streak: 2), "yalnız ilk seri günü")
        s.reminderOffered = true
        XCTAssertFalse(ReminderOffer.shouldOffer(s, streak: 1), "bir kez")
        s.reminderOffered = false
        s.reminder = true
        XCTAssertFalse(ReminderOffer.shouldOffer(s, streak: 1), "hatırlatma açıksa yok")
        // Eski kayıtta alan yok: gösterilmemiş sayılır; kaydedilip geri okunur
        let old = try JSONDecoder().decode(Settings.self, from: Data(#"{"reminder":false}"#.utf8))
        XCTAssertFalse(old.reminderOffered)
        var n = Settings()
        n.reminderOffered = true
        XCTAssertTrue(try JSONDecoder().decode(Settings.self, from: JSONEncoder().encode(n)).reminderOffered)
    }
}
