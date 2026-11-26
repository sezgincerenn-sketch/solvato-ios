// Uygulama akışı (web App.tsx): tur başlat → bitir → sonuç → geri; hataların tekrarı; oyun turu ve günün meydan okuması
// kaydı; ayarların ve istatistiklerin kaydedilmesi; sıfırlama.
import Foundation
import XCTest

@testable import SolvatoCore

@MainActor
final class AppModelTests: XCTestCase {
    private var dir: URL!
    private var p: Persistence!
    private let clock = DayClock(timeZone: TimeZone(identifier: "Europe/Istanbul")!)

    override func setUp() async throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("solvato-app-\(UUID().uuidString)")
        p = Persistence(store: FileStore(directory: dir))
    }

    override func tearDown() async throws { try? FileManager.default.removeItem(at: dir) }

    private func model() -> AppModel {
        let wed = clock.date(year: 2026, month: 11, day: 18).addingTimeInterval(10 * 3600)
        let c = clock
        return AppModel(persistence: p, random: seededRandom(7), clock: { Now(wed, clock: c) })
    }

    private func answer(_ qs: [Question], correct: (Int) -> Bool) -> [SessionResult] {
        qs.enumerated().map { SessionResult(question: $1, correct: correct($0), timeMs: 2000) }
    }

    func testOpenLessonRemembersLast() async {
        let m = model()
        XCTAssertNil(m.lastLesson)
        m.go(.study)
        m.openLesson("mnemonic-treble")
        XCTAssertEqual(m.nav.current, .lesson)
        XCTAssertEqual(m.lessonId, "mnemonic-treble")
        XCTAssertEqual(model().lastLesson?.title, "Kolay hatırla: Sol anahtarı")
        p.setLastLesson("silinmis-ders")
        XCTAssertNil(model().lastLesson)
    }

    func testFirstLaunch() async {
        let m = model()
        XCTAssertTrue(m.showOnboarding)
        XCTAssertEqual(m.settings.joinedAt, "2026-11-18")
        XCTAssertEqual(p.loadSettings().joinedAt, "2026-11-18", "kaydedildi")
        m.finishOnboarding()
        XCTAssertFalse(model().showOnboarding)
    }

    func testQuizRoundFlow() async {
        let m = model()
        m.go(.dashboard)
        m.startQuiz(.treble)
        XCTAssertEqual(m.nav.current, .quiz)
        XCTAssertEqual(m.sessionQuestions.count, 10)
        XCTAssertTrue(m.sessionQuestions.allSatisfy { $0.clef == .treble })
        let results = answer(m.sessionQuestions) { $0 < 7 }
        m.completeQuiz(results)
        XCTAssertEqual(m.nav.current, .result)
        XCTAssertEqual(m.lastPoints, 70)
        XCTAssertEqual(m.lastStars.stars, 2)
        XCTAssertEqual(m.lastStars.best, 0)
        XCTAssertEqual(m.stats.totalPoints, 70)
        XCTAssertEqual(p.loadStats().totalPoints, 70, "kaydedildi")
        XCTAssertEqual(m.stats.history?.first?.label, "Sol Anahtarı")
        XCTAssertNotNil(m.celebrate, "günlük hedef 10 tamam")
        XCTAssertEqual(m.streak, 1)

        m.retryWrong()
        XCTAssertEqual(m.sessionQuestions.count, 3)
        m.completeQuiz(answer(m.sessionQuestions) { _ in true })
        XCTAssertEqual(m.stats.history?.first?.label, "Hataların tekrarı")
        XCTAssertNil(m.lastStars.best, "hata tekrarında yıldız rekoru yazılmaz")
        m.back()
        XCTAssertEqual(m.nav.current, .dashboard, "Bitir turun başladığı ekrana")
    }

    func testDailyGameSavesFirstAttempt() async {
        let m = model()
        let info = Games.dailyInfo("2026-11-18")
        m.go(.games)
        m.go(.gameDaily)
        m.startGame(.daily(date: info.date, category: info.category, seed: info.seed, number: info.number))
        XCTAssertEqual(m.sessionQuestions.map(\.id), Games.questions(info.category, level: 2, seed: info.seed).map(\.id))
        m.completeQuiz(answer(m.sessionQuestions) { $0 % 2 == 0 })
        XCTAssertEqual(m.nav.current, .gameresult)
        XCTAssertEqual(p.loadDaily()["2026-11-18"]?.correct, 5)
        XCTAssertEqual(m.stats.history?.first?.label, "Oyun · \(info.category.label)")
        XCTAssertEqual(m.todayGame, info)
        XCTAssertEqual(m.todayDaily?.correct, 5)
        XCTAssertEqual(m.gameResult?.title, "Günün meydan okuması #\(info.number)")
        XCTAssertEqual(m.gameResult?.dailyStreak, 1)
        m.back()
        XCTAssertEqual(m.nav.current, .gameDaily)
    }

    func testNewChallengeUsesSettingsLevelAndSeededRandom() async {
        let m = model()
        m.settings.level = 3
        m.startNewChallenge(.rhythm)
        guard case let .challenge(cat, level, seed, opp) = m.game else { return XCTFail() }
        XCTAssertEqual(cat, .rhythm)
        XCTAssertEqual(level, 3)
        XCTAssertNil(opp)
        XCTAssertEqual(m.sessionQuestions.map(\.id), Games.questions(.rhythm, level: 3, seed: seed).map(\.id))
        m.completeQuiz(answer(m.sessionQuestions) { _ in true })
        XCTAssertEqual(m.gameResult?.title, "Meydan okuman hazır")
    }

    func testSpecialRoundAndRetry() async {
        let m = model()
        m.go(.chordquiz)
        m.completeSpecial(.chords, answers: (0..<10).map { RoundAnswer(questionId: $0, correct: $0 < 9, timeMs: 0) })
        XCTAssertEqual(m.nav.current, .result)
        XCTAssertEqual(m.stats.categoryAccuracy.chords, Tally(correct: 9, total: 10))
        XCTAssertEqual(m.lastStars.stars, 3)
        m.retry()
        XCTAssertEqual(m.nav.current, .chordquiz)
    }

    func testResetAndTutorial() async {
        let m = model()
        m.settings.level = 2
        m.startQuiz(.all)
        m.completeQuiz(answer(m.sessionQuestions) { _ in true })
        m.go(.settings)
        m.resetProgress()
        XCTAssertEqual(m.stats.totalPoints, 0)
        XCTAssertEqual(m.settings.level, 2, "seviye kalır")
        XCTAssertEqual(m.nav.current, .home)
        m.showTutorial()
        XCTAssertTrue(m.showOnboarding)
        XCTAssertFalse(p.loadSettings().coachDone)
    }

    /// Alt menü: başka sekme yığını sıfırlar; açık sekmeye tekrar dokunmak gezinmez, en üste kaydırma ister
    func testSelectTab() async {
        let m = model()
        m.go(.games)
        m.selectTab(.profile)
        XCTAssertEqual(m.nav.current, .profile)
        XCTAssertEqual(m.nav.stack, [])
        XCTAssertEqual(m.scrollTopRequest, 0)
        m.selectTab(.profile)
        XCTAssertEqual(m.nav.current, .profile)
        XCTAssertEqual(m.scrollTopRequest, 1)
        m.go(.settings)
        m.selectTab(.study)
        XCTAssertEqual(m.nav.current, .study)
        XCTAssertEqual(m.nav.stack, [])
        XCTAssertEqual(m.scrollTopRequest, 1)
    }
}

