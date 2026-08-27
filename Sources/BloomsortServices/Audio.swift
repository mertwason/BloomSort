import Foundation

/// İmza ses sistemi — `docs/gdd.md` §7.3.
///
/// "Her polen yerleşince pentatonik bir nota çalar; nota, kabın yığın
/// derinliğine göre yükselir. Aynı renk üst üste gelince arpej oluşur."
///
/// **Not.** §7.3 "1. tane = D, 5. tane = A" diyor. Beş notada D'den A'ya
/// çıkmak yarım ses aralığı gerektiriyor (D E F♯ G A) ve o dizi pentatonik
/// değil — pentatoniğin bütün mesele ettiği şey yarım ses içermemesi, yani
/// hangi notalar üst üste binerse binsin kulağı tırmalamaması. Burada D majör
/// pentatonik (D E F♯ A B) kullanılıyor; A dördüncü tanede geliyor. Sistemin
/// vaadi (derinlikle yükselen, hep uyumlu nota) korunuyor.
public struct PentatonicScale: Sendable, Equatable {
    /// Kök nota frekansı — D4.
    public static let rootFrequency = 293.6648
    /// D majör pentatonik, kökten yarım ses uzaklıkları.
    public static let semitoneOffsets = [0, 2, 4, 7, 9]

    public init() {}

    /// Yığın derinliğine karşılık gelen frekans. Derinlik 0 tabandaki tane.
    ///
    /// Dizinin sonuna gelince bir oktav yukarı devam eder — 6 kapasiteli
    /// kaplarda da nota yükselmeye devam etsin diye.
    public func frequency(forDepth depth: Int) -> Double {
        precondition(depth >= 0, "Derinlik negatif olamaz")
        let octave = depth / PentatonicScale.semitoneOffsets.count
        let degree = depth % PentatonicScale.semitoneOffsets.count
        let semitones = PentatonicScale.semitoneOffsets[degree] + 12 * octave
        return PentatonicScale.rootFrequency * pow(2, Double(semitones) / 12)
    }

    /// Nota adı — teşhis ve testler için.
    public func noteName(forDepth depth: Int) -> String {
        let names = ["D", "E", "F#", "A", "B"]
        let octave = 4 + depth / names.count
        return "\(names[depth % names.count])\(octave)"
    }
}

/// Ses olayları (§7.3).
public enum SoundEffect: String, Sendable, CaseIterable {
    /// Polen yerleşti — pentatonik nota, frekans derinlikten gelir.
    case beadLanded
    /// Çiçek açtı: yumuşak yaprak hışırtısı + tek çan notası.
    case bloom
    /// Levha presi: kâğıt bastırma + ahşap tık.
    case platePressed
    /// Arı uçuşu: mesafeyle pitch'i değişen düşük uğultu.
    case beeFlight
    /// Açılış çanı.
    case splashChime
}

/// Ses motorunun sözleşmesi.
///
/// Ortam sesi 90 sn döngü, kesintisiz (§7.3). Bütün sesler kapatılabilir,
/// haptik ayrı kapatılabilir.
public protocol AudioEngineProtocol: AnyObject {
    var isMuted: Bool { get set }
    var ambienceVolume: Double { get set }
    func startAmbience()
    func stopAmbience()
    /// Polen yerleşti — nota yığın derinliğine göre seçilir.
    func playBeadLanded(depth: Int)
    func play(_ effect: SoundEffect)
}

/// Testlerde ve önizlemelerde kullanılan sahte ses motoru.
public final class FakeAudioEngine: AudioEngineProtocol, @unchecked Sendable {
    public var isMuted = false
    public var ambienceVolume = 1.0
    public private(set) var ambiencePlaying = false
    public private(set) var playedNotes: [Double] = []
    public private(set) var playedEffects: [SoundEffect] = []
    private let scale = PentatonicScale()

    public init() {}

    public func startAmbience() { ambiencePlaying = true }
    public func stopAmbience() { ambiencePlaying = false }

    public func playBeadLanded(depth: Int) {
        guard !isMuted else { return }
        playedNotes.append(scale.frequency(forDepth: depth))
        playedEffects.append(.beadLanded)
    }

    public func play(_ effect: SoundEffect) {
        guard !isMuted else { return }
        playedEffects.append(effect)
    }
}

/// Haptik motorunun sözleşmesi — harita `docs/ui-spec.md` §1.8'de,
/// `BloomsortDesign.Haptic` olarak.
public protocol HapticEngineProtocol: AnyObject {
    var isEnabled: Bool { get set }
    func play(_ haptic: HapticKind)
}

/// Haptik tipleri. `BloomsortDesign.Haptic` ile birebir eşleşir; servis
/// katmanı tasarım katmanına bağımlı olmasın diye burada da tanımlı.
public enum HapticKind: String, Sendable, CaseIterable {
    case vesselSelected   // .soft, 0,4
    case beadLanded       // .light, 0,6
    case invalidMove      // .warning
    case bloomed          // .medium, 0,8
    case levelComplete    // .success
    case platePressed     // .rigid, 1,0
    case button           // .selection

    /// Darbe şiddeti (0...1); bildirim tipi haptiklerde `nil`.
    public var intensity: Double? {
        switch self {
        case .vesselSelected: return 0.4
        case .beadLanded:     return 0.6
        case .bloomed:        return 0.8
        case .platePressed:   return 1.0
        case .invalidMove, .levelComplete, .button: return nil
        }
    }
}

public final class FakeHapticEngine: HapticEngineProtocol, @unchecked Sendable {
    public var isEnabled = true
    public private(set) var played: [HapticKind] = []
    public init() {}
    public func play(_ haptic: HapticKind) {
        guard isEnabled else { return }
        played.append(haptic)
    }
}
