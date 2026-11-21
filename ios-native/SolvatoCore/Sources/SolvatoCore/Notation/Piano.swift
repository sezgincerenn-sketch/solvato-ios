// Piyano klavyeleri: tuş listesi, konumlar, tuş durumu, renkler, yazılar. Web karşılıkları src/design/piano.ts (tek
// kaynak), components/piano/QuizPiano.tsx (soru turu: 1–3 oktav), MultiPiano.tsx (akor: Do3–Si4, çoklu seçim) ve
// QuizSession.tsx `noteKeyOf` + klavye penceresi. Tuşlar iki temada da gerçek piyano gibi (fildişi / abanoz);
// tema rengi kullanılmaz. SwiftUI tarafı yalnızca çizer ve dokunmayı iletir.

public enum KeyState: String, Sendable {
    case idle, hint, selected, correct, wrong, reveal
}

public struct KeyShadow: Equatable, Sendable {
    public var inset: Bool
    public var x: Double
    public var y: Double
    public var blur: Double
    public var color: RGBA
}

/// Bir tuşun görünüşü: dikey gradyan (üst → alt), kenarlık (nil = saydam), gölgeler (dış parıltı ve iç basma)
public struct KeyLook: Equatable, Sendable {
    public var top: RGBA
    public var bottom: RGBA
    public var border: RGBA?
    public var shadows: [KeyShadow]
}

public struct KeyLabel: Equatable, Sendable {
    /// Satırlar "\n" ile ("Orta\nDo")
    public var text: String
    public var size: Double
    public var weight: Int
    public var color: RGBA
}

public struct PianoKey: Equatable, Sendable {
    public var note: String
    public var octave: Int
    public var isBlack: Bool
    public var state: KeyState
    public var look: KeyLook
    public var labels: [KeyLabel]
    /// Erişilebilirlik adı ("Do tuşu", "Orta Do tuşu")
    public var accessibilityLabel: String?
    /// Dokununca verilen cevap ("Do", oktavlı klavyede "Do4")
    public var answer: String
    /// Siyah tuş: soldan uzaklık ve genişlik, klavye genişliğinin yüzdesi
    public var leftPct: Double?
    public var widthPct: Double?
    /// Akor klavyesi: seçili tuşta mor nokta
    public var dot = false
}

public enum Piano {
    /// Fildişi / abanoz tonları: gerçek piyano hissi için palet dışı, yalnızca klavyede (web pianoColors)
    public static let ivoryTop = RGBA(0xE8E4DC_FF)
    public static let ivoryBottom = RGBA(0xCEC8BA_FF)
    public static let ivoryEdge = RGBA(0x9A9080_FF)
    public static let ivoryLabel = RGBA(0x5A5040_FF)
    public static let ebonyTop = RGBA(0x1C1814_FF)
    public static let ebonyBottom = RGBA(0x0E0C0A_FF)
    public static let ebonyEdge = RGBA(0x0A0808_FF)
    public static let ebonyLabel = RGBA(0x9A9080_FF)

    static func p(_ c: PaletteColor) -> RGBA { c.rgba }
    static func glow(_ blur: Double, _ c: RGBA) -> KeyShadow { KeyShadow(inset: false, x: 0, y: 0, blur: blur, color: c) }
    static let press = KeyShadow(inset: true, x: 0, y: -4, blur: 0, color: RGBA(0x000000_26))

    /// Beyaz tuş (web whiteKeyStyle)
    public static func whiteLook(_ st: KeyState) -> KeyLook {
        switch st {
        case .hint:
            KeyLook(top: RGBA(0xFEF3C7_FF), bottom: p(.amber300), border: p(.amber500), shadows: [glow(18, p(.amber500).opacity(0.7)), press])
        case .selected:
            KeyLook(top: p(.violet300), bottom: p(.violet400), border: p(.violet500), shadows: [glow(14, p(.violet500).opacity(0.65)), press])
        case .correct:
            KeyLook(top: RGBA(0xD1FAE5_FF), bottom: p(.green300), border: p(.green500), shadows: [glow(16, p(.green500).opacity(0.7)), press])
        case .wrong:
            KeyLook(top: RGBA(0xFEE2E2_FF), bottom: p(.red300), border: p(.red500), shadows: [glow(16, p(.red500).opacity(0.65)), press])
        case .reveal:
            KeyLook(top: RGBA(0xD1FAE5_FF), bottom: p(.green300), border: p(.green500), shadows: [glow(20, p(.green500).opacity(0.8))])
        case .idle:
            KeyLook(
                top: ivoryTop, bottom: ivoryBottom, border: ivoryEdge,
                shadows: [KeyShadow(inset: true, x: 0, y: -5, blur: 0, color: RGBA(0x000000_38))])
        }
    }

