// Ayarlar › Gizlilik ve Ayarlar › Lisanslar sayfalarının metinleri. Kaynak web src/data/legal.ts; `node scripts/altin.mjs`
// Resources/hukuk.json'a birebir aktarır (elle düzenlemeyin). Ekran Solvato/Screens/LegalScreen.swift.
import Foundation

public struct LegalSection: Decodable, Equatable, Sendable {
    public let title: String
    public let body: [String]
}

public struct License: Decodable, Equatable, Sendable {
    public let name: String
    public let use: String
    public let notice: String
    public let text: String?
}

public enum Legal {
    private struct File: Decodable {
        let privacy: [LegalSection]
        let licenses: [License]
    }

    private static let file: File = {
        guard let url = Bundle.module.url(forResource: "hukuk", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let f = try? JSONDecoder().decode(File.self, from: data)
        else { return File(privacy: [], licenses: []) }
        return f
    }()

    public static var privacy: [LegalSection] { file.privacy }
    /// Native sürüm yalnız yazı tiplerini kullanır: React ve Capacitor çıkar (özellik dokümanı E-14)
    public static let nativeLicenses = ["Bravura", "Outfit", "JetBrains Mono"]
    public static var licenses: [License] { file.licenses.filter { nativeLicenses.contains($0.name) } }
    public static let licensesIntro = "Solvato aşağıdaki açık kaynaklı yazı tiplerini ve yazılımları kullanır. Teşekkürler!"
}
