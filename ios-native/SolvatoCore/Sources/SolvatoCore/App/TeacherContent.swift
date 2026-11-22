// Öğretmen kodu ekranının kuralları: kodu uygulama, öğretmen tarafındaki seçimlerin başlangıcı ve konu seçimi.
// Web src/screens/TeacherScreen.tsx. Ekran Solvato/Screens/TeacherScreen.swift.
import Foundation

public enum TeacherFlow {
    public static let invalidMessage = "Kod geçersiz. 6 karakteri kontrol et."

    /// Kod kutusuna yazılan metin: büyük harf, en çok 7 karakter
    public static func sanitize(_ input: String) -> String {
        String(input.uppercased().prefix(7))
    }

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
