// Ekran görüntüsü testleri: her ekranı koyu ve açık temada açar, görüntüyü test sonucuna ekler.
// Codemagic bu görüntüleri cihaz adıyla birlikte derleme çıktısına koyar (scripts/native-ekranlar.py).
// Yeni ekran geldikçe buraya bir adım eklenir; web'deki aynı durumun görüntüsüyle yan yana karşılaştırılır.
import XCTest

final class ScreenshotTests: XCTestCase {
    @MainActor
    func testDesignSystem() {
        continueAfterFailure = false
        for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
            let app = launch(theme: theme)
            let screen = app.descendants(matching: .any)["tasarim-sistemi"]
            XCTAssertTrue(screen.waitForExistence(timeout: 10), "tasarım sistemi ekranı açılmadı")
            // Ekran uzun: her iki kaydırmada bir görüntü (iPad'de son görüntüler tekrar edebilir)
            for shot in 1...5 {
                if shot > 1 {
                    app.swipeUp()
                    app.swipeUp()
                }
                snap("tasarim-\(shot)-\(tr)")
            }
            app.terminate()
        }
    }

    @MainActor
    private func launch(theme: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestTheme", theme]
        app.launch()
        return app
    }

    @MainActor
    private func snap(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
