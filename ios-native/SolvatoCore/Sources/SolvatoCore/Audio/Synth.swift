// Ses sentezi (G-07, web utils/audio.ts): bütün sesler kodla üretilir, dosya yok. Her ses birkaç "ses kaynağı"ndan
// (osilatör + kazanç zarfı) oluşur; değerler web'deki Web Audio düğümleriyle birebir (frekans, dalga, atak, üstel
// sönüm, durma anı). SynthMixer bunları örnek doğruluğunda zamanlar ve toplar; uygulamada AVAudioEngine'in kaynak
// düğümü bu karıştırıcıdan okur (Solvato/Audio.swift). Arayüzden bağımsız, Linux'ta testli.
import Foundation

/// Osilatör dalga biçimi (Web Audio OscillatorType)
public enum Wave: Sendable, Equatable { case sine, triangle, square }

/// Tek ses kaynağı: Web Audio'daki osilatör → kazanç düğümü. Zamanlar sesin başlangıcına göre (sn).
public struct Voice: Sendable, Equatable {
    public var wave: Wave
    public var freq: Double
    /// Frekansın üstel olarak indiği değer ve süresi (exponentialRampToValueAtTime); yoksa sabit
    public var freqTo: Double?
    public var freqRamp: Double = 0
    /// Başlangıç (sesin çalma anına göre)
    public var start: Double
    /// Zarf: 0'dan `peak`'e `attack` sürede doğrusal, sonra `end` anında `floor`'a üstel; `stop`'ta susar
    public var peak: Double
    public var attack: Double
    public var floor: Double
    public var end: Double
    public var stop: Double

    public init(
        wave: Wave, freq: Double, freqTo: Double? = nil, freqRamp: Double = 0, start: Double, peak: Double, attack: Double, floor: Double,
        end: Double, stop: Double
    ) {
        self.wave = wave
        self.freq = freq
        self.freqTo = freqTo
        self.freqRamp = freqRamp
        self.start = start
        self.peak = peak
        self.attack = attack
        self.floor = floor
        self.end = end
        self.stop = stop
    }

    /// Kazanç, sesin başlangıcından `t` sn sonra (Web Audio linearRamp + exponentialRamp formülleri)
    public func gain(at t: Double) -> Double {
        if t < 0 || t >= stop { return 0 }
        if t < attack { return peak * t / attack }
        if t < end { return peak * pow(floor / peak, (t - attack) / (end - attack)) }
        return floor
    }

    /// Frekans, başlangıçtan `t` sn sonra
    public func frequency(at t: Double) -> Double {
        guard let f1 = freqTo, freqRamp > 0 else { return freq }
        if t >= freqRamp { return f1 }
        return freq * pow(f1 / freq, max(0, t) / freqRamp)
    }
}

/// Uygulamanın sesleri (web utils/audio.ts'deki fonksiyonlar, aynı adlarla)
public enum Sounds {
    /// Do4 oktavındaki frekanslar (web NOTE_FREQ_C4)
    public static let noteFreqC4: [String: Double] = [
        "Do": 261.63, "Re": 293.66, "Mi": 329.63, "Fa": 349.23, "Sol": 392.0, "La": 440.0, "Si": 493.88,
        "Do#": 277.18, "Re#": 311.13, "Fa#": 369.99, "Sol#": 415.3, "La#": 466.16,
    ]

    /// Piyano notası: temel + 4 harmonik, 8 ms atak, 1,8 sn üstel sönüm. Akorda `volume` düşürülür.
    public static func pianoNote(_ name: String, octave: Int, delay: Double = 0, volume: Double = 0.45) -> [Voice] {
        guard let base = noteFreqC4[name] else { return [] }
        let f = base * pow(2, Double(octave - 4))
        let decay = 1.8
        let partials: [(ratio: Double, level: Double)] = [(1, 1.0), (2, 0.35), (3, 0.12), (4, 0.06), (5, 0.03)]
        // Ana kazanç zarfı × harmonik düzeyi
        return partials.map { p in
            Voice(
                wave: .sine, freq: f * p.ratio, start: delay, peak: volume * p.level, attack: 0.008, floor: 0.001 * p.level, end: decay,
                stop: decay + 0.05)
        }
    }

    /// Notalar birlikte ya da `gap` sn arayla (akor dinle / arpej; web setTimeout i * gap)
    public static func notes(_ pitches: [Pitch], gap: Double = 0) -> [Voice] {
        pitches.enumerated().flatMap { i, p in pianoNote(p.name, octave: p.octave, delay: Double(i) * gap) }
    }

