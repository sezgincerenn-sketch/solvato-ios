// Altın tablo yardımcıları: Fixtures/altin/*.json (scripts/altin.mjs çıktısı) okunur, React'ın verdiği sonuçla
// Swift'in sonucu karşılaştırılır. Fark çıkarsa ilk farklı yolu söyler.
import Foundation
import XCTest

@testable import SolvatoCore

enum Golden {
    static func load(_ name: String) throws -> JSON {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures/altin"), "\(name).json yok")
        return try JSON.parse(Data(contentsOf: url))
    }

    /// İki JSON arasındaki ilk fark (anahtar sırasına bakmaz); yoksa nil
    static func diff(_ a: JSON, _ b: JSON, path: String = "$") -> String? {
        switch (a, b) {
        case let (.object(x), .object(y)):
            for k in Set(x.keys).union(y.keys).sorted() {
                guard let xv = x[k] else { return "\(path).\(k): Swift'te yok" }
                guard let yv = y[k] else { return "\(path).\(k): React'ta yok" }
                if let d = diff(xv, yv, path: "\(path).\(k)") { return d }
            }
            return nil
        case let (.array(x), .array(y)):
            if x.count != y.count { return "\(path): uzunluk \(x.count) ≠ \(y.count)" }
            for (i, (xv, yv)) in zip(x, y).enumerated() { if let d = diff(xv, yv, path: "\(path)[\(i)]") { return d } }
            return nil
        default:
            return a == b ? nil : "\(path): \(a.serialized) ≠ \(b.serialized)"
        }
    }

    static func clock(_ tz: String) -> DayClock { DayClock(timeZone: TimeZone(identifier: tz)!) }
    static func now(_ ms: Int, _ tz: String) -> Now { Now(dateFromMs(ms), clock: clock(tz)) }
}

extension JSON {
    var strings: [String] { array?.compactMap(\.string) ?? [] }
    var ints: [Int] { array?.compactMap(\.int) ?? [] }
    var isNull: Bool { self == .null }
}
