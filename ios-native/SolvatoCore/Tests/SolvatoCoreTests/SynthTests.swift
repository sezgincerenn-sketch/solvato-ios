// Ses sentezi (G-07): web'in Chromium'da OfflineAudioContext ile ürettiği seslerin 5 ms'lik RMS düzeyleri
// (Fixtures/ses.json, scripts/altin-ses.mjs) SynthMixer'ın ürettiği seslerle pencere pencere aynı olmalı:
// aynı perde ve harmonikler (vuruşlar aynı yerde), aynı zarf, aynı sıra ve süre.
import Foundation
import XCTest

@testable import SolvatoCore

final class SynthTests: XCTestCase {
    private func fixture() throws -> JSON {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "ses", withExtension: "json", subdirectory: "Fixtures"))
        return try JSON.parse(Data(contentsOf: url))
    }

    /// Sesi 48 kHz'de üretir ve 5 ms'lik pencerelerin RMS'ini verir (sondaki sessizlik atılır)
    private func rms(_ voices: [Voice], at: Double? = nil) -> [Double] {
        let m = SynthMixer(sampleRate: 48000)
        m.schedule(voices, at: at)
        let n = 48000 * 4
        var buf = [Float](repeating: 0, count: n)
        // Uygulamadaki gibi küçük parçalar hâlinde (512 örnek)
        buf.withUnsafeMutableBufferPointer { p in
            var i = 0
            while i < n {
                let k = min(512, n - i)
                m.render(p.baseAddress! + i, frames: k)
                i += k
            }
        }
        var out: [Double] = []
        for i in stride(from: 0, to: n, by: 240) {
            let s = buf[i..<(i + 240)].reduce(0.0) { $0 + Double($1) * Double($1) }
            out.append(((s / 240).squareRoot() * 1e5).rounded() / 1e5)
        }
        while out.last == 0 { out.removeLast() }
        return out
    }

    func testSoundsMatchWeb() throws {
        let sounds = try XCTUnwrap(fixture()["sounds"]?.object)
        let ear = Sounds.ear(.note(ref: Pitch(name: "Do", octave: 4), target: Pitch(name: "Sol", octave: 4)))
        let earChord = Sounds.ear(.chord(notes: [Pitch(name: "Do", octave: 4), Pitch(name: "Mi", octave: 4), Pitch(name: "Sol", octave: 4)]))
        let cases: [(String, [Voice], Double?)] = [
            ("piyano-Do4", Sounds.pianoNote("Do", octave: 4), nil),
            ("piyano-La#5", Sounds.pianoNote("La#", octave: 5), nil),
            ("piyano-Sol3-akor", Sounds.pianoNote("Sol", octave: 3, delay: 0.25, volume: 0.24), nil),
            ("dogru", Sounds.correctChime, nil),
            ("yanlis", Sounds.wrongBuzz, nil),
            ("tur-sonu", Sounds.sessionDone, nil),
            ("hedef", Sounds.goalDone, nil),
            ("seviye", Sounds.levelUp, nil),
            ("seri", Sounds.streakUp, nil),
            ("tik-vurgulu", Sounds.click(strong: true), 0.1),
            ("tik", Sounds.click(strong: false), 0.1),
            ("ritim-notasi", Sounds.beat, 0.1),
            ("kulak-nota", ear.voices, nil),
            ("kulak-akor", earChord.voices, nil),
        ]
        XCTAssertEqual(Set(cases.map(\.0)), Set(sounds.keys))
        for (name, voices, at) in cases {
            let web = sounds[name]?["rms"]?.array?.compactMap(\.double) ?? []
            let mine = rms(voices, at: at)
            // Süre: son sesli pencere en çok bir pencere farklı
            XCTAssertLessThanOrEqual(abs(web.count - mine.count), 1, "\(name): süre \(web.count) ≠ \(mine.count) pencere")
            // Düzey: her pencerede tepe düzeyin %3'ünden az fark. "Yanlış" sesinde ikinci nota 130 ms'de, Chrome'un
            // 128 örneklik bloğunun ortasında başlar; Chrome o bloğun sonuna kadar (0,7 ms) frekansı varsayılan 440 Hz
            // alır (web kodunun amacı 220 Hz). İki notanın girişimi bu yüzden kayar: orada pencere pencere değil, toplam
            // enerji karşılaştırılır; tek notalı ilk 130 ms birebir.
            let peak = web.max() ?? 1
            let strict = name == "yanlis" ? 26 : min(web.count, mine.count)
            if name == "yanlis" {
                let e = { (a: [Double]) in a.reduce(0) { $0 + $1 * $1 } }
                XCTAssertEqual(e(mine) / e(web), 1, accuracy: 0.05, "\(name): toplam enerji")
            }
            var worst = 0.0
            var at = 0
            for i in 0..<strict where abs(web[i] - mine[i]) > worst {
                worst = abs(web[i] - mine[i])
                at = i
            }
            XCTAssertLessThan(worst / peak, 0.03, "\(name): \(at * 5) ms'de \(web[at]) ≠ \(mine[at])")
        }
        // "Çalıyor" süreleri web'le aynı (ms)
        XCTAssertEqual(ear.duration * 1000, sounds["kulak-nota"]?["ms"]?.double ?? 0, accuracy: 0.001)
        XCTAssertEqual(earChord.duration * 1000, sounds["kulak-akor"]?["ms"]?.double ?? 0, accuracy: 0.001)
    }

    func testMixerClockAndScheduling() {
        let m = SynthMixer(sampleRate: 48000)
        XCTAssertEqual(m.time, 0)
        var buf = [Float](repeating: 1, count: 4800)
        // Gelecekte zamanlanan ses o ana kadar sessiz
        m.schedule(Sounds.click(strong: true), at: 0.05)
        buf.withUnsafeMutableBufferPointer { m.render($0.baseAddress!, frames: 2400) }
        XCTAssertEqual(m.time, 0.05, accuracy: 1e-9)
        XCTAssertTrue(buf[0..<2400].allSatisfy { $0 == 0 })
        XCTAssertTrue(m.isBusy)
        buf.withUnsafeMutableBufferPointer { m.render($0.baseAddress!, frames: 4800) }
        XCTAssertGreaterThan(buf[0..<480].map(abs).max() ?? 0, 0.05)
        // Tık 0,06 sn sonra biter, karıştırıcı boşalır
        XCTAssertFalse(m.isBusy)
        m.schedule(Sounds.correctChime)
        m.stopAll()
        XCTAssertFalse(m.isBusy)
    }

    func testHostClockIsContinuous() {
        let m = SynthMixer(sampleRate: 48000)
        var buf = [Float](repeating: 0, count: 480)
        XCTAssertEqual(m.clock(host: 100), 0)
        // 480 örneklik parça cihaz saatinde 100,0'da çıkar: arada geçen süre ses saatine eklenir
        buf.withUnsafeMutableBufferPointer { m.render($0.baseAddress!, frames: 480, host: 100) }
        XCTAssertEqual(m.clock(host: 100.004), 0.004, accuracy: 1e-9)
        buf.withUnsafeMutableBufferPointer { m.render($0.baseAddress!, frames: 480, host: 100.01) }
        XCTAssertEqual(m.clock(host: 100.012), 0.012, accuracy: 1e-9)
        XCTAssertEqual(m.time, 0.02, accuracy: 1e-9)
    }

    func testCelebrationSound() {
        XCTAssertEqual(Celebration(rankUp: .init(rank: 2, label: "x"), goalDone: true, streak: 3).sound, Sounds.levelUp)
        XCTAssertEqual(Celebration(goalDone: true, streak: 3, unlocked: "Orta").sound, Sounds.levelUp)
        XCTAssertEqual(Celebration(goalDone: true, streak: 3).sound, Sounds.goalDone)
        XCTAssertEqual(Celebration(streak: 3).sound, Sounds.streakUp)
    }

    func testUnknownNoteIsSilent() {
        XCTAssertTrue(Sounds.pianoNote("Mib", octave: 4).isEmpty)
        XCTAssertEqual(Sounds.pianoNote("Do", octave: 5).first?.freq ?? 0, 523.26, accuracy: 1e-9)
    }
}
