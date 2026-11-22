// Çalışma › Notalar dersleri: Sol/Fa anahtarı notaları (‹ › ile gezinme, porte, mini piyano), diyez ve bemol, ezber
// cümleleri. Web src/screens/study/NotesStudy.tsx, shared.tsx, data/accidentals.ts. Veri ve kurallar burada (altın
// tablo nota-dersleri.json); ekranlar Solvato/Screens/Lessons/NoteLessons.swift.
import Foundation

public struct StaffNoteRef: Equatable, Sendable {
    public let name: String
    public let y: Int
    public let ledger: [Int]
    public let label: String
    public let desc: String
}

public enum Accidentals {
    public static let symbol: [Accidental: String] = [.sharp: "♯", .flat: "♭"]
    /// Hangi doğal notalara diyez / bemol eklenebilir
    public static let sharpNames = ["Do", "Re", "Fa", "Sol", "La"]
    public static let flatNames = ["Re", "Mi", "Sol", "La", "Si"]
    static let sharpKey = ["Do": "Do#", "Re": "Re#", "Fa": "Fa#", "Sol": "Sol#", "La": "La#"]
    static let flatKey = ["Re": "Do#", "Mi": "Re#", "Sol": "Fa#", "La": "Sol#", "Si": "La#"]
    public static let letter = ["Do": "C", "Re": "D", "Mi": "E", "Fa": "F", "Sol": "G", "La": "A", "Si": "B"]

    /// Piyanodaki siyah tuş adı
    public static func key(_ name: String, _ acc: Accidental) -> String? { (acc == .sharp ? sharpKey : flatKey)[name] }

    /// "Do#" → "Do♯ / Re♭"
    public static func blackKeyLabel(_ key: String) -> String {
        let sharp = key.replacingOccurrences(of: "#", with: "♯")
        let order = ["Re", "Mi", "Sol", "La", "Si"]
        if let flat = order.first(where: { flatKey[$0] == key }) { return "\(sharp) / \(flat)♭" }
        return sharp
    }
}

public enum NoteStudy {
    public static let pianoOrder = ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"]
    public static let blackAfter = [0, 1, 3, 4, 5]
    static let trebleOctaves = [4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5]
    static let bassOctaves = [2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4]

    private static func r(_ n: String, _ y: Int, _ ledger: [Int], _ label: String, _ desc: String) -> StaffNoteRef {
        StaffNoteRef(name: n, y: y, ledger: ledger, label: label, desc: desc)
    }

    private static func r(_ n: String, _ y: Int, _ label: String, _ desc: String) -> StaffNoteRef { r(n, y, [], label, desc) }

    public static let treble: [StaffNoteRef] = [
        r("Do", 90, [90], "Do (C4)", "Alttaki 1. ek çizgi — Orta Do"),
        r("Re", 85, "Re (D4)", "1. çizgi altı"),
        r("Mi", 80, "Mi (E4)", "1. çizgi"),
        r("Fa", 75, "Fa (F4)", "1.–2. çizgi arası"),
        r("Sol", 70, "Sol (G4)", "2. çizgi — Anahtar çizgisi"),
        r("La", 65, "La (A4)", "2.–3. çizgi arası"),
        r("Si", 60, "Si (B4)", "3. (orta) çizgi"),
        r("Do", 55, "Do (C5)", "3.–4. çizgi arası"),
        r("Re", 50, "Re (D5)", "4. çizgi"),
        r("Mi", 45, "Mi (E5)", "4.–5. çizgi arası"),
        r("Fa", 40, "Fa (F5)", "5. çizgi"),
        r("Sol", 35, "Sol (G5)", "5. çizgi üstü"),
        r("La", 30, [30], "La (A5)", "Üstteki 1. ek çizgi"),
    ]

    public static let bass: [StaffNoteRef] = [
        r("Mi", 90, [90], "Mi (E2)", "Alttaki 1. ek çizgi"),
        r("Fa", 85, "Fa (F2)", "1. çizgi altı"),
        r("Sol", 80, "Sol (G2)", "1. çizgi"),
        r("La", 75, "La (A2)", "1.–2. çizgi arası"),
        r("Si", 70, "Si (B2)", "2. çizgi"),
        r("Do", 65, "Do (C3)", "2.–3. çizgi arası"),
        r("Re", 60, "Re (D3)", "3. (orta) çizgi"),
        r("Mi", 55, "Mi (E3)", "3.–4. çizgi arası"),
        r("Fa", 50, "Fa (F3)", "4. çizgi"),
        r("Sol", 45, "Sol (G3)", "4.–5. çizgi arası"),
        r("La", 40, "La (A3)", "5. çizgi"),
        r("Si", 35, "Si (B3)", "5. çizgi üstü"),
        r("Do", 30, [30], "Do (C4)", "Üstteki 1. ek çizgi — Orta Do"),
    ]

