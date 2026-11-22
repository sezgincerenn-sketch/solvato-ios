// Ses çıkışı (G-07) ve titreşim (G-08). Sesler SolvatoCore Sounds'ta (web utils/audio.ts ile aynı dalga ve zarf,
// altın tabloyla testli); burada AVAudioEngine'in kaynak düğümü SynthMixer'dan okur. Ses oturumu `playback` +
// `mixWithOthers`: sessiz düğmesi açıkken de çalar, arkadaki müziği durdurmaz (web AppDelegate.swift ile aynı).
// Ayarlar › Ses / Titreşim kapalıysa hiçbiri çalmaz; AppRoot ayarı `enabled`'a yansıtır.
// Ritmi Tut için ses saati: `now` (şu an çıkışa verilen örneğin zamanı) ve `latency` (çıkış gecikmesi).
import AVFoundation
import QuartzCore
import SolvatoCore
import UIKit

@MainActor
final class Sound {
    static let shared = Sound()

    /// Ayarlar › Ses (web soundKeys)
    var enabled = true

    private let engine = AVAudioEngine()
    private var mixer: SynthMixer?

    // Kesinti (telefon araması) ya da çıkış değişince motor durur; bir sonraki seste yeniden başlar (start)
    private init() {}

    /// Sesi hemen (ya da ses saatinde `at` anında) çalar. Ses kapalıysa hiçbir şey yapmaz.
    static func play(_ voices: [Voice], at: Double? = nil) {
        guard shared.enabled, let m = shared.start() else { return }
        m.schedule(voices, at: at)
    }

    /// Piyano notası (tuşlar, dersler)
    static func note(_ name: String, octave: Int, delay: Double = 0) {
        play(Sounds.pianoNote(name, octave: octave, delay: delay))
    }

    /// Çalan sesleri susturur (turdan çıkınca)
    static func stopAll() { shared.mixer?.stopAll() }

    /// Ses saati (sn): şu an çıkışa verilen örneğin zamanı; zamanlama ve dokunuş ölçümü için tek kaynak
    static var now: Double {
        guard shared.enabled, let m = shared.start() else { return CACurrentMediaTime() }
        return m.clock(host: CACurrentMediaTime())
    }

    /// Zamanlanan sesin kulağa ulaşma gecikmesi (sn); dokunuş bununla düzeltilir (web audioLatency)
    static var latency: Double { AVAudioSession.sharedInstance().outputLatency }

    /// Motoru gerekiyorsa kurar ve başlatır
    private func start() -> SynthMixer? {
        if let mixer, engine.isRunning { return mixer }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        if mixer == nil {
            let sr = session.sampleRate > 0 ? session.sampleRate : 48000
            let m = SynthMixer(sampleRate: sr)
            guard let format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1) else { return nil }
            let node = Self.sourceNode(m, format: format)
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            mixer = m
        }
        engine.prepare()
        do { try engine.start() } catch { return nil }
        return mixer
    }

    /// Ses iş parçacığında çalışan kaynak düğümü. Ana iş parçacığına bağlı olmasın diye ayrı (nonisolated) kurulur.
    nonisolated private static func sourceNode(_ m: SynthMixer, format: AVAudioFormat) -> AVAudioSourceNode {
        AVAudioSourceNode(format: format) { _, timestamp, frameCount, data in
            let buffers = UnsafeMutableAudioBufferListPointer(data)
            let n = Int(frameCount)
            let ts = timestamp.pointee
            let host = ts.mFlags.contains(.hostTimeValid) ? AVAudioTime.seconds(forHostTime: ts.mHostTime) : nil
            guard let first = buffers.first?.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            m.render(first, frames: n, host: host)
            for b in buffers.dropFirst() {
                b.mData?.assumingMemoryBound(to: Float.self).update(from: first, count: n)
            }
            return noErr
        }
    }
}

/// Titreşim (web utils/haptics.ts): dokunuş (hafif), başarı, hata. Ayarlar › Titreşim kapalıysa hiçbiri.
@MainActor
enum Haptics {
    static var enabled = true

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func error() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
