// UI testleri için senaryo: depolama, tarih ve rastgelelik sabit (web scripts/referans.mjs ile aynı veri, aynı an).
// UI testi senaryoyu ortam değişkeniyle verir; uygulama gerçek kayıtlara dokunmadan bellekte çalışır.
import Foundation

/// Bellekte anahtar → metin deposu (testler ve UI test senaryoları)
public final class MemoryStore: KeyValueStore, @unchecked Sendable {
    private var values: [String: String]
    private let lock = NSLock()

    public init(_ values: [String: String] = [:]) { self.values = values }

    public func read(_ key: String) -> String? { lock.withLock { values[key] } }
    public func write(_ key: String, _ value: String?) { lock.withLock { values[key] = value } }
}

public struct TestScenario: Sendable {
    /// Ortam değişkenleri: SOLVATO_SENARYO_STORE (anahtar → metin JSON), SOLVATO_SENARYO_SIMDI (ISO 8601),
    /// SOLVATO_SENARYO_TOHUM, SOLVATO_SENARYO_ACILIS ("1": açılış animasyonu gösterilsin)
    public static let storeKey = "SOLVATO_SENARYO_STORE"
    public static let nowKey = "SOLVATO_SENARYO_SIMDI"
    public static let seedKey = "SOLVATO_SENARYO_TOHUM"
    public static let splashKey = "SOLVATO_SENARYO_ACILIS"

    public var store: [String: String]
    public var now: Date
    public var seed: UInt32
    public var splash: Bool

    /// Ortamda senaryo yoksa nil (normal açılış)
    public init?(environment env: [String: String]) {
        guard let raw = env[Self.storeKey], let o = (try? JSON.parse(raw))?.object else { return nil }
        store = Dictionary(uniqueKeysWithValues: o.entries.compactMap { e in e.value.string.map { (e.key, $0) } })
        let f = ISO8601DateFormatter()
        now = env[Self.nowKey].flatMap { f.date(from: $0) } ?? Date()
        seed = env[Self.seedKey].flatMap { UInt32($0) } ?? 20_261_118
        splash = env[Self.splashKey] == "1"
    }

    /// Senaryonun uygulama durumu: bellekte depo, İstanbul saatiyle sabit an, tohumlu rastgelelik
    @MainActor
    public func makeModel() -> AppModel {
        let clock = DayClock(timeZone: TimeZone(identifier: "Europe/Istanbul")!)
        let now = self.now
        let m = AppModel(
            persistence: Persistence(store: MemoryStore(store)), random: seededRandom(seed), clock: { Now(now, clock: clock) })
        m.showSplash = splash
        return m
    }
}
