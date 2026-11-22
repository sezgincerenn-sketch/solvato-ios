// Ekran görüntüsü testleri: her ekranı koyu ve açık temada açar, görüntüyü test sonucuna ekler.
// Codemagic bu görüntüleri cihaz adıyla birlikte derleme çıktısına koyar (scripts/native-ekranlar.py).
// Yeni ekran geldikçe buraya bir adım eklenir; web'deki aynı durumun görüntüsüyle yan yana karşılaştırılır.
import XCTest

final class ScreenshotTests: XCTestCase {
    @MainActor
    func testDesignSystem() {
        continueAfterFailure = false
        for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
            let app = try! launch(theme: theme)
            let screen = app.descendants(matching: .any)["tasarim-sistemi"]
            XCTAssertTrue(screen.waitForExistence(timeout: 10), "tasarım sistemi ekranı açılmadı")
            // Simülatörün ilk açılış bildirimleri (ör. Apple Intelligence) kaybolsun
            if theme == "dark" { Thread.sleep(forTimeInterval: 8) }
            // Ekran uzun: her kısa kaydırmada bir görüntü (iPad'de son görüntüler tekrar edebilir)
            for shot in 1...12 {
                if shot > 1 { app.swipeUp(velocity: .slow) }
                snap("tasarim-\(shot)-\(tr)")
            }
            app.terminate()
        }
    }

    /// Pratik ekranı, web referans görüntüleriyle aynı adlar ve aynı veri (scripts/referans.mjs senaryoları)
    @MainActor
    func testPratik() throws {
        continueAfterFailure = false
        for name in ["pratik-yeni", "pratik", "pratik-ogretmen", "pratik-hedef-tamam", "pratik-alt"] {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name)
                XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10), "\(name): Pratik açılmadı")
                if name == "pratik-alt" {
                    for _ in 0..<4 { app.swipeUp() }
                }
                Thread.sleep(forTimeInterval: 0.6)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    @MainActor
    private func launch(theme: String, scenario: String? = nil) throws -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestTheme", theme]
        if let scenario {
            // senaryolar.json: `node scripts/referans.mjs --json ios-native/SolvatoUITests/senaryolar.json`
            let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "senaryolar", withExtension: "json"))
            let all = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
            let sc = try XCTUnwrap((all["senaryolar"] as? [String: Any])?[scenario] as? [String: Any], scenario)
            let store = try JSONSerialization.data(withJSONObject: sc["store"] as Any)
            app.launchEnvironment["SOLVATO_SENARYO_STORE"] = String(decoding: store, as: UTF8.self)
            app.launchEnvironment["SOLVATO_SENARYO_SIMDI"] = all["simdi"] as? String
            app.launchEnvironment["SOLVATO_SENARYO_TOHUM"] = String(describing: all["tohum"] ?? "")
            app.launchEnvironment["SOLVATO_SENARYO_ACILIS"] = (sc["splash"] as? Bool) == true ? "1" : "0"
        }
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
