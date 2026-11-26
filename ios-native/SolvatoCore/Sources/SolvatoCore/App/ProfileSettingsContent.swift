// Profil ve Ayarlar yazıları (web screens/profile/ProfileScreen.tsx; öğretmen kodu kartı docs/ozellikler/gezinme.md, RankCard.tsx detaylı, SettingsScreen.tsx,
// components/NotesPicker.tsx). SwiftUI ekranları (Screens/ProfileScreen, Screens/SettingsScreen) bunları kullanır.
import Foundation

public enum SettingsText {
    // MARK: Satır değerleri (docs/ozellikler/ayarlar.md): satırın sağındaki soluk yazı ve seçim penceresi seçenekleri

    /// Günlük hedef seçenekleri ve pencerede yanlarındaki açıklama
    public static let goalOptions: [(goal: Int, note: String)] = [
        (10, "rahat tempo"), (20, "düzenli çalışma"), (30, "hızlı ilerleme"), (50, "yoğun tempo"),
    ]
    /// "10 soru"
    public static func goalValue(_ goal: Int) -> String { "\(goal) soru" }

    public static let levelOptions: [(level: Int, label: String)] = [(1, "Başlangıç"), (2, "Orta"), (3, "İleri")]
    public static func levelValue(_ level: Int) -> String { levelOptions.first { $0.level == level }?.label ?? "" }

    public static let clefOptions: [(clef: ClefChoice, label: String)] = [(.treble, "Sol"), (.bass, "Fa"), (.both, "İkisi de")]
    public static func clefValue(_ c: ClefChoice) -> String { clefOptions.first { $0.clef == c }?.label ?? "" }

    public static let inputOptions: [(mode: InputMode, label: String)] = [(.piano, "Klavye"), (.choice, "Şıklar")]
    public static func inputValue(_ m: InputMode) -> String { inputOptions.first { $0.mode == m }?.label ?? "" }

    public static let themeOptions: [(mode: ThemeMode, label: String)] = [(.system, "Sistem"), (.dark, "Koyu"), (.light, "Açık")]
    public static func themeValue(_ m: ThemeMode) -> String { themeOptions.first { $0.mode == m }?.label ?? "" }

    /// Notalar satırının en uzun değeri (harf); iPhone SE'de başlıkla aynı satıra sığar
    public static let notesValueLimit = 15

    /// Notalar satırının değeri: hepsi seçiliyse "Hepsi", değilse seçili notalar ("Do Re Mi Sol"). Sığmazsa sondan
    /// bütün notalar atılır ve "…" eklenir ("Do Re Mi Fa…").
    public static func notesValue(_ notes: [String]) -> String {
        if allNotes.allSatisfy(notes.contains) { return "Hepsi" }
        let full = notes.joined(separator: " ")
        guard full.count > notesValueLimit else { return full }
        var out = ""
        for n in notes {
            let next = out.isEmpty ? n : out + " " + n
            if next.count + 1 > notesValueLimit { break }
            out = next
        }
        return out + "…"
    }

    /// Seviye satırının açıklaması
    public static func levelSub(_ s: Settings) -> String {
        guard s.level < 3 else { return "Tüm sorular açık." }
        let n = s.levelProgress.n
        return "Sonraki seviyeye: \(n)/50 soru" + (n > 0 ? " · %\(jsRound(Double(s.levelProgress.c) / Double(n) * 100)) doğru" : "")
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
