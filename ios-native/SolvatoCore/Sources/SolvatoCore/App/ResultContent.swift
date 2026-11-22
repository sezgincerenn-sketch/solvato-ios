// Tur sonucu ve kutlama penceresinin içeriği. Web karşılıkları src/screens/ResultScreen.tsx, screens/profile/RankCard.tsx
// (kısa hali) ve components/Celebration.tsx. SwiftUI ekranları (Screens/ResultScreen, UI/CelebrationView) bunu çizer.
import Foundation

/// Sayıyı Türkçe yazar (web toLocaleString("tr-TR")): 2,4 · 1.234,5
public func trNumber(_ x: Double, maxFraction: Int = 3) -> String {
    let neg = x < 0
    var v = abs(x)
    let scale = pow(10, Double(maxFraction))
    v = (v * scale).rounded() / scale
    let int = Int(v.rounded(.down))
    var frac = String(format: "%.\(maxFraction)f", v - Double(int)).dropFirst(2)
    while frac.last == "0" { frac.removeLast() }
    var digits = String(int)
    var grouped = ""
    while digits.count > 3 {
        grouped = "." + digits.suffix(3) + grouped
        digits.removeLast(3)
    }
    grouped = digits + grouped
    return (neg ? "-" : "") + grouped + (frac.isEmpty ? "" : "," + frac)
}

public struct ResultContent: Equatable, Sendable {
    public static let categoryLabels: [String: String] = [
        "all": "Karma Pratik", "treble": "Sol Anahtarı Pratiği", "bass": "Fa Anahtarı Pratiği", "rhythm": "Ritim Pratiği",
        "terms": "Müzik Terimleri Pratiği", "accidentals": "Diyez & Bemol Pratiği", "writing": "Nota Yazımı Pratiği",
        "ear": "Kulak Pratiği", "chords": "Akor Pratiği", "rhythmtap": "Ritmi Tut",
    ]

    public var stars: Int
    public var newBest: Bool
    /// "Tur bitti · Harika iş!"
    public var title: String
    public var categoryLabel: String
    /// Solfie'nin balonu: rekor ya da sonraki yıldız ipucu
    public var solfieText: String
    public var correct: Int
    public var total: Int
    public var pct: Int
    public var points: Int
    /// "2,4 sn" ya da Ritmi Tut'ta "38 ms"
    public var timeValue: String
    public var timeLabel: String
    /// Hatalar varsa "Hatalarını tekrar et · 3 soru", yoksa "Yeni tur"
    public var primaryTitle: String
    public var hasWrong: Bool
    // Ünvan kartı
    public var rank: RankInfo
    public var totalXp: Int
    public var rankNote: String

    /// key: FilterCategory ya da "chords" / "rhythmtap"
    public init(answers: [RoundAnswer], key: String, points: Int, stars: Int, previousBest: Int?, totalXp: Int, questions: [Question]) {
        self.stars = stars
        newBest = previousBest.map { stars > $0 } ?? false
        correct = answers.filter(\.correct).count
        total = answers.count
        pct = total > 0 ? jsRound(Double(correct) / Double(total) * 100) : 0
        let headline = pct >= 90 ? "Harika iş!" : pct >= 70 ? "Çok iyi!" : pct >= 50 ? "Güzel gidiyorsun" : "Tekrarla, oturacak"
        title = "Tur bitti · \(headline)"
        categoryLabel = Self.categoryLabels[key] ?? ""
        solfieText = newBest ? "Bu konuda yeni rekor!" : (Stars.nextHint(stars) ?? "Tam puan: 3 yıldız")
        self.points = points
        let sum = answers.reduce(0) { $0 + $1.timeMs }
        if key == "rhythmtap" {
            timeValue = "\(answers.isEmpty ? 0 : jsRound(Double(sum) / Double(answers.count))) ms"
            timeLabel = "Ort. Sapma"
        } else {
            let avg = answers.isEmpty ? 0 : Double(jsRound(Double(sum) / Double(answers.count) / 100)) / 10
            timeValue = "\(trNumber(avg)) sn"
            timeLabel = "Ort. Süre"
        }
        let ids = Set(questions.map(\.id))
        let wrong = answers.filter { !$0.correct && ids.contains($0.questionId) }.count
        hasWrong = wrong > 0
        primaryTitle = wrong > 0 ? "Hatalarını tekrar et · \(wrong) soru" : "Yeni tur"
        let r = Ranks.from(xp: totalXp)
        rank = r
        self.totalXp = totalXp
        rankNote =
            (points > 0 ? "Bu turda +\(points) XP. " : "")
            + (r.nextLabel.map { "\($0) ünvanına \(r.toNext) XP kaldı." } ?? "En üst ünvandasın.")
    }
}

/// Kutlama penceresinin satırları (web Celebration): sırayla ünvan, seviye, hedef, seri
public struct CelebrationRow: Equatable, Sendable {
    public var icon: IconName
    public var title: String
    public var sub: String
    public var color: ThemeColor
    /// Dolu ikon (hedef ikonu hariç)
    public var filled: Bool { icon != .target }
}

extension Celebration {
    public var rows: [CelebrationRow] {
        var out: [CelebrationRow] = []
        if let r = rankUp {
            out.append(
                CelebrationRow(
                    icon: .star, title: "Yeni ünvan: \(r.label)",
                    sub: r.nextLabel.map { "\(r.rank). ünvan · sırada \($0)" } ?? "En üst ünvana ulaştın", color: .amberText))
        }
        if let u = unlocked {
            out.append(CelebrationRow(icon: .sparkles, title: "Yeni seviye: \(u)", sub: "Turlarda artık yeni sorular da var", color: .violetText))
        }
        if goalDone {
            out.append(CelebrationRow(icon: .target, title: "Günlük hedef tamam", sub: "Bugünkü çalışmanı bitirdin", color: .greenText))
        }
        if let s = streak, s != 0 {
            out.append(
                CelebrationRow(icon: .flame, title: "\(s) günlük seri", sub: s == 1 ? "Yeni bir seri başladı" : "Devam, bozma!", color: .orangeText))
        }
        return out
    }

    /// Pencere kendiliğinden kapanır (sn)
    public static let autoClose = 6.5
}
