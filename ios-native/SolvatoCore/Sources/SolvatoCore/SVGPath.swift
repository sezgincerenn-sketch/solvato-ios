// SVG yol metnini ("M12 2l3.09 6.26…") mutlak koordinatlı çizim komutlarına çevirir. Web'deki ikonlar, yıldız ve
// logo SVG yolu olarak yazılmış; native aynı metni okuyup aynı şekli çizer (arayüz katmanı komutları Path'e çevirir).
// Desteklenen komutlar: M L H V C S Q T A Z (büyük harf mutlak, küçük harf göreli). Yaylar kübik eğriye çevrilir.
import Foundation

public struct Point: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

public enum PathCommand: Equatable, Sendable {
    case move(Point)
    case line(Point)
    case cubic(Point, Point, Point)  // kontrol 1, kontrol 2, bitiş
    case quad(Point, Point)  // kontrol, bitiş
    case close
}

public enum SVGPathError: Error, Equatable {
    case unexpected(String)
}

public enum SVGPath {
    /// Yol metnini komutlara çevirir. Bozuk metinde hata verir (sessizce yanlış çizmez).
    public static func parse(_ d: String) throws -> [PathCommand] {
        var scanner = Tokens(Array(d.utf8))
        var out: [PathCommand] = []
        var current = Point(0, 0)
        var start = Point(0, 0)
        var lastCubic: Point?  // S için yansıtılacak kontrol noktası
        var lastQuad: Point?  // T için
        var command: UInt8 = 0

        while true {
            scanner.skipSeparators()
            guard let c = scanner.peek() else { break }
            if Tokens.isCommand(c) {
                command = c
                scanner.advance()
            } else if command == 0 {
                throw SVGPathError.unexpected(String(UnicodeScalar(c)))
            } else if command == UInt8(ascii: "M") {
                command = UInt8(ascii: "L")  // M'den sonra gelen sayılar çizgi
            } else if command == UInt8(ascii: "m") {
                command = UInt8(ascii: "l")
            }

            let relative = command >= UInt8(ascii: "a")
            let base = relative ? current : Point(0, 0)
            func point() throws -> Point {
                let x = try scanner.number()
                let y = try scanner.number()
                return Point(base.x + x, base.y + y)
            }

            switch command | 0x20 {  // küçük harfe indir
            case UInt8(ascii: "m"):
                current = try point()
                start = current
                out.append(.move(current))
            case UInt8(ascii: "l"):
                current = try point()
                out.append(.line(current))
            case UInt8(ascii: "h"):
                let n = try scanner.number()
                current = Point((relative ? current.x : 0) + n, current.y)
                out.append(.line(current))
            case UInt8(ascii: "v"):
                let n = try scanner.number()
                current = Point(current.x, (relative ? current.y : 0) + n)
                out.append(.line(current))
            case UInt8(ascii: "c"):
                let c1 = try point()
                let c2 = try point()
                current = try point()
                out.append(.cubic(c1, c2, current))
                lastCubic = c2
            case UInt8(ascii: "s"):
                let c1 = reflect(lastCubic, around: current)
                let c2 = try point()
                current = try point()
                out.append(.cubic(c1, c2, current))
                lastCubic = c2
            case UInt8(ascii: "q"):
                let c = try point()
                current = try point()
                out.append(.quad(c, current))
                lastQuad = c
            case UInt8(ascii: "t"):
                let c = reflect(lastQuad, around: current)
                current = try point()
                out.append(.quad(c, current))
                lastQuad = c
            case UInt8(ascii: "a"):
                let rx = try scanner.number()
                let ry = try scanner.number()
                let rotation = try scanner.number()
                let large = try scanner.flag()
                let sweep = try scanner.flag()
                let end = try point()
                out += arc(from: current, to: end, rx: rx, ry: ry, rotation: rotation, large: large, sweep: sweep)
                current = end
            case UInt8(ascii: "z"):
                out.append(.close)
                current = start
            default:
                throw SVGPathError.unexpected(String(UnicodeScalar(command)))
            }
            let lower = command | 0x20
            if lower != UInt8(ascii: "c") && lower != UInt8(ascii: "s") { lastCubic = nil }
            if lower != UInt8(ascii: "q") && lower != UInt8(ascii: "t") { lastQuad = nil }
            if lower == UInt8(ascii: "z") { command = 0 }
        }
        return out
    }

    private static func reflect(_ p: Point?, around c: Point) -> Point {
        guard let p else { return c }
        return Point(2 * c.x - p.x, 2 * c.y - p.y)
    }

