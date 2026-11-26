// Öğretmen kodu ekranının kuralları: tanıtımdaki seçime göre görünen bölüm (tanitim.md R35), kodu uygulama, öğretmen
// tarafındaki seçimlerin başlangıcı ve konu seçimi. Web src/screens/TeacherScreen.tsx. Ekran Solvato/Screens/TeacherScreen.swift.
import Foundation

/// Öğretmen kodu ekranında görünen bölüm(ler); tanıtımdaki öğretmen sorusuna (teacherRole) göre
public enum TeacherSection: Equatable, Sendable {
    /// Yalnız kod girme (Evet, öğretmenim var)
    case enter
    /// Yalnız öğrenci kodu hazırlama (Ben öğretmenim)
    case prepare
    /// İkisi de (kendi kendime ya da soru atlandı)
    case both

    public init(_ role: TeacherRole) {
        switch role {
        case .student: self = .enter
        case .teacher: self = .prepare
        case .solo, .unset: self = .both
        }
    }

    public var showsEnter: Bool { self != .prepare }
    public var showsPrepare: Bool { self != .enter }

    /// Ekran başlığı (Profil'deki öğretmen kodu kartının başlığıyla aynı)
    public var title: String {
        switch self {
        case .enter: "Öğretmen kodunu gir"
        case .prepare: "Öğrenci kodu hazırla"
        case .both: "Öğretmen kodu"
        }
    }

    /// Üstteki açıklama
    public var intro: String {
        switch self {
        case .enter, .both:
            "Öğretmenin hangi notaları ve hangi seviyede çalışacağını bir kodla gönderir. Kodu girince uygulaman o ayarlarla kurulur."
        case .prepare: "Öğrencin için konu, seviye, hedef ve notaları seç; kodu WhatsApp ya da mesajla gönder."
        }
    }

    /// Altta diğer bölüme geçiş bağlantısı ve dokununca kaydedilecek rol; iki bölüm birden görünüyorsa yok
    public var switchLink: (text: String, role: TeacherRole)? {
        switch self {
        case .enter: ("Öğretmen misin? Öğrencin için kod hazırla", .teacher)
        case .prepare: ("Öğrenci misin? Öğretmeninin kodunu gir", .student)
        case .both: nil
        }
    }
}

public enum TeacherFlow {
    public static let invalidMessage = "Kod geçersiz. 6 karakteri kontrol et."

    /// Kod kutusuna yazılan metin: büyük harf, 6 karakter, üçüncüden sonra tire kendiliğinden (R31)
    public static func sanitize(_ input: String) -> String { formatCodeInput(input, length: 6, split: 3) }

    /// "Kodu yapıştır": panodaki metinden öğretmen kodu (R30)
    public static func pasted(_ text: String) -> String { codeFromPaste(text, length: 6, split: 3) }

    /// Öğretmen tarafı kendi ayarlarıyla dolu başlar; hedef listede yoksa 10
    public static func initialSetup(_ s: Settings) -> TeacherSetup {
        TeacherSetup(
            notes: s.notes, clef: s.clef, level: s.level,
            dailyGoal: TeacherCode.goals.contains(s.dailyGoal) ? s.dailyGoal : 10,
            keyLabels: s.keyLabels, topics: s.topics)
    }

    /// Kodu ayarlara uygular. Geçersizse nil. Seviye değişirse seviye ilerlemesi sıfırlanır.
    public static func apply(_ code: String, to s: inout Settings) -> (code: String, setup: TeacherSetup)? {
        guard let setup = TeacherCode.decode(code) else { return nil }
        let clean = TeacherCode.encode(setup)
        if setup.level != s.level { s.levelProgress = LevelProgress(n: 0, c: 0) }
        s.notes = setup.notes
        s.clef = setup.clef
        s.level = setup.level
        s.dailyGoal = setup.dailyGoal
        s.keyLabels = setup.keyLabels
        s.topics = setup.topics
        s.teacherCode = clean
        return (clean, setup)
    }

    /// "Hepsi" dışındaki bir konu çipine dokunma; hiç konu kalmazsa "Hepsi"ne döner, sıra listedeki sıradır
    public static func toggleTopic(_ key: String, in topics: [String]) -> [String] {
        let all = TeacherCode.allTopics(topics)
        let on = !all && topics.contains(key)
        let cur = all ? [] : topics
        let next = on ? cur.filter { $0 != key } : cur + [key]
        return TeacherCode.topics.map(\.key).filter { next.contains($0) }
    }

    public static func topicSelected(_ key: String, in topics: [String]) -> Bool {
        !TeacherCode.allTopics(topics) && topics.contains(key)
    }
}
