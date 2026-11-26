// Uygulamanın durumu ve akışı (web App.tsx): gezinme, ayarlar, istatistikler, tema, turun soruları, tur sonu ve
// kutlama. Ekranlar bunu okur ve buradaki işlemleri çağırır; kurallar Logic/ altında, kayıt Persistence'ta.
// SwiftUI'den bağımsız: Linux'ta da derlenir ve testlenir (AppModelTests).
import Foundation
import Observation

/// Oyun turu: günün meydan okuması ya da kodla meydan okuma (web GameCtx)
public enum GameContext: Equatable, Sendable {
    case daily(date: String, category: GameCategory, seed: Int, number: Int)
    case challenge(category: GameCategory, level: Int, seed: Int, opponent: Challenge?)

    public var category: GameCategory {
        switch self {
        case let .daily(_, c, _, _), let .challenge(c, _, _, _): c
        }
    }
}

/// Sonuç ekranının bir cevaptan ihtiyacı olan kadarı (web RoundAnswer)
public struct RoundAnswer: Equatable, Sendable {
    public var questionId: Int
    public var correct: Bool
    public var timeMs: Int
    public init(questionId: Int, correct: Bool, timeMs: Int) {
        self.questionId = questionId
        self.correct = correct
        self.timeMs = timeMs
    }
}

@MainActor @Observable
public final class AppModel {
    /// Soru başına süre (zaman yarışı açıkken, web TIMER_SECONDS)
    public static let timerSeconds = 5

    @ObservationIgnored public let persistence: Persistence
    @ObservationIgnored private let random: RandomSource
    @ObservationIgnored private let clock: () -> Now

    public private(set) var nav = ScreenStack()
    public var stats: AppStats { didSet { persistence.save(stats) } }
    public var settings: Settings { didSet { persistence.save(settings) } }
    public var themeMode: ThemeMode { didSet { persistence.save(themeMode) } }

    public var celebrate: Celebration?
    public var showSplash = true
    public var showOnboarding: Bool
    /// Öğren'de açık ders
    public var lessonId = "notes-treble"

    // Tur
    public private(set) var currentCategory: FilterCategory = .all
    /// Son turlar listesindeki özel ad ("Zayıf notalar", "Hataların tekrarı"); nil ise konu adı
    public private(set) var sessionLabel: String?
    public private(set) var sessionQuestions: [Question] = []
    public private(set) var game: GameContext?
    public private(set) var lastResults: [RoundAnswer] = []
    /// Son tur akor turu ya da Ritmi Tut muydu (sonuç başlığı ve "Yeni tur")
    public private(set) var lastSpecial: SpecialRound?
    public private(set) var lastPoints = 0
    public private(set) var lastStars: (stars: Int, best: Int?) = (0, nil)
    /// Her yeni turda artar: soru ekranı sıfırdan kurulsun (aynı ekrandan yeni tura geçişte de)
    public private(set) var quizToken = 0
    /// Her tur bitişinde artar: kutlama yoksa tur sonu sesi çalınır (web `if (!cel) playSessionDone()`)
    public private(set) var roundsCompleted = 0

    public init(
        persistence: Persistence = Persistence(), random: @escaping RandomSource = systemRandom,
        clock: @escaping () -> Now = { Now() }
    ) {
        self.persistence = persistence
        self.random = random
        self.clock = clock
        stats = persistence.loadStats()
        var s = persistence.loadSettings()
        // Profildeki "…'den beri" tarihi: ilk açılışta bir kez
        if s.joinedAt.isEmpty {
            s.joinedAt = clock().todayKey
            persistence.save(s)
        }
        settings = s
        themeMode = persistence.loadTheme()
        showOnboarding = !s.onboarded
        sessionQuestions = Session.questions(.all, settings: s, random: random)
    }

    /// Kuralların "şimdi"si (testlerde ve UI test senaryolarında sabit)
    public var now: Now { clock() }
    /// Bugünün meydan okuması oynandıysa ilk denemenin kaydı
    public var todayDaily: DailyRecord? { persistence.loadDaily()[clock().todayKey] }
    /// Bugünün meydan okuması (konu, tohum, numara)
    public var todayGame: DailyInfo { Games.dailyInfo(clock().todayKey) }
    /// Oyun serisi: art arda oynanan gün
    public var gameStreak: Int { persistence.dailyStreak(now: clock()) }
    /// Yeni meydan okumanın tohumu (web newSeed: Math.random ile; testte tohumlu kaynak)
    public func newGameSeed() -> Int { Int(random() * 65536) }

