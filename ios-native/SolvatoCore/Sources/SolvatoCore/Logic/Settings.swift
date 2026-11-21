// Kullanıcı ayarları. Web karşılığı src/utils/settings.ts: aynı alan adları, aynı varsayılanlar, aynı JSON biçimi
// (depolama anahtarı `pianote_settings_v1`). Kayıtta eksik alan varsa varsayılan kullanılır.
import Foundation

public let allNotes = ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"]

public struct LevelProgress: Codable, Equatable, Sendable {
    public var n: Int
    public var c: Int
    public init(n: Int, c: Int) {
        self.n = n
        self.c = c
    }
}

public enum ClefChoice: String, Codable, Sendable, CaseIterable {
    case treble, bass, both
}

public enum InputMode: String, Codable, Sendable {
    case piano, choice
}

public struct Settings: Codable, Equatable, Sendable {
    public static let storageKey = "pianote_settings_v1"

    /// Tüm sesler (tuş, doğru/yanlış, kutlama)
    public var soundKeys = true
    /// Nota sorularında çıkacak notalar (öğretmen önerisi); varsayılan hepsi
    public var notes = allNotes
    /// Zaman yarışı: soru başına süre
    public var timer = false
    public var haptics = true
    public var reminder = false
    public var reminderHour = 20
    public var onboarded = false
    public var inputMode = InputMode.piano
    /// Piyano tuşlarında nota adları
    public var keyLabels = false
    /// Günde çözülecek soru
    public var dailyGoal = 10
    /// Soru seviyesi: 1 Başlangıç, 2 Orta, 3 İleri
    public var level = 1
    /// Karışık turlarda hangi anahtar
    public var clef = ClefChoice.both
    /// Mevcut seviyede çözülen ve doğru bilinen soru sayısı (seviye atlamak için)
    public var levelProgress = LevelProgress(n: 0, c: 0)
    public var name = ""
    /// Profil rengi (palet adı)
    public var avatarColor = "violet"
    /// İlk açılış (YYYY-MM-DD)
    public var joinedAt = ""
    /// Ana sayfa tanıtımı gösterildi
    public var coachDone = false
    /// Son uygulanan öğretmen kodu, yoksa ""
    public var teacherCode = ""
    /// Öğretmenin seçtiği konular (TeacherCode.topics); boş = hepsi
    public var topics: [String] = []

    public init() {}

    private enum Keys: String, CodingKey {
        case soundKeys, notes, timer, haptics, reminder, reminderHour, onboarded, inputMode, keyLabels, dailyGoal
        case level, clef, levelProgress, name, avatarColor, joinedAt, coachDone, teacherCode, topics
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        func get<T: Decodable>(_ k: Keys, _ def: T) -> T { (try? c.decodeIfPresent(T.self, forKey: k)) ?? def }
        let d = Settings()
        soundKeys = get(.soundKeys, d.soundKeys)
        notes = get(.notes, d.notes)
        timer = get(.timer, d.timer)
        haptics = get(.haptics, d.haptics)
        reminder = get(.reminder, d.reminder)
        reminderHour = get(.reminderHour, d.reminderHour)
        onboarded = get(.onboarded, d.onboarded)
        inputMode = get(.inputMode, d.inputMode)
        keyLabels = get(.keyLabels, d.keyLabels)
        dailyGoal = get(.dailyGoal, d.dailyGoal)
        level = get(.level, d.level)
        clef = get(.clef, d.clef)
        levelProgress = get(.levelProgress, d.levelProgress)
        name = get(.name, d.name)
        avatarColor = get(.avatarColor, d.avatarColor)
        joinedAt = get(.joinedAt, d.joinedAt)
        coachDone = get(.coachDone, d.coachDone)
        teacherCode = get(.teacherCode, d.teacherCode)
        topics = get(.topics, d.topics)
    }

    /// Akor turunun seviyesi (Uzman yalnız Çalışma'da)
    public var effectiveChordLevel: Int { min(level, 3) }
}
