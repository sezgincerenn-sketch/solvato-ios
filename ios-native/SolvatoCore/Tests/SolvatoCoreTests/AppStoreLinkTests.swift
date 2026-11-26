// R32: paylaşım mesajlarının sonundaki App Store bağlantısı; kod yapıştırmayı bozmamalı.
import XCTest
@testable import SolvatoCore

final class AppStoreLinkTests: XCTestCase {
    func testAppended() {
        XCTAssertEqual(AppStoreLink.url, "https://apps.apple.com/app/id6837820383")
        XCTAssertEqual(AppStoreLink.appended(to: "A"), "A\n\nSolvato'yu App Store'dan indir: https://apps.apple.com/app/id6837820383")
    }

    /// Mesajın tamamı yapıştırılsa da kod bulunur (bağlantı kod sanılmaz)
    func testPasteStillFindsCode() {
        let msg = AppStoreLink.appended(to: "ABCD-EFGH\n\nAyşe sana meydan okuyor!")
        XCTAssertEqual(GameScreens.pastedCode(msg), "ABCD-EFGH")
        XCTAssertEqual(TeacherFlow.pasted(AppStoreLink.appended(to: "ABC-DEF\n\n🎹 Solvato")), "ABC-DEF")
    }
}