    /// Ritmi Tut turu: öğrencinin seviyesi, 6 ritim (web pickPatterns: Math.random ile; testte tohumlu kaynak)
    public func newRhythmRound() -> RhythmTapRound { RhythmTapRound(level: settings.level, random: random) }

    /// Akor düellosunun soruları (web buildDuel: Math.random ile; testte tohumlu kaynak)
    public func newDuel(level: Int) -> DuelGame { DuelGame(questions: DuelGame.build(level: level, random: random)) }

    /// Yeni meydan okuma: seçilen konu, öğrencinin seviyesi
    public func startNewChallenge(_ category: GameCategory) {
        startGame(.challenge(category: category, level: settings.level, seed: newGameSeed(), opponent: nil))
    }

    /// Oyun sonucu ekranının içeriği (son oyun turu)
    public var gameResult: GameResultContent? {
        game.map { GameResultContent(ctx: $0, results: lastResults, name: settings.name, dailyStreak: gameStreak) }
    }

    /// Gösterilen seri (bugün ya da dün hedef tamamlanmadıysa 0)
    public var streak: Int { Progress.currentStreak(stats, now: clock()) }
    public var dailySolved: Int { stats.dailyQuestions[clock().todayKey] ?? 0 }

    // MARK: Gezinme
    /// Turlarda kenardan kaydırma: ekranın kendi çıkış onayını açması istenir (sayaç her istekte artar)
    public private(set) var exitRequest = 0
    public func requestExit() { exitRequest += 1 }

    /// Açık turda en az bir cevap verildi mi; tur ekranı bildirir (tur-ekranlari.md). Yeni ekranda sıfırlanır.
    public var roundHasAnswers = false

    /// Turdan çıkış (✕ ya da kenardan kaydırma bırakıldı): cevap verildiyse ekranın onayı istenir (true), yoksa sormadan
    /// önceki ekrana dönülür (false)
    @discardableResult
    public func exitRound() -> Bool {
        if roundHasAnswers {
            requestExit()
            return true
        }
        back()
        return false
    }

    /// Kaydırma hafızası: geri dönülen ekran kalınan yerden açılır (gözlenmez; kaydırırken ekran yeniden çizilmez)
    @ObservationIgnored public let scroll = ScrollMemory()

    public func go(_ v: AppView) {
        roundHasAnswers = false
        scroll.willGo(from: nav.current, to: v)
        nav.go(v)
    }
    public func back() {
        roundHasAnswers = false
        scroll.didBack(to: nav.back())
    }

    /// Açık sekmeye alt menüden tekrar dokunuldu: her istekte artar, o sekmenin sayfası en üste kayar
    public private(set) var scrollTopRequest = 0
    /// Alt menüden sekme seçildi: başka sekmeyse oraya gidilir (yığın sıfırlanır), açık sekmeyse sayfa en üste kayar
    public func selectTab(_ v: AppView) {
        if nav.current == v {
            scrollTopRequest += 1
        } else {
            go(v)
        }
    }

    /// Çalışma'dan bir ders açar; son açılan ders "Kaldığın yer" için bu cihazda hatırlanır (yedeğe girmez)
    public func openLesson(_ id: String) {
        persistence.setLastLesson(id)
        lessonId = id
        go(.lesson)
    }

    /// Çalışma › Kaldığın yer: son açılan ders (bilinmeyen kimlik yok sayılır)
    public var lastLesson: Lesson? { persistence.lastLesson().flatMap(Lessons.byId) }
    /// Bir kaplama (açılış, tanıtım, kutlama) açık mı: kenardan kaydırma çalışmaz
    public var overlayOpen: Bool { celebrate != nil || showOnboarding || showSplash }

    // MARK: Tur başlatma
    public func startQuiz(_ cat: FilterCategory) {
        quizToken += 1
        sessionLabel = nil
        game = nil
        currentCategory = cat
        sessionQuestions = Session.questions(cat, settings: settings, random: random)
        go(.quiz)
    }

