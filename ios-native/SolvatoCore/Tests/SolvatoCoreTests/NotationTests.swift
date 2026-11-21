// Nota çizimi React'la aynı mı (0.4): bankadaki, terimlerdeki, Ritmi Tut'taki bütün nota metinleri, her nota konumunun
// portesi, 94 akor portesi, günlük hedef portesi ve anahtar ikonları. React bileşenleri SVG'ye dökülüp parçalarına
// ayrılır (scripts/altin/cizim.ts); Swift yerleşim motoru aynı sırayla aynı parçaları üretmeli.
import Foundation
import XCTest

@testable import SolvatoCore

final class NotationTests: XCTestCase {
    private func close(_ a: Double?, _ b: Double?) -> Bool {
        guard let a, let b else { return a == nil && b == nil }
        return abs(a - b) <= 1e-9 * max(1, abs(a), abs(b))
    }

    private func pathClose(_ a: [PathCommand], _ b: [PathCommand]) -> Bool {
        func pts(_ c: PathCommand) -> [Point] {
            switch c {
            case let .move(p), let .line(p): [p]
            case let .cubic(a, b, c): [a, b, c]
            case let .quad(a, b): [a, b]
            case .close: []
            }
        }
        return a.count == b.count
            && zip(a, b).allSatisfy { x, y in
                let px = pts(x), py = pts(y)
                return px.count == py.count && zip(px, py).allSatisfy { close($0.x, $1.x) && close($0.y, $1.y) }
            }
    }

    /// Bir öğe web'dekiyle aynı mı; değilse farkı anlatan metin
    private func compare(_ item: DrawItem, _ w: JSON) -> String? {
        func n(_ k: String) -> Double? { w[k]?.double }
        func p(_ k: String) -> String? { w[k]?.string }
        func bad(_ what: String) -> String { "\(what): Swift \(item) ≠ web \(w.serialized)" }
        switch item {
        case let .line(x1, y1, x2, y2, stroke, width, round):
            guard p("t") == "line" else { return bad("tür") }
            if !(close(x1, n("x1")) && close(y1, n("y1")) && close(x2, n("x2")) && close(y2, n("y2"))) { return bad("konum") }
            if stroke.key != p("stroke") || !close(width, n("w")) || round != w["round"]?.bool { return bad("çizgi") }
        case let .rect(x, y, rw, h, rx, fill, stroke, sw):
            guard p("t") == "rect" else { return bad("tür") }
            if !(close(x, n("x")) && close(y, n("y")) && close(rw, n("w")) && close(h, n("h")) && close(rx, n("rx"))) { return bad("konum") }
            if fill?.key != p("fill") || stroke?.key != p("stroke") || !close(sw, n("sw")) { return bad("renk") }
        case let .circle(cx, cy, r, fill):
            guard p("t") == "circle" else { return bad("tür") }
            if !(close(cx, n("cx")) && close(cy, n("cy")) && close(r, n("r"))) || fill.key != p("fill") { return bad("daire") }
        case let .path(cmds, fill, stroke, width, round):
            guard p("t") == "path" else { return bad("tür") }
            guard let web = try? SVGPath.parse(p("d") ?? ""), pathClose(cmds, web) else { return bad("yol") }
            if fill?.key != p("fill") || stroke?.key != p("stroke") || !close(width, n("w")) || round != w["round"]?.bool { return bad("yol rengi") }
        case let .glyph(name, x, y, sp, fill, opacity, glow):
            guard p("t") == "glyph" else { return bad("tür") }
            if name != p("name") || !close(x, n("x")) || !close(y, n("y")) || !close(sp, n("sp")) { return bad("sembol") }
            if fill.key != p("fill") || !close(opacity, n("opacity")) || glow?.key != p("glow") { return bad("sembol rengi") }
        case let .text(s, x, y, size, weight, italic, anchor, font, fill):
            guard p("t") == "text" else { return bad("tür") }
            if s != p("s") || !close(x, n("x")) || !close(y, n("y")) || !close(size, n("size")) { return bad("yazı") }
            if Double(weight) != n("weight") || italic != w["italic"]?.bool || anchor.rawValue != p("anchor") || font.rawValue != p("font")
                || fill.key != p("fill")
            {
                return bad("yazı biçimi")
            }
        }
        return nil
    }

    private func check(_ d: Drawing, _ web: JSON, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let vb = web["viewBox"]!.array!.compactMap(\.double)
        XCTAssertTrue(
            close(d.viewBox.x, vb[0]) && close(d.viewBox.y, vb[1]) && close(d.viewBox.w, vb[2]) && close(d.viewBox.h, vb[3]),
            "\(label) viewBox \(d.viewBox) ≠ \(vb)", file: file, line: line)
        let items = web["items"]!.array!
        XCTAssertEqual(d.items.count, items.count, "\(label) öğe sayısı", file: file, line: line)
        for (i, (a, b)) in zip(d.items, items).enumerated() {
            if let diff = compare(a, b) {
                XCTFail("\(label) öğe \(i) \(diff)", file: file, line: line)
                return
            }
        }
    }

