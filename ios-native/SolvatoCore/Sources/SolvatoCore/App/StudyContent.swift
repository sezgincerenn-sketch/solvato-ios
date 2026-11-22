// Çalışma sekmesinin ders listesi, arama kuralı ve terim tablosu. Web src/screens/study/lessons.tsx, StudyScreen.tsx,
// TermsStudy.tsx (TERMS_REF). Ekranlar Solvato/Screens/StudyScreen.swift ve ders ekranları.
import Foundation

public struct Term: Equatable, Sendable {
    public let symbol: String
    public let name: String
    public let meaning: String
}

public struct TermGroup: Equatable, Sendable {
    public let group: String
    public let color: PaletteColor
    public let items: [Term]

    /// Ders listesindeki alt yazı: ilk üç terimin adı, küçük harfle (web `toLowerCase`)
    public var sample: String { items.prefix(3).map { $0.name.lowercased() }.joined(separator: ", ") + "…" }
}

public enum Terms {
    private static func t(_ s: String, _ n: String, _ m: String) -> Term { Term(symbol: s, name: n, meaning: m) }

    public static let groups: [TermGroup] = [
        TermGroup(group: "Dinamikler", color: .red500, items: [
            t("ppp", "pianississimo", "Neredeyse duyulmaz"),
            t("pp", "pianissimo", "Çok hafif"),
            t("p", "piano", "Hafif"),
            t("mp", "mezzo piano", "Orta hafif"),
            t("mf", "mezzo forte", "Orta güçlü"),
            t("f", "forte", "Güçlü"),
            t("ff", "fortissimo", "Çok güçlü"),
            t("fff", "forte fortissimo", "En güçlü"),
            t("sfz", "sforzando", "Ani kuvvetli vurgu"),
        ]),
        TermGroup(group: "Tempo", color: .blue500, items: [
            t("Largo", "largo", "Çok yavaş ve geniş (♩≈50)"),
            t("Lento", "lento", "Yavaş (♩≈55)"),
            t("Adagio", "adagio", "Yavaş ve ifadeli (♩≈70)"),
            t("Andante", "andante", "Yürüyüş hızında (♩≈90)"),
            t("Moderato", "moderato", "Orta hızda (♩≈115)"),
            t("Allegretto", "allegretto", "Biraz hızlı (♩≈115)"),
            t("Allegro", "allegro", "Hızlı ve canlı (♩≈140)"),
            t("Vivace", "vivace", "Canlı ve hareketli (♩≈165)"),
            t("Presto", "presto", "Çok hızlı (♩≈185)"),
        ]),
        TermGroup(group: "Değişim işaretleri", color: .cyan500, items: [
            t("cresc.", "crescendo", "Giderek kuvvetlen"),
            t("dim.", "diminuendo", "Giderek hafifle"),
            t("rit.", "ritardando", "Giderek yavaşla"),
            t("accel.", "accelerando", "Giderek hızlan"),
            t("a tempo", "a tempo", "Önceki tempoya dön"),
        ]),
        TermGroup(group: "Artikülasyon", color: .green500, items: [
            t("legato", "legato", "Düzgün ve bağlı"),
            t("staccato", "staccato", "Kısa ve kesik"),
            t("tenuto", "tenuto", "Tam değerinde tut"),
            t("marcato", "marcato", "Belirgin ve vurgulu"),
        ]),
        TermGroup(group: "İfade", color: .amber500, items: [
            t("cantabile", "cantabile", "Şarkı söyler gibi"),
            t("dolce", "dolce", "Tatlı ve nazik"),
            t("espressivo", "espressivo", "İfadeli"),
        ]),
        TermGroup(group: "Yapısal İşaretler", color: .violet400, items: [
            t("D.C.", "Da Capo", "Başa dön"),
            t("Fine", "Fine", "Son/bitiş"),
            t("Coda", "Coda", "Bitiş bölümü"),
            t("Fermata", "Fermata", "İstediğin kadar uzat"),
            t(":‖", "Tekrar İşareti", "Belirtilen bölümü tekrarla"),
        ]),
    ]
}

/// Çalışma kartlarında nota adlarının renkleri (web study/shared.tsx NOTE_COLORS)
public enum NoteColors {
    public static let byName: [String: PaletteColor] = [
        "Do": .red400, "Re": .orange400, "Mi": .amber400, "Fa": .lime400, "Sol": .green400, "La": .blue400, "Si": .violet400,
    ]
}

public enum LessonSection: String, CaseIterable, Sendable {
    case notes = "Notalar", rhythm = "Ritim", chords = "Akorlar", terms = "Terimler"
}