    public func startGame(_ ctx: GameContext) {
        quizToken += 1
        let level: Int
        let seed: Int
        switch ctx {
        case let .daily(_, _, s, _):
            level = 2
            seed = s
        case let .challenge(_, l, s, _):
            level = l
            seed = s
        }
        game = ctx
        sessionQuestions = Games.questions(ctx.category, level: level, seed: seed)
        go(.quiz)
    }

    public func startWeakPractice(_ keys: [String]) {
        quizToken += 1
        let qs = Session.weakQuestions(keys, random: random)
        guard !qs.isEmpty else { return }
        sessionLabel = "Zayıf notalar"
        game = nil
        currentCategory = .all
        sessionQuestions = qs
        go(.quiz)
    }

    /// Sonuçta "Yeni tur" / "Tekrar"
    public func retry() {
        quizToken += 1
        roundHasAnswers = false
        if let s = lastSpecial { nav.replace(s == .chords ? .chordquiz : .rhythmtap) } else { startQuiz(currentCategory) }
    }

    /// Sonuçta "Hataları tekrar et": son turda yanlış yapılan sorular, aynı sırayla
    public func retryWrong() {
        quizToken += 1
        let wrong = Set(lastResults.filter { !$0.correct }.map(\.questionId))
        let qs = sessionQuestions.filter { wrong.contains($0.id) }
        guard !qs.isEmpty else { return }
        sessionLabel = "Hataların tekrarı"
        sessionQuestions = qs
        go(.quiz)
    }

    // MARK: Tur sonu
    /// Soru turu bitti (web handleComplete)
    public func completeQuiz(_ results: [SessionResult]) {
        lastResults = results.map { RoundAnswer(questionId: $0.questionId, correct: $0.correct, timeMs: $0.timeMs) }
        lastSpecial = nil
        let now = clock()
        var s = settings
        let out = Progress.completeQuiz(
            stats, settings: &s, results: results, category: currentCategory, label: sessionLabel, game: game?.category, now: now)
        if s != settings { settings = s }
        lastPoints = out.points
        lastStars = (out.stars, out.previousBest)
        celebrate = out.celebration
        stats = out.stats
        roundsCompleted += 1
        if let game {
            if case let .daily(date, _, _, _) = game {
                let sum = Games.summarize(results.map { ($0.correct, $0.timeMs) })
                persistence.saveDaily(DailyRecord(date: date, correct: sum.correct, sec: sum.sec, marks: sum.marks))
            }
            nav.replace(.gameresult)
        } else {
            nav.replace(.result)
        }
        roundHasAnswers = false
    }

    /// Akor turu ya da Ritmi Tut bitti (web handleSpecialComplete)
    public func completeSpecial(_ kind: SpecialRound, answers: [RoundAnswer]) {
        let out = Progress.completeSpecial(stats, settings: settings, kind: kind, answers: answers.map(\.correct), now: clock())
        lastStars = (out.stars, out.previousBest)
        lastResults = answers
        lastPoints = out.points
        lastSpecial = kind
        sessionQuestions = []  // bu turların "hataları tekrar et"i yok
        celebrate = out.celebration
        stats = out.stats
        roundsCompleted += 1
        nav.replace(.result)
        roundHasAnswers = false
    }

    // MARK: Ayarlar
    /// Ayarlar › İlerlemeyi sıfırla
    public func resetProgress() {
        var s = AppStats()
        s.history = []
        s.dailyAccuracy = OrderedMap()
        stats = s
        go(.home)
    }

    /// Ayarlar › Tanıtımı yeniden göster
    public func showTutorial() {
        settings.coachDone = false
        go(.home)
        showOnboarding = true
    }

    /// Tanıtım bitti ya da atlandı: Ana sayfa en üstten açılır (R12). Öğretmen yolunda ("Ben öğretmenim") öğretmen
    /// kodu ekranı açılır; oradan geri dönülünce Profil.
    public func finishOnboarding(openTeacher: Bool = false) {
        settings.onboarded = true
        showOnboarding = false
        go(.home)
        scrollTopRequest += 1
        if openTeacher {
            go(.profile)
            go(.teacher)
        }
    }
}
