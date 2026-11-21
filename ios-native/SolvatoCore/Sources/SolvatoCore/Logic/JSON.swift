// Küçük, anahtar sırasını koruyan JSON okuyucu/yazıcı. Web'deki JS nesneleri anahtarları ekleme sırasıyla tutar ve
// bu sıra ekranda görünür (ör. eşit yüzdeli zorlandığın notalar); Foundation'ın JSONDecoder'ı sırayı korumaz.
// İstatistikler (AppStats) bu tiple okunup yazılır; çıktı JSON.stringify ile aynı biçimde.
import Foundation

public enum JSON: Equatable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSON])
    case object(OrderedMap<JSON>)

    // MARK: Okuma kolaylıkları
    public subscript(key: String) -> JSON? {
        if case let .object(o) = self { return o[key] }
        return nil
    }
    public var int: Int? {
        if case let .number(n) = self { return Int(exactly: n.rounded()) }
        return nil
    }
    public var double: Double? {
        if case let .number(n) = self { return n }
        return nil
    }
    public var string: String? {
        if case let .string(s) = self { return s }
        return nil
    }
    public var bool: Bool? {
        if case let .bool(b) = self { return b }
        return nil
    }
    public var array: [JSON]? {
        if case let .array(a) = self { return a }
        return nil
    }
    public var object: OrderedMap<JSON>? {
        if case let .object(o) = self { return o }
        return nil
    }

    /// Anahtar sırasına bakmadan eşitlik (testlerde)
    public func sameValue(_ other: JSON) -> Bool {
        switch (self, other) {
        case let (.object(a), .object(b)):
            return a.count == b.count && a.keys.allSatisfy { k in b[k].map { a[k]!.sameValue($0) } ?? false }
        case let (.array(a), .array(b)):
            return a.count == b.count && zip(a, b).allSatisfy { $0.sameValue($1) }
        default: return self == other
        }
    }
}

// MARK: - Sıralı sözlük
public struct OrderedMap<Value>: Sendable where Value: Sendable {
    public private(set) var keys: [String] = []
    private var storage: [String: Value] = [:]

    public init() {}
    public init(_ pairs: [(String, Value)]) { for (k, v) in pairs { self[k] = v } }

    public var count: Int { keys.count }
    public var isEmpty: Bool { keys.isEmpty }
    public var values: [Value] { keys.map { storage[$0]! } }
    public var entries: [(key: String, value: Value)] { keys.map { ($0, storage[$0]!) } }

    /// Yeni anahtar sona eklenir; var olanın yeri değişmez (JS nesnesi gibi). nil atamak siler.
    public subscript(key: String) -> Value? {
        get { storage[key] }
        set {
            if let newValue {
                if storage.updateValue(newValue, forKey: key) == nil { keys.append(key) }
            } else if storage.removeValue(forKey: key) != nil {
                keys.removeAll { $0 == key }
            }
        }
    }

    public func mapValues<T>(_ f: (Value) throws -> T) rethrows -> OrderedMap<T> {
        var out = OrderedMap<T>()
        for k in keys { out[k] = try f(storage[k]!) }
        return out
    }
}

extension OrderedMap: Equatable where Value: Equatable {
    public static func == (a: Self, b: Self) -> Bool { a.keys == b.keys && a.storage == b.storage }
}

// MARK: - Okuma
extension JSON {
    public struct ParseError: Error { public let offset: Int }

    public static func parse(_ text: String) throws -> JSON { try parse(Data(text.utf8)) }

    public static func parse(_ data: Data) throws -> JSON {
        var p = Parser(bytes: [UInt8](data))
        p.skipSpace()
        let v = try p.value()
        p.skipSpace()
        guard p.i == p.bytes.count else { throw ParseError(offset: p.i) }
        return v
    }

    private struct Parser {
        let bytes: [UInt8]
        var i = 0

        mutating func skipSpace() {
            while i < bytes.count, [0x20, 0x09, 0x0A, 0x0D].contains(bytes[i]) { i += 1 }
        }

        mutating func expect(_ s: String) throws {
            for b in s.utf8 {
                guard i < bytes.count, bytes[i] == b else { throw ParseError(offset: i) }
                i += 1
            }
        }

