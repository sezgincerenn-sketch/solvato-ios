// "Bize yaz" (Ayarlar › Yardım ve destek, kullanici-testi-revize.md madde 10): telefonun e-posta penceresini destek
// adresi, "Solfado destek" konusu ve gövdede sürüm numarasıyla açar; gönderen kullanıcıdır, uygulama bir şey göndermez.
// Telefonda e-posta hesabı yoksa adres panoya kopyalanır (çağıran "E-posta adresi kopyalandı" der). Metinler HelpContent'te.
@preconcurrency import MessageUI
import SolvatoCore
import UIKit

@MainActor
enum MailSupport {
    /// E-posta penceresi açıldıysa true; açılamadıysa adres kopyalanır ve false
    static func compose() -> Bool {
        guard MFMailComposeViewController.canSendMail(), let top = Presenter.top() else {
            UIPasteboard.general.string = HelpContent.supportEmail
            return false
        }
        let info = Bundle.main.infoDictionary
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = MailDelegate.shared
        mail.setToRecipients([HelpContent.supportEmail])
        mail.setSubject(HelpContent.mailSubject)
        mail.setMessageBody(
            HelpContent.mailBody(
                version: info?["CFBundleShortVersionString"] as? String ?? "", build: info?["CFBundleVersion"] as? String ?? "",
                system: UIDevice.current.systemVersion, device: UIDevice.current.model),
            isHTML: false)
        top.present(mail, animated: true)
        return true
    }
}

/// Pencere gönderilince ya da vazgeçilince kapanır
@MainActor
private final class MailDelegate: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
    static let shared = MailDelegate()

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