    /// Kulak sorusu (web EarPrompt playEar): nota → referans Do, 0,9 sn ara, soru notası; akor → notalar 0,38 sn arayla
    /// tek tek, sonra birlikte. Çalma süresi (sn) "çalıyor" görünümü için.
    public static func ear(_ prompt: EarPrompt) -> (voices: [Voice], duration: Double) {
        let noteGap = 0.9
        let arpGap = 0.38
        switch prompt {
        case let .note(ref, target):
            return (pianoNote(ref.name, octave: ref.octave) + pianoNote(target.name, octave: target.octave, delay: noteGap), noteGap + 1)
        case let .chord(ns):
            let together = Double(ns.count) * arpGap + 0.25
            let v =
                ns.enumerated().flatMap { i, n in pianoNote(n.name, octave: n.octave, delay: Double(i) * arpGap, volume: 0.32) }
                + ns.flatMap { pianoNote($0.name, octave: $0.octave, delay: together, volume: 0.24) }
            return (v, together + 1.2)
        }
    }

    /// Çan benzeri tek ses: temel ton + ince üst sesler, yumuşak sönüm (web bell)
    public static func bell(_ freq: Double, start: Double, dur: Double = 0.5, vol: Double = 0.16) -> [Voice] {
        [(freq, vol, Wave.sine), (freq * 2, vol * 0.28, .sine), (freq * 3.01, vol * 0.08, .triangle)].map { f, v, w in
            Voice(wave: w, freq: f, start: start, peak: v, attack: 0.012, floor: 0.0008, end: dur, stop: dur + 0.02)
        }
    }

    /// Doğru cevap: kısa, parlak "ting-ting" (Sol5 → Do6)
    public static var correctChime: [Voice] { bell(783.99, start: 0, dur: 0.35, vol: 0.15) + bell(1046.5, start: 0.09, dur: 0.55, vol: 0.16) }

    /// Yanlış cevap: yumuşak, alçalan iki "dum"
    public static var wrongBuzz: [Voice] {
        [(261.63, 0.0), (220.0, 0.13)].map { f, s in
            Voice(wave: .triangle, freq: f, freqTo: f * 0.94, freqRamp: 0.25, start: s, peak: 0.14, attack: 0.02, floor: 0.001, end: 0.28, stop: 0.3)
        }
    }

    /// Tur bitti: üç notalık küçük melodi
    public static var sessionDone: [Voice] { [523.25, 659.25, 783.99].enumerated().flatMap { bell($1, start: Double($0) * 0.12, dur: 0.5, vol: 0.14) } }

    /// Günlük hedef tamam: yükselen arpej ve son akor
    public static var goalDone: [Voice] {
        [392.0, 523.25, 659.25, 783.99].enumerated().flatMap { bell($1, start: Double($0) * 0.1, dur: 0.45, vol: 0.14) }
            + [523.25, 659.25, 783.99, 1046.5].flatMap { bell($0, start: 0.5, dur: 0.9, vol: 0.09) }
    }

    /// Seviye / ünvan: iki oktavlık parlak arpej
    public static var levelUp: [Voice] {
        [523.25, 659.25, 783.99, 1046.5, 1318.5].enumerated().flatMap { bell($1, start: Double($0) * 0.09, dur: 0.6, vol: 0.13) }
            + [1046.5, 1318.5, 1568.0].flatMap { bell($0, start: 0.55, dur: 1.1, vol: 0.08) }
    }

    /// Seri artışı: sıcak iki nota ve parıltı
    public static var streakUp: [Voice] {
        bell(587.33, start: 0, dur: 0.4, vol: 0.14) + bell(880.0, start: 0.11, dur: 0.5, vol: 0.14) + bell(1760.0, start: 0.26, dur: 0.4, vol: 0.06)
    }

    /// Metronom tıkı; ölçü başı (strong) daha tiz ve güçlü
    public static func click(strong: Bool) -> [Voice] {
        [Voice(wave: .square, freq: strong ? 1760 : 1320, start: 0, peak: strong ? 0.09 : 0.06, attack: 0.002, floor: 0.0005, end: 0.05, stop: 0.06)]
    }

    /// Ritmi Tut dinleme modunda ritim notası: kısa, tok vuruş
    public static var beat: [Voice] { bell(523.25, start: 0, dur: 0.22, vol: 0.2) }
}

extension Celebration {
    /// Kutlamanın sesi (web Celebration): ünvan ya da seviye → seviye arpeji; değilse hedef → hedef arpeji; değilse seri
    public var sound: [Voice] {
        if rankUp != nil || unlocked != nil { return Sounds.levelUp }
        if goalDone { return Sounds.goalDone }
        if streak != nil { return Sounds.streakUp }
        return []
    }
}

/// Seslerin örnek doğruluğunda zamanlandığı ve toplandığı karıştırıcı. `time` ses saatidir (sn): o ana kadar üretilen
/// örnek sayısı / örnekleme hızı. Ritmi Tut tıkları bu saate göre önceden zamanlanır, dokunuşlar aynı saatle ölçülür.
/// `render` ses iş parçacığından çağrılır; zamanlama ana iş parçacığından. İkisi kilitle ayrılır.
public final class SynthMixer: @unchecked Sendable {
    public let sampleRate: Double
    private let lock = NSLock()
    private var frame: Int64 = 0
    private var active: [Playing] = []
    /// Son üretilen parçanın ilk örneği ve o örneğin çıkışa verileceği an (cihaz saati, sn)
    private var anchor: (frame: Int64, host: Double)?