    public static func notes(_ clef: Clef) -> [StaffNoteRef] { clef == .treble ? treble : bass }
    public static func octaves(_ clef: Clef) -> [Int] { clef == .treble ? trebleOctaves : bassOctaves }
}

/// Notaları keşfet dersinin durumu (web StaffStudy): doğal notalar ya da ♯/♭ seçimiyle diyezli/bemollü notalar
public struct StaffStudyState: Equatable, Sendable {
    public let clef: Clef
    /// true: Diyez ve bemol dersi
    public let accidentalsMode: Bool
    public private(set) var acc: Accidental?
    /// Seçili notanın tablodaki sırası
    public private(set) var selected: Int

    public init(clef: Clef, accidentalsMode: Bool) {
        self.clef = clef
        self.accidentalsMode = accidentalsMode
        acc = accidentalsMode ? .sharp : nil
        selected = 0
        selected = list.first ?? 0
    }

    var notes: [StaffNoteRef] { NoteStudy.notes(clef) }
    var octaves: [Int] { NoteStudy.octaves(clef) }

    /// Gezilebilen notaların tablodaki sıraları
    public var list: [Int] {
        notes.indices.filter { i in
            guard let acc else { return true }
            return (acc == .sharp ? Accidentals.sharpNames : Accidentals.flatNames).contains(notes[i].name)
        }
    }

    public var pos: Int { max(0, list.firstIndex(of: selected) ?? 0) }
    public var note: StaffNoteRef { notes[selected] }
    public var octave: Int { octaves[selected] }

    /// "1/13"
    public var counter: String { "\(pos + 1)/\(list.count)" }

    /// ‹ › ile geçilen notanın sesi (web go: işaretliyse siyah tuş, "Re♭" → "Do#")
    public var playPitch: Pitch { Pitch(name: acc.flatMap { Accidentals.key(note.name, $0) } ?? note.name, octave: octave) }

    /// ‹ › ile bir önceki / sonraki nota (başa sarar)
    public mutating func go(_ delta: Int) {
        let l = list
        selected = l[(pos + delta + l.count) % l.count]
    }

    /// ♯ Diyez / ♭ Bemol seçimi: listenin ilk notasına geçer
    public mutating func setAcc(_ a: Accidental) {
        acc = a
        selected = list.first ?? 0
    }

    /// Mini piyanoda bu tuşa basınca bir notaya geçilebilir mi
    public func available(_ n: String, _ o: Int, sharp: Bool) -> Bool {
        notes.indices.contains { k in
            notes[k].name == n && octaves[k] == o && (!accidentalsMode ? !sharp : sharp && Accidentals.sharpNames.contains(n))
        }
    }

    /// Mini piyanoda bir tuşa basıldı (geçilemeyen tuş yalnız ses çalar)
    public mutating func pick(_ n: String, _ o: Int, sharp: Bool) {
        guard available(n, o, sharp: sharp), let i = notes.indices.first(where: { notes[$0].name == n && octaves[$0] == o }) else { return }
        if sharp { acc = .sharp }
        selected = i
    }

    /// Kutudaki kısa ad: "Do" ya da "Do♯"
    public var badge: String { note.name + (acc.flatMap { Accidentals.symbol[$0] } ?? "") }

    public var title: String {
        guard let acc, let s = Accidentals.symbol[acc] else { return note.label }
        return "\(note.name)\(s) (\(Accidentals.letter[note.name]!)\(s)\(octave))"
    }

    public var desc: String {
        guard let acc else { return note.desc }
        let key = Accidentals.key(note.name, acc) ?? ""
        return "\(note.name) notasının yarım ses \(acc == .sharp ? "üstü (yükseltir)" : "altı (alçaltır)"). Piyanoda siyah tuştur: \(Accidentals.blackKeyLabel(key))."
    }

    /// Mini piyanonun üstündeki ad ("Do" ya da "Do♯ / Re♭")
    public var keyName: String { acc.flatMap { Accidentals.key(note.name, $0) }.map(Accidentals.blackKeyLabel) ?? note.name }

