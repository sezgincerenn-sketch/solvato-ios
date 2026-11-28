// Gezinme kuralları web App.tsx ile aynı mı (G-10): sekme yığını sıfırlar, alt ekranlar eklenir, sonuç ekranı yığına
// girmez, "Bitir" turun başlatıldığı ekrana döner, kaydırma yalnız alt ekranlarda; Profil sekme (gezinme.md).
import XCTest

@testable import SolvatoCore

final class ScreenStackTests: XCTestCase {
    func testSettingsFromProfileSwipeBack() {
        var s = ScreenStack()
        s.go(.games)
        s.go(.profile)
        XCTAssertEqual(s.stack, [], "Profil sekme: yığın sıfırlanır")
        XCTAssertFalse(s.canSwipeBack(overlayOpen: false), "Profil'de kaydırarak geri yok")
        s.go(.settings)
        XCTAssertEqual(s.stack, [.profile])
        XCTAssertTrue(s.canSwipeBack(overlayOpen: false))
        XCTAssertEqual(s.backTarget, .profile)
        XCTAssertEqual(s.back(), .profile, "Ayarlar'dan geri: Profil")
        XCTAssertEqual(s.back(), .home, "boş yığında ana sayfa")
    }

    func testResultReturnsToWhereRoundStarted() {
        var s = ScreenStack()
        s.go(.dashboard)
        s.go(.quiz)
        s.replace(.result)
        XCTAssertEqual(s.stack, [.dashboard])
        XCTAssertEqual(s.back(), .dashboard, "Bitir → İlerleme")

        var h = ScreenStack()
        h.go(.quiz)
        h.replace(.result)
        // Sonuçtan "Hataları tekrar et": sonuç yığına girmez
        h.go(.quiz)
        XCTAssertEqual(h.stack, [.home])
        h.replace(.result)
        XCTAssertEqual(h.back(), .home)
    }

    func testTabsResetAndNoDuplicate() {
        var s = ScreenStack()
        s.go(.games)
        s.go(.gameDaily)
        s.go(.gameDaily)
        XCTAssertEqual(s.stack, [.home, .games])
        s.go(.study)
        XCTAssertEqual(s.stack, [])
        XCTAssertEqual(s.current, .study)
    }

    func testSwipeOnlyOnSubScreens() {
        XCTAssertEqual(AppView.allCases.filter(\.swipesBack).count, 12)
        for v in [AppView.quiz, .chordquiz, .rhythmtap, .duel, .home, .dashboard, .study, .profile] { XCTAssertFalse(v.swipesBack, v.rawValue) }
        XCTAssertEqual(AppView.allCases.filter(\.isTab), [.home, .dashboard, .study, .profile], "alt menüde dört sekme")
        var s = ScreenStack()
        s.go(.settings)
        XCTAssertFalse(s.canSwipeBack(overlayOpen: true), "kutlama açıkken kaydırma yok")
        XCTAssertEqual(AppView.allCases.filter(\.allowsLandscape), [.quiz, .chordquiz])
    }

    /// gezinme-cubugu.md: sekmenin yığını Apple'ın gezinme yığınına, turlar ve tur sonucu üstteki tam ekran katmana
    func testNavigationPath() {
        var s = ScreenStack()
        XCTAssertEqual(s.rootTab, .home)
        XCTAssertEqual(s.navPath, [])
        s.go(.profile)
        s.go(.settings)
        s.go(.notes)
        XCTAssertEqual(s.rootTab, .profile)
        XCTAssertEqual(s.navPath, [.settings, .notes])
        XCTAssertEqual(s.stack.last?.title, "Ayarlar", "geri düğmesi: ‹ Ayarlar")
        s.back()
        XCTAssertEqual(s.navPath, [.settings])

        // Oyun: tur açıkken yol turdan önceki ekranda kalır, oyun sonucu yola girer
        var g = ScreenStack()
        g.go(.games)
        g.go(.gameDaily)
        g.go(.quiz)
        XCTAssertEqual(g.rootTab, .home)
        XCTAssertEqual(g.navPath, [.games, .gameDaily], "tur tam ekran; altında Günün meydan okuması")
        g.replace(.gameresult)
        XCTAssertEqual(g.navPath, [.games, .gameDaily, .gameresult])
        XCTAssertEqual(g.back(), .gameDaily)

        // Öğren › ders › tur › sonuç: yol dersde kalır
        var l = ScreenStack()
        l.go(.study)
        l.go(.lesson)
        l.go(.quiz)
        l.replace(.result)
        XCTAssertEqual(l.rootTab, .study)
        XCTAssertEqual(l.navPath, [.lesson])
        XCTAssertEqual(l.back(), .lesson)

        XCTAssertEqual(AppView.allCases.filter(\.isFullScreen), [.quiz, .result, .chordquiz, .rhythmtap])
        XCTAssertFalse(AppView.duel.isFullScreen, "düello kurulumu çubuklu alt ekran")
        for v in AppView.allCases where v.isTab { XCTAssertFalse(v.title.isEmpty, v.rawValue) }
        XCTAssertEqual(AppView.home.title, "Ana sayfa", "Oyunlar'ın geri düğmesi: ‹ Ana sayfa")
    }
}
