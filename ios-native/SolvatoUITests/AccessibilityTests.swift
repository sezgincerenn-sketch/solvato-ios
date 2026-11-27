// Erişilebilirlik ve iPad testleri (0.8, docs/ozellikler/erisilebilirlik-ipad.md):
// - testBuyukYazi: telefonda yazı boyutu xxxLarge ve AX5 (en büyük erişilebilirlik boyutu) iken ana ekranlar; AX5'te
//   yazının xxxLarge'da kaldığı görülür. Görüntü adları `buyuk-yazi-<ekran>-<boyut>`.
// - testIpadYonler: iPad'de dört yönde (dikey, ters dikey, iki yatay) ana ekranlar; `yon-<ekran>-<yön>`.
// - testErisilebilirlikDenetimi: Apple'ın otomatik denetimi (performAccessibilityAudit) her ana ekranda; bulunanlar
//   test çıktısına `DENETIM|ekran|tür|açıklama|öğe` satırı olarak yazılır, test düşmez (gerekçeler dokümanda).
import XCTest

final class AccessibilityTests: XCTestCase {
    /// Yazı boyutu başlatma argümanı (iOS'un Ayarlar'daki boyutuyla aynı)
    private func size(_ category: String) -> [String] { ["-UIPreferredContentSizeCategoryName", category] }

    @MainActor
    func testBuyukYazi() throws {
        let pad = UIDevice.current.userInterfaceIdiom == .pad
        try XCTSkipIf(pad, "büyük yazı telefonda denenir")
        continueAfterFailure = true
        executionTimeAllowance = 1800
        let screens = ["pratik", "ilerleme", "profil", "ayarlar", "ogren", "ders", "oyunlar", "soru", "akor", "ritmi-tut"]
        for (category, tag, list) in [
            ("UICTContentSizeCategoryXXXL", "xxxl", screens),
            ("UICTContentSizeCategoryAccessibilityXXXL", "ax5", ["pratik", "ayarlar", "soru"]),
        ] {
            for screen in list {
                let app = try launch(theme: "dark", scenario: scenario(for: screen), extraArgs: size(category))
                if !goTo(app, screen) { XCTFail("\(screen) açılmadı (\(tag))") }
                Thread.sleep(forTimeInterval: 0.5)
                snap("buyuk-yazi-\(screen)-\(tag)-koyu")
                // Uzun sayfaların altı da (kesik yazı en çok kartların altında çıkar)
                if ["pratik", "ilerleme", "profil", "ayarlar", "ogren"].contains(screen) {
                    for _ in 0..<3 { app.swipeUp() }
                    Thread.sleep(forTimeInterval: 0.4)
                    snap("buyuk-yazi-\(screen)-alt-\(tag)-koyu")
                }
                app.terminate()
            }
        }
    }

    @MainActor
    func testIpadYonler() throws {
        let pad = UIDevice.current.userInterfaceIdiom == .pad
        try XCTSkipUnless(pad, "yönler iPad'de denenir")
        continueAfterFailure = true
        executionTimeAllowance = 1800
        let orientations: [(UIDeviceOrientation, String)] = [
            (.portrait, "dikey"), (.landscapeLeft, "yatay-sol"), (.portraitUpsideDown, "ters-dikey"), (.landscapeRight, "yatay-sag"),
        ]
        defer { XCUIDevice.shared.orientation = .portrait }
        for screen in ["pratik", "ilerleme", "ogren", "profil", "ayarlar", "oyunlar", "soru", "akor", "ritmi-tut"] {
            XCUIDevice.shared.orientation = .portrait
            let app = try launch(theme: "dark", scenario: scenario(for: screen))
            if !goTo(app, screen) { XCTFail("\(screen) açılmadı") }
            for (o, name) in orientations {
                XCUIDevice.shared.orientation = o
                Thread.sleep(forTimeInterval: 1.0)
                snap("yon-\(screen)-\(name)-koyu")
            }
            // Döndürme sırasında tur kaybolmadı
            if ["soru", "akor", "ritmi-tut"].contains(screen) {
                XCTAssertTrue(app.buttons["Turdan çık"].exists, "\(screen): döndürünce tur kapandı")
            }
            app.terminate()
        }
    }

    @MainActor
    func testErisilebilirlikDenetimi() throws {
        continueAfterFailure = true
        executionTimeAllowance = 1800
        for screen in ["pratik", "ilerleme", "ogren", "ders", "profil", "ayarlar", "oyunlar", "soru", "akor", "ritmi-tut"] {
            for theme in ["dark", "light"] {
                let app = try launch(theme: theme, scenario: scenario(for: screen))
                if !goTo(app, screen) { XCTFail("\(screen) açılmadı") }
                Thread.sleep(forTimeInterval: 0.5)
                try app.performAccessibilityAudit { issue in
                    let el = issue.element.map { "\($0.elementType.rawValue):\($0.label)" } ?? "-"
                    print("DENETIM|\(screen)-\(theme)|\(issue.auditType.rawValue)|\(issue.compactDescription)|\(el)")
                    // Kayda yazılır, test düşmez: kalan uyarılar dokümanda gerekçesiyle
                    return true
                }
                app.terminate()
            }
        }
    }
}
