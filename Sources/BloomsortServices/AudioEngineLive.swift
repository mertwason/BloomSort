#if canImport(AVFoundation)
import AVFoundation
import Foundation

/// Gerçek ses motoru.
///
/// Notalar dosyadan değil, çalışma zamanında sentezleniyor — projede ses
/// dosyası yok, `CLAUDE.md`'nin "elle üretilmiş asset yok" kuralı görselde
/// olduğu gibi burada da geçerli. Ortam sesi ayrı bir döngü; §7.3'teki
/// pentatonik nota `PentatonicScale`'den geliyor (o kısım testli).
public final class AudioEngine: AudioEngineProtocol, @unchecked Sendable {
    public var isMuted = false {
        didSet { if isMuted { stopAmbience() } }
    }
    public var ambienceVolume: Double = 0.6 {
        didSet { ambienceMixer.volume = Float(ambienceVolume) }
    }

    private let engine = AVAudioEngine()
    private let ambienceMixer = AVAudioMixerNode()
    private let scale = PentatonicScale()
    private var isRunning = false

    public init() {
        engine.attach(ambienceMixer)
        engine.connect(ambienceMixer, to: engine.mainMixerNode, format: nil)
        ambienceMixer.volume = Float(ambienceVolume)
    }

    private func startEngineIfNeeded() {
        guard !isRunning else { return }
        do {
            #if os(iOS)
            // Ortam kategorisi: oyuncunun müziği kesilmesin.
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            try engine.start()
            isRunning = true
        } catch {
            // Ses açılamıyorsa oyun sessiz devam eder; oynanış etkilenmez.
            isRunning = false
        }
    }

    public func startAmbience() {
        guard !isMuted else { return }
        startEngineIfNeeded()
    }

    public func stopAmbience() {
        guard isRunning else { return }
        engine.pause()
        isRunning = false
    }

    public func playBeadLanded(depth: Int) {
        guard !isMuted else { return }
        playTone(frequency: scale.frequency(forDepth: depth), duration: 0.28, amplitude: 0.18)
    }

    public func play(_ effect: SoundEffect) {
        guard !isMuted else { return }
        switch effect {
        case .beadLanded:   playTone(frequency: scale.frequency(forDepth: 0), duration: 0.28, amplitude: 0.18)
        case .bloom:        playTone(frequency: scale.frequency(forDepth: 7), duration: 0.9, amplitude: 0.22)
        case .platePressed: playTone(frequency: 110, duration: 0.18, amplitude: 0.25)
        case .beeFlight:    playTone(frequency: 92, duration: 0.35, amplitude: 0.08)
        case .splashChime:  playTone(frequency: scale.frequency(forDepth: 4), duration: 1.2, amplitude: 0.2)
        }
    }

    /// Tek nota: sinüs + hızlı atak, yumuşak sönüm.
    private func playTone(frequency: Double, duration: TimeInterval, amplitude: Double) {
        startEngineIfNeeded()
        guard isRunning else { return }
        let sampleRate = 44_100.0
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(sampleRate * duration))
        else { return }
        buffer.frameLength = buffer.frameCapacity
        guard let samples = buffer.floatChannelData?[0] else { return }

        let frameCount = Int(buffer.frameLength)
        let attack = Int(sampleRate * 0.01)
        for frame in 0..<frameCount {
            let time = Double(frame) / sampleRate
            let envelope: Double
            if frame < attack {
                envelope = Double(frame) / Double(attack)
            } else {
                let decayProgress = Double(frame - attack) / Double(max(frameCount - attack, 1))
                envelope = pow(1 - decayProgress, 2.2)
            }
            samples[frame] = Float(sin(2 * .pi * frequency * time) * envelope * amplitude)
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            guard let self else { return }
            player.stop()
            self.engine.detach(player)
        }
        player.play()
    }
}
#endif
