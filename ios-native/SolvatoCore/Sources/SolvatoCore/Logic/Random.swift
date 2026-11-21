// Rastgelelik: web'deki Math.random yerine dışarıdan verilen kaynak, oyunlar için tohumlu üreteç (games.ts `rng`).
// Aynı tohum React'ta ve burada aynı sayı dizisini verir; meydan okuma kodları iki sürüm arasında bu sayede çalışır.

/// 0 ≤ x < 1 arası sayı veren kaynak (web'de Math.random)
public typealias RandomSource = () -> Double

/// mulberry32: web `rng(seed)` ile bit bit aynı
public func seededRandom(_ seed: UInt32) -> RandomSource {
    var a = seed
    return {
        a = a &+ 0x6D2B_79F5
        var t = a
        t = (t ^ (t >> 15)) &* (t | 1)
        t ^= t &+ ((t ^ (t >> 7)) &* (t | 61))
        return Double(t ^ (t >> 14)) / 4_294_967_296
    }
}

/// Sistem rastgeleliği (uygulamada normal turlar için)
public func systemRandom() -> Double { Double.random(in: 0..<1) }

/// Fisher–Yates; web `shuffleArray` / `shuffleWith` ile aynı sırada aynı sayıları tüketir
public func shuffled<T>(_ arr: [T], _ r: RandomSource) -> [T] {
    var a = arr
    var i = a.count - 1
    while i > 0 {
        let j = Int((r() * Double(i + 1)).rounded(.down))
        a.swapAt(i, j)
        i -= 1
    }
    return a
}

/// Kararlı sıralama (JS Array.prototype.sort gibi): eşit öğeler yerini korur
func stableSorted<T>(_ arr: [T], by less: (T, T) -> Bool) -> [T] {
    arr.enumerated().sorted { a, b in
        if less(a.element, b.element) { return true }
        if less(b.element, a.element) { return false }
        return a.offset < b.offset
    }.map(\.element)
}
