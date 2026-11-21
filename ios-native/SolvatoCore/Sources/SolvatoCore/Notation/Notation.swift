// Küçük nota yazım dili ("ts:4/4 q q h ||") → çizim listesi. Web karşılığı src/components/Notation.tsx; hesaplar aynı
// sırayla yapılır ki koordinatlar bit bit tutsun. Dil:
//   w h q e s  nota · wr hr qr er sr  sus · ee ssss 3eee ess sse e.s ses  bağlı grup / triole
//   sonekler: . noktalı  ! staccato  > aksan  - tenuto  ^ fermata  @n n adım yukarı  d sap aşağı  x sap yanlış tarafta
//   önek/sonek # b diyez/bemol (sonek: yanlış yazım örneği) · ts:4/4 ts:C ts:¢ · | || · ~ süre bağı · ( … ) legato
//   = + ? · t:÷2 porte içi yazı · tx: tempo yazısı · end: sağ üst yazı · dyn:p dinamik · hair:< hair:> çatal
import Foundation

public enum NotationLayout {
    static let ink = Paint.theme(.notation)
    static let line = Paint.theme(.staffLine)
    static let accent = Paint.palette(.violet400)
    static let baseY = 65.0
    static var headW: Double { Smufl.width("noteheadBlack") }
    static var wholeW: Double { Smufl.width("noteheadWhole") }

