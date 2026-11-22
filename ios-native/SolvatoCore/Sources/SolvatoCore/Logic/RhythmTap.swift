// Ritmi Tut: 4/4'lük tek ölçülük ritimler, ritim metninin ayrıştırılması ve dokunuşların puanlanması.
// Web karşılığı src/data/rhythmTap.ts (+ RhythmTapSession.tsx'teki erken/geç uyarısı). Ses zamanlaması uygulamada
// (Solvato/Audio.swift ses saati); buradaki puan kuralı değişmez: tam 1, yakın 0,6, ıska 0, fazla dokunuş −0,2; %70 ve üstü geçti.

public enum TapGrade: String, Sendable {
    case perfect, good, miss
}

public struct TapResult: Equatable, Sendable {
    public struct Note: Equatable, Sendable {
        /// Notanın vuruşu
        public var beat: Double
        /// Zamanlama farkı (ms, + geç); ıskada nil
        public var deltaMs: Int?
        public var grade: TapGrade
    }
    public var notes: [Note]
    /// Hiçbir notaya denk gelmeyen dokunuşlar (vuruş cinsinden)
    public var extra: [Double]
    /// 0–1
    public var score: Double
    /// Ortalama mutlak sapma (ms)
    public var meanAbsMs: Int
    /// Ortalama işaretli sapma (ms): + geride kalıyor, − acele ediyor
    public var biasMs: Int

    public var passed: Bool { score >= RhythmTap.pass }

    /// Sapma belirginse yön söylenir (geçtiyse de: "Güzel; biraz erken…")
    public var biasHint: String? {
        let hits = notes.filter { $0.grade != .miss }.count
        guard hits >= 2, abs(biasMs) > 45 else { return nil }
        let text =
            biasMs < 0 ? "biraz erken dokunuyorsun, metronomu dinle." : "biraz geç dokunuyorsun, vuruşla birlikte dokun."
        return passed ? "Güzel; " + text : "B" + text.dropFirst()
    }
}

public struct RhythmEvent: Equatable, Sendable {
    /// Başlangıç (vuruş)
    public var at: Double
    public var rest: Bool
    public var dur: Double
}

public enum RhythmTap {
    /// Seviyeye göre ritimler (Notation dilinde); toplam süre her zaman 4 vuruş
    public static let patterns: [Int: [String]] = [
        1: [
            "q q ee q", "h ee q", "q ee q q", "ee ee q q", "q qr ee q", "q q h", "q h q", "ee q h", "qr q ee q",
            "ee ee ee q",
        ],
        2: [
            "ssss q q q", "q ess q q", "sse q h", "ess sse q q", "q. e q q", "h. ee", "ssss ee q q", "q sse ess q",
            "ee ssss q q", "q. e ess q",
        ],
        3: [
            "e.s e.s q q", "q e.s ssss q", "e.s ess sse q", "ses q ses q", "e q e e.s q", "er e ess e.s q",
            "q. e e.s ssss", "ssss e.s sse ess", "e.s q. e q", "sse er e e.s q",
        ],
    ]
    /// Tempo (dörtlük / dakika); onaltılıklı seviyeler biraz daha yavaş
    public static let tempo = [1: 76, 2: 66, 3: 72]
    /// Turdaki ritim sayısı
    public static let roundLength = 6
    public static let pass = 0.7

    static let base: [Character: Double] = ["w": 4, "h": 2, "q": 1, "e": 0.5, "s": 0.25]

    /// Bağlı grup (ee, ssss, ess, sse, e.s, ses): 2–4 parça, her biri e/s ve isteğe bağlı nokta
    static func group(_ tok: Substring) -> [Double]? {
        var out: [Double] = []
        var chars = tok.makeIterator()
        var next = chars.next()
        while let c = next {
            guard c == "e" || c == "s" else { return nil }
            next = chars.next()
            var dur = base[c]!
            if next == "." {
                dur *= 1.5
                next = chars.next()
            }
            out.append(dur)
        }
        return (2...4).contains(out.count) ? out : nil
    }