@MainActor
final class TestScenarioTests: XCTestCase {
    /// referans.mjs'in yazdığı "pratik" senaryosu: Orta seviye, Deniz, 1.270 XP, 4 günlük seri (dün), bugün 8 soru
    func testPratikScenario() async throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../SolvatoUITests/senaryolar.json")
        let all = try JSON.parse(Data(contentsOf: url))
        let sc = try XCTUnwrap(all["senaryolar"]?["pratik"]?["store"])
        let env = [TestScenario.storeKey: sc.serialized, TestScenario.nowKey: all["simdi"]!.string!]
        let m = try XCTUnwrap(TestScenario(environment: env)).makeModel()
        XCTAssertFalse(m.showOnboarding)
        XCTAssertFalse(m.showSplash)
        XCTAssertEqual(m.settings.name, "Deniz")
        XCTAssertEqual(m.stats.totalPoints, 1270)
        XCTAssertEqual(m.streak, 4)
        XCTAssertEqual(m.dailySolved, 8)
        XCTAssertNil(TestScenario(environment: [:]))
    }
}

/// Turdan çıkış (tur-ekranlari.md): cevap yoksa sormadan geri, varsa ekranın onayı istenir
@MainActor
final class RoundExitTests: XCTestCase {
    func testExitRound() async {
        let m = AppModel(persistence: Persistence(store: MemoryStore()), random: seededRandom(7))
        m.startQuiz(.all)
        XCTAssertFalse(m.exitRound(), "cevap yok")
        XCTAssertEqual(m.nav.current, .home)
        m.startQuiz(.all)
        m.roundHasAnswers = true
        let req = m.exitRequest
        XCTAssertTrue(m.exitRound())
        XCTAssertEqual(m.exitRequest, req + 1, "ekran onay açar")
        XCTAssertEqual(m.nav.current, .quiz)
        m.back()
        XCTAssertFalse(m.roundHasAnswers, "ekrandan çıkınca sıfırlanır")
    }

    func testHasAnswers() async {
        var r = QuizRound(questions: [QuestionBank.byId[1]!, QuestionBank.byId[2]!])
        XCTAssertFalse(r.hasAnswers)
        _ = r.answer("yanlış", timeMs: 300)
        XCTAssertTrue(r.hasAnswers)
        var c = ChordRound(level: 1, random: seededRandom(9))
        XCTAssertFalse(c.hasAnswers)
        c.timeout(timeMs: 15000)
        XCTAssertTrue(c.hasAnswers, "süresi dolan da sayılır")
        XCTAssertFalse(RhythmTapRound(level: 1, random: seededRandom(2)).hasAnswers)
        var g = DuelGame(questions: DuelGame.build(level: 1, random: seededRandom(4)))
        XCTAssertFalse(g.hasAnswers)
        _ = g.pick(0, "yanlış")
        XCTAssertTrue(g.hasAnswers)
    }
}
