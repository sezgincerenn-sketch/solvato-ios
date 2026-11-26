// Profil ve Ayarlar yazıları (web screens/profile/ProfileScreen.tsx; öğretmen kodu kartı docs/ozellikler/gezinme.md, RankCard.tsx detaylı, SettingsScreen.tsx,
// components/NotesPicker.tsx). SwiftUI ekranları (Screens/ProfileScreen, Screens/SettingsScreen) bunları kullanır.
import Foundation

public enum SettingsText {
    public static let goalText: [Int: String] = [
        10: "Günde 10 soru: rahat tempo.", 20: "Günde 20 soru: düzenli çalışma.", 30: "Günde 30 soru: hızlı ilerleme.",
        50: "Günde 50 soru: yoğun tempo.",
    ]

    /// Seviye satırının açıklaması
    public static func levelSub(_ s: Settings) -> String {
        guard s.level < 3 else { return "Tüm sorular açık." }
        let n = s.levelProgress.n
        return "Sonraki seviyeye: \(n)/50 soru" + (n > 0 ? " · %\(jsRound(Double(s.levelProgress.c) / Double(n) * 100)) doğru" : "")
    }

    /// "Her gün 19:30'da", "Her gün 07:45'te"
    public static func reminderSub(_ s: Settings) -> String? {
        s.reminder ? "Her gün \(timeText(hour: s.reminderHour, minute: s.reminderMinute))" : nil
    }

    /// 24 saat biçimi: "09:05"
    public static func clock(hour: Int, minute: Int) -> String { String(format: "%02d:%02d", hour, minute) }

    /// Saat ve bulunma eki: "19:00'da", "07:45'te", "20:00'de". Ek, saatin okunuşundaki son sözcüğe uyar
    /// (dakika sıfırsa saat: "on dokuz"da; değilse dakika: "kırk beş"te).
    public static func timeText(hour: Int, minute: Int) -> String {
        clock(hour: hour, minute: minute) + "'" + locativeSuffix(minute == 0 ? hour : minute)
    }

    /// 0–59 arası sayının okunuşuna göre bulunma eki
    static func locativeSuffix(_ n: Int) -> String {
        let ones = ["da", "de", "de", "te", "te", "te", "da", "de", "de", "da"]  // sıfır bir iki üç dört beş altı yedi sekiz dokuz
        let tens = ["da", "da", "de", "da", "ta", "de"]  // sıfır on yirmi otuz kırk elli
        return n % 10 != 0 ? ones[n % 10] : tens[(n / 10) % 6]
    }

    // MARK: Çalışılacak notalar (web NotesPicker)
    public static let notePresets: [(label: String, notes: [String])] = [
        ("Do Re Mi", ["Do", "Re", "Mi"]), ("Do – Sol", ["Do", "Re", "Mi", "Fa", "Sol"]), ("Hepsi", allNotes),
    ]

    public static func notesSummary(_ notes: [String]) -> String {
        notes.count >= allNotes.count
            ? "Tüm notalar soruluyor. Bir süre yalnızca birkaç notaya odaklanmak için daralt (en az 3)."
            : "Nota sorularında yalnızca \(notes.joined(separator: " ")) çıkar."
    }

    /// Notaya dokununca: aç/kapat, en az 3 kalır, sıra Do…Si
    public static func toggleNote(_ n: String, in value: [String]) -> [String] {
        let next = value.contains(n) ? value.filter { $0 != n } : value + [n]
        guard next.count >= TeacherCode.minNotes else { return value }
        return allNotes.filter(next.contains)
    }
}

public enum ProfileText {
    static let months = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]

    /// "Porte Gezgini ünvanı · 3 Kasım 2026'den beri". Web joinedAt'i UTC gece yarısı okuyup yerel tarihle yazar.
    public static func subtitle(rankLabel: String, joinedAt: String, clock: DayClock) -> String {
        var s = "\(rankLabel) ünvanı"
        let p = joinedAt.split(separator: "-").compactMap { Int($0) }
        if p.count == 3 {
            var utc = Calendar(identifier: .gregorian)
            utc.timeZone = TimeZone(identifier: "UTC")!
            if let d = utc.date(from: DateComponents(year: p[0], month: p[1], day: p[2])) {
                let c = clock.calendar.dateComponents([.year, .month, .day], from: d)
                s += " · \(c.day!) \(months[c.month! - 1]) \(c.year!)'den beri"
            }
        }
        return s
    }

    /// Profildeki ünvan listesi: bir önceki, şimdiki, sonraki üçü; son ünvan hep görünür (web visibleRanks). 0'dan sıra.
    public static func visibleRanks(_ rank: Int) -> [Int] {
        let cur = rank - 1
        let from = max(0, cur - 1)
        let to = min(Ranks.all.count - 1, cur + 3)
        var list = Array(from...to)
        if to < Ranks.all.count - 1 { list.append(Ranks.all.count - 1) }
        return list
    }

    /// Profil'deki öğretmen kodu kartı: başlık, alt yazı ve öne çıkıp çıkmadığı. Kod uygulanmışsa kod; değilse
    /// tanıtımdaki öğretmen sorusuna göre (Öğretmenim var / Ben öğretmenim kart mor çerçeveyle öne çıkar).
    public struct TeacherCard: Equatable, Sendable {
        public var title: String
        public var sub: String
        public var highlight: Bool
        /// Kod uygulanmışsa altta açıklama ve iki düğme ("Diğer konuları da göster", "Kodu kaldır")
        public var applied: Bool
    }

    public static func teacherCard(_ s: Settings) -> TeacherCard {
        if !s.teacherCode.isEmpty {
            return TeacherCard(title: "Öğretmen kodu", sub: "Uygulandı · \(s.teacherCode)", highlight: false, applied: true)
        }
        switch s.teacherRole {
        case .student:
            return TeacherCard(title: "Öğretmen kodunu gir", sub: "Öğretmeninin gönderdiği kodu yaz", highlight: true, applied: false)
        case .teacher:
            return TeacherCard(title: "Öğrenci kodu hazırla", sub: "Öğrencilerine konu, seviye ve hedef gönder", highlight: true, applied: false)
        case .solo, .unset:
            return TeacherCard(
                title: "Öğretmen kodu", sub: "Öğretmeninin kodunu gir ya da öğrencine kod hazırla", highlight: false, applied: false)
        }
    }

    public static let teacherNote = "Öğretmeninin konuları Ana sayfada üstte. Diğer konuları da açık tutabilirsin."
    public static func showRestLabel(_ on: Bool) -> String { on ? "Diğer konular açık ✓" : "Diğer konuları da göster" }

    /// Toplam çözülen soru
    public static func solved(_ stats: AppStats) -> Int { stats.dailyQuestions.values.reduce(0, +) }
}
