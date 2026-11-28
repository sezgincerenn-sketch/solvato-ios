// App Store indirme bağlantısı (R32): paylaşım mesajlarının sonuna eklenir; alan kişi uygulamayı oradan indirir.
// Kullanıldığı yerler: oyun sonucu ve meydan okuma kodu, öğretmen kodu, haftalık rapor (AppButton, ProgressScreen, ProfileScreen).
import Foundation

public enum AppStoreLink {
    public static let appID = "6837820383"
    public static let url = "https://apps.apple.com/app/id\(appID)"
    public static let line = "Solfado'yu App Store'dan indir: \(url)"

    /// Paylaşılacak metin + boş satır + indirme bağlantısı
    public static func appended(to text: String) -> String { "\(text)\n\n\(line)" }
}