    private struct Playing {
        let voice: Voice
        /// Kaynağın başladığı örnek (mutlak)
        let startFrame: Int64
        let stopFrame: Int64
        var phase: Double = 0
        let table: WaveTable?
    }

    public init(sampleRate: Double) { self.sampleRate = sampleRate }

    /// Ses saati (sn)
    public var time: Double {
        lock.lock()
        defer { lock.unlock() }
        return Double(frame) / sampleRate
    }

    /// Cihaz saatinde `host` anında çıkışa verilen örneğin ses saati (sn). Parça sınırlarına bağlı kalmadan sürekli;
    /// Ritmi Tut dokunuşları bununla ölçülür. Ses henüz üretilmediyse `time`.
    public func clock(host: Double) -> Double {
        lock.lock()
        defer { lock.unlock() }
        guard let a = anchor else { return Double(frame) / sampleRate }
        return Double(a.frame) / sampleRate + (host - a.host)
    }

    /// Çıkış yeniden başlarken: eski cihaz saati bağı unutulur (ses saati kaldığı yerden devam eder)
    public func resetAnchor() {
        lock.lock()
        anchor = nil
        lock.unlock()
    }

    /// Sesi ses saatinde `at` anında (verilmezse hemen) çalar
    public func schedule(_ voices: [Voice], at: Double? = nil) {
        lock.lock()
        defer { lock.unlock() }
        let base = at.map { $0 * sampleRate } ?? Double(frame)
        for v in voices {
            let s = Int64((base + v.start * sampleRate).rounded())
            active.append(
                Playing(
                    voice: v, startFrame: s, stopFrame: s + Int64((v.stop * sampleRate).rounded()),
                    table: v.wave == .sine ? nil : WaveTable.make(v.wave, freq: max(v.freq, v.freqTo ?? 0), sampleRate: sampleRate)))
        }
    }

    /// Zamanlanmış bütün sesleri susturur
    public func stopAll() {
        lock.lock()
        active = []
        lock.unlock()
    }

    /// Çalan ya da sırada bekleyen ses var mı
    public var isBusy: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !active.isEmpty
    }

    /// `frames` örnek üretir (üzerine yazar) ve saati ilerletir. `host`: bu parçanın çıkışa verileceği cihaz saati (sn)
    public func render(_ out: UnsafeMutablePointer<Float>, frames: Int, host: Double? = nil) {
        lock.lock()
        defer { lock.unlock() }
        if let host { anchor = (frame, host) }
        for i in 0..<frames { out[i] = 0 }
        let f0 = frame
        let f1 = frame + Int64(frames)
        let dt = 1 / sampleRate
        for k in active.indices {
            let p = active[k]
            let from = max(p.startFrame, f0)
            let to = min(p.stopFrame, f1)
            guard from < to else { continue }
            var phase = p.phase
            for f in from..<to {
                let t = Double(f - p.startFrame) * dt
                let g = p.voice.gain(at: t)
                let s: Double
                if let table = p.table { s = table.sample(phase) } else { s = sin(2 * .pi * phase) }
                out[Int(f - f0)] += Float(g * s)
                phase += p.voice.frequency(at: t) * dt
                if phase >= 1 { phase -= floor(phase) }
            }
            active[k].phase = phase
        }
        active.removeAll { $0.stopFrame <= f1 }
        frame = f1
    }
}

/// Bant sınırlı dalga tablosu (Web Audio periyodik dalgaları gibi: Fourier serisi, Nyquist altı harmonikler, tepe 1)
struct WaveTable: Sendable {
    static let size = 2048
    let values: [Double]

    func sample(_ phase: Double) -> Double {
        let x = phase * Double(Self.size)
        let i = Int(x) % Self.size
        let frac = x - Double(Int(x))
        return values[i] + (values[(i + 1) % Self.size] - values[i]) * frac
    }

    private static let cacheLock = NSLock()
    nonisolated(unsafe) private static var cache: [String: WaveTable] = [:]

    static func make(_ wave: Wave, freq: Double, sampleRate: Double) -> WaveTable {
        let harmonics = max(1, min(64, Int(sampleRate / 2 / max(freq, 1))))
        let key = "\(wave)-\(harmonics)"
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let t = cache[key] { return t }
        var v = [Double](repeating: 0, count: size)
        for n in 1...harmonics {
            let b: Double
            switch wave {
            case .square: b = n % 2 == 1 ? 4 / (Double(n) * .pi) : 0
            case .triangle: b = n % 2 == 1 ? 8 * sin(Double(n) * .pi / 2) / pow(Double(n) * .pi, 2) : 0
            case .sine: b = n == 1 ? 1 : 0
            }
            guard b != 0 else { continue }
            for i in 0..<size { v[i] += b * sin(2 * .pi * Double(n) * Double(i) / Double(size)) }
        }
        let peak = v.map(abs).max() ?? 1
        let t = WaveTable(values: v.map { $0 / peak })
        cache[key] = t
        return t
    }
}
