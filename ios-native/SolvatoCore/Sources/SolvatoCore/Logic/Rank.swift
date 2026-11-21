// Ünvan (XP basamakları) ve tur yıldızları. Web karşılıkları src/utils/level.ts (RANKS, rankFromXp) ve src/utils/stars.ts.
// "Seviye" yalnızca Başlangıç / Orta / İleri; XP basamakları "ünvan".

public struct RankInfo: Equatable, Sendable {
    /// 1'den başlayan sıra
    public var rank: Int
    public var label: String
    public var nextLabel: String?
    public var nextAt: Int?
    public var toNext: Int
    public var pct: Int
}

public enum Ranks {
    public static let all: [(min: Int, label: String)] = [
        (0, "Yeni Başlayan"), (100, "Meraklı"), (300, "Nota Avcısı"), (600, "Çırak"), (1000, "Porte Gezgini"),
        (1500, "Ritim Tutan"), (2200, "Kulağı Açık"), (3000, "Kendinden Emin"), (4000, "Hızlı Okuyucu"),
        (5500, "Deşifreci"), (7500, "Solist"), (10000, "Maestro Adayı"), (13000, "Maestro"), (17000, "Virtüöz"),
        (22000, "Efsane"),
    ]

    public static func from(xp: Int) -> RankInfo {
        var i = 0
        for k in all.indices where xp >= all[k].min { i = k }
        let cur = all[i]
        let next = i + 1 < all.count ? all[i + 1] : nil
        return RankInfo(
            rank: i + 1,
            label: cur.label,
            nextLabel: next?.label,
            nextAt: next?.min,
            toNext: next.map { $0.min - xp } ?? 0,
            pct: next.map { jsRound(Double(xp - cur.min) / Double($0.min - cur.min) * 100) } ?? 100
        )
    }
}

public enum Stars {
    public static let steps: [Double] = [0.5, 0.7, 0.9]

    /// %90+ → 3 · %70+ → 2 · %50+ → 1 · altı → 0
    public static func forRound(correct: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        let r = Double(correct) / Double(total)
        return steps.filter { r >= $0 - 1e-9 }.count
    }

    /// Bir sonraki yıldız için gereken doğruluk; 3 yıldızda nil
    public static func nextHint(_ stars: Int) -> String? {
        stars >= 3 ? nil : "\(stars + 1). yıldız için %\(jsRound(steps[stars] * 100)) doğru yap"
    }
}

/// JS Math.round: .5 yukarı (negatiflerde de sıfıra değil +∞'a doğru)
public func jsRound(_ x: Double) -> Int { Int((x + 0.5).rounded(.down)) }