    /// SVG yayı (uç nokta biçimi) → kübik eğriler. SVG 1.1 ek F.6'daki dönüşüm.
    static func arc(
        from p0: Point, to p1: Point, rx: Double, ry: Double, rotation: Double, large: Bool, sweep: Bool
    ) -> [PathCommand] {
        if p0 == p1 { return [] }
        var rx = abs(rx)
        var ry = abs(ry)
        if rx == 0 || ry == 0 { return [.line(p1)] }
        let phi = rotation * .pi / 180
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)
        let dx = (p0.x - p1.x) / 2
        let dy = (p0.y - p1.y) / 2
        let x1p = cosPhi * dx + sinPhi * dy
        let y1p = -sinPhi * dx + cosPhi * dy
        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 {
            rx *= lambda.squareRoot()
            ry *= lambda.squareRoot()
        }
        let num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
        let den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
        var coef = (max(0, num) / den).squareRoot()
        if large == sweep { coef = -coef }
        let cxp = coef * rx * y1p / ry
        let cyp = -coef * ry * x1p / rx
        let cx = cosPhi * cxp - sinPhi * cyp + (p0.x + p1.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + (p0.y + p1.y) / 2

        func angle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            atan2(ux * vy - uy * vx, ux * vx + uy * vy)
        }
        let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var delta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
        if !sweep && delta > 0 { delta -= 2 * .pi }
        if sweep && delta < 0 { delta += 2 * .pi }

        // Her parça en fazla 90°
        let segments = max(1, Int((abs(delta) / (.pi / 2) - 1e-9).rounded(.up)))  // yarım çember tam 2 parça
        let step = delta / Double(segments)
        let k = 4.0 / 3.0 * tan(step / 4)
        var result: [PathCommand] = []
        var t = theta1
        func onEllipse(_ a: Double) -> (Point, Point) {
            // nokta ve türev (birim adım için)
            let x = rx * cos(a)
            let y = ry * sin(a)
            let dxa = -rx * sin(a)
            let dya = ry * cos(a)
            let p = Point(cx + cosPhi * x - sinPhi * y, cy + sinPhi * x + cosPhi * y)
            let d = Point(cosPhi * dxa - sinPhi * dya, sinPhi * dxa + cosPhi * dya)
            return (p, d)
        }
        for i in 0..<segments {
            let (a, da) = onEllipse(t)
            let (b, db) = onEllipse(t + step)
            let end = i == segments - 1 ? p1 : b
            result.append(
                .cubic(
                    Point(a.x + k * da.x, a.y + k * da.y),
                    Point(b.x - k * db.x, b.y - k * db.y),
                    end
                ))
            t += step
        }
        return result
    }
}

/// Sayı ve komut harflerini sırayla okur
private struct Tokens {
    let bytes: [UInt8]
    var i = 0

    init(_ bytes: [UInt8]) { self.bytes = bytes }

    static func isCommand(_ c: UInt8) -> Bool {
        "MmLlHhVvCcSsQqTtAaZz".utf8.contains(c)
    }

    func peek() -> UInt8? { i < bytes.count ? bytes[i] : nil }
    mutating func advance() { i += 1 }

    mutating func skipSeparators() {
        while let c = peek(), c == UInt8(ascii: " ") || c == UInt8(ascii: ",") || c == 0x0A || c == 0x0D || c == 0x09 {
            i += 1
        }
    }

    /// Yay bayrağı: tek rakam (0/1), boşluksuz yazılabilir ("a2 2 0 011 1")
    mutating func flag() throws -> Bool {
        skipSeparators()
        guard let c = peek(), c == UInt8(ascii: "0") || c == UInt8(ascii: "1") else {
            throw SVGPathError.unexpected("yay bayrağı")
        }
        i += 1
        return c == UInt8(ascii: "1")
    }

    /// "-1.5", ".33", "1e-3"; "1.65.33" iki ayrı sayıdır
    mutating func number() throws -> Double {
        skipSeparators()
        let begin = i
        if let c = peek(), c == UInt8(ascii: "-") || c == UInt8(ascii: "+") { i += 1 }
        var sawDot = false
        var sawDigit = false
        while let c = peek() {
            if c >= UInt8(ascii: "0") && c <= UInt8(ascii: "9") {
                sawDigit = true
                i += 1
            } else if c == UInt8(ascii: ".") && !sawDot {
                sawDot = true
                i += 1
            } else {
                break
            }
        }
        if sawDigit, let c = peek(), c == UInt8(ascii: "e") || c == UInt8(ascii: "E") {
            i += 1
            if let s = peek(), s == UInt8(ascii: "-") || s == UInt8(ascii: "+") { i += 1 }
            while let c = peek(), c >= UInt8(ascii: "0") && c <= UInt8(ascii: "9") { i += 1 }
        }
        guard sawDigit, let value = Double(String(decoding: bytes[begin..<i], as: UTF8.self)) else {
            throw SVGPathError.unexpected("sayı (\(begin). karakter)")
        }
        return value
    }
}
