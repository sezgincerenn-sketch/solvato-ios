// Ekranlar arası gezinme kuralları (web App.tsx setView / replaceView / goBack / kaydırarak geri).
// Basit bir yığın: sekmeler (Ana sayfa, İlerleme, Öğren, Profil) yığını sıfırlar; alt ekranlar üstüne eklenir; geri bir önceki
// ekrana döner. Sonuç ekranları yığına girmez: oradan geri dönünce turdan önceki ekrana dönülür.
// Ekranda (gezinme-cubugu.md): yığının sekmesi Apple'ın sekme çubuğunda, alt ekranlar o sekmenin gezinme yığınında
// (`navPath`, Apple'ın gezinme çubuğu ve "‹ Profil" geri düğmesiyle); turlar ve tur sonucu üstte tam ekran katman.

public enum AppView: String, Sendable, CaseIterable {
    case home, dashboard, study
    case quiz, result, chordquiz, rhythmtap, settings, duel, games
    case gameDaily = "game-daily"
    case gameChallenge = "game-challenge"
    case gameresult, profile, lesson, teacher, privacy, licenses
    /// Ayarlar › Çalışılacak notalar (ayarlar.md)
    case notes

    public var isTab: Bool { self == .home || self == .dashboard || self == .study || self == .profile }

    /// Telefonda yan çevrilebilen ekranlar (G-02)
    public var allowsLandscape: Bool { self == .quiz || self == .chordquiz }

    /// Ekranda geçen süre toplam çalışma süresine sayılır: soru turları (oyunlar dahil), akor turu, Ritmi Tut, akor
    /// düellosu ve dersler (kullanici-testi-revize.md madde 8)
    public var countsStudyTime: Bool {
        switch self {
        case .quiz, .chordquiz, .rhythmtap, .duel, .lesson: true
        default: false
        }
    }

    /// Kenardan kaydırınca bir önceki ekrana dönülen ekranlar. Turlarda (test, akor, Ritmi Tut, düello) ekran yine
    /// parmakla kayar ama geri dönülmez; bırakınca turun çıkış onayı açılır (R34).
    public var swipesBack: Bool {
        switch self {
        case .settings, .notes, .result, .games, .gameDaily, .gameChallenge, .gameresult, .lesson, .teacher, .privacy, .licenses: true
        default: false
        }
    }

    /// Gezinme çubuğu olmayan, sekmelerin üstünde tam ekran açılan ekranlar: turlar ve tur sonucu (gezinme-cubugu.md).
    /// Akor düellosu kurulumu çubuklu bir alt ekran; oyun başlayınca çubuk kendisi gizlenir.
    public var isFullScreen: Bool { self == .quiz || self == .chordquiz || self == .rhythmtap || self == .result }

    /// Gezinme çubuğundaki başlık; sonraki ekranın geri düğmesi de bu adı taşır ("‹ Profil"). Ders ve öğretmen kodu
    /// ekranının başlığı içeriğe göre değişir (dersin adı, TeacherSection.title); burada genel adları.
    /// Oyun sonucunda başlık yok: ekranın kendi büyük başlığı sonucu söyler ("Kazandın!").
    public var title: String {
        switch self {
        case .home: "Ana sayfa"
        case .dashboard: "İlerleme"
        case .study: "Öğren"
        case .profile: "Profil"
        case .settings: "Ayarlar"
        case .notes: "Çalışılacak notalar"
        case .games: "Oyunlar"
        case .gameDaily: "Günün meydan okuması"
        case .gameChallenge: "Arkadaşına meydan oku"
        case .gameresult: ""
        case .duel: "Akor düellosu"
        case .quiz: "Soru"
        case .chordquiz: "Akor"
        case .rhythmtap: "Ritmi Tut"
        case .result: "Tur sonucu"
        case .lesson: "Ders"
        case .teacher: "Öğretmen kodu"
        case .privacy: "Gizlilik"
        case .licenses: "Lisanslar"
        }
    }

    /// Kendi çıkış onayı olan tur ekranları: kenardan kaydırma ekranı kaydırır, bırakınca onay açılır (R34)
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

    /// Yığının ait olduğu sekme (alt menüde seçili olan): yığının dibindeki sekme, yoksa bulunulan sekme
    public var rootTab: AppView {
        if current.isTab { return current }
        if let first = stack.first, first.isTab { return first }
        return .home
    }

    /// Sekmenin gezinme yığınında sekmenin üstüne açılmış alt ekranlar, alttan üste (turlar ve tur sonucu girmez;
    /// tur açıkken altında turdan önceki ekran durur)
    public var navPath: [AppView] {
        (stack.dropFirst() + [current]).filter { !$0.isTab && !$0.isFullScreen }
    }

    /// Kenardan kaydırma şu an geri götürür mü (açılış, tanıtım ya da kutlama açıkken hayır)
    public func canSwipeBack(overlayOpen: Bool) -> Bool { !overlayOpen && current.swipesBack }
}
