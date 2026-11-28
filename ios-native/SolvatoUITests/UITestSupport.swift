// UI testlerinin ortak yardımcıları: senaryoyla uygulamayı açma, öğe beklenmezse ekranı kaydetme, ekran görüntüsü ve
// sık kullanılan yollar (Pratik'ten bir ekrana gitme). Kullananlar: ScreenshotTests, AccessibilityTests, PerformanceTests.
import XCTest

extension XCTestCase {
    /// Senaryo verisiyle (senaryolar.json) hazırlanmış ama açılmamış uygulama. `extraArgs`: ör. yazı boyutu
    @MainActor
    func configuredApp(theme: String, scenario: String? = nil, designSystem: Bool = false, extraArgs: [String] = []) throws -> XCUIApplication {
        let app = XCUIApplication()
        // Ses motoru açılmaz: Codemagic simülatöründe ses servisi yanıt vermiyor (Audio.swift)
        app.launchArguments = ["-UITestTheme", theme, "-UITestNoAudio"] + (designSystem ? ["-UITestDesignSystem"] : []) + extraArgs
        if let scenario {
            // senaryolar.json: web referans senaryolarından döküldü (scripts/referans.mjs, `web-arsiv` dalı); artık elle düzenlenir
            let url = try XCTUnwrap(Bundle(for: ScreenshotTests.self).url(forResource: "senaryolar", withExtension: "json"))
            let all = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
            let sc = try XCTUnwrap((all["senaryolar"] as? [String: Any])?[scenario] as? [String: Any], scenario)
            let store = try JSONSerialization.data(withJSONObject: sc["store"] as Any)
            app.launchEnvironment["SOLVATO_SENARYO_STORE"] = String(decoding: store, as: UTF8.self)
            app.launchEnvironment["SOLVATO_SENARYO_SIMDI"] = all["simdi"] as? String
            app.launchEnvironment["SOLVATO_SENARYO_TOHUM"] = String(describing: all["tohum"] ?? "")
            app.launchEnvironment["SOLVATO_SENARYO_ACILIS"] = (sc["splash"] as? Bool) == true ? "1" : "0"
        }
        return app
    }

    @MainActor
    func launch(theme: String, scenario: String? = nil, designSystem: Bool = false, extraArgs: [String] = []) throws -> XCUIApplication {
        let app = try configuredApp(theme: theme, scenario: scenario, designSystem: designSystem, extraArgs: extraArgs)
        app.launch()
        return app
    }

    /// Öğe gelmezse o anki ekranı (ad: `<senaryo>-hata-<tema>`) ve erişilebilirlik ağacını kayda yazıp testi durdurur
    @MainActor
    func must(_ app: XCUIApplication, _ el: XCUIElement, _ msg: String, shot: String, timeout: Double = 10) throws {
        if el.waitForExistence(timeout: timeout) { return }
        snap(shot)
        print("── \(msg) · ekran ağacı ──\n\(app.debugDescription)")
        XCTFail(msg)
    }

    @MainActor
    func snap(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Alt menüde sekmeye dokunur ve seçildiğini doğrular. Simülatörde gezinme çubuğu yerleşirken sekme çubuğu kısa
    /// süre kayabiliyor; dokunuş komşu sekmeye düşerse yeniden dokunulur (gezinme-cubugu.md; telefonda sorun yok)
    @MainActor
    func tapTab(_ app: XCUIApplication, _ label: String) {
        let tab = app.tabBars.buttons[label].firstMatch
        _ = tab.waitForExistence(timeout: 5)
        // Dokunuş hep soldaki sekmeye düştüğü için her denemede biraz daha sağa
        for i in 0..<4 {
            tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + 0.25 * Double(i), dy: 0.5)).tap()
            Thread.sleep(forTimeInterval: 0.4)
            if tab.isSelected { return }
        }
    }

    /// Pratik'ten bir ekrana gider (goTo). Ekranlar: pratik, ilerleme, ogren, ders, profil, ayarlar, oyunlar, soru, akor,
    /// ritmi-tut. Ekran gelmezse false.
    @MainActor
    @discardableResult
    func goTo(_ app: XCUIApplication, _ screen: String) -> Bool {
        guard app.buttons["Profil"].waitForExistence(timeout: 10) else { return false }
        func tapLabel(_ prefix: String, scroll: Bool = true) -> Bool {
            let b = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
            if scroll { for _ in 0..<8 where !(b.exists && b.isHittable) { app.swipeUp(velocity: .slow) } }
            guard b.waitForExistence(timeout: 5) else { return false }
            b.tap()
            Thread.sleep(forTimeInterval: 0.6)
            return true
        }
        switch screen {
        case "pratik": return true
        case "ilerleme":
            tapTab(app, "İlerleme")
        case "ogren": tapTab(app, "Öğren")
        case "ders":
            tapTab(app, "Öğren")
            return tapLabel("Sol anahtarı notaları")
        case "profil": tapTab(app, "Profil")
        case "ayarlar":
            tapTab(app, "Profil")
            Thread.sleep(forTimeInterval: 0.5)
            return tapLabel("Ayarlar", scroll: false)
        case "oyunlar": return tapLabel("Oyunlar")
        case "soru":
            let card = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sol Anahtarı'")).firstMatch
            for _ in 0..<6 where !(card.exists && card.isHittable) { app.swipeUp(velocity: .slow) }
            card.tap()
            return app.buttons["Turdan çık"].waitForExistence(timeout: 5)
        case "akor":
            guard tapLabel("Akor") else { return false }
            return app.buttons["Turdan çık"].waitForExistence(timeout: 5)
        case "ritmi-tut":
            guard tapLabel("Ritmi Tut") else { return false }
            return app.buttons["Turdan çık"].waitForExistence(timeout: 5)
        default: return false
        }
        Thread.sleep(forTimeInterval: 0.6)
        return true
    }

    /// Ekranın senaryosu (senaryolar.json): ekran görüntüsü testlerindeki verilerle aynı
    func scenario(for screen: String) -> String {
        [
            "pratik": "pratik", "ilerleme": "ilerleme", "ogren": "calisma", "ders": "ders-notes-treble", "profil": "profil",
            "ayarlar": "ayarlar", "oyunlar": "oyunlar", "soru": "soru-nota", "akor": "akor", "ritmi-tut": "ritmi-tut",
        ][screen] ?? "pratik"
    }
}
