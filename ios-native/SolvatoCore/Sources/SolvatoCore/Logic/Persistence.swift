// Kalıcı depolama: ayarlar, istatistikler, tema, günün meydan okuması kayıtları, "yan çevir" ipucu, son açılan ders.
// Anahtar adları ve içerik biçimi web'deki localStorage ile aynı (README, CLAUDE.md: adlar değişmez).
// Her anahtar Application Support/Solvato altında bir dosya; dosyalar veri korumalı yazılır (telefon kilitliyken
// şifreli, açılmadan okunamaz). Son açılan ders iCloud yedeğine girmeyen alt klasörde. Ağ yok, hesap yok.
import Foundation

/// Anahtar → metin deposu (web localStorage gibi)
public protocol KeyValueStore: Sendable {
    func read(_ key: String) -> String?
    /// nil siler
    func write(_ key: String, _ value: String?)
}

/// Dosya tabanlı depo: her anahtar bir dosya, atomik ve veri korumalı yazılır
public struct FileStore: KeyValueStore {
    public let directory: URL
    /// Yedeğe girmeyen anahtarlar bu alt klasörde
    public let noBackupDirectory: URL
    public let noBackupKeys: Set<String>

    public init(directory: URL, noBackupKeys: Set<String> = [Persistence.lastLessonKey]) {
        self.directory = directory
        noBackupDirectory = directory.appendingPathComponent("NoBackup", isDirectory: true)
        self.noBackupKeys = noBackupKeys
        let fm = FileManager.default
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
        try? fm.createDirectory(at: noBackupDirectory, withIntermediateDirectories: true)
        #if canImport(Darwin)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var dir = noBackupDirectory
            try? dir.setResourceValues(values)
        #endif
    }

    /// Uygulamanın varsayılan klasörü: Application Support/Solvato
    public static func standard() -> FileStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return FileStore(directory: base.appendingPathComponent("Solvato", isDirectory: true))
    }

    public func url(for key: String) -> URL {
        (noBackupKeys.contains(key) ? noBackupDirectory : directory).appendingPathComponent(key, isDirectory: false)
    }

    public func read(_ key: String) -> String? {
        (try? Data(contentsOf: url(for: key))).map { String(decoding: $0, as: UTF8.self) }
    }

    public func write(_ key: String, _ value: String?) {
        let u = url(for: key)
        guard let value else {
            try? FileManager.default.removeItem(at: u)
            return
        }
        try? Data(value.utf8).write(to: u, options: Self.writeOptions)
    }

    /// Kilitliyken şifreli; uygulama arka plana geçip telefon kilitlenirken süren yazım yarım kalmaz (G-09; testli)
    public static let writeOptions: Data.WritingOptions = [.atomic, .completeFileProtectionUnlessOpen]
}

/// Uygulamanın kalıcı verileri, web'deki anahtar adları ve biçimleriyle
public struct Persistence: Sendable {
    public static let lastLessonKey = "solvato_last_lesson_v1"
    public static let rotateHintKey = "notalik_rotate_hint_v1"

    public let store: KeyValueStore
    public init(store: KeyValueStore = FileStore.standard()) { self.store = store }

    // MARK: Ayarlar (pianote_settings_v1)
    /// Kayıt yoksa ya da bozuksa varsayılanlar; eksik alanlar varsayılanla tamamlanır
    public func loadSettings() -> Settings {
        guard let raw = store.read(Settings.storageKey),
            let s = try? JSONDecoder().decode(Settings.self, from: Data(raw.utf8))
        else { return Settings() }
        return s
    }

    public func save(_ s: Settings) {
        guard let data = try? JSONEncoder().encode(s) else { return }
        store.write(Settings.storageKey, String(decoding: data, as: UTF8.self))
    }

    // MARK: İstatistikler (notausta_stats_v1)
    public func loadStats() -> AppStats {
        guard let raw = store.read(AppStats.storageKey), let j = try? JSON.parse(raw) else { return AppStats() }
        return AppStats(json: j)
    }

    public func save(_ s: AppStats) { store.write(AppStats.storageKey, s.json.serialized) }

    /// Ayarlar › İlerlemeyi sıfırla: istatistikler sıfırlanır. Ayarlar ve günün meydan okuması kayıtları kalır
    /// (Bilinen durum 2).
    public func resetProgress() {
        var s = AppStats()
        s.history = []
        s.dailyAccuracy = OrderedMap()
        save(s)
    }

    // MARK: Tema (pianote_theme_v1)
    public func loadTheme() -> ThemeMode { ThemeMode(stored: store.read(ThemeMode.storageKey)) }
    public func save(_ t: ThemeMode) { store.write(ThemeMode.storageKey, t.rawValue) }

    // MARK: Günün meydan okuması (notalik-daily)
    public func loadDaily() -> [String: DailyRecord] {
        guard let raw = store.read(Games.dailyStorageKey), let o = (try? JSON.parse(raw))?.object else { return [:] }
        var out: [String: DailyRecord] = [:]
        for e in o.entries {
            guard let date = e.value["date"]?.string, let c = e.value["correct"]?.int, let sec = e.value["sec"]?.int
            else { continue }
            out[e.key] = DailyRecord(date: date, correct: c, sec: sec, marks: e.value["marks"]?.string ?? "")
        }
        return out
    }

    /// Yalnız ilk deneme kaydedilir
    public func saveDaily(_ rec: DailyRecord) {
        var o = (store.read(Games.dailyStorageKey).flatMap { try? JSON.parse($0) })?.object ?? OrderedMap()
        guard o[rec.date] == nil else { return }
        o[rec.date] = .object(
            OrderedMap([
                ("date", .string(rec.date)), ("correct", .number(Double(rec.correct))), ("sec", .number(Double(rec.sec))),
                ("marks", .string(rec.marks)),
            ]))
        store.write(Games.dailyStorageKey, JSON.object(o).serialized)
    }

    public func dailyStreak(now: Now) -> Int { Games.dailyStreak(Set(loadDaily().keys), now: now) }

    // MARK: "Yan çevir" ipucu (notalik_rotate_hint_v1): kaç kez gösterildi, 99 = bir daha gösterme
    public func rotateHintCount() -> Int { store.read(Self.rotateHintKey).flatMap { Int($0) } ?? 0 }
    public func bumpRotateHint(done: Bool = false) {
        store.write(Self.rotateHintKey, String(done ? 99 : rotateHintCount() + 1))
    }

    // MARK: Çalışma'da son açılan ders (solvato_last_lesson_v1, yedeğe girmez)
    public func lastLesson() -> String? { store.read(Self.lastLessonKey) }
    public func setLastLesson(_ id: String) { store.write(Self.lastLessonKey, id) }
}
