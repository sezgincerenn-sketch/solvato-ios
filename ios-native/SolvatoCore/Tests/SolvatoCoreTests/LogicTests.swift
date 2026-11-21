// Mantık kuralları React'la aynı mı: soru bankası ve seviyeler (K-01, K-02), ünvan (K-06), yıldız (K-09),
// dönemler (K-14), zorlandığın notalar (K-12). Girdi/çıktılar Fixtures/altin'de.
import Foundation
import XCTest

@testable import SolvatoCore

final class LogicTests: XCTestCase {
    func testQuestionBankAndLevels() throws {
        let g = try Golden.load("soru-bankasi")
        XCTAssertEqual(QuestionBank.all.count, 701)
        XCTAssertEqual(QuestionBank.all.count, g["count"]?.int)
        XCTAssertEqual(Set(QuestionBank.all.map(\.id)).count, 701, "kimlikler tekil")
        let levels = try XCTUnwrap(g["levels"]?.object)
        var dist = [0, 0, 0, 0]
        for q in QuestionBank.all {
            let lv = QuestionBank.level(of: q)
            dist[lv] += 1
            XCTAssertEqual(lv, levels[String(q.id)]?.int, "soru \(q.id) seviyesi")
        }
        XCTAssertEqual(dist, [0, 362, 155, 184])
        // Kategoriler: 504 nota + 60 diyez/bemol, 70 ritim, 34 terim, 33 yazım
        let cats = Dictionary(grouping: QuestionBank.all, by: \.category).mapValues(\.count)
        XCTAssertEqual(cats[.noteIdentification], 564)
        XCTAssertEqual(QuestionBank.all.filter { $0.accidental != nil }.count, 60)
        XCTAssertEqual(cats[.rhythm], 70)
        XCTAssertEqual(cats[.musicalTerms], 34)
        XCTAssertEqual(cats[.writing], 33)
    }

    func testRanks() throws {
        for row in try XCTUnwrap(Golden.load("unvan").array) {
            let xp = try XCTUnwrap(row["xp"]?.int)
            let r = Ranks.from(xp: xp)
            XCTAssertEqual(r.rank, row["rank"]?.int, "xp \(xp)")
            XCTAssertEqual(r.label, row["label"]?.string, "xp \(xp)")
            XCTAssertEqual(r.nextLabel, row["nextLabel"]?.string, "xp \(xp)")
            XCTAssertEqual(r.nextAt, row["nextAt"]?.int, "xp \(xp)")
            XCTAssertEqual(r.toNext, row["toNext"]?.int, "xp \(xp)")
            XCTAssertEqual(r.pct, row["pct"]?.int, "xp \(xp)")
        }
    }

    func testStars() throws {
        let g = try Golden.load("yildiz")
        for row in try XCTUnwrap(g["rows"]?.array) {
            let c = row["correct"]!.int!, t = row["total"]!.int!
            XCTAssertEqual(Stars.forRound(correct: c, total: t), row["stars"]?.int, "\(c)/\(t)")
        }
        let hints = try XCTUnwrap(g["hints"]?.array)
        for s in 0...3 { XCTAssertEqual(Stars.nextHint(s), hints[s].string) }
    }

    func testPeriods() throws {
        let clock = Golden.clock("Europe/Istanbul")
        for row in try XCTUnwrap(Golden.load("donem").array) {
            let now = dateFromMs(row["now"]!.int!)
            let kind = Period(rawValue: row["period"]!.string!)!
            let offset = row["offset"]!.int!
            let r = clock.periodRange(kind, offset: offset, now: now)
            let label = "\(clock.dayKey(now)) \(kind) \(offset)"
            XCTAssertEqual(clock.dayKey(r.from), row["from"]?.string, label)
            XCTAssertEqual(clock.dayKey(r.to), row["to"]?.string, label)
            XCTAssertEqual(clock.eachDay(from: r.from, to: r.to).count, row["days"]?.int, label)
        }
    }

    func testWeakNotes() throws {
        let g = try Golden.load("zayif-notalar")
        for (i, row) in try XCTUnwrap(g["rows"]?.array).enumerated() {
            var stats = AppStats()
            for e in row["noteStats"]!.object!.entries {
                stats.noteStats[e.key] = Tally(correct: e.value["correct"]!.int!, total: e.value["total"]!.int!)
            }
            for (limit, key) in [(6, "six"), (4, "four")] {
                let mine = WeakNotes.list(stats, limit: limit)
                let web = row[key]!.array!
                XCTAssertEqual(mine.count, web.count, "örnek \(i) \(key)")
                for (m, w) in zip(mine, web) {
                    XCTAssertEqual(m.key, w["key"]?.string, "örnek \(i)")
                    XCTAssertEqual(m.note, w["note"]?.string, "örnek \(i) \(m.key)")
                    XCTAssertEqual(m.clef.rawValue, w["clef"]?.string)
                    XCTAssertEqual(m.pct, w["pct"]?.int)
                    XCTAssertEqual(m.total, w["total"]?.int)
                    XCTAssertEqual(m.noteY, w["noteY"]?.int)
                    XCTAssertEqual(m.ledgerLines, w["ledgerLines"]?.ints)
                    XCTAssertEqual(m.accidental?.rawValue, w["accidental"]?.string)
                }
            }
        }
    }
}
