// Ritmi Tut turunun akışı (web src/screens/RhythmTapSession.tsx): her ritimde hazır → [Dinle] → Başla: 4 vuruş sayma →
// çalma (dokunuşlar ölçünün başına göre sn) → değerlendirme. Zaman dışarıdan verilir (uygulamada ses saati), böylece
// akış testlenir. Ekran Solvato/Screens/RhythmTapScreen.swift.
import Foundation

public struct RhythmTapRound: Sendable {
    public enum Phase: Sendable, Equatable { case ready, listen, countin, play, result }
    public enum Mode: Sendable { case listen, play }

    public let level: Int
    public let bpm: Int
    public let patterns: [String]
    public private(set) var index = 0
    public private(set) var phase: Phase = .ready
    public private(set) var result: TapResult?
    public private(set) var answers: [RoundAnswer] = []
    /// Sayma ve çalarken yanan vuruş ışığı (1–4)
    public private(set) var count: Int?
    /// Çalarken oynatma çizgisi (0–1)
    public private(set) var progress: Double?
    /// Her dokunuşta artar (dokunma alanının yanıp sönmesi)
    public private(set) var pulse = 0
    private var mode: Mode = .play
    private var t0 = 0.0
    private var m0 = 0.0
    private var taps: [Double] = []

    public init(level: Int, random: @escaping RandomSource) {
        self.level = level
        bpm = RhythmTap.tempo[level] ?? 76
        patterns = RhythmTap.pickPatterns(level: level, random: random)
    }

    public var beat: Double { 60 / Double(bpm) }
    public var score: String { patterns[index] }
    /// Ekrandaki partisyon
    public var notation: String { "ts:4/4 \(score) ||" }
    /// En az bir ritim denendi mi (yoksa çıkış sormadan olur)
    /// "Tekrar dene" sonucu silse de ritim denenmiş sayılır (tur-ekranlari.md: bir ritim denendiyse onay sorulur)
    public var hasAnswers: Bool { !answers.isEmpty || result != nil || tried }
    private var tried = false
    public var busy: Bool { phase == .countin || phase == .play || phase == .listen }
    public var isLast: Bool { index + 1 >= patterns.count }

    /// Dinle / Başla: `now` ses saati (sn). Sayma `now + 0.15`te başlar; dönen değer: tıkların ve (dinlerken) notaların
    /// çalınacağı anlar
    public mutating func start(_ m: Mode, now: Double) -> (clicks: [(at: Double, accent: Bool)], beats: [Double]) {
        mode = m
        result = nil
        taps = []
        t0 = now + 0.15
        m0 = t0 + 4 * beat
        phase = .countin
        var clicks: [(at: Double, accent: Bool)] = []
        for start in [t0, m0] {
            for i in 0..<4 { clicks.append((at: start + Double(i) * beat, accent: i == 0)) }
        }
        let beats = m == .listen ? RhythmTap.onsets(score).map { m0 + $0 * beat } : []
        return (clicks, beats)
    }

    /// Ekran karesi: `now` duyulan an (ses saati − gecikme). Bitti mi döner (bitince çizim durur)
    @discardableResult
    public mutating func tick(now: Double) -> Bool {
        guard busy else { return true }
        if now < m0 {
            count = now < t0 ? nil : min(4, Int(((now - t0) / beat).rounded(.down)) + 1)
            progress = nil
        } else {
            count = now < m0 + 4 * beat ? Int(((now - m0) / beat).rounded(.down)) + 1 : nil
            if phase == .countin { phase = mode == .listen ? .listen : .play }
            progress = min(1, (now - m0) / (4 * beat))
        }
        if now < m0 + 4 * beat + 0.35 { return false }
        progress = nil
        if mode == .listen {
            phase = .ready
        } else {
            result = RhythmTap.grade(score, taps: taps, bpm: bpm, level: level)
            tried = true
            phase = .result
        }
        return true
    }

    /// Dokunuş (`now`: duyulan an). Sayma ve çalma sırasında kaydedilir
    public mutating func tap(now: Double) {
        guard phase == .play || phase == .countin else { return }
        pulse += 1
        let t = now - m0
        if t > -0.3 { taps.append(t) }
    }

    /// Çıkış onayı açılırken: çalıyorsa deneme durur
    public mutating func interrupt() {
        guard phase != .result && phase != .ready else { return }
        count = nil
        progress = nil
        phase = .ready
    }

    /// Sıradaki / Turu bitir. Tur bittiyse cevaplar döner
    public mutating func finishPattern() -> [RoundAnswer]? {
        guard let r = result else { return nil }
        let next = answers + [RoundAnswer(questionId: 3000 + index, correct: r.passed, timeMs: r.meanAbsMs)]
        if isLast { return next }
        answers = next
        index += 1
        result = nil
        phase = .ready
        return nil
    }

    // MARK: Yazılar
    public var header: String { "Ritmi Tut · \(index + 1)/\(patterns.count)" }
    public var title: String {
        phase == .result ? (result?.passed == true ? "Ritim yerinde!" : "Bir daha deneyelim") : "Dört vuruş say, sonra ritmi dokunarak çal"
    }
    public var tapLabel: String {
        switch phase {
        case .play: "Dokun"
        case .countin: "Hazır…"
        case .listen: "Dinle…"
        default: "Başlamak için dokun"
        }
    }

    /// Tur başlamadan alan dokununca turu başlatır (Başla düğmesiyle aynı; kullanici-testi-revize.md madde 7)
    public var tapStarts: Bool { phase == .ready }

    /// "5/6 vuruş yerinde · 1 fazla dokunuş" ve "%72" (renkli kısım)
    public var summary: (main: String, pct: String)? {
        guard let r = result else { return nil }
        let hits = r.notes.filter { $0.grade != .miss }.count
        return ("\(hits)/\(r.notes.count) vuruş yerinde" + (r.extra.isEmpty ? "" : " · \(r.extra.count) fazla dokunuş"), " · %\(jsRound(r.score * 100))")
    }

    public var hint: String? {
        guard let r = result else { return nil }
        return r.biasHint ?? (r.passed ? "Güzel zamanlama." : "Mor çizgiler dokunman gereken anlar; noktalar senin dokunuşların.")
    }

    /// Üstteki bölümler: geçildi (yeşil) / geçilmedi (amber) / şimdiki / sırada
    public enum Segment: Sendable { case passed, failed, current, upcoming }
    public var segments: [Segment] {
        patterns.indices.map { i in
            i < index ? (answers[i].correct ? .passed : .failed) : i == index ? .current : .upcoming
        }
    }
}