        mutating func value() throws -> JSON {
            guard i < bytes.count else { throw ParseError(offset: i) }
            switch bytes[i] {
            case UInt8(ascii: "{"):
                i += 1
                var o = OrderedMap<JSON>()
                skipSpace()
                if i < bytes.count, bytes[i] == UInt8(ascii: "}") {
                    i += 1
                    return .object(o)
                }
                while true {
                    skipSpace()
                    guard case let .string(k) = try value() else { throw ParseError(offset: i) }
                    skipSpace()
                    try expect(":")
                    skipSpace()
                    o[k] = try value()
                    skipSpace()
                    guard i < bytes.count else { throw ParseError(offset: i) }
                    if bytes[i] == UInt8(ascii: ",") { i += 1; continue }
                    try expect("}")
                    return .object(o)
                }
            case UInt8(ascii: "["):
                i += 1
                var a: [JSON] = []
                skipSpace()
                if i < bytes.count, bytes[i] == UInt8(ascii: "]") {
                    i += 1
                    return .array(a)
                }
                while true {
                    skipSpace()
                    a.append(try value())
                    skipSpace()
                    guard i < bytes.count else { throw ParseError(offset: i) }
                    if bytes[i] == UInt8(ascii: ",") { i += 1; continue }
                    try expect("]")
                    return .array(a)
                }
            case UInt8(ascii: "\""): return .string(try string())
            case UInt8(ascii: "t"): try expect("true"); return .bool(true)
            case UInt8(ascii: "f"): try expect("false"); return .bool(false)
            case UInt8(ascii: "n"): try expect("null"); return .null
            default:
                let start = i
                while i < bytes.count, "+-0123456789.eE".utf8.contains(bytes[i]) { i += 1 }
                guard let s = String(bytes: bytes[start..<i], encoding: .utf8), let n = Double(s) else {
                    throw ParseError(offset: start)
                }
                return .number(n)
            }
        }

        mutating func string() throws -> String {
            i += 1
            var out = [UInt8]()
            var units = [UInt16]()
            func flushUnits() {
                if !units.isEmpty {
                    out.append(contentsOf: Array(String(decoding: units, as: UTF16.self).utf8))
                    units.removeAll()
                }
            }
            while i < bytes.count {
                let b = bytes[i]
                if b == UInt8(ascii: "\"") {
                    i += 1
                    flushUnits()
                    return String(decoding: out, as: UTF8.self)
                }
                if b == UInt8(ascii: "\\") {
                    i += 1
                    guard i < bytes.count else { break }
                    let e = bytes[i]
                    i += 1
                    if e == UInt8(ascii: "u") {
                        guard i + 4 <= bytes.count, let s = String(bytes: bytes[i..<i + 4], encoding: .utf8),
                            let u = UInt16(s, radix: 16)
                        else { throw ParseError(offset: i) }
                        i += 4
                        units.append(u)
                        continue
                    }
                    flushUnits()
                    switch e {
                    case UInt8(ascii: "n"): out.append(0x0A)
                    case UInt8(ascii: "t"): out.append(0x09)
                    case UInt8(ascii: "r"): out.append(0x0D)
                    case UInt8(ascii: "b"): out.append(0x08)
                    case UInt8(ascii: "f"): out.append(0x0C)
                    default: out.append(e)  // \" \\ \/
                    }
                    continue
                }
                flushUnits()
                out.append(b)
                i += 1
            }
            throw ParseError(offset: i)
        }
    }
}

// MARK: - Yazma (JSON.stringify biçimi: boşluksuz)
extension JSON {
    public var serialized: String {
        var s = ""
        write(&s)
        return s
    }

    private func write(_ s: inout String) {
        switch self {
        case .null: s += "null"
        case let .bool(b): s += b ? "true" : "false"
        case let .number(n):
            if n.isFinite, n == n.rounded(), abs(n) < 1e15 { s += String(Int(n)) } else { s += "\(n)" }
        case let .string(str): JSON.quote(str, into: &s)
        case let .array(a):
            s += "["
            for (k, v) in a.enumerated() {
                if k > 0 { s += "," }
                v.write(&s)
            }
            s += "]"
        case let .object(o):
            s += "{"
            for (k, e) in o.entries.enumerated() {
                if k > 0 { s += "," }
                JSON.quote(e.key, into: &s)
                s += ":"
                e.value.write(&s)
            }
            s += "}"
        }
    }

    private static func quote(_ str: String, into s: inout String) {
        s += "\""
        for u in str.unicodeScalars {
            switch u {
            case "\"": s += "\\\""
            case "\\": s += "\\\\"
            case "\n": s += "\\n"
            case "\r": s += "\\r"
            case "\t": s += "\\t"
            case "\u{08}": s += "\\b"
            case "\u{0C}": s += "\\f"
            default:
                if u.value < 0x20 { s += String(format: "\\u%04x", u.value) } else { s.unicodeScalars.append(u) }
            }
        }
        s += "\""
    }
}