    private func px(_ style: String, _ key: String) -> Double? {
        guard let r = style.range(of: "\(key):") else { return nil }
        let rest = style[r.upperBound...].prefix { $0 != ";" }
        return rest.hasSuffix("px") ? Double(rest.dropLast(2)) : nil
    }

    func testNotation() throws {
        let rows = try XCTUnwrap(Golden.load("cizim")["notation"]?.array)
        XCTAssertGreaterThan(rows.count, 200)
        for r in rows {
            let score = r["score"]!.string!
            let d = NotationLayout.notation(score, maxW: r["maxW"]?.double)
            check(d, r, score)
            let style = r["style"]!.string!
            XCTAssertTrue(close(d.sizing.maxWidth, px(style, "max-width")), "\(score) en geniş")
            XCTAssertEqual(d.sizing.maxHeight, 220)
        }
    }

    func testNoteStaves() throws {
        for r in try XCTUnwrap(Golden.load("cizim")["staff"]?.array) {
            let clef = Clef(rawValue: r["clef"]!.string!)!
            let d = Staves.note(
                clef: clef, noteY: r["noteY"]!.int!, ledgerLines: r["ledgerLines"]!.ints,
                accidental: r["accidental"]?.string.flatMap(Accidental.init(rawValue:)), showLabel: r["showLabel"]!.bool!,
                maxHeight: r["maxHeight"]?.double)
            check(d, r, "\(clef) \(r["noteY"]!.int!) \(r["accidental"]?.string ?? "")")
            XCTAssertEqual(d.sizing.height, px(r["style"]!.string!, "height"))
            XCTAssertTrue(d.sizing.notationShadow)
        }
    }

    func testNoteStaffFeedbackColors() {
        let ok = Staves.note(clef: .treble, noteY: 70, ledgerLines: [], accidental: .sharp, feedback: .correct)
        let colored = ok.items.filter {
            if case let .glyph(n, _, _, _, fill, _, _) = $0, n != "gClef" { return fill == .palette(.green400) }
            if case let .line(_, _, _, _, stroke, _, _) = $0 { return stroke == .palette(.green400) }
            return false
        }
        XCTAssertEqual(colored.count, 3, "işaret, baş, sap yeşil")
    }

    func testChordStaves() throws {
        for r in try XCTUnwrap(Golden.load("cizim")["chords"]?.array) {
            let chord = Chords.all.first { $0.id == r["id"]!.string! }!
            let color: Paint = r["color"]?.string.map { hex in
                .color(RGBA(UInt32(hex.dropFirst(), radix: 16)! << 8 | 0xFF))
            } ?? .theme(.violetText)
            let d = Staves.chord(chord, color: color, maxWidth: r["maxWidth"]?.double ?? 310)
            check(d, r, "\(chord.id) \(color.key)")
            XCTAssertTrue(close(d.sizing.maxWidth, px(r["style"]!.string!, "max-width")))
        }
    }

    func testGoalStaves() throws {
        for r in try XCTUnwrap(Golden.load("cizim")["goal"]?.array) {
            let goal = r["goal"]!.int!, done = r["done"]!.int!
            check(Staves.goal(done: done, goal: goal), r, "hedef \(done)/\(goal)")
        }
    }

    func testClefIcons() throws {
        for r in try XCTUnwrap(Golden.load("cizim")["clefIcons"]?.array) {
            let d = Staves.clefIcon(Clef(rawValue: r["clef"]!.string!)!, size: r["size"]!.double!)
            check(d, r, "anahtar \(r["clef"]!.string!) \(r["size"]!.int!)")
            XCTAssertTrue(close(d.sizing.width, r["width"]?.double))
            XCTAssertTrue(close(d.sizing.height, r["height"]?.double))
        }
    }

    func testTermAndRhythmScores() {
        XCTAssertEqual(NotationLayout.termScore("mf"), "q q q q dyn:mf")
        XCTAssertEqual(NotationLayout.termScore("Andante"), "tx:Andante q q q q")
        XCTAssertNil(NotationLayout.termScore("2/4"))
        for q in QuestionBank.all where q.category == .musicalTerms && !q.questionText.hasPrefix("Hangi") {
            if let d = q.displayText, let s = NotationLayout.termScore(d) {
                XCTAssertGreaterThan(NotationLayout.notation(s).items.count, 5, s)
            }
        }
        XCTAssertEqual(NotationLayout.rhythmScore(rhythmType: "eighth_rest", displayText: nil), "er")
        XCTAssertEqual(NotationLayout.rhythmScore(rhythmType: "", displayText: "6/8"), "ts:6/8")
        XCTAssertNil(NotationLayout.rhythmScore(rhythmType: "", displayText: "Allegro"))
    }

    func testEveryGlyphParses() {
        XCTAssertEqual(Smufl.glyphs.count, 44)
        for (name, g) in Smufl.glyphs { XCTAssertFalse(g.path.isEmpty, name) }
    }
}
