// Çalışma › Akor kartları dersi: kart içerikleri (ad, formül, parmak numaraları, akor yapısı, örnek diziler) ve kök
// filtresi. Web src/screens/study/ChordsStudy.tsx (`toDef`, `ChordsStudy`). Ekran Solvato/Screens/Lessons/ChordLessons.swift.
import Foundation

public struct ChordCardInfo: Sendable {
    public let chord: Chord
    /// Türkçe kök adı (Do, Re♭…)
    public let rootTR: String
    /// Türün adı, ilk harfi büyük (Majör, Minör 7…)
    public let nameTR: String
    /// Kök sembolü (C, D♭…): kök filtresi
    public let root: String
    public let fingering: String
    /// "4 + 3 yarım ses"
    public let interval: String
    public let progressions: [String]
    public let color: RGBA
    /// Çalma için tuş adları (Re♭ → Do#)
    public let playKeys: [String]

    nonisolated(unsafe) private static let suffix = try! NSRegularExpression(pattern: "(maj7|m7♭5|dim7|dim|aug|sus2|sus4|m7|m|7|9|13)$")

    public init(_ c: Chord) {
        chord = c
        let rootTR = String(c.name.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)[0])
        self.rootTR = rootTR
        let quality = String(c.name.dropFirst(rootTR.count + 1))
        nameTR = quality.prefix(1).uppercased(with: Locale(identifier: "tr")) + quality.dropFirst()
        let ns = c.symbol as NSString
        root = Self.suffix.stringByReplacingMatches(
            in: c.symbol, range: NSRange(location: 0, length: ns.length), withTemplate: "")
        fingering = ["1 – 3 – 5", "1 – 2 – 3 – 5", "1 – 2 – 3 – 4 – 5"][min(c.notes.count - 3, 2)]
        interval = zip(c.semis.dropFirst(), c.semis).map { "\($0 - $1)" }.joined(separator: " + ") + " yarım ses"
        progressions = Chords.progressions(c)
        let hex = Chords.qualityColor[c.quality].flatMap { UInt32($0.dropFirst(), radix: 16) }
        color = hex.map { RGBA($0 << 8 | 0xFF) } ?? PaletteColor.violet500.rgba
        playKeys = c.notes.map { Chords.pcKey[$0.pc] }
    }

    /// Parmak numaraları (kutucuklar)
    public var fingers: [String] { fingering.components(separatedBy: "–").map { $0.trimmingCharacters(in: .whitespaces) } }

    /// Tuş adı → akordaki yazımı (Re# → Mi♭)
    public var keyLabels: [String: String] { Dictionary(zip(playKeys, chord.noteNames), uniquingKeysWith: { a, _ in a }) }

    /// Kökten yarım ses uzaklığına göre aralığın adı
    public static func intervalName(_ semi: Int, _ quality: String) -> String {
        if semi == 9 && quality == "dim7" { return "eksik 7'li" }
        let names = [
            0: "Kök", 2: "2'li", 3: "küçük 3'lü", 4: "büyük 3'lü", 5: "4'lü", 6: "eksik 5'li", 7: "5'li", 8: "artık 5'li", 9: "6'lı",
            10: "küçük 7'li", 11: "büyük 7'li", 14: "9'lu", 21: "13'lü",
        ]
        return names[semi] ?? ""
    }

    public var intervalNames: [String] { chord.semis.map { Self.intervalName($0, chord.quality) } }

    /// Şerit klavyede yanan tuşların yazıları, ekrandaki sırayla (önce beyazlar, sonra siyahlar)
    public var stripLabels: [String] {
        let whites = ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"].filter { chord.keys.contains($0) }
        let blacks = ["Do#", "Re#", "Fa#", "Sol#", "La#"].filter { chord.keys.contains($0) }
        let l = keyLabels
        return (whites + blacks).map { l[$0] ?? $0 }
    }
}

public enum ChordStudy {
    public static let cards: [ChordCardInfo] = Chords.all.map(ChordCardInfo.init)

    public static func roots(level: Int) -> [String] {
        var seen: [String] = []
        for c in cards where c.chord.level == level && !seen.contains(c.root) { seen.append(c.root) }
        return seen
    }

    /// rootFilter: nil = açılış (ilk kök), "*" = Tümü
    public static func activeRoot(level: Int, rootFilter: String?) -> String? {
        rootFilter == "*" ? nil : (rootFilter ?? roots(level: level).first)
    }

    public static func filtered(level: Int, rootFilter: String?) -> [ChordCardInfo] {
        let active = activeRoot(level: level, rootFilter: rootFilter)
        return cards.filter { $0.chord.level == level && (active == nil || $0.root == active) }
    }

    /// Ekrandaki yazılar sırasıyla (altın tablo karşılaştırması için; web ChordsStudy, ders içinde seviye sabit)
    public static func texts(level: Int, rootFilter: String?) -> [String] {
        var t = ["Tümü"] + roots(level: level)
        for c in filtered(level: level, rootFilter: rootFilter) {
            t += ["\(c.rootTR) \(c.nameTR)", "(\(c.chord.symbol))", "Piyano Tuşları"] + c.stripLabels
            t += ["Formül", c.interval, "Parmak"] + c.fingers + ["Örnek diziler için çevir →"]
            t += ["Akor yapısı ve örnek diziler", "← geri", "Akor Yapısı"]
            for (n, iv) in zip(c.chord.noteNames, c.intervalNames) { t += [n] + (iv.isEmpty ? [] : [iv]) }
            t += ["\(c.chord.formula) · \(c.interval)", "Sık kullanılan diziler"]
            for (i, p) in c.progressions.enumerated() { t += ["\(i + 1)", p] }
            t += ["Arpej Dinle"]
        }
        return t
    }
}