    nonisolated(unsafe) static let singleRx = try! Regex(#"^([#b]?)(w|h|q|e|s)(\.?)([!>\-^]*)([dx]*)([#b]?)(?:@(-?[0-9]+))?$"#)
    nonisolated(unsafe) static let groupRx = try! Regex(#"^(3?)((?:[es]\.?){2,4})$"#)
    static let restKinds: [String: (String, Double)] = [
        "wr": ("restWhole", 50), "hr": ("restHalf", 60), "qr": ("restQuarter", 60), "er": ("rest8th", 60),
        "sr": ("rest16th", 60),
    ]
    static let dynGlyph: [Character: String] = [
        "p": "dynamicPiano", "m": "dynamicMezzo", "f": "dynamicForte", "s": "dynamicSforzando", "z": "dynamicZ",
    ]

    static func head(_ x: Double, _ y: Double, filled: Bool, whole: Bool = false) -> DrawItem {
        let name = whole ? "noteheadWhole" : filled ? "noteheadBlack" : "noteheadHalf"
        return .glyph(name, x: x - (whole ? wholeW : headW) / 2, y: y, fill: ink)
    }

    /// Sap: yukarıda sağda, aşağıda solda; wrongSide yazım kuralı sorularında ters taraf
    static func stemX(_ nx: Double, down: Bool, wrongSide: Bool = false) -> Double {
        let right = nx + headW / 2 - 0.65
        let left = nx - headW / 2 + 0.65
        return down != wrongSide ? left : right
    }

    static func cap(_ m: AnyRegexOutput, _ i: Int) -> String { m[i].substring.map(String.init) ?? "" }
    static func isDigits(_ s: String) -> Bool { !s.isEmpty && s.allSatisfy { ("0"..."9").contains($0) } }

    /// Web <Notation score maxW />
    public static func notation(_ score: String, maxW: Double? = nil) -> Drawing {
        var items: [DrawItem] = []
        var above: [DrawItem] = []
        var below: [DrawItem] = []
        var x = 18.0
        var lastNote: (x: Double, y: Double)?
        var tiePending = false
        var slurStart: (x: Double, y: Double)?
        var slurOpen = false
        var firstNoteX: Double?
        var lastNoteX = 0.0
        var tx: String?
        var endText: String?
        var dyn: String?
        var hair: String?

        func noteAt(_ nx: Double, _ ny: Double) {
            if tiePending, let ln = lastNote {
                let x1 = ln.x + 4
                let x2 = nx - 4
                let yy = max(ln.y, ny) + 8
                items.append(.path([.move(Point(x1, yy)), .quad(Point((x1 + x2) / 2, yy + 9), Point(x2, yy))], stroke: ink, width: 1.8))
                tiePending = false
            }
            if slurOpen && slurStart == nil { slurStart = (nx, ny) }
            lastNote = (nx, ny)
            if firstNoteX == nil { firstNoteX = nx }
            lastNoteX = nx
        }

        func single(_ tok: String) -> Bool {
            guard let m = try? singleRx.wholeMatch(in: tok)?.output else { return false }
            let pre = cap(m, 1), v = cap(m, 2), dot = cap(m, 3), arts = cap(m, 4), flags = cap(m, 5), post = cap(m, 6)
            let off = Double(Int(cap(m, 7)) ?? 0)
            let y = baseY - off * 5
            let down = flags.contains("d")
            func accG(_ c: String) -> String { c == "#" ? "accidentalSharp" : "accidentalFlat" }
            let preW = pre.isEmpty ? 0 : Smufl.width(accG(pre)) + 4
            let nx = x + 9 + preW
            let sx = stemX(nx, down: down, wrongSide: flags.contains("x"))
            let end = down ? y + 35 : y - 35
            var parts: [DrawItem] = [head(nx, y, filled: v != "w" && v != "h", whole: v == "w")]
            if !pre.isEmpty { parts.append(.glyph(accG(pre), x: nx - headW / 2 - 3 - Smufl.width(accG(pre)), y: y, fill: ink)) }
            if !post.isEmpty { parts.append(.glyph(accG(post), x: nx + headW / 2 + (down ? 3 : 6), y: y, fill: ink)) }
            if v != "w" { parts.append(.line(x1: sx, y1: down ? y + 1.5 : y - 1.5, x2: sx, y2: end, stroke: ink, width: 1.3)) }
            if v == "e" { parts.append(.glyph(down ? "flag8thDown" : "flag8thUp", x: sx - 0.65, y: end, fill: ink)) }
            if v == "s" { parts.append(.glyph(down ? "flag16thDown" : "flag16thUp", x: sx - 0.65, y: end, fill: ink)) }
            let onLine = y.truncatingRemainder(dividingBy: 10) == 0
            if !dot.isEmpty { parts.append(.circle(cx: nx + (v == "w" ? 14 : 11), cy: onLine ? y - 5 : y, r: 2, fill: ink)) }
            // İşaret, sapın karşı tarafında nota başının yanındaki ilk aralığa
            var by = down ? (onLine ? y - 15 : y - 10) : onLine ? y + 15 : y + 10
            for a in arts {
                let art: String? =
                    a == "!"
                    ? (down ? "articStaccatoAbove" : "articStaccatoBelow")
                    : a == ">"
                        ? (down ? "articAccentAbove" : "articAccentBelow")
                        : a == "-" ? (down ? "articTenutoAbove" : "articTenutoBelow") : nil
                if let art { parts.append(.glyph(art, x: nx - Smufl.width(art) / 2, y: by, fill: ink)) }
                if a == "^" { parts.append(.glyph("fermataAbove", x: nx - Smufl.width("fermataAbove") / 2, y: 30, fill: ink)) }
                by += down ? -10 : 10
            }
            noteAt(nx, y)
            items += parts
            let base: Double = v == "w" ? 32 : 28
            let dotAdd: Double = dot.isEmpty ? 0 : 8
            let postAdd = post.isEmpty ? 0 : Smufl.width(accG(post)) + 8
            x += base + dotAdd + preW + postAdd
            return true
        }

        func group(_ tok: String) -> Bool {
            guard let m = try? groupRx.wholeMatch(in: tok)?.output else { return false }
            let trip = cap(m, 1) == "3"
            var notes: [(v: Character, dot: Bool)] = []
            for c in cap(m, 2) {
                if c == "." { notes[notes.count - 1].dot = true } else { notes.append((c, false)) }
            }
            let n = notes.count
            let gap = 20.0
            let top = baseY - 33
            var xs: [Double] = []
            var gx = x + 8
            for nt in notes {
                xs.append(gx)
                gx += gap + (nt.dot ? 7 : 0)
            }
            func sx(_ i: Int) -> Double { stemX(xs[i], down: false) }
            var parts: [DrawItem] = []
            for (i, nx) in xs.enumerated() {
                parts.append(head(nx, baseY, filled: true))
                parts.append(.line(x1: sx(i), y1: baseY - 1.5, x2: sx(i), y2: top, stroke: ink, width: 1.3))
                if notes[i].dot { parts.append(.circle(cx: nx + 11, cy: baseY, r: 2, fill: ink)) }
                noteAt(nx, baseY)
            }
            func beam(_ x1: Double, _ x2: Double, _ row: Double) -> DrawItem {
                .rect(x: x1 - 0.65, y: top + row * 7.5, w: x2 - x1 + 1.3, h: 5, fill: ink)
            }
            parts.append(beam(sx(0), sx(n - 1), 0))
            let stub = 9.0
            for i in 0..<n where notes[i].v == "s" {
                let prevS = i > 0 && notes[i - 1].v == "s"
                let nextS = i < n - 1 && notes[i + 1].v == "s"
                if nextS {
                    parts.append(beam(sx(i), sx(i + 1), 1))
                } else if !prevS {
                    parts.append(i == 0 ? beam(sx(i), sx(i) + stub, 1) : beam(sx(i) - stub, sx(i), 1))
                }
            }
            if trip {
                parts.append(
                    .text("3", x: (xs[0] + xs[n - 1]) / 2 + 6, y: top - 6, size: 13, weight: 700, italic: true, anchor: .middle, font: .serif, fill: ink))
            }
            items += parts
            x = gx + 4
            return true
        }

        for raw in score.split(whereSeparator: { $0.isWhitespace }).map(String.init) {
            var tok = raw
            if tok.hasPrefix("(") {
                slurOpen = true
                slurStart = nil
                tok.removeFirst()
            }
            var closeSlur = false
            if tok.hasSuffix(")") && tok.utf16.count > 1 {
                closeSlur = true
                tok.removeLast()
            }
            if tok.isEmpty { continue }

            if tok.hasPrefix("ts:") {
                let v = String(tok.dropFirst(3))
                if v == "C" || v == "¢" {
                    let g = v == "C" ? "timeSigCommon" : "timeSigCutCommon"
                    items.append(.glyph(g, x: x + 2, y: 60, fill: ink))
                    x += Smufl.width(g) + 14
                } else {
                    let parts = v.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
                    let t = parts[0]
                    let b = parts.count > 1 ? parts[1] : ""
                    func wOf(_ s: String) -> Double {
                        isDigits(s) ? s.reduce(0.0) { $0 + Smufl.width("timeSig\($1)") } : 20
                    }
                    let W = max(wOf(t), wOf(b))
                    func digits(_ s: String, _ y: Double) {
                        guard isDigits(s) else {
                            items.append(.text(s, x: x + 10, y: y + 8, size: 24, weight: 800, anchor: .middle, fill: accent))
                            return
                        }
                        let ws = s.map { Smufl.width("timeSig\($0)") }
                        let total = ws.reduce(0, +)
                        var cx = x + (W - total) / 2
                        for (i, d) in s.enumerated() {
                            items.append(.glyph("timeSig\(d)", x: cx, y: y, fill: ink))
                            cx += ws[i]
                        }
                    }
                    digits(t, 50)
                    digits(b, 70)
                    x += W + 14
                }
            } else if tok == "|" || tok == "||" {
                if tok == "|" {
                    items.append(.line(x1: x + 4, y1: 40, x2: x + 4, y2: 80, stroke: ink, width: 1.5))
                } else {
                    items.append(.line(x1: x + 2, y1: 40, x2: x + 2, y2: 80, stroke: ink, width: 1.5))
                    items.append(.rect(x: x + 6, y: 40, w: 4.5, h: 40, fill: ink))
                }
                x += tok == "|" ? 14 : 16
            } else if tok == "~" {
                tiePending = true
            } else if tok == "=" || tok == "+" {
                items.append(.text(tok, x: x + 9, y: baseY + 7, size: 22, weight: 700, anchor: .middle, fill: accent))
                x += 22
            } else if tok == "?" {
                items.append(
                    .rect(x: x + 1, y: 47, w: 24, h: 26, rx: 7, fill: .color(PaletteColor.violet500.rgba.opacity(0.18)), stroke: accent, strokeWidth: 1.5))
                items.append(.text("?", x: x + 13, y: 66, size: 18, weight: 800, anchor: .middle, fill: accent))
                x += 32
            } else if tok.hasPrefix("t:") {
                let s = String(tok.dropFirst(2)).replacingOccurrences(of: "_", with: " ")
                items.append(.text(s, x: x + 2, y: baseY + 6, size: 17, weight: 700, fill: accent))
                x += Double(s.utf16.count * 10 + 8)
            } else if tok.hasPrefix("tx:") {
                tx = String(tok.dropFirst(3)).replacingOccurrences(of: "_", with: " ")
            } else if tok.hasPrefix("end:") {
                endText = String(tok.dropFirst(4)).replacingOccurrences(of: "_", with: " ")
            } else if tok.hasPrefix("dyn:") {
                dyn = String(tok.dropFirst(4))
            } else if tok.hasPrefix("hair:") {
                hair = String(tok.dropFirst(5))
            } else if let (name, ry) = restKinds[tok] {
                items.append(.glyph(name, x: x + 10 - Smufl.width(name) / 2, y: ry, fill: ink))
                x += 26
            } else if !group(tok) {
                _ = single(tok)
            }

            if closeSlur, let s0 = slurStart, let s1 = lastNote {
                let y0 = min(s0.y, s1.y) - 42
                items.append(
                    .path(
                        [.move(Point(s0.x + 4, s0.y - 38)), .quad(Point((s0.x + s1.x) / 2 + 4, y0 - 12), Point(s1.x + 6, s1.y - 38))],
                        stroke: ink, width: 1.8))
                slurOpen = false
                slurStart = nil
            }
        }

        let width = max(x + 10, 120)
        if let tx { above.append(.text(tx, x: 16, y: 22, size: 17, weight: 800, font: .serif, fill: ink)) }
        if let endText {
            above.append(.text(endText, x: width - 12, y: 28, size: 16, weight: 800, italic: true, anchor: .end, font: .serif, fill: ink))
        }
        let fx = firstNoteX ?? 20
        if let dyn {
            if dyn.allSatisfy({ dynGlyph[$0] != nil }) {
                var cx = fx - 4
                for c in dyn {
                    below.append(.glyph(dynGlyph[c]!, x: cx, y: 102, sp: 11, fill: ink))
                    cx += Smufl.width(dynGlyph[c]!, sp: 11) * 0.92
                }
            } else {
                below.append(.text(dyn, x: fx - 4, y: 104, size: 20, weight: 800, italic: true, font: .serif, fill: ink))
            }
        }
        if let hair {
            let x1 = dyn.map { !$0.isEmpty } == true ? fx + 6 + Double(dyn!.utf16.count * 12) : fx - 4
            let x2 = max(lastNoteX + 10, x1 + 40)
            let (open, close) = hair == "<" ? (x1, x2) : (x2, x1)
            below.append(
                .path([.move(Point(close, 90)), .line(Point(open, 97)), .line(Point(close, 104))], stroke: ink, width: 1.8, round: true))
        }

        let staff: [DrawItem] = [40.0, 50, 60, 70, 80].map {
            .line(x1: 8, y1: $0, x2: width - 8, y2: $0, stroke: line, width: 1.2, round: true)
        }
        return Drawing(
            viewBox: (0, 0, width, 112), items: staff + items + above + below,
            sizing: .init(maxWidth: maxW ?? min(360, width * 2.4), maxHeight: 220))
    }

    /// Terim soruları partisyonda nasıl görünüyorsa (web termScore); çizilemeyecekse nil
    public static func termScore(_ display: String) -> String? {
        let d = display.trimmingCharacters(in: .whitespacesAndNewlines)
        let dynamics: Set<String> = ["p", "pp", "ppp", "mp", "mf", "f", "ff", "fff", "sfz", "fp"]
        if dynamics.contains(d) { return "q q q q dyn:\(d)" }
        if d == "cresc." { return "q q q q q hair:<" }
        if d == "dim." { return "q q q q q hair:>" }
        if d == "Fermata" { return "q q h^ ||" }
        if d == "Staccato" { return "q! q! q! q!" }
        if d == "Legato" { return "(q q@1 q@2 q@3)" }
        if d == "Tenuto" { return "q- q- q- q-" }
        if d.hasPrefix("Da Capo") { return "q q q q || end:D.C." }
        if d == "Fine" { return "q q h || end:Fine" }
        if d == "Coda" { return "q q q q || end:Coda" }
        if d.utf16.count > 18 || d.contains("/") { return nil }
        return "tx:\(d.replacingOccurrences(of: " ", with: "_")) q q q q"
    }

    /// Ritim sorusunda tek nota / sus gösterimi (web RhythmDisplay); çizilemeyecekse nil
    public static func rhythmScore(rhythmType: String, displayText: String?) -> String? {
        let map = [
            "whole": "w", "half": "h", "quarter": "q", "eighth": "e", "sixteenth": "s", "whole_rest": "wr",
            "half_rest": "hr", "quarter_rest": "qr", "eighth_rest": "er", "sixteenth_rest": "sr",
        ]
        if let s = map[rhythmType] { return s }
        if let d = displayText, (try? Regex(#"^[0-9]+/[0-9]+$"#).wholeMatch(in: d)) != nil { return "ts:\(d)" }
        return nil
    }
}
