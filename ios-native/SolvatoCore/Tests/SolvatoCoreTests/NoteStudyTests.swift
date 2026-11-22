// Çalışma › Nota dersleri web'le aynı mı (altın tablo nota-dersleri.json): nota tabloları, ezber kartları, derslerin
// açılış yazıları; ‹ › gezinme, ♯/♭ seçimi ve piyanodan nota seçme kuralları.
import XCTest

@testable import SolvatoCore

final class NoteStudyTests: XCTestCase {
    func testRefsMatchWeb() throws {
        let g = try Golden.load("nota-dersleri")
        for (clef, key) in [(Clef.treble, "treble"), (.bass, "bass")] {
            let web = try XCTUnwrap(g[key]?.array)
            let mine = NoteStudy.notes(clef)
            XCTAssertEqual(web.count, mine.count)
            for (w, n) in zip(web, mine) {
                XCTAssertEqual(w["name"]?.string, n.name)
                XCTAssertEqual(w["y"]?.int, n.y)
                XCTAssertEqual(w["ledger"]?.ints, n.ledger)
                XCTAssertEqual(w["label"]?.string, n.label)
                XCTAssertEqual(w["desc"]?.string, n.desc)
            }
            for (kind, card) in zip(["lines", "spaces"], Mnemonics.cards(clef)) {
                let w = try XCTUnwrap(g["mnemonics"]?[key]?[kind])
                XCTAssertEqual(w["title"]?.string, card.title)
                XCTAssertEqual(w["notes"]?.string, card.notes)
                XCTAssertEqual(w["letterColors"]?.strings, card.letterColors.map(\.rawValue))
                XCTAssertEqual(w["mnemonic"]?.string, card.mnemonic)
                XCTAssertEqual(w["words"]?.array?.map(\.strings), card.words.map { [$0.0, $0.1] })
                XCTAssertEqual(w["backNoteType"]?.string, card.lines ? "lines" : "spaces")
                XCTAssertEqual(w["backDotColor"]?.string, card.backDotColor.rawValue)
                XCTAssertEqual(w["noteNames"]?.strings, card.noteNames)
            }
        }
    }

    func testOpeningTextsMatchWeb() throws {
        let screens = try XCTUnwrap(Golden.load("nota-dersleri")["screens"]?.array)
        func screen(_ id: String) -> JSON? { screens.first { $0["id"]?.string == id } }
        let cases: [(String, StaffStudyState, [String])] = [
            ("notes-treble", StaffStudyState(clef: .treble, accidentalsMode: false), []),
            ("notes-bass", StaffStudyState(clef: .bass, accidentalsMode: false), []),
            ("accidentals", StaffStudyState(clef: .treble, accidentalsMode: true), AccidentalMemoContent.texts),
        ]
        for (id, st, extra) in cases {
            XCTAssertEqual(st.texts + extra, screen(id)?["texts"]?.strings, id)
            XCTAssertEqual(["Önceki nota", "Sonraki nota"] + st.keyLabels, screen(id)?["labels"]?.strings, id)
        }
        for (id, clef) in [("mnemonic-treble", Clef.treble), ("mnemonic-bass", .bass)] {
            XCTAssertEqual(Mnemonics.texts(clef), screen(id)?["texts"]?.strings, id)
            let keys = NoteStudy.pianoOrder.map { "\($0) tuşu" }
            XCTAssertEqual(["Notaları sırayla çal"] + keys + ["Notaları sırayla çal"] + keys, screen(id)?["labels"]?.strings, id)
        }
    }

    func testNavigation() {
        var s = StaffStudyState(clef: .treble, accidentalsMode: false)
        XCTAssertEqual(s.counter, "1/13")
        s.go(-1)
        XCTAssertEqual(s.note.label, "La (A5)")
        s.go(1)
        XCTAssertEqual(s.note.label, "Do (C4)")
        // Doğal derste siyah tuş geçmez, beyaz tuş geçer
        s.pick("Re", 4, sharp: true)
        XCTAssertEqual(s.selected, 0)
        s.pick("Sol", 5, sharp: false)
        XCTAssertEqual(s.title, "Sol (G5)")
        XCTAssertFalse(s.available("Si", 5, sharp: false))

        var a = StaffStudyState(clef: .treble, accidentalsMode: true)
        XCTAssertEqual(a.counter, "1/10")
        XCTAssertEqual(a.keyName, "Do♯ / Re♭")
        a.setAcc(.flat)
        XCTAssertEqual(a.title, "Re♭ (D♭4)")
        XCTAssertEqual(a.desc, "Re notasının yarım ses altı (alçaltır). Piyanoda siyah tuştur: Do♯ / Re♭.")
        XCTAssertEqual(a.highlighted.name, "Do")
        XCTAssertTrue(a.highlighted.black)
        // Siyah tuşa basınca diyeze geçer
        a.pick("Fa", 4, sharp: true)
        XCTAssertEqual(a.badge, "Fa♯")
        XCTAssertEqual(a.counter, "3/10")
        XCTAssertFalse(a.available("Fa", 4, sharp: false))
    }
}
