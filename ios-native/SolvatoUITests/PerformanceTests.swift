// Performans ölçümleri (0.8, docs/ozellikler/erisilebilirlik-ipad.md §4). GitHub Actions her ios-native gönderiminde
// iPhone simülatöründe koşar (scripts/native-ui-testleri.sh); sonuçlar scripts/native-performans.py ile `ekranlar`
// dalındaki performans.md tablosuna yazılır, sınır aşılırsa iş kırmızı olur. Test adları tablodaki sütunlara bağlı.
import XCTest

final class PerformanceTests: XCTestCase {
    private func options(_ n: Int, manualStop: Bool = false) -> XCTMeasureOptions {
        let o = XCTMeasureOptions()
        o.iterationCount = n
        if manualStop { o.invocationOptions = [.manuallyStop] }
        return o
    }

    /// Soğuk açılış: uygulamanın ilk karesine kadar (sınır 1,5 sn)
    @MainActor
    func testSogukAcilis() throws {
        let app = try configuredApp(theme: "dark", scenario: "pratik")
        measure(metrics: [XCTApplicationLaunchMetric()], options: options(5)) {
            app.launch()
        }
        app.terminate()
    }

    /// Pratik → İlerleme sekme geçişi: dokunuştan İlerleme sayfası görünene kadar (uygulamadaki işaret, Perf.swift;
    /// sınır 0,3 sn)
    @MainActor
    func testSekmeGecisi() throws {
        let app = try launch(theme: "dark", scenario: "ilerleme")
        XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10))
        let progress = app.buttons.matching(NSPredicate(format: "label CONTAINS 'İlerleme'")).firstMatch
        let home = app.buttons["Ana sayfa"].firstMatch
        measure(
            metrics: [XCTOSSignpostMetric(subsystem: "com.solvato.app", category: "performans", name: "sekme")],
            options: options(5, manualStop: true)
        ) {
            progress.tap()
            Thread.sleep(forTimeInterval: 1.0)
            stopMeasuring()
            home.tap()
            Thread.sleep(forTimeInterval: 1.0)
        }
        app.terminate()
    }

    /// 10 soruluk tur boyunca uygulamanın en yüksek belleği (sınır 150 MB)
    @MainActor
    func testBellekTur() throws {
        let app = try launch(theme: "dark", scenario: "soru-nota")
        XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10))
        measure(metrics: [XCTMemoryMetric(application: app)], options: options(1)) {
            guard goTo(app, "soru") else { return XCTFail("soru turu açılmadı") }
            for _ in 0..<40 {
                if app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Tur bitti'")).firstMatch.exists { break }
                if app.otherElements["Kutlama"].exists || app.staticTexts["Harika iş!"].exists { break }
                let next = app.buttons.matching(NSPredicate(format: "label IN {'Sıradaki', 'Turu bitir'}")).firstMatch
                if next.exists { next.tap() } else {
                    let key = app.buttons["Do tuşu"].firstMatch
                    if key.exists { key.tap() } else { app.buttons.allElementsBoundByIndex.last { $0.isEnabled && $0.isHittable }?.tap() }
                }
                Thread.sleep(forTimeInterval: 0.9)
            }
            // XCTest bloğu birden çok kez koşabilir: her seferinde Pratik'e dön (kutlama → Devam, sonuç → Bitir)
            for label in ["Devam", "Bitir"] {
                let b = app.buttons[label].firstMatch
                if b.waitForExistence(timeout: 3) { b.tap(); Thread.sleep(forTimeInterval: 0.8) }
            }
        }
        app.terminate()
    }

    // Kaydırmada takılan kare oranı simülatörde ölçülemiyor (yalnız süre geliyor, 27 Kasım koşusu); cihazda Xcode
    // Organizer / Instruments ile bakılır.
}
