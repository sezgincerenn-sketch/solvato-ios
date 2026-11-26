// Uygulama kabuğu: ekranlar arası gezinme, tema, istatistiklerin güncellenmesi, kaydırarak geri.
import TeacherScreen from "./screens/TeacherScreen"
import { Coachmark, TabTitle, TabletColumn, type CoachStep } from "./ui"
import ProfileScreen from "./screens/profile/ProfileScreen"
import { useState, useEffect, useLayoutEffect, useCallback, useSyncExternalStore, useRef } from "react"
import { forgetScroll, restoreScroll, saveScroll } from "./utils/scrollMemory"
import type { FilterCategory, SessionResult, AppStats, RoundAnswer, SpecialRound } from "./types"
import { DEFAULT_STATS } from "./types"
import QuizSession from "./screens/QuizSession"
import ChordQuizSession from "./screens/ChordQuizSession"
import RhythmTapSession from "./screens/RhythmTapSession"
import ChordDuel from "./screens/ChordDuel"
import { useSwipeBack, visibleBack } from "./utils/swipeBack"
import GamesScreen, { ChallengeGameScreen, DailyGameScreen } from "./screens/GamesScreen"
import GameResultScreen from "./screens/GameResultScreen"
import type { GameCtx } from "./screens/gameShared"
import { catLabel, buildGameQuestions, newSeed, saveDaily, summarize, type GameCat } from "./utils/games"
import { allowLandscape, useLandscape, useTablet } from "./utils/orientation"
import ProgressScreen from "./screens/ProgressScreen"
import StudyScreen from "./screens/study/StudyScreen"
import LessonScreen from "./screens/study/LessonScreen"
import { playSessionDone } from "./utils/audio"
import Celebration, { type CelebrationData } from "./components/Celebration"
import SettingsScreen, { NotesSettings } from "./screens/SettingsScreen"
import LegalScreen from "./screens/LegalScreen"
import Onboarding from "./screens/Onboarding"
import Splash from "./screens/Splash"
import { getSettings, updateSettings, subscribeSettings } from "./utils/settings"
import { todayKey } from "./utils/level"

import { shadow, colors, palette } from "./design/tokens"
import NavBar from "./ui/NavBar"
import HomeScreen from "./screens/HomeScreen"
import ResultScreen from "./screens/ResultScreen"
import {
  loadStats,
  saveStats,
  currentStreak,
  applyProgress,
  detectCelebration,
  recordLevelProgress,
  recordStars,
  recordTopics,
  topicOf,
} from "./state/stats"
import { starsFor } from "./utils/stars"
import { applyStatusBar, THEME_KEY, loadThemeMode, systemTheme, type ThemeMode } from "./state/theme"
import { ROUND_LABELS, getQuestions, getWeakQuestions } from "./data/session"
import type { NavTab, View, Theme } from "./types"

const TIMER_SECONDS = 5

// ─── Home screen ───────────────────────────────────────────────────────────────

// Ana sayfaya ilk girişte kısa tanıtım
// Revize R29: ipuçları ekrandaki sırayla yukarıdan aşağı (Seviye → Bugün → Oyunlar → Konular → alt menü)
const COACH_STEPS: CoachStep[] = [
  {
    target: "level",
    title: "Seviyen",
    text: "Bu seviyede 50 soru çözüp %80 doğru yapınca bir üst seviyenin soruları açılır.",
  },
  {
    target: "today",
    title: "Buradan başla",
    text: "Her gün karışık 10 soru. Günlük hedefini tamamlayınca serin bir gün artar.",
  },
  { target: "games", title: "Oyunlar", text: "Günün meydan okumasını oyna ya da arkadaşına meydan oku." },
  {
    target: "categories",
    title: "Bir konuya odaklan",
    text: "Sadece Sol anahtarı, ritim ya da terim çalışmak istersen bir karta dokun.",
  },
  {
    target: "nav",
    title: "İlerleme, Öğren ve Profil",
    text: "Gelişimini İlerleme'de gör, notaları Öğren'de çalış; öğretmen kodu ve ayarlar Profil'de.",
  },
]

