// Ses çıkışı (G-07) ve titreşim (G-08). Sesler SolvatoCore Sounds'ta (web utils/audio.ts ile aynı dalga ve zarf,
// altın tabloyla testli); burada AVAudioEngine'in kaynak düğümü SynthMixer'dan okur. Ses oturumu `playback` +
// `mixWithOthers`: sessiz düğmesi açıkken de çalar, arkadaki müziği durdurmaz (web AppDelegate.swift ile aynı).
// Motor ana iş parçacığını hiç bekletmez: ses karıştırıcıya hemen zamanlanır, motor kendi kuyruğunda başlatılır
// (ilk açılışta, ses açıksa önceden). Ses iş parçacığındaki kod hiçbir aktöre bağlı değildir (AudioOutput).
// Ayarlar › Ses / Titreşim kapalıysa hiçbiri çalmaz; AppRoot ayarı `enabled`'a yansıtır.
// Ritmi Tut için ses saati: `now` (şu an çıkışa verilen örneğin zamanı) ve `latency` (çıkış gecikmesi).
// UI testleri `-UITestNoAudio` ile açar: Codemagic simülatöründe iOS ses servisi yanıt vermiyor, ses birimi açılırken
// zaman aşımıyla uygulama kapanıyor (çökme raporu: AURemoteIO::Initialize, _ReportRPCTimeout). Testte motor hiç açılmaz.
import AVFoundation
import QuartzCore
import SolvatoCore
import UIKit

@MainActor
enum Sound {
    /// Ayarlar › Ses (web soundKeys); açılınca motor önceden başlatılır
    static var enabled = true {
        didSet { if enabled { AudioOutput.shared.warmUp() } else { stopAll() } }
    }

    /// Sesi hemen (ya da ses saatinde `at` anında) çalar. Ses kapalıysa hiçbir şey yapmaz.
    static func play(_ voices: [Voice], at: Double? = nil) {
        guard enabled, !voices.isEmpty else { return }
        AudioOutput.shared.mixer.schedule(voices, at: at)
        AudioOutput.shared.warmUp()
    }

    /// Piyano notası (tuşlar, dersler)
    static func note(_ name: String, octave: Int, delay: Double = 0) {
        play(Sounds.pianoNote(name, octave: octave, delay: delay))
    }

    /// Çalan ve sırada bekleyen sesleri susturur (turdan çıkınca)
    static func stopAll() { AudioOutput.shared.mixer.stopAll() }

    /// Ses saati (sn): şu an çıkışa verilen örneğin zamanı; zamanlama ve dokunuş ölçümü için tek kaynak
    static var now: Double {
        AudioOutput.disabled ? CACurrentMediaTime() : AudioOutput.shared.mixer.clock(host: CACurrentMediaTime())
    }

    /// Zamanlanan sesin kulağa ulaşma gecikmesi (sn); dokunuş bununla düzeltilir (web audioLatency)
    static var latency: Double { AudioOutput.shared.latency }
}

/// AVAudioEngine ve karıştırıcı. Hiçbir aktöre bağlı değil: motor işleri kendi seri kuyruğunda, ses üretimi ses iş
/// parçacığında (SynthMixer kilitli). Karıştırıcı 48 kHz tek kanal üretir; çıkışa dönüştürmeyi motor yapar.
final class AudioOutput: @unchecked Sendable {
    static let shared = AudioOutput()
    /// UI testinde ses çıkışı yok (bkz. dosya başı)
    static let disabled = ProcessInfo.processInfo.arguments.contains("-UITestNoAudio")

    let mixer = SynthMixer(sampleRate: 48000)
    private let queue = DispatchQueue(label: "solvato.audio")
    private let engine = AVAudioEngine()
    private var attached = false
    private var starting = false
    private let latencyLock = NSLock()
    private var cachedLatency = 0.0

    var latency: Double {
        latencyLock.lock()
        defer { latencyLock.unlock() }
        return cachedLatency
    }

    /// Motor çalışmıyorsa kendi kuyruğunda kurar ve başlatır (çağıran beklemez)
    func warmUp() {
        guard !Self.disabled else { return }
        queue.async { self.startIfNeeded() }
    }

    private func startIfNeeded() {
        if engine.isRunning { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        // Ses çıkışı yoksa (ör. derleme sunucusundaki simülatör) motor bağlanmaz: AVAudioEngine geçersiz çıkış biçiminde
        // yakalanamayan bir istisnayla uygulamayı kapatır. Bir sonraki seste yeniden denenir.
        let hw = engine.outputNode.outputFormat(forBus: 0)
        guard hw.sampleRate > 0, hw.channelCount > 0 else { return }
        if !attached {
            guard let format = AVAudioFormat(standardFormatWithSampleRate: mixer.sampleRate, channels: 1) else { return }
            let node = makeSourceNode(mixer, format: format)
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            attached = true
        }
        mixer.resetAnchor()
        engine.prepare()
        do { try engine.start() } catch { return }
        latencyLock.lock()
        cachedLatency = session.outputLatency
        latencyLock.unlock()
    }
}

/// Ses iş parçacığında çalışan kaynak düğümü. Dosya düzeyinde ve @Sendable: hiçbir aktöre bağlanmaz, Swift 6'nın
/// iş parçacığı denetimi ses iş parçacığında devreye girmez.
private func makeSourceNode(_ m: SynthMixer, format: AVAudioFormat) -> AVAudioSourceNode {
    let render: @Sendable (
        UnsafeMutablePointer<ObjCBool>, UnsafePointer<AudioTimeStamp>, AVAudioFrameCount, UnsafeMutablePointer<AudioBufferList>
    ) -> OSStatus = { _, timestamp, frameCount, data in
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
    return AVAudioSourceNode(format: format, renderBlock: render)
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
