// CSS cubic-bezier eğrisinin değeri: zamanın oranı (0–1) → ilerleme. Animasyonları web'deki eğriyle birebir oynatmak
// için (açılış, kutlama, tanıtım). CSS'in hazır adları da burada.
extension Curve {
    public init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) { self.init(x1: x1, y1: y1, x2: x2, y2: y2) }

    public static let cssEase = Curve(0.25, 0.1, 0.25, 1)
    public static let easeIn = Curve(0.42, 0, 1, 1)
    public static let easeOut = Curve(0, 0, 0.58, 1)
    public static let easeInOut = Curve(0.42, 0, 0.58, 1)
    public static let linear = Curve(0, 0, 1, 1)

    /// t (0–1) anındaki ilerleme; aşan eğrilerde (yay) 1'i geçebilir
    public func value(at t: Double) -> Double {
        if t <= 0 { return 0 }
        if t >= 1 { return 1 }
        func bez(_ a: Double, _ b: Double, _ s: Double) -> Double {
            let u = 1 - s
            return 3 * u * u * s * a + 3 * u * s * s * b + s * s * s
        }
        func dbez(_ a: Double, _ b: Double, _ s: Double) -> Double {
            let u = 1 - s
            return 3 * u * u * a + 6 * u * s * (b - a) + 3 * s * s * (1 - b)
        }
        // x(s) = t çözümü: Newton, gerekirse ikiye bölme
        var s = t
        for _ in 0..<8 {
            let d = dbez(x1, x2, s)
            if abs(d) < 1e-6 { break }
            s -= (bez(x1, x2, s) - t) / d
        }
        if s < 0 || s > 1 || abs(bez(x1, x2, s) - t) > 1e-5 {
            var lo = 0.0, hi = 1.0
            s = t
            for _ in 0..<40 {
                if bez(x1, x2, s) < t { lo = s } else { hi = s }
                s = (lo + hi) / 2
            }
        }
        return bez(y1, y2, s)
    }

    /// Gecikmeli, belli sürede oynayan bir animasyonun o anki ilerlemesi (CSS animation-delay / duration, both)
    public func progress(_ time: Double, delay: Double, duration: Double) -> Double {
        value(at: (time - delay) / duration)
    }

    /// İlerlemenin ilk kez p'ye ulaştığı zaman oranı (0–1); ör. çevrilen kartta 90°'nin geçildiği an
    public func time(reaching p: Double) -> Double {
        var lo = 0.0, hi = 1.0
        for _ in 0..<50 {
            let mid = (lo + hi) / 2
            if value(at: mid) < p { lo = mid } else { hi = mid }
        }
        return hi
    }
}