export default function App() {
  // ── Gezinme: basit bir yığın. Sekmeler yığını sıfırlar; alt ekranlar üstüne eklenir;
  // geri (düğme, kaydırma, Android) bir önceki ekrana döner.
  const [view, setViewRaw] = useState<View>("home")
  const viewRef = useRef<View>("home")
  viewRef.current = view
  const stackRef = useRef<View[]>([])
  const topRef = useRef<HTMLDivElement>(null)
  /** Geri dönülen ekranın kaydırma konumu çizimden sonra uygulanır */
  const restoreRef = useRef<View | null>(null)
  /** Yeni ekrana git. Sonuç ekranlarından gidilirse sonuç ekranı yığına girmez. */
  const setView = useCallback((v: View) => {
    const cur = viewRef.current
    if (v === "home" || v === "dashboard" || v === "study" || v === "profile") {
      stackRef.current = []
      forgetScroll()
    } else if (cur !== "result" && cur !== "gameresult" && cur !== v) {
      stackRef.current.push(cur)
      saveScroll(topRef.current, cur)
    }
    // Aynı anda art arda iki gezinme (tanıtım → Profil → öğretmen kodu) yığını doğru kursun
    viewRef.current = v
    setViewRaw(v)
  }, [])
  /** Bulunulan ekranın yerine geç (tur → sonuç) */
  const replaceView = useCallback((v: View) => setViewRaw(v), [])
  const backTarget = () => stackRef.current[stackRef.current.length - 1] ?? "home"
  const goBack = useCallback(() => {
    const v = stackRef.current.pop() ?? "home"
    restoreRef.current = v
    setViewRaw(v)
  }, [])
  useLayoutEffect(() => {
    if (restoreRef.current !== view) return
    restoreRef.current = null
    restoreScroll(topRef.current, view)
    forgetScroll(view)
  }, [view])
  // Profil için "…'den beri" tarihi: ilk açılışta bir kez kaydedilir
  useEffect(() => {
    if (!getSettings().joinedAt) updateSettings({ joinedAt: todayKey() })
  }, [])
  // Uygulamada (iOS/Android) yan çevirmeye sadece soru ekranlarında izin ver
  useEffect(() => {
    allowLandscape(view === "quiz" || view === "chordquiz")
  }, [view])
  const [themeMode, setThemeMode] = useState<ThemeMode>(loadThemeMode)
  const [sysTheme, setSysTheme] = useState<Theme>(systemTheme)
  const theme: Theme = themeMode === "system" ? sysTheme : themeMode
  useEffect(() => {
    const mq = window.matchMedia?.("(prefers-color-scheme: light)")
    if (!mq) return
    const on = () => setSysTheme(mq.matches ? "light" : "dark")
    mq.addEventListener?.("change", on)
    return () => mq.removeEventListener?.("change", on)
  }, [])
  const [stats, setStats] = useState<AppStats>(loadStats)
  const [celebrate, setCelebrate] = useState<CelebrationData | null>(null)
  const [currentCategory, setCurrentCategory] = useState<FilterCategory>("all")
  // Son turlar listesinde görünecek özel ad (hataların tekrarı vb.); null ise kategori adı
  /** Son turun yıldızı ve (konu turuysa) o konudaki önceki en iyi */
  const [lastStars, setLastStars] = useState<{ stars: number; best: number | null }>({ stars: 0, best: null })
  const sessionLabelRef = useRef<string | null>(null)
  // Çalışma'da açık olan ders
  const [lessonId, setLessonId] = useState("notes-treble")
  const [sessionQuestions, setSessionQuestions] = useState(() => getQuestions("all"))
  const [lastResults, setLastResults] = useState<RoundAnswer[]>([])
  /** Son tur akor turu muydu? (sonuç ekranında başlık ve "Yeni tur" için) */
  const [lastSpecial, setLastSpecial] = useState<SpecialRound | null>(null)
  const [game, setGame] = useState<GameCtx | null>(null)
  const gameRef = useRef<GameCtx | null>(null)
  const [lastPoints, setLastPoints] = useState(0)
  const [showOnboarding, setShowOnboarding] = useState(() => !getSettings().onboarded)
  const [showSplash, setShowSplash] = useState(true)
  const settings = useSyncExternalStore(subscribeSettings, getSettings)

  useEffect(() => {
    saveStats(stats)
  }, [stats])
  useEffect(() => {
    try {
      localStorage.setItem(THEME_KEY, themeMode)
    } catch (_) {
      /* ignore */
    }
    document.documentElement.style.colorScheme = theme
    applyStatusBar(theme)
  }, [theme, themeMode])

  const startGame = useCallback((ctx: GameCtx) => {
    const level = ctx.mode === "daily" ? 2 : ctx.level
    gameRef.current = ctx
    setGame(ctx)
    setSessionQuestions(buildGameQuestions(ctx.cat, level, ctx.seed))
    setView("quiz")
  }, [])

  const startQuiz = useCallback((cat: FilterCategory) => {
    sessionLabelRef.current = null
    gameRef.current = null
    setGame(null)
    setCurrentCategory(cat)
    setSessionQuestions(getQuestions(cat))
    setView("quiz")
  }, [])

  const handleComplete = useCallback(
    (results: SessionResult[]) => {
      setLastResults(results)
      setLastSpecial(null)
      let pts = 0
      results.forEach((r) => {
        if (r.correct) pts += 10
      })
      setLastPoints(pts)

      const g0 = gameRef.current
      const label = g0 ? `Oyun · ${catLabel(g0.cat)}` : (sessionLabelRef.current ?? ROUND_LABELS[currentCategory])
      const newStats = applyProgress(stats, pts, results.length, {
        label,
        correct: results.filter((r) => r.correct).length,
        total: results.length,
        sec: Math.round(results.reduce((a, r) => a + r.timeMs, 0) / 1000),
      })

      results.forEach((r) => {
        if (r.category === "note_identification" && r.noteY !== undefined) {
          const key = `${r.clef}:${r.noteY}${r.accidental ? ":" + r.accidental : ""}`
          const cur = newStats.noteStats[key] ?? { correct: 0, total: 0 }
          newStats.noteStats[key] = {
            correct: cur.correct + (r.correct ? 1 : 0),
            total: cur.total + 1,
          }
        }
      })

      const acc = { ...newStats.categoryAccuracy }
      results.forEach((r) => {
        if (r.category === "note_identification") {
          const isLedger = r.hasLedger ?? false
          if (r.clef === "treble") {
            acc.treble = {
              correct: acc.treble.correct + (r.correct ? 1 : 0),
              total: acc.treble.total + 1,
            }
            if (isLedger)
              acc.trebleLedger = {
                correct: acc.trebleLedger.correct + (r.correct ? 1 : 0),
                total: acc.trebleLedger.total + 1,
              }
          } else if (r.clef === "bass") {
            acc.bass = {
              correct: acc.bass.correct + (r.correct ? 1 : 0),
              total: acc.bass.total + 1,
            }
            if (isLedger)
              acc.bassLedger = {
                correct: acc.bassLedger.correct + (r.correct ? 1 : 0),
                total: acc.bassLedger.total + 1,
              }
          }
        } else if (r.category === "ear") {
          const e = acc.ear ?? { correct: 0, total: 0 }
          acc.ear = { correct: e.correct + (r.correct ? 1 : 0), total: e.total + 1 }
        } else if (r.category === "writing") {
          const w = acc.writing ?? { correct: 0, total: 0 }
          acc.writing = { correct: w.correct + (r.correct ? 1 : 0), total: w.total + 1 }
        } else if (r.category === "rhythm") {
          acc.rhythm = {
            correct: acc.rhythm.correct + (r.correct ? 1 : 0),
            total: acc.rhythm.total + 1,
          }
        } else if (r.category === "musical_terms") {
          acc.terms = {
            correct: acc.terms.correct + (r.correct ? 1 : 0),
            total: acc.terms.total + 1,
          }
        }
      })
      newStats.categoryAccuracy = acc
      // Yıldız: yalnızca normal konu turlarında (oyun, karma günlük tur, hata tekrarı sayılmaz)
      const roundStars = starsFor(results.filter((r) => r.correct).length, results.length)
      setLastStars({
        stars: roundStars,
        best: !g0 && !sessionLabelRef.current ? recordStars(newStats, currentCategory, roundStars) : null,
      })
      recordTopics(
        newStats,
        results.map((r) => ({ topic: topicOf(r), correct: r.correct ? 1 : 0, total: 1 })),
      )
      let cel = detectCelebration(stats, newStats)
      const unlocked = recordLevelProgress(results)
      if (unlocked) cel = { ...(cel ?? {}), unlocked }
      setCelebrate(cel)
      if (!cel) playSessionDone()
      setStats(newStats)
      const g = gameRef.current
      if (g) {
        if (g.mode === "daily") saveDaily({ date: g.date, ...summarize(results) })
        replaceView("gameresult")
      } else replaceView("result")
    },
    [stats, currentCategory],
  )

  // Akor kartları ve Ritmi Tut: kendi ekranlarında oynanır, sonuç ortak ekranda.
  // Akor doğruluğu "chords"a, Ritmi Tut "rhythm"a yazılır; yıldızlar tur türüyle tutulur.
  const handleSpecialComplete = useCallback(
    (kind: SpecialRound, answers: RoundAnswer[]) => {
      const correct = answers.filter((a) => a.correct).length
      const total = answers.length
      const pts = correct * 10
      const topic = kind === "chords" ? "chords" : "rhythm"
      const next = applyProgress(stats, pts, total, {
        label: kind === "chords" ? "Akorlar" : "Ritmi Tut",
        correct,
        total,
      })
      const prev = next.categoryAccuracy[topic] ?? { correct: 0, total: 0 }
      next.categoryAccuracy = {
        ...next.categoryAccuracy,
        [topic]: { correct: prev.correct + correct, total: prev.total + total },
      }
      recordTopics(next, [{ topic, correct, total }])
      const stars = starsFor(correct, total)
      setLastStars({ stars, best: recordStars(next, kind, stars) })
      setLastResults(answers)
      setLastPoints(pts)
      setLastSpecial(kind)
      setSessionQuestions([]) // bu turların "hataları tekrar et"i yok; "Yeni tur" çıkar
      const cel = detectCelebration(stats, next)
      setCelebrate(cel)
      if (!cel) playSessionDone()
      setStats(next)
      replaceView("result")
    },
    [stats],
  )

  const startWeakPractice = useCallback((keys: string[]) => {
    const qs = getWeakQuestions(keys)
    if (qs.length === 0) return
    sessionLabelRef.current = "Zayıf notalar"
    gameRef.current = null
    setGame(null)
    setCurrentCategory("all")
    setSessionQuestions(qs)
    setView("quiz")
  }, [])

  // Dokunmatik geniş ekran (iPad) için biraz daha geniş sütun; bilgisayarda telefon çerçevesi
  const isTablet = useTablet()
  // Yan ekran sadece soru ekranlarında: telefon yan çevrilince sütun genişler
  const inQuestions = view === "quiz" || view === "chordquiz"
  const land = useLandscape() && inQuestions
  // Sol kenardan sağa kaydırınca geri (Instagram gibi ekran kayar) / Android geri tuşu
  const shellRef = useRef<HTMLDivElement>(null)
  const underRef = useRef<HTMLDivElement>(null)
  const swipe = useSwipeBack<View>({
    root: shellRef,
    top: topRef,
    under: underRef,
    getTarget: () => {
      if (celebrate || showOnboarding || showSplash) return null
      // Turdan çıkış onayı açıksa kaydırma ekranı kaydırmaz, "Devam et"e basar
      if (shellRef.current?.querySelector("[data-exit-open]")) return null
      if (
        [
          "quiz",
          "chordquiz",
          "rhythmtap",
          "duel",
          "notes",
          "settings",
          "result",
          "games",
          "game-daily",
          "game-challenge",
          "gameresult",
          "lesson",
          "teacher",
          "privacy",
          "licenses",
        ].includes(view)
      )
        return backTarget()
      return null
    },
    commit: () => goBack(),
    // Turda cevap verildiyse (✕ data-answered taşır) bırakınca ekran yerine oturur, onay açılır (revize R34)
    confirmOnRelease: () => visibleBack(shellRef.current)?.dataset.answered === "1",
  })

  // Kaydırırken alttan görünen önceki ekran da kalınan yerde dursun
  useLayoutEffect(() => {
    if (swipe.underlay) restoreScroll(underRef.current, swipe.underlay)
  }, [swipe.underlay])

  const shellBg = colors.bg
  const isTabView = (v: View) => v === "home" || v === "dashboard" || v === "study" || v === "profile"
  // Bir ekranı (içerik + gerekiyorsa alt menü) çizer; kaydırmada alttaki ekran için de kullanılır
  const renderScreen = (v: View) => (
    <>
      <div className="flex-1 min-h-0 overflow-hidden">
        {v === "home" && (
          <HomeScreen
            stats={stats}
            onStart={startQuiz}
            onChordQuiz={() => setView("chordquiz")}
            onRhythmTap={() => setView("rhythmtap")}
            onGames={() => setView("games")}
            onOpenProfile={() => setView("profile")}
            dailyGoal={settings.dailyGoal}
          />
        )}

        {v === "teacher" && (
          <TabletColumn width={680}>
            <TeacherScreen onBack={goBack} />
          </TabletColumn>
        )}
        {v === "profile" && (
          <TabletColumn width={680}>
            <ProfileScreen
              stats={stats}
              onOpenTeacher={() => setView("teacher")}
              onOpenSettings={() => setView("settings")}
              onOpenProgress={() => setView("dashboard")}
            />
          </TabletColumn>
        )}

        {(v === "privacy" || v === "licenses") && (
          <TabletColumn width={680}>
            <LegalScreen page={v} onBack={goBack} />
          </TabletColumn>
        )}
        {v === "settings" && (
          <TabletColumn width={680}>
            <SettingsScreen
              themeMode={themeMode}
              onThemeMode={setThemeMode}
              onBack={goBack}
              onOpenPrivacy={() => setView("privacy")}
              onOpenLicenses={() => setView("licenses")}
              onOpenNotes={() => setView("notes")}
              onShowTutorial={() => {
                updateSettings({ coachDone: false })
                setView("home")
                setShowOnboarding(true)
              }}
              onReset={() => {
                setStats({
                  ...DEFAULT_STATS,
                  dailyLog: {},
                  dailyQuestions: {},
                  noteStats: {},
                  history: [],
                  dailyAccuracy: {},
                })
                setView("home")
              }}
            />
          </TabletColumn>
        )}

        {v === "notes" && (
          <TabletColumn width={680}>
            <NotesSettings onBack={goBack} />
          </TabletColumn>
        )}

        {v === "games" && (
          <TabletColumn width={680}>
            <GamesScreen
              onBack={goBack}
              onOpen={(g) => setView(g === "duel" ? "duel" : g === "daily" ? "game-daily" : "game-challenge")}
            />
          </TabletColumn>
        )}

        {v === "game-daily" && (
          <TabletColumn width={680}>
            <DailyGameScreen onBack={goBack} onPlay={startGame} />
          </TabletColumn>
        )}

        {v === "game-challenge" && (
          <TabletColumn width={680}>
            <ChallengeGameScreen onBack={goBack} onPlay={startGame} />
          </TabletColumn>
        )}

        {v === "gameresult" && game && (
          <TabletColumn width={680}>
            <GameResultScreen
              ctx={game}
              results={lastResults}
              onNewChallenge={(cat: GameCat) =>
                startGame({ mode: "challenge", cat, level: settings.level, seed: newSeed() })
              }
              onExit={goBack}
            />
          </TabletColumn>
        )}

        {v === "duel" && (
          <div style={{ position: "relative", height: "100%" }}>
            <ChordDuel onExit={goBack} />
          </div>
        )}

        {v === "chordquiz" && (
          <ChordQuizSession onExit={goBack} onComplete={(a) => handleSpecialComplete("chords", a)} />
        )}
        {v === "rhythmtap" && (
          <TabletColumn width={680}>
            <RhythmTapSession onExit={goBack} onComplete={(a) => handleSpecialComplete("rhythmtap", a)} />
          </TabletColumn>
        )}

        {v === "quiz" && (
          <QuizSession
            questions={sessionQuestions}
            timerEnabled={settings.timer && !game}
            timerSeconds={TIMER_SECONDS}
            onComplete={handleComplete}
            onExit={goBack}
            noHints={!!game}
          />
        )}

        {v === "result" && (
          <TabletColumn width={680}>
            <ResultScreen
              results={lastResults}
              pointsEarned={lastPoints}
              stars={lastStars.stars}
              prevBest={lastStars.best}
              totalXp={stats.totalPoints}
              questions={sessionQuestions}
              category={lastSpecial ?? currentCategory}
              streak={currentStreak(stats)}
              onHome={goBack}
              onRetry={() =>
                lastSpecial
                  ? replaceView(lastSpecial === "chords" ? "chordquiz" : "rhythmtap")
                  : startQuiz(currentCategory)
              }
              onRetryWrong={() => {
                const wrongIds = new Set(lastResults.filter((r) => !r.correct).map((r) => r.questionId))
                const wrongQs = sessionQuestions.filter((q) => wrongIds.has(q.id))
                if (wrongQs.length > 0) {
                  sessionLabelRef.current = "Hataların tekrarı"
                  setSessionQuestions(wrongQs)
                  setView("quiz")
                }
              }}
            />
          </TabletColumn>
        )}

        {v === "dashboard" && (
          <ProgressScreen
            stats={stats}
            onStartQuiz={() => setView("home")}
            onPracticeWeak={startWeakPractice}
            onPracticeCategory={(k) => (k === "chords" ? setView("chordquiz") : startQuiz(k))}
            onReplayRound={(label, weak) => {
              // Revize R38: "Oyun · …" Oyunlar listesi; "Zayıf notalar" şimdiki zorlanılan notalar; tanınmayan ad karma tur
              if (label.startsWith("Oyun · ")) setView("games")
              else if (label === "Akorlar") setView("chordquiz")
              else if (label === "Ritmi Tut") setView("rhythmtap")
              else if (label === "Zayıf notalar") weak.length ? startWeakPractice(weak) : startQuiz("all")
              else {
                const cat = (Object.keys(ROUND_LABELS) as FilterCategory[]).find((k) => ROUND_LABELS[k] === label)
                startQuiz(cat ?? "all")
              }
            }}
            header={<TabTitle>İlerleme</TabTitle>}
          />
        )}

        {v === "study" && (
          <TabletColumn width={820}>
            <StudyScreen
              onOpen={(id) => {
                setLessonId(id)
                setView("lesson")
              }}
            />
          </TabletColumn>
        )}

        {v === "lesson" && (
          <TabletColumn width={820}>
            <LessonScreen id={lessonId} onBack={goBack} />
          </TabletColumn>
        )}
      </div>
      {isTabView(v) && <NavBar active={v as NavTab} onChange={(t) => setView(t)} />}
    </>
  )

  return (
    <div
      className={`theme-shell theme-${theme} flex items-center justify-center w-full h-full`}
      style={{ background: colors.bgDeep }}
    >
      <div
        ref={shellRef}
        className="relative flex flex-col w-full h-full overflow-hidden"
        style={{
          maxWidth: isTablet ? 1100 : land ? 960 : 430,
          maxHeight: isTablet || land ? undefined : 932,
          paddingLeft: land ? "env(safe-area-inset-left)" : undefined,
          paddingRight: land ? "env(safe-area-inset-right)" : undefined,
          paddingTop: "env(safe-area-inset-top)",
          paddingBottom: "env(safe-area-inset-bottom)",
          background: colors.bg,
          boxShadow: shadow.shell,
        }}
      >
        {/* Kaydırarak geri: alttaki önceki ekran */}
        {swipe.underlay && (
          <div
            ref={underRef}
            aria-hidden="true"
            className="absolute inset-0 flex flex-col"
            style={{ pointerEvents: "none", background: shellBg, transform: "translateX(-30%)" }}
          >
            {renderScreen(swipe.underlay)}
            <div data-dim style={{ position: "absolute", inset: 0, background: palette.black, opacity: 0.35 }} />
          </div>
        )}
        {/* Şu anki ekran (kaydırınca parmakla kayar) */}
        <div
          ref={topRef}
          className="relative flex-1 min-h-0 flex flex-col"
          style={{ background: shellBg, willChange: swipe.underlay ? "transform" : undefined }}
        >
          {renderScreen(view)}
        </div>

        {showSplash && <Splash onDone={() => setShowSplash(false)} />}

        {showOnboarding && !showSplash && (
          <Onboarding
            onDone={(openTeacher) => {
              updateSettings({ onboarded: true })
              setShowOnboarding(false)
              // Revize R12: tanıtım bitince Ana sayfa en üstten başlasın
              topRef.current?.querySelector<HTMLElement>(".overflow-y-auto")?.scrollTo(0, 0)
              // "Ben öğretmenim": öğretmen kodu ekranı (hazırlama); geri dönünce Profil
              if (openTeacher) {
                setView("profile")
                setView("teacher")
              }
            }}
          />
        )}

        {view === "home" && !showSplash && !showOnboarding && !celebrate && !settings.coachDone && (
          <Coachmark steps={COACH_STEPS} onDone={() => updateSettings({ coachDone: true })} />
        )}
        {celebrate && <Celebration data={celebrate} onClose={() => setCelebrate(null)} />}
      </div>
    </div>
  )
}
