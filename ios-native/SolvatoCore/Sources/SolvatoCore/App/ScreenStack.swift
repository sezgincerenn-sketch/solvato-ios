// Ekranlar arası gezinme kuralları (web App.tsx setView / replaceView / goBack / kaydırarak geri).
// Basit bir yığın: sekmeler (Ana sayfa, İlerleme, Öğren, Profil) yığını sıfırlar; alt ekranlar üstüne eklenir; geri bir önceki
// ekrana döner. Sonuç ekranları yığına girmez: oradan geri dönünce turdan önceki ekrana dönülür.

public enum AppView: String, Sendable, CaseIterable {
    case home, dashboard, study
    case quiz, result, chordquiz, rhythmtap, settings, duel, games
    case gameDaily = "game-daily"
    case gameChallenge = "game-challenge"
    case gameresult, profile, lesson, teacher, privacy, licenses

    public var isTab: Bool { self == .home || self == .dashboard || self == .study || self == .profile }

    /// Telefonda yan çevrilebilen ekranlar (G-02)
    public var allowsLandscape: Bool { self == .quiz || self == .chordquiz }

    /// Kenardan kaydırınca bir önceki ekrana dönülen ekranlar. Turlarda (test, akor, Ritmi Tut, düello) kaydırma
    /// ekranı kaydırmaz, ekranın kendi geri düğmesi (çıkış onayı) çalışır.
    public var swipesBack: Bool {
        switch self {
        case .settings, .result, .games, .gameDaily, .gameChallenge, .gameresult, .lesson, .teacher, .privacy, .licenses: true
        default: false
        }
    }

    /// Kendi çıkış onayı olan tur ekranları: kenardan kaydırma onayı açar (ekran kaymaz)
    public var confirmsExit: Bool { self == .quiz || self == .chordquiz || self == .rhythmtap || self == .duel }
}

public struct ScreenStack: Equatable, Sendable {
    public private(set) var current: AppView = .home
    public private(set) var stack: [AppView] = []

    public init() {}

    /// Yeni ekrana git. Sekme yığını sıfırlar; sonuç ekranından gidilirse sonuç yığına girmez.
    public mutating func go(_ v: AppView) {
        if v.isTab {
            stack = []
        } else if current != .result && current != .gameresult && current != v {
            stack.append(current)
        }
        current = v
    }

    /// Bulunulan ekranın yerine geç (tur → sonuç)
    public mutating func replace(_ v: AppView) { current = v }

    /// Geri dönülecek ekran (kaydırırken altta görünen)
    public var backTarget: AppView { stack.last ?? .home }

    /// Bir önceki ekrana dön; dönülen ekranı verir (kaydırma konumu geri yüklenir)
    @discardableResult
    public mutating func back() -> AppView {
        current = stack.popLast() ?? .home
        return current
    }

    /// Kenardan kaydırma şu an geri götürür mü (açılış, tanıtım ya da kutlama açıkken hayır)
    public func canSwipeBack(overlayOpen: Bool) -> Bool { !overlayOpen && current.swipesBack }
}
