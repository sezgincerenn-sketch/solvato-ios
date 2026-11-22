// Ritmi Tut akışı (web RhythmTapSession): sayma, çalma, dokunuşların ölçüye göre kaydı, değerlendirme, sıradaki ritim.
import XCTest

@testable import SolvatoCore

final class RhythmTapRoundTests: XCTestCase {
    func testPerfectAttempt() {
        var r = RhythmTapRound(level: 1, random: seededRandom(5))
        XCTAssertEqual(r.bpm, 76)
        XCTAssertEqual(r.patterns.count, RhythmTap.roundLength)
        XCTAssertEqual(r.header, "Ritmi Tut · 1/6")
        let plan = r.start(.play, now: 10)
        XCTAssertEqual(plan.clicks.count, 8)
        XCTAssertTrue(plan.beats.isEmpty)
        XCTAssertEqual(r.phase, .countin)
        XCTAssertEqual(r.tapLabel, "Hazır…")
        let m0 = 10.15 + 4 * r.beat
        r.tick(now: 10.15 + r.beat * 1.5)
        XCTAssertEqual(r.count, 2)
        // Ritmin notalarına tam zamanında dokun
        for b in RhythmTap.onsets(r.score) {
            r.tick(now: m0 + b * r.beat)
            XCTAssertEqual(r.phase, .play)
            r.tap(now: m0 + b * r.beat)
        }
        XCTAssertFalse(r.tick(now: m0 + 4 * r.beat))
        XCTAssertTrue(r.tick(now: m0 + 4 * r.beat + 0.36))
        XCTAssertEqual(r.phase, .result)
        XCTAssertEqual(r.title, "Ritim yerinde!")
        XCTAssertEqual(r.summary?.pct, " · %100")
        XCTAssertEqual(r.hint, "Güzel zamanlama.")
        XCTAssertNil(r.finishPattern())
        XCTAssertEqual(r.index, 1)
        XCTAssertEqual(r.segments.first, .passed)
    }

    func testListenAndInterrupt() {
        var r = RhythmTapRound(level: 2, random: seededRandom(9))
        let plan = r.start(.listen, now: 0)
        XCTAssertEqual(plan.beats.count, RhythmTap.onsets(r.score).count)
        r.tick(now: 0.15 + 4 * r.beat + 0.1)
        XCTAssertEqual(r.phase, .listen)
        r.tap(now: 3)  // dinlerken dokunuş sayılmaz
        XCTAssertEqual(r.pulse, 0)
        r.interrupt()
        XCTAssertEqual(r.phase, .ready)
        XCTAssertNil(r.progress)
    }

    func testNoTapsFailsAndLastFinishes() {
        var r = RhythmTapRound(level: 3, random: seededRandom(1))
        for i in 0..<6 {
            _ = r.start(.play, now: 0)
            r.tick(now: 100)
            XCTAssertEqual(r.title, "Bir daha deneyelim")
            XCTAssertTrue(r.summary!.main.hasPrefix("0/"))
            let out = r.finishPattern()
            XCTAssertEqual(out == nil, i < 5)
            if let out { XCTAssertEqual(out.map(\.questionId), Array(3000..<3006)) }
        }
    }
}