public struct Lesson: Equatable, Sendable {
    public let id: String
    public let section: LessonSection
    public let title: String
    public let sub: String
    public let icon: IconName
    public let color: PaletteColor
}

public struct LessonGroup: Equatable, Sendable {
    public let section: LessonSection
    public let items: [Lesson]
}

public enum Lessons {
    /// Akor kartları seviyelerinin açıklaması (web ChordsStudy LEVEL_HELP)
    public static let levelHelp = [
        1: "Doğal notaların majör ve minör akorları.",
        2: "Ara seslerin (diyez/bemol) majör ve minörleri.",
        3: "7'li akorlar: majör 7, dominant 7, minör 7.",
        4: "dim, aug, m7♭5, dim7, sus2, sus4, 9'lu, 13'lü. İleri armoni ve caz için.",
    ]

    public static let all: [Lesson] = {
        var l: [Lesson] = [
            Lesson(id: "notes-treble", section: .notes, title: "Sol anahtarı notaları", sub: "Portedeki yeri, piyanodaki tuşu", icon: .note, color: CategoryColor.treble.base),
            Lesson(id: "notes-bass", section: .notes, title: "Fa anahtarı notaları", sub: "Sol el notaları, portede ve piyanoda", icon: .note, color: CategoryColor.bass.base),
            Lesson(id: "mnemonic-treble", section: .notes, title: "Ezber cümleleri: Sol anahtarı", sub: "Misafir Sola Silgiyi Reçele Fırlattı", icon: .bookmark, color: CategoryColor.treble.base),
            Lesson(id: "mnemonic-bass", section: .notes, title: "Ezber cümleleri: Fa anahtarı", sub: "Solucan Simit, Reçel, Fasulye, Lahana yedi", icon: .bookmark, color: CategoryColor.bass.base),
            Lesson(id: "accidentals", section: .notes, title: "Diyez ve bemol", sub: "Siyah tuşlar, ♯ ve ♭ sırası", icon: .piano, color: CategoryColor.accidentals.base),
            Lesson(id: "rhythm-values", section: .rhythm, title: "Nota değerleri", sub: "Birlik, ikilik, dörtlük… kaç vuruş?", icon: .waves, color: CategoryColor.rhythm.base),
            Lesson(id: "rhythm-rests", section: .rhythm, title: "Sus işaretleri", sub: "Her notanın aynı süren bir susu var", icon: .waves, color: CategoryColor.rhythm.base),
            Lesson(id: "rhythm-dotted", section: .rhythm, title: "Noktalı notalar", sub: "Nokta, notaya yarısı kadar süre ekler", icon: .waves, color: CategoryColor.rhythm.base),
            Lesson(id: "chords-build", section: .chords, title: "Majör ve minör nasıl kurulur", sub: "Yarım ses sayarak akor formülleri", icon: .piano, color: CategoryColor.chords.base),
        ]
        for lv in 1...4 {
            l.append(Lesson(id: "chords-\(lv)", section: .chords, title: "Akor kartları: \(Chords.levelLabels[lv]!)", sub: levelHelp[lv]!, icon: .piano, color: CategoryColor.chords.base))
        }
        for g in Terms.groups {
            l.append(Lesson(id: "terms-\(g.group)", section: .terms, title: g.group, sub: g.sample, icon: .type, color: CategoryColor.terms.base))
        }
        return l
    }()

    public static func byId(_ id: String) -> Lesson? { all.first { $0.id == id } }

    /// Türkçe büyük/küçük harf ve aksan farkı aramayı bozmasın: "fa anahtari" → "Fa anahtarı" (web `norm`)
    public static func norm(_ s: String) -> String {
        let lower = s.lowercased(with: Locale(identifier: "tr")).decomposedStringWithCanonicalMapping
        let scalars = lower.unicodeScalars.filter { !(0x300...0x36F).contains($0.value) }
        return String(String.UnicodeScalarView(scalars)).replacingOccurrences(of: "ı", with: "i")
    }

    /// Aramaya uyan dersler, bölüm sırasıyla; boş bölümler çıkar
    public static func groups(query: String) -> [LessonGroup] {
        let q = norm(query.trimmingCharacters(in: .whitespacesAndNewlines))
        return LessonSection.allCases.compactMap { sec in
            let items = all.filter { $0.section == sec && (q.isEmpty || norm("\($0.title) \($0.sub) \($0.section.rawValue)").contains(q)) }
            return items.isEmpty ? nil : LessonGroup(section: sec, items: items)
        }
    }

    public static func emptyText(_ query: String) -> String {
        "“\(query.trimmingCharacters(in: .whitespacesAndNewlines))” için konu bulunamadı. Başka bir kelime dene."
    }
}
