// Piyano klavyeleri React'la aynı mı (0.4): her nota sorusunun klavyedeki yeri ve klavye penceresi; soru turu
// klavyesinin 84, akor klavyesinin 16 durumunda her tuşun konumu, rengi, kenarlığı, gölgesi, yazısı.
import Foundation
import XCTest

@testable import SolvatoCore

final class PianoTests: XCTestCase {
    private func close(_ a: Double?, _ b: Double?) -> Bool {
        guard let a, let b else { return a == nil && b == nil }
        return abs(a - b) <= 1e-9 * max(1, abs(a))
    }

    private func checkKeys(_ mine: [PianoKey], _ web: [JSON], _ label: String) {
        XCTAssertEqual(mine.count, web.count, label)
        for (i, (k, w)) in zip(mine, web).enumerated() {
            let l = "\(label) tuş \(i) \(k.note)\(k.octave)"
            XCTAssertEqual(k.isBlack, w["black"]?.bool, l)
            if let aria = w["aria"]?.string { XCTAssertEqual(k.accessibilityLabel, aria, l) }
            XCTAssertTrue(close(k.leftPct, w["left"]?.double), "\(l) sol \(String(describing: k.leftPct))")
            XCTAssertTrue(close(k.widthPct, w["width"]?.double), "\(l) genişlik")
            XCTAssertEqual(k.look.top.hex, w["top"]?.string, l)
            XCTAssertEqual(k.look.bottom.hex, w["bottom"]?.string, l)
            XCTAssertEqual(k.look.border?.hex ?? "transparent", w["border"]?.string, l)
            let shadows = w["shadows"]!.array!
            XCTAssertEqual(k.look.shadows.count, shadows.count, "\(l) gölge")
            for (s, ws) in zip(k.look.shadows, shadows) {
                XCTAssertEqual(s.inset, ws["inset"]?.bool, l)
                XCTAssertEqual([s.x, s.y, s.blur], [ws["x"]!.double!, ws["y"]!.double!, ws["blur"]!.double!], l)
                XCTAssertEqual(s.color.hex, ws["color"]?.string, "\(l) gölge rengi")
            }
            let labels = w["labels"]!.array!
            XCTAssertEqual(k.labels.map(\.text), labels.map { $0["text"]!.string! }, l)
            XCTAssertEqual(k.labels.map(\.size), labels.map { $0["size"]!.double! }, l)
            XCTAssertEqual(k.labels.map(\.weight), labels.map { $0["weight"]!.int! }, l)
            XCTAssertEqual(k.labels.map(\.color.hex), labels.map { $0["color"]!.string! }, l)
            XCTAssertEqual(k.dot, w["dot"]?.bool, l)
        }
    }

    func testNoteKeysAndWindows() throws {
        let rows = try XCTUnwrap(Golden.load("piyano")["notes"]?.array)
        XCTAssertEqual(rows.count, 564)
        for r in rows {
            let q = QuestionBank.byId[r["id"]!.int!]!
            let t = Piano.noteKey(q)
            XCTAssertEqual(t?.key, r["target"]?["key"]?.string, "soru \(q.id)")
            XCTAssertEqual(t?.octave, r["target"]?["octave"]?.int, "soru \(q.id)")
            for w in r["windows"]!.array! {
                let win = Piano.window(for: q, octaves: w["kbOctaves"]!.int!)
                XCTAssertEqual(win.start, w["kbStart"]?.int, "soru \(q.id) \(w.serialized)")
                XCTAssertEqual(win.octaveMode, w["octaveMode"]?.bool, "soru \(q.id)")
            }
        }
    }

    func testQuizKeyboard() throws {
        for (i, r) in try XCTUnwrap(Golden.load("piyano")["quiz"]?.array).enumerated() {
            let p = r["props"]!
            let keys = Piano.quizKeys(
                octaves: p["octaves"]!.int!, startOctave: p["startOctave"]?.int, octaveMode: p["octaveMode"]!.bool!,
                answerState: p["answerState"]!.string!, selectedNote: p["selectedNote"]?.string,
                correctAnswer: p["correctAnswer"]?.string, hintNote: p["hintNote"]?.string, showLabels: p["showLabels"]!.bool!)
            checkKeys(keys, r["keys"]!.array!, "klavye \(i) \(p.serialized)")
            let tall = p["tall"]?.bool ?? false
            XCTAssertEqual(r["height"]?.string, tall ? "clamp(120px, 38vh, 190px)" : "clamp(120px, 21vh, 190px)")
        }
        XCTAssertEqual(Piano.quizHeight(screenHeight: 844, tall: false), 844 * 0.21)
        XCTAssertEqual(Piano.quizHeight(screenHeight: 390, tall: true), 148.2, accuracy: 1e-9)
        XCTAssertEqual(Piano.quizHeight(screenHeight: 1366, tall: false), 190)
        XCTAssertEqual(Piano.quizHeight(screenHeight: 400, tall: false), 120)
    }

    func testChordKeyboard() throws {
        for r in try XCTUnwrap(Golden.load("piyano")["multi"]?.array) {
            let keys = Piano.multiKeys(
                selected: Set(r["selected"]!.strings), correctKeys: r["correctKeys"]!.strings, showResult: r["showResult"]!.bool!,
                lit: r["lit"]?.array.map { Set($0.compactMap(\.string)) })
            checkKeys(keys, r["keys"]!.array!, "\(r["chord"]!.string!) \(r["mode"]!.string!)")
            XCTAssertEqual(Piano.octaveMarkers, r["markers"]?.strings)
        }
    }
}