    /// Mini piyanoda yanan tuş: (ad, oktav, siyah mı)
    public var highlighted: (name: String, octave: Int, black: Bool) {
        guard let acc, let key = Accidentals.key(note.name, acc) else { return (note.name, octave, false) }
        return (key.replacingOccurrences(of: "#", with: ""), octave, true)
    }

    /// Klavye anahtarın porte aralığını sabit gösterir: Sol Do4–Si5, Fa Do2–Do4
    public var startOctave: Int { clef == .treble ? 4 : 2 }
    public var whites: Int { clef == .treble ? 14 : 15 }

    public var hint: String {
        accidentalsMode
            ? "Bir siyah tuşa bas: o nota portede gösterilir."
            : "Bir beyaz tuşa bas: o nota portede gösterilir. Siyah tuşlar Diyez ve bemol dersinde."
    }

    /// Ekrandaki yazılar sırasıyla (altın tablo karşılaştırması için)
    public var texts: [String] {
        var t: [String] = accidentalsMode ? ["♯ Diyez", "♭ Bemol"] : []
        t += ["‹", counter, "Oklarla ya da piyanoda bir tuşa basarak gez", "›", badge, title, desc, "Piyanoda:", keyName]
        for i in 0..<whites {
            let n = NoteStudy.pianoOrder[i % 7]
            t.append(n == "Do" ? "\(n)\(startOctave + i / 7)" : n)
        }
        return t + [hint]
    }

    /// Mini piyano tuşlarının erişilebilirlik adları: önce beyazlar, sonra siyahlar ("Do#4")
    public var keyLabels: [String] {
        let w = (0..<whites).map { "\(NoteStudy.pianoOrder[$0 % 7])\(startOctave + $0 / 7)" }
        let b = (0..<(whites - 1)).filter { NoteStudy.blackAfter.contains($0 % 7) }.map {
            "\(NoteStudy.pianoOrder[$0 % 7])#\(startOctave + $0 / 7)"
        }
        return w + b
    }
}

// MARK: - Ezber cümleleri
public struct MnemonicCard: Equatable, Sendable {
    public let title: String
    public let notes: String
    public let letterColors: [PaletteColor]
    public let mnemonic: String
    /// [vurgulanan hece, kalan]
    public let words: [(String, String)]
    public let lines: Bool
    public let backDotColor: PaletteColor
    public let noteNames: [String]

    public static func == (a: MnemonicCard, b: MnemonicCard) -> Bool {
        a.title == b.title && a.noteNames == b.noteNames && a.words.map { [$0.0, $0.1] } == b.words.map { [$0.0, $0.1] }
    }

    /// Notanın rengi (web colorOf): nota adının rengi, yoksa kartın rengi
    public func color(_ i: Int) -> PaletteColor { NoteColors.byName[noteNames[i]] ?? backDotColor }

    public var cardTitle: String { lines ? "Çizgilerdeki notalar" : "Aralıklardaki notalar" }

    /// "Dinle": kartın notaları porte üzerindeki oktavlarıyla (web MemoCard octs), 260 ms arayla çalınır
    public func pitches(_ clef: Clef) -> [Pitch] {
        let octs = clef == .treble ? (lines ? [4, 4, 4, 5, 5] : [4, 4, 5, 5]) : lines ? [2, 2, 3, 3, 3] : [2, 3, 3, 3]
        return zip(noteNames, octs).map { Pitch(name: $0, octave: $1) }
    }
}

public enum Mnemonics {
    public static func cards(_ clef: Clef) -> [MnemonicCard] { clef == .treble ? treble : bass }

    static let treble = [
        MnemonicCard(
            title: "Çizgideki Notalar", notes: "Mi · Sol · Si · Re · Fa", letterColors: [.amber400, .green400, .violet400, .orange400, .lime400],
            mnemonic: "Misafir Sola Silgiyi Reçele Fırlattı", words: [("Mi", "safir"), ("Sol", "a"), ("Si", "lgiyi"), ("Re", "çele"), ("F", "ırlattı")],
            lines: true, backDotColor: .violet600, noteNames: ["Mi", "Sol", "Si", "Re", "Fa"]),
        MnemonicCard(
            title: "Aralıktaki Notalar", notes: "Fa · La · Do · Mi", letterColors: [.lime400, .blue400, .red400, .amber400],
            mnemonic: "Fare Lahanayı Dolapta Mideledi", words: [("Fa", "re"), ("La", "hanayı"), ("Do", "lapta"), ("Mi", "deledi")],
            lines: false, backDotColor: .amber500, noteNames: ["Fa", "La", "Do", "Mi"]),
    ]

