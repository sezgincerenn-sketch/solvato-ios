// Ekran görüntüsü testleri: her ekranı koyu ve açık temada açar, görüntüyü test sonucuna ekler.
// Codemagic bu görüntüleri cihaz adıyla birlikte derleme çıktısına koyar (scripts/native-ekranlar.py).
// Yeni ekran geldikçe buraya bir adım eklenir; web'deki aynı durumun görüntüsüyle yan yana karşılaştırılır.
import XCTest

final class ScreenshotTests: XCTestCase {
    @MainActor
    func testDesignSystem() {
        continueAfterFailure = false
        for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
            let app = try! launch(theme: theme, designSystem: true)
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

    /// Soru turu: Pratik'ten konu kartına dokunup tur açılır (web referans senaryolarıyla aynı adlar ve adımlar)
    @MainActor
    func testSoru() throws {
        continueAfterFailure = false
        // (senaryo, dokunulacak konu, sonra yapılacak: ipucu / yanlis / dogru / cikis / boş)
        let steps: [(String, String, String)] = [
            ("soru-nota", "Sol Anahtarı", ""),
            ("soru-nota-ipucu", "Sol Anahtarı", "ipucu"),
            ("soru-nota-yanlis", "Sol Anahtarı", "yanlis"),
            ("soru-nota-dogru", "Sol Anahtarı", "dogru"),
            ("soru-nota-siklar", "Fa Anahtarı", ""),
            ("soru-diyez", "Diyez & Bemol", ""),
            ("soru-ritim", "Ritim & Ölçü", ""),
            ("soru-terim", "Müzik Terimleri", ""),
            ("soru-yazim", "Nota Yazımı", ""),
            ("soru-kulak", "Kulak", ""),
            ("soru-sure", "Sol Anahtarı", ""),
            ("soru-cikis", "Sol Anahtarı", "cikis"),
        ]
        for (name, topic, action) in steps {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name)
                XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10), "\(name): Pratik açılmadı")
                let card = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", topic)).firstMatch
                // Kart görünene kadar kaydır (alttaki konular ilk ekranda yok)
                for _ in 0..<6 where !(card.exists && card.isHittable) { app.swipeUp(velocity: .slow) }
                card.tap()
                XCTAssertTrue(app.buttons["Çık"].waitForExistence(timeout: 5), "\(name): soru açılmadı")
                switch action {
                case "ipucu": app.buttons["İpucu"].firstMatch.tap()
                case "yanlis": answerUntil(app, wrong: true)
                case "dogru": answerUntil(app, wrong: false)
                case "cikis": app.buttons["Çık"].firstMatch.tap()
                default: break
                }
                Thread.sleep(forTimeInterval: 0.5)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// Tur sonucu ve kutlama: Pratik'te "Devam et" ile karma tur açılır, sonuna kadar oynanır (web turuBitir)
    @MainActor
    func testSonuc() throws {
        continueAfterFailure = false
        for name in ["sonuc", "kutlama"] {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name)
                XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10), "\(name): Pratik açılmadı")
                app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Devam et' OR label BEGINSWITH 'Bugünün çalışması' OR label BEGINSWITH 'Bir tur daha'")).firstMatch.tap()
                for _ in 0..<40 {
                    if app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Tur bitti'")).firstMatch.exists { break }
                    if app.otherElements["Kutlama"].exists || app.staticTexts["Harika iş!"].exists { break }
                    let next = app.buttons.matching(NSPredicate(format: "label IN {'Sıradaki', 'Turu bitir'}")).firstMatch
                    if next.exists { next.tap() } else {
                        let key = app.buttons["Do tuşu"]
                        if key.exists { key.tap() } else { app.buttons.allElementsBoundByIndex.last { $0.isEnabled && $0.isHittable }?.tap() }
                    }
                    Thread.sleep(forTimeInterval: 0.9)
                }
                Thread.sleep(forTimeInterval: 0.6)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// Klavyede "Do tuşu"na ya da son şıkka basarak yanlış (ya da doğru) cevaplanan ilk soruda durur
    @MainActor
    private func answerUntil(_ app: XCUIApplication, wrong: Bool) {
        for _ in 0..<10 {
            let key = app.buttons["Do tuşu"]
            if key.exists { key.tap() } else { app.buttons.allElementsBoundByIndex.last { $0.isEnabled && $0.isHittable }?.tap() }
            Thread.sleep(forTimeInterval: 0.3)
            let isWrong = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Doğru cevap:'")).firstMatch.exists
            if isWrong == wrong { return }
            if isWrong { app.buttons.matching(NSPredicate(format: "label IN {'Sıradaki', 'Turu bitir'}")).firstMatch.tap() }
            Thread.sleep(forTimeInterval: 0.9)
        }
    }

    @MainActor
    private func launch(theme: String, scenario: String? = nil, designSystem: Bool = false) throws -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestTheme", theme] + (designSystem ? ["-UITestDesignSystem"] : [])
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
