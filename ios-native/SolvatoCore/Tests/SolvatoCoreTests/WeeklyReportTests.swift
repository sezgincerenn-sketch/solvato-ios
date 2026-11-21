// Haftalık rapor React'la aynı mı (K-13): 70 istatistik + tarih için gün şeridi, konular, doğruluk, metin karakter
// karakter. Dönem doğruluğu (K-14): tüm zamanlar, bu/geçen hafta, bu/geçen ay.
import Foundation
import XCTest

@testable import SolvatoCore

final class WeeklyReportTests: XCTestCase {
    func testWeeklyReports() throws {
        for (i, c) in try XCTUnwrap(Golden.load("haftalik-rapor").array).enumerated() {
            let now = Golden.now(c["now"]!.int!, "Europe/Istanbul")
            let stats = AppStats(json: c["stats"]!)
            var s = Settings()
            s.name = c["settings"]!["name"]!.string!
            s.level = c["settings"]!["level"]!.int!
            s.dailyGoal = c["settings"]!["dailyGoal"]!.int!
            s.teacherCode = c["settings"]!["teacherCode"]!.string!
            let r = WeeklyReport(stats: stats, settings: s, now: now)
            let w = c["report"]!
            let label = "rapor \(i) \(r.range)"
            XCTAssertEqual(r.text, c["text"]?.string, label)
            XCTAssertEqual(r.range, w["range"]?.string, label)
            XCTAssertEqual(r.name, w["name"]?.string, label)
            XCTAssertEqual(r.days.map(\.key), w["days"]!.array!.map { $0["key"]!.string! }, label)
            XCTAssertEqual(r.days.map(\.future), w["days"]!.array!.map { $0["future"]!.bool! }, label)
            XCTAssertEqual(r.accuracy, w["accuracy"]?.int, label)
            XCTAssertEqual(r.prevAccuracy, w["prevAccuracy"]?.int, label)
            XCTAssertEqual(r.topics.map(\.key), w["topics"]!.array!.map { $0["key"]!.string! }, label)
            XCTAssertEqual(r.streak, w["streak"]?.int, label)

            let acc = c["acc"]!
            func eq(_ t: Tally, _ j: JSON, _ what: String) {
                XCTAssertEqual(t.correct, j["correct"]?.int, "\(label) \(what)")
                XCTAssertEqual(t.total, j["total"]?.int, "\(label) \(what)")
            }
            eq(Progress.accuracy(stats, now: now), acc["all"]!, "tümü")
            for o in 0...2 { eq(Progress.accuracy(stats, period: .week, offset: o, now: now), acc["week"]!.array![o], "hafta \(o)") }
            for o in 0...1 { eq(Progress.accuracy(stats, period: .month, offset: o, now: now), acc["month"]!.array![o], "ay \(o)") }
        }
    }
}