    static let bass = [
        MnemonicCard(
            title: "Çizgideki Notalar", notes: "Sol · Si · Re · Fa · La", letterColors: [.green400, .violet400, .orange400, .lime400, .blue400],
            mnemonic: "Solucan Simit, Reçel, Fasulye, Lahana yedi",
            words: [("Sol", "ucan"), ("Si", "mit,"), ("Re", "çel,"), ("Fa", "sulye,"), ("La", "hana"), ("", "yedi")],
            lines: true, backDotColor: .violet600, noteNames: ["Sol", "Si", "Re", "Fa", "La"]),
        MnemonicCard(
            title: "Aralıktaki Notalar", notes: "La · Do · Mi · Sol", letterColors: [.blue400, .red400, .amber400, .green400],
            mnemonic: "Lacivert Dolapta Minik Solucan", words: [("La", "civert"), ("Do", "lapta"), ("Mi", "nik"), ("Sol", "ucan")],
            lines: false, backDotColor: .amber500, noteNames: ["La", "Do", "Mi", "Sol"]),
    ]

    /// Kartın portesi (web MemoCard svg, 300×118): renkli notalar, altında adları; aralık notalarında renkli bant
    public static func staff(_ card: MnemonicCard, clef: Clef) -> Drawing {
        let ys: [Double] = card.lines ? [80, 70, 60, 50, 40] : [75, 65, 55, 45]
        let x0 = 96.0
        let dx: Double = card.lines ? 44 : 52
        var items: [DrawItem] = []
        if !card.lines {
            for (i, y) in ys.enumerated() {
                items.append(.rect(x: x0 + Double(i) * dx - 18, y: y - 4.5, w: 36, h: 9, rx: 3, fill: .color(card.color(i).rgba.opacity(0.14))))
            }
        }
        for y in [40.0, 50, 60, 70, 80] { items.append(.line(x1: 44, y1: y, x2: 294, y2: y, stroke: .theme(.staffLine), width: 1.2)) }
        items.append(
            clef == .treble
                ? .glyph("gClef", x: 48, y: 70, fill: .theme(.notation), opacity: 0.85)
                : .glyph("fClef", x: 48, y: 50, fill: .theme(.notation), opacity: 0.85))
        for (i, y) in ys.enumerated() {
            let x = x0 + Double(i) * dx
            let c = Paint.color(card.color(i).rgba)
            if card.lines { items.append(.line(x1: x - 16, y1: y, x2: x + 16, y2: y, stroke: c, width: 2.4)) }
            items.append(.glyph("noteheadBlack", x: x - 5.9, y: y, fill: c))
            items.append(.text(card.noteNames[i], x: x, y: 106, size: 14, weight: 800, anchor: .middle, fill: c))
        }
        return Drawing(viewBox: (0, 0, 300, 118), items: items, sizing: .init())
    }

    /// Ekrandaki yazılar sırasıyla (altın tablo karşılaştırması için)
    public static func texts(_ clef: Clef) -> [String] {
        cards(clef).flatMap { c in
            [c.cardTitle, "Dinle"] + c.words.flatMap { [$0.0, $0.1].filter { !$0.isEmpty } } + NoteStudy.pianoOrder
        }
    }
}

/// Diyez ve bemol dersinin alt kısmı (web AccidentalMemo)
public enum AccidentalMemoContent {
    public static let sharpOrder = ["Fa", "Do", "Sol", "Re", "La", "Mi", "Si"]
    public static let flatOrder = ["Si", "Mi", "La", "Re", "Sol", "Do", "Fa"]
    public static let blackKeys = ["Do#", "Re#", "Fa#", "Sol#", "La#"]

    public static var texts: [String] {
        ["Diyez ♯ ve Bemol ♭", "Kural", "♯ diyez notayı yarım ses", "yükseltir", "(sağdaki tuşa), ♭ bemol", "alçaltır",
         "(soldaki tuşa). İşaret notanın önüne yazılır. Mi–Fa ve Si–Do arasında siyah tuş yoktur.", "Diyez ve bemol sırası"]
            + sharpOrder.map { $0 + "♯" } + flatOrder.map { $0 + "♭" }
            + ["Bemol sırası, diyez sırasının tersidir.", "Siyah tuşlar — dokun ve dinle", "Her siyah tuşun iki adı vardır (aynı ses)."]
            + blackKeys.map(Accidentals.blackKeyLabel)
    }
}
