// Ayarlar › Yardım ve destek ekranının metinleri: kısa sık sorulan sorular (kullanici-testi-revize.md madde 10). Ekran
// Solvato/Screens/HelpScreen.swift. Cevaplardaki kurallar uygulamanın kendi kurallarıyla aynı (testli): seri günlük hedefle
// artar, seviye son 50 soruda %80 doğruyla açılır, veriler yalnız telefonda.
import Foundation

public struct HelpItem: Equatable, Sendable {
    public let question: String
    public let answer: String
}

public enum HelpContent {
    public static let title = "Yardım ve destek"

    // MARK: Bize yaz
    public static let supportEmail = "solfado.destek@gmail.com"
    public static let mailTitle = "Bize yaz"
    public static let mailNote = "Bir sorun ya da önerin mi var? E-postayla yaz, en kısa sürede dönelim."
    public static let mailSubject = "Solfado destek"
    /// E-posta hesabı yoksa adres panoya kopyalanır
    public static let copied = "E-posta adresi kopyalandı"

    /// E-postanın gövdesi: yazı için boş satırlar, altta sürüm ve cihaz (sorunu bulmaya yardım eder)
    public static func mailBody(version: String, build: String, system: String, device: String) -> String {
        "\n\n\n—\nSolfado \(version) (\(build)) · \(device) · iOS \(system)"
    }

    public static let items: [HelpItem] = [
        HelpItem(
            question: "Günlük hedef ve seri nasıl işler?",
            answer:
                "Günlük hedefin, bir günde çözmek istediğin soru sayısı (10, 20 ya da 30). Hedefini tamamladığın her gün serin 1 artar; bir gün atlarsan seri yeniden başlar. Hedefini Ayarlar › Günlük hedef'ten değiştirebilirsin."
        ),
        HelpItem(
            question: "Seviyem nasıl yükselir?",
            answer:
                "Üç seviye var: Başlangıç, Orta ve İleri. Bulunduğun seviyede son \(Progress.levelNeed) sorunun en az %\(Int(Progress.levelAcc * 100))'ini doğru cevaplayınca bir üst seviye açılır. Seviyeni Ayarlar › Seviye'den kendin de seçebilirsin. Kazandığın XP ise ünvanını yükseltir."
        ),
        HelpItem(
            question: "Öğretmen kodu nedir, nasıl kullanılır?",
            answer:
                "Öğretmenin senin için konuları, seviyeyi, günlük hedefi ve notaları seçip bir kod hazırlar. Kodu Profil › Öğretmen kodu bölümüne yapıştırınca çalışman öğretmeninin seçtiği gibi ayarlanır. Öğretmensen aynı bölümden öğrencin için kod hazırlayabilirsin."
        ),
        HelpItem(
            question: "Haftalık raporu öğretmenime nasıl gönderirim?",
            answer:
                "Profil'in altındaki \"Haftalık raporu öğretmenine gönder\" düğmesine dokun (İlerleme'nin sağ üstündeki paylaş düğmesi de aynı raporu açar). Açılan menüden WhatsApp, Mesajlar ya da Mail'i seçip öğretmenine gönder."
        ),
        HelpItem(
            question: "Ses gelmiyor, ne yapmalıyım?",
            answer:
                "Ayarlar › Ses açık mı, bak. Solfado telefonun sessiz anahtarı açıkken de çalar; ses yine gelmiyorsa telefonun ses düzeyini yükselt."
        ),
        HelpItem(
            question: "Verilerim nerede, silinir mi?",
            answer:
                "İlerlemen ve ayarların yalnız bu telefonda saklanır, hiçbir yere gönderilmez. Uygulamayı silersen onlar da silinir. Baştan başlamak istersen Ayarlar › İlerlemeyi sıfırla."
        ),
    ]
}