    /// Ritim metni → her nota/sus için başlangıç, sus mu, süre (bilinmeyen parça atlanır)
    public static func parse(_ score: String) -> [RhythmEvent] {
        var out: [RhythmEvent] = []
        var t = 0.0
        for tok in score.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" }) {
            if let durs = group(tok) {
                for d in durs {
                    out.append(RhythmEvent(at: t, rest: false, dur: d))
                    t += d
                }
                continue
            }
            let c = Array(tok)
            guard let first = c.first, let b = base[first] else { continue }
            var i = 1
            let rest = i < c.count && c[i] == "r"
            if rest { i += 1 }
            let dotted = i < c.count && c[i] == "."
            if dotted { i += 1 }
            guard i == c.count else { continue }
            let dur = b * (dotted ? 1.5 : 1)
            out.append(RhythmEvent(at: t, rest: rest, dur: dur))
            t += dur
        }
        return out
    }

    /// Dokunulması gereken anlar (vuruş)
    public static func onsets(_ score: String) -> [Double] { parse(score).filter { !$0.rest }.map(\.at) }

    /// Dokunuşları notalarla eşleştirir; taps ölçü başından saniye. Pencereler: tam ±110/±90 ms, yakın ±200/±180 ms
    /// (Başlangıç / diğer), en kısa nota aralığının yarısını geçmez.
    public static func grade(_ score: String, taps: [Double], bpm: Int, level: Int) -> TapResult {
        let beatSec = 60 / Double(bpm)
        let beats = onsets(score)
        var minGap = Double.infinity
        for i in beats.indices.dropFirst() { minGap = min(minGap, (beats[i] - beats[i - 1]) * beatSec) }
        let good = min(level == 1 ? 0.2 : 0.18, minGap * 0.5)
        let perfect = min(level == 1 ? 0.11 : 0.09, good * 0.6)
        let free = taps.sorted()
        var used = Set<Int>()
        let notes = beats.map { beat -> TapResult.Note in
            let target = beat * beatSec
            var best = -1
            var bestD = Double.infinity
            for (i, t) in free.enumerated() where !used.contains(i) {
                let d = abs(t - target)
                if d < bestD {
                    bestD = d
                    best = i
                }
            }
            if best < 0 || bestD > good { return .init(beat: beat, deltaMs: nil, grade: .miss) }
            used.insert(best)
            return .init(beat: beat, deltaMs: jsRound((free[best] - target) * 1000), grade: bestD <= perfect ? .perfect : .good)
        }
        let extra = free.enumerated().filter { !used.contains($0.offset) }.map { $0.element / beatSec }
        let sum = notes.reduce(0.0) { $0 + ($1.grade == .perfect ? 1 : $1.grade == .good ? 0.6 : 0) }
        let raw = sum / Double(notes.count) - 0.2 * Double(extra.count)
        let deltas = notes.filter { $0.grade != .miss }.map { $0.deltaMs ?? 0 }
        let n = Double(deltas.count)
        return TapResult(
            notes: notes, extra: extra, score: max(0, min(1, raw)),
            meanAbsMs: deltas.isEmpty ? 0 : jsRound(Double(deltas.reduce(0) { $0 + abs($1) }) / n),
            biasMs: deltas.isEmpty ? 0 : jsRound(Double(deltas.reduce(0, +)) / n))
    }

    /// Turdaki ritimler: Başlangıç'ta 6'sı kendi seviyesinden; Orta/İleri'de 4 kendi + 2 alt seviyeden
    public static func pickPatterns(level: Int, random r: @escaping RandomSource = systemRandom) -> [String] {
        let own = patterns[level] ?? []
        let lower = level > 1 ? patterns[level - 1] ?? [] : []
        let nOwn = level == 1 ? roundLength : roundLength - 2
        let a = Array(shuffled(own, r).prefix(nOwn))
        let b = Array(shuffled(lower, r).prefix(roundLength - nOwn))
        return shuffled(a + b, r)
    }
}
