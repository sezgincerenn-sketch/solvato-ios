// Tarih yardımcıları: gün anahtarı (YYYY-MM-DD), JS `toDateString` biçimi, takvim dönemleri.
// Web karşılıkları src/utils/level.ts `todayKey`, src/utils/dates.ts. Hepsi yerel saatle; saat dilimi `Calendar`dan gelir.
import Foundation

public enum Period: String, Sendable { case week, month }

public struct DayClock: Sendable {
    public var calendar: Calendar

    public init(timeZone: TimeZone = .current) {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = timeZone
        c.firstWeekday = 2
        calendar = c
    }

    /// Web `todayKey(d)`: "2026-11-18"
    public func dayKey(_ d: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    /// Web `new Date().toDateString()`: "Wed Nov 18 2026" (stats.lastPlayDate bu biçimde)
    public func dateString(_ d: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day, .weekday], from: d)
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return "\(days[c.weekday! - 1]) \(months[c.month! - 1]) \(String(format: "%02d", c.day!)) \(String(format: "%04d", c.year!))"
    }

    /// Yerel takvim günü → o günün başı (web `new Date(y, m, d)`; taşan gün/ay sonraki aya geçer)
    public func date(year: Int, month: Int, day: Int) -> Date {
        let first = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let m = calendar.date(byAdding: .month, value: month - 1, to: first)!
        return calendar.date(byAdding: .day, value: day - 1, to: m)!
    }

    public func startOfDay(_ d: Date) -> Date {
        let c = calendar.dateComponents([.year, .month, .day], from: d)
        return date(year: c.year!, month: c.month!, day: c.day!)
    }

    /// Web `periodRange`: "week" Pazartesi–Pazar, "month" 1'i–son günü; offset 1 = önceki dönem
    public func periodRange(_ kind: Period, offset: Int = 0, now: Date) -> (from: Date, to: Date) {
        let c = calendar.dateComponents([.year, .month, .day, .weekday], from: now)
        if kind == .week {
            let sinceMonday = (c.weekday! - 1 + 6) % 7  // Pzt=0 … Paz=6
            let from = date(year: c.year!, month: c.month!, day: c.day! - sinceMonday - 7 * offset)
            let f = calendar.dateComponents([.year, .month, .day], from: from)
            return (from, date(year: f.year!, month: f.month!, day: f.day! + 6))
        }
        let from = date(year: c.year!, month: c.month! - offset, day: 1)
        let f = calendar.dateComponents([.year, .month], from: from)
        return (from, date(year: f.year!, month: f.month! + 1, day: 0))
    }

    /// from–to arasındaki her gün (ikisi de dahil)
    public func eachDay(from: Date, to: Date) -> [Date] {
        var out: [Date] = []
        var d = startOfDay(from)
        while d <= to {
            out.append(d)
            let c = calendar.dateComponents([.year, .month, .day], from: d)
            d = date(year: c.year!, month: c.month!, day: c.day! + 1)
        }
        return out
    }

    public func isFuture(_ d: Date, now: Date) -> Bool { startOfDay(d) > startOfDay(now) }
}

/// Web `Date.now()` karşılığı milisaniye
public func epochMs(_ d: Date) -> Int { Int((d.timeIntervalSince1970 * 1000).rounded()) }
public func dateFromMs(_ ms: Int) -> Date { Date(timeIntervalSince1970: Double(ms) / 1000) }