    /// Siyah tuş (web blackKeyStyle)
    public static func blackLook(_ st: KeyState) -> KeyLook {
        switch st {
        case .hint:
            KeyLook(top: RGBA(0xB45309_FF), bottom: p(.amber500), border: p(.amber500), shadows: [glow(16, p(.amber500).opacity(0.8))])
        case .selected:
            KeyLook(top: p(.violet600), bottom: p(.violet700), border: nil, shadows: [glow(14, p(.violet600).opacity(0.75))])
        case .correct, .reveal:
            KeyLook(
                top: RGBA(0x065F46_FF), bottom: p(.green600), border: p(.green500),
                shadows: [glow(st == .reveal ? 18 : 14, p(.green500).opacity(0.8))])
        case .wrong:
            KeyLook(top: RGBA(0x7F1D1D_FF), bottom: p(.red600), border: p(.red500), shadows: [glow(14, p(.red500).opacity(0.8))])
        case .idle:
            KeyLook(
                top: ebonyTop, bottom: ebonyBottom, border: ebonyEdge,
                shadows: [
                    KeyShadow(inset: true, x: -2, y: -5, blur: 0, color: RGBA(0x000000_80)),
                    KeyShadow(inset: true, x: 2, y: 0, blur: 0, color: RGBA(0xFFFFFF_0F)),
                ])
        }
    }

    /// Tuş yazısının rengi (web keyLabelColor)
    public static func labelColor(_ st: KeyState, black: Bool) -> RGBA {
        switch st {
        case .correct, .reveal: black ? p(.white) : RGBA(0x065F46_FF)
        case .wrong: black ? p(.white) : RGBA(0x7F1D1D_FF)
        case .selected: black ? p(.white) : p(.violet900)
        default: black ? ebonyLabel : ivoryLabel
        }
    }

    static let whiteNotes = ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"]
    static let blackNotes: [(note: String, whiteIdx: Int)] = [("Do#", 0), ("Re#", 1), ("Fa#", 3), ("Sol#", 4), ("La#", 5)]
    static let kbNames = ["Do", "Do#", "Re", "Re#", "Mi", "Fa", "Fa#", "Sol", "Sol#", "La", "La#", "Si"]
    static let letterPc = [0, 2, 4, 5, 7, 9, 11]

    // MARK: Soru turu klavyesi

    /// Notanın klavyedeki tam yeri: "Do#4" ve oktav (web noteKeyOf). Sol anahtarında y=90, Fa'da y=30 orta Do.
    public static func noteKey(_ q: Question) -> (key: String, octave: Int)? {
        guard let noteY = q.noteY, let clef = q.clef else { return nil }
        let idx = 28 + ((clef == .treble ? 90 : 30) - noteY) / 5
        let letter = ((idx % 7) + 7) % 7
        let oct = Int((Double(idx) / 7).rounded(.down))
        let midi = oct * 12 + letterPc[letter] + (q.accidental == .sharp ? 1 : q.accidental == .flat ? -1 : 0)
        let o = Int((Double(midi) / 12).rounded(.down))
        return ("\(kbNames[((midi % 12) + 12) % 12])\(o)", o)
    }

    /// Klavye penceresi: telefonda dikey 1 oktav, iPad 2, yan ekran 3. İki ve üç oktavda cevap oktavıyla alınır;
    /// Sol anahtarında Do4'ten, Fa'da Do2'den başlar, nota dışarıda kalırsa kayar.
    public static func window(for q: Question, octaves: Int) -> (start: Int, octaveMode: Bool) {
        let octaveMode = octaves >= 2 && q.category == .noteIdentification
        var start = q.clef == .bass ? 2 : octaves >= 3 ? 3 : 4
        if let t = noteKey(q) {
            if t.octave < start { start = t.octave } else if t.octave > start + octaves - 1 { start = t.octave - octaves + 1 }
        }
        if !octaveMode { start = 4 }
        return (start, octaveMode)
    }

    /// Klavyenin yüksekliği: CSS clamp(120px, 21vh / yan ekranda 38vh, 190px)
    public static func quizHeight(screenHeight: Double, tall: Bool) -> Double {
        min(190, max(120, screenHeight * (tall ? 0.38 : 0.21)))
    }

