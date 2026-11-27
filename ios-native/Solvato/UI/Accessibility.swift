// VoiceOver duyuruları (0.8, docs/ozellikler/erisilebilirlik-ipad.md §2): cevap sonucu, süre, Ritmi Tut sonucu.
// VoiceOver kapalıyken hiçbir şey yapmaz; uygulama sesi kapalı olsa da çalışır (sistem sesi). Metinler SolvatoCore
// AccessibilityText'te (testli). Kullananlar: QuizScreen, ChordQuizScreen, RhythmTapScreen.
import SwiftUI
import UIKit

@MainActor
enum Announce {
    /// `high`: o an okunan yazıyı keser ve odak değişince kesilmez (cevap sonucu); değilse sıraya girer
    static func post(_ text: String, high: Bool = false) {
        guard UIAccessibility.isVoiceOverRunning, !text.isEmpty else { return }
        let s = NSAttributedString(
            string: text,
            attributes: [.accessibilitySpeechAnnouncementPriority: high ? UIAccessibilityPriority.high : UIAccessibilityPriority.default])
        UIAccessibility.post(notification: .announcement, argument: s)
    }
}
