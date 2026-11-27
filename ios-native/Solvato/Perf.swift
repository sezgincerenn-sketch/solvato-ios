// Performans ölçümü için işaretler (0.8, erisilebilirlik-ipad.md §4): sekme geçişinin başı (sekmeye dokunma) ve sonu
// (yeni sayfanın görünmesi) os_signpost aralığı olarak yazılır; UI testi (SolvatoUITests/PerformanceTests) bunu
// XCTOSSignpostMetric ile ölçer. Cihaz dışına bir şey gitmez; kullanıcıya görünmez.
import os

@MainActor
enum Perf {
    static let subsystem = "com.solvato.app"
    static let category = "performans"
    private static let signposter = OSSignposter(subsystem: subsystem, category: category)
    private static var tab: OSSignpostIntervalState?

    /// Sekmeye dokunuldu
    static func beginTab() {
        if let s = tab { signposter.endInterval("sekme", s) }
        tab = signposter.beginInterval("sekme")
    }

    /// Yeni sekmenin sayfası göründü
    static func endTab() {
        guard let s = tab else { return }
        signposter.endInterval("sekme", s)
        tab = nil
    }
}