    /// Soru turu klavyesi (web QuizPiano). answerState: "pending" | "correct" | "wrong"
    public static func quizKeys(
        octaves: Int = 1, startOctave: Int? = nil, octaveMode: Bool = false, answerState: String,
        selectedNote: String? = nil, correctAnswer: String? = nil, hintNote: String? = nil, showLabels: Bool
    ) -> [PianoKey] {
        let startOct = startOctave ?? (octaves >= 2 ? 3 : 4)
        let whites = (0..<octaves).flatMap { o in whiteNotes.map { ($0, startOct + o) } }
        let wk = 100 / Double(whites.count)
        func state(_ note: String, _ oct: Int) -> KeyState {
            let name = octaveMode ? "\(note)\(oct)" : note
            if answerState == "pending" { return hintNote != nil && name == hintNote ? .hint : .idle }
            if name == selectedNote { return answerState == "correct" ? .correct : .wrong }
            if answerState == "wrong" && name == correctAnswer { return .reveal }
            return .idle
        }
        var keys: [PianoKey] = whites.map { note, oct in
            let st = state(note, oct)
            var labels: [KeyLabel] = []
            if octaveMode && note == "Do" && !showLabels {
                labels.append(KeyLabel(text: oct == 4 ? "Orta\nDo" : "Do\(oct)", size: oct == 4 ? 11 : 12, weight: 800, color: ivoryLabel))
            }
            if showLabels {
                let text = octaveMode && note == "Do" ? (oct == 4 ? "Orta Do" : "Do\(oct)") : note
                labels.append(KeyLabel(text: text, size: 14, weight: 700, color: labelColor(st, black: false)))
            }
            return PianoKey(
                note: note, octave: oct, isBlack: false, state: st, look: whiteLook(st), labels: labels,
                accessibilityLabel: octaveMode && note == "Do" && oct == 4 ? "Orta Do tuşu" : "\(note) tuşu",
                answer: octaveMode ? "\(note)\(oct)" : note)
        }
        for o in 0..<octaves {
            for b in blackNotes {
                let wi = b.whiteIdx + 7 * o
                let oct = whites[wi].1
                let st = state(b.note, oct)
                keys.append(
                    PianoKey(
                        note: b.note, octave: oct, isBlack: true, state: st, look: blackLook(st),
                        labels: showLabels
                            ? [KeyLabel(text: b.note.replacingOccurrences(of: "#", with: "♯"), size: 14, weight: 600, color: labelColor(st, black: true))]
                            : [],
                        accessibilityLabel: "\(b.note) tuşu", answer: octaveMode ? "\(b.note)\(oct)" : b.note,
                        leftPct: Double(wi + 1) * wk - wk * 0.32, widthPct: wk * 0.62))
            }
        }
        return keys
    }

    // MARK: Akor klavyesi (Do3–Si4)

    public static let multiHeight = 148.0
    public static let octaveMarkers = ["3. Oktav", "4. Oktav"]

    /// Akor klavyesi (web MultiPiano). lit: yalnız gösterim, oktavlı ("Do3"); yoksa seçim oktavsız ("Do")
    public static func multiKeys(selected: Set<String>, correctKeys: [String], showResult: Bool, lit: Set<String>? = nil) -> [PianoKey] {
        func state(_ note: String, _ oct: Int) -> KeyState {
            let sel = lit.map { $0.contains("\(note)\(oct)") } ?? selected.contains(note)
            if showResult {
                if correctKeys.contains(note) { return .correct }
                if sel { return .wrong }
            }
            return sel ? .selected : .idle
        }
        let whites = [3, 4].flatMap { o in whiteNotes.map { ($0, o) } }
        let wk = 100 / Double(whites.count)
        var keys: [PianoKey] = whites.map { note, oct in
            let st = state(note, oct)
            var look = whiteLook(st)
            if st == .idle { look.border = p(.slate800) }
            return PianoKey(
                note: note, octave: oct, isBlack: false, state: st, look: look,
                labels: note == "Do" ? [KeyLabel(text: "Do\(oct)", size: 12, weight: 700, color: labelColor(st, black: false))] : [],
                answer: note, dot: st == .selected)
        }
        for (i, b) in (blackNotes + blackNotes.map { ($0.note, $0.whiteIdx + 7) }).enumerated() {
            let oct = i < 5 ? 3 : 4
            let st = state(b.note, oct)
            keys.append(
                PianoKey(
                    note: b.note, octave: oct, isBlack: true, state: st, look: blackLook(st), labels: [], answer: b.note,
                    leftPct: Double(b.whiteIdx + 1) * wk - wk * 0.32, widthPct: wk * 0.62))
        }
        return keys
    }
}
