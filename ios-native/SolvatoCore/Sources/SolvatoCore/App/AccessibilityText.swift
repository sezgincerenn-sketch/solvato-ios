// VoiceOver metinleri (0.8, docs/ozellikler/erisilebilirlik-ipad.md §2): tur ekranlarında okunan ve duyurulan yazılar.
// Testli olsun diye çekirdekte; ekranlar (QuizScreen, ChordQuizScreen, RhythmTapScreen, ResultScreen) buradan okur.
// Kural: soru turunda portedeki notanın adı ya da yeri hiçbir öğede okunmaz.

public enum AccessibilityText {
    /// Tur üstündeki noktalar: "3. soru, 10 sorudan"
    public static func roundPosition(index: Int, count: Int) -> String { "\(index + 1). soru, \(count) sorudan" }

    /// Anahtarın okunuşu: "Sol anahtarı" / "Fa anahtarı"
    public static func clefName(_ clef: Clef) -> String { clef == .treble ? "Sol anahtarı" : "Fa anahtarı" }

    /// Soru portesi (nota adı ve yeri yok): "Porte: Sol anahtarı, bir nota"
    public static func noteStaff(_ clef: Clef) -> String { "Porte: \(clefName(clef)), bir nota" }

    /// Akor portesi: "Porte: Sol anahtarı, bir akor"
    public static func chordStaff(_ clef: Clef = .treble) -> String { "Porte: \(clefName(clef)), bir akor" }

    /// Ritim portesi
    public static let rhythmStaff = "Porte: bir ritim"

    /// Kulak sorusunun çalma düğmesi (notanın adı okunmaz)
    public static let listen = "Dinle"

    /// Cevaptan sonraki duyuru: "Doğru" / "Yanlış. Doğru cevap: Sol" / "Süre doldu. Doğru cevap: Sol"
    public static func answerResult(correct: Bool, timedOut: Bool, correctAnswer: String) -> String {
        if correct { return "Doğru" }
        return (timedOut ? "Süre doldu." : "Yanlış.") + " Doğru cevap: " + correctAnswer
    }

    /// Süre çubuğu: "Kalan süre 5 saniye"
    public static func timeLeft(_ seconds: Int) -> String { "Kalan süre \(seconds) saniye" }

    /// Her saniye duyurulmaz; yalnız son 3 saniye
    public static func announcesTime(_ seconds: Int) -> Bool { (1...3).contains(seconds) }

    /// Yıldızlar: "3 yıldızdan 2"
    public static func stars(_ value: Int, of total: Int = 3) -> String { "\(total) yıldızdan \(value)" }

    /// Kartın tek öğe olarak okunuşu: boş parçalar atlanır, virgülle birleşir ("Sol Anahtarı, %72, 10 soru")
    public static func join(_ parts: [String?]) -> String {
        parts.compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

extension QuizRound {
    /// Soru kartının VoiceOver adı: nota sorusunda yalnız anahtar ("Porte: Sol anahtarı, bir nota"), ritimde "Porte: bir
    /// ritim", terim sorusunda terimin kendisi; yazım ve kulak sorularında nil (kendi öğeleri okunur)
    public var promptAccessibilityLabel: String? {
        let q = question
        switch q.category {
        case .noteIdentification: return AccessibilityText.noteStaff(q.clef ?? .treble)
        case .rhythm: return AccessibilityText.rhythmStaff
        case .musicalTerms: return termScore != nil ? (q.displayText ?? termText) : termText
        case .writing, .ear: return nil
        }
    }

    /// Cevaptan sonra duyurulacak sonuç (yanlış kartındaki "Doğru cevap: …" ile aynı ad); cevap yoksa nil
    public var answerAnnouncement: String? {
        guard answerState != .pending else { return nil }
        return AccessibilityText.answerResult(
            correct: answerState == .correct, timedOut: selected == "__timeout__", correctAnswer: question.correctAnswer)
    }
}

extension ChordRound {
    /// Kontrolden ya da süre dolunca duyurulacak sonuç; bekliyorsa nil
    public var answerAnnouncement: String? {
        guard state != .pending else { return nil }
        return AccessibilityText.answerResult(correct: state == .correct, timedOut: state == .timeout, correctAnswer: question.chord.label)
    }
}

extension PianoKey {
    /// Akor klavyesinde tuşun durumu VoiceOver değeri olarak: "seçili" ("Akoru bas"ta seçilen, "Tuşlardan bul"da basılı
    /// gösterilen tuş), sonuçta "doğru" / "yanlış"; boşta nil
    public var stateAccessibilityValue: String? {
        switch state {
        case .selected: "seçili"
        case .correct: "doğru"
        case .wrong: "yanlış"
        default: nil
        }
    }
}
