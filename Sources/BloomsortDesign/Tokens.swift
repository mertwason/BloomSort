import Foundation

/// Aralık ölçeği — 4 pt tabanlı (`docs/ui-spec.md` §1.4).
public enum Spacing {
    public static let s1 = 4.0
    public static let s2 = 8.0
    public static let s3 = 12.0
    public static let s4 = 16.0
    public static let s5 = 24.0
    public static let s6 = 32.0
    public static let s7 = 48.0
    public static let s8 = 64.0
    /// Ekran kenar boşluğu, sol/sağ sabit.
    public static let screenMargin = 20.0
}

/// Köşe yarıçapları (§1.5).
public enum Radius {
    public static let small = 10.0
    public static let medium = 16.0
    public static let large = 24.0
    public static let extraLarge = 32.0
    public static let pill = 999.0
    /// Kap silueti: alt 20, üst 8 — organik vazo.
    public static let vesselBottom = 20.0
    public static let vesselMouth = 8.0
}

/// Hareket tokenları (§1.7). Süreler saniye.
public enum Motion {
    public static let tap = 0.09
    public static let micro = 0.18
    public static let beeMin = 0.34
    public static let beeMax = 0.52
    public static let bloom = 0.42
    public static let plate = 0.62
    public static let sheet = 0.32
    public static let screen = 0.28

    /// Çiçek açma yayı: `spring(response: .42, damping: .68)`.
    public static let bloomResponse = 0.42
    public static let bloomDamping = 0.68
    /// Levha presi yayı.
    public static let plateResponse = 0.55
    public static let plateDamping = 0.80

    /// Azaltılmış hareket açıkken bütün süreler bu katsayıyla çarpılır.
    public static let reducedMotionScale = 0.4

    public static func duration(_ base: Double, reduceMotion: Bool) -> Double {
        reduceMotion ? base * reducedMotionScale : base
    }
}

/// Tipografi ölçeği (§1.3). Boyut/satır yüksekliği punto.
public struct TextStyle: Hashable, Sendable {
    public enum Family: String, Sendable {
        /// Fraunces — logo, seviye numarası, levha adı. Ekranda en fazla 2 yerde.
        case display
        /// SF Pro Rounded — diğer her şey.
        case ui
        /// SF Pro Rounded, monospacedDigit — sayaçlar.
        case numeric
    }

    public let name: String
    public let size: Double
    public let lineHeight: Double
    public let weight: Int
    public let tracking: Double
    public let family: Family
    /// Dynamic Type ile ölçeklenir mi?
    public let scales: Bool
    /// Ölçeklenme üst sınırı (display stilleri düzeni bozmasın diye %130).
    public let maximumScale: Double

    public init(name: String, size: Double, lineHeight: Double, weight: Int,
                tracking: Double, family: Family, scales: Bool, maximumScale: Double = 1.3) {
        self.name = name
        self.size = size
        self.lineHeight = lineHeight
        self.weight = weight
        self.tracking = tracking
        self.family = family
        self.scales = scales
        self.maximumScale = maximumScale
    }
}

public enum Typography {
    public static let displayXL = TextStyle(name: "display-xl", size: 44, lineHeight: 48,
                                            weight: 600, tracking: -0.8, family: .display, scales: false)
    public static let displayL  = TextStyle(name: "display-l", size: 32, lineHeight: 38,
                                            weight: 600, tracking: -0.5, family: .display, scales: false)
    public static let displayM  = TextStyle(name: "display-m", size: 24, lineHeight: 30,
                                            weight: 600, tracking: -0.3, family: .display, scales: false)
    public static let title     = TextStyle(name: "title", size: 20, lineHeight: 26,
                                            weight: 700, tracking: -0.2, family: .ui, scales: true)
    public static let body      = TextStyle(name: "body", size: 17, lineHeight: 24,
                                            weight: 500, tracking: 0, family: .ui, scales: true,
                                            maximumScale: 3.0)
    public static let bodyStrong = TextStyle(name: "body-strong", size: 17, lineHeight: 24,
                                             weight: 700, tracking: 0, family: .ui, scales: true,
                                             maximumScale: 3.0)
    public static let caption   = TextStyle(name: "caption", size: 14, lineHeight: 20,
                                            weight: 500, tracking: 0.1, family: .ui, scales: true,
                                            maximumScale: 3.0)
    public static let micro     = TextStyle(name: "micro", size: 11, lineHeight: 14,
                                            weight: 700, tracking: 0.6, family: .ui, scales: true)
    public static let numericL  = TextStyle(name: "numeric-l", size: 28, lineHeight: 32,
                                            weight: 700, tracking: 0, family: .numeric, scales: false)

    public static let all: [TextStyle] = [displayXL, displayL, displayM, title, body,
                                          bodyStrong, caption, micro, numericL]
}

/// Kap ölçüleri (§2.2). Kapasite → genişlik, yükseklik, yuva çapı.
public enum VesselMetrics {
    public struct Size: Hashable, Sendable {
        public let width: Double
        public let height: Double
        public let slotDiameter: Double
    }

    public static func size(forCapacity capacity: Int) -> Size {
        switch capacity {
        case ...3: return Size(width: 62, height: 108, slotDiameter: 40)
        case 4:    return Size(width: 62, height: 134, slotDiameter: 40)
        case 5:    return Size(width: 66, height: 162, slotDiameter: 42)
        default:   return Size(width: 66, height: 188, slotDiameter: 42)
        }
    }

    /// Polen tanesi çapı = yuva çapı − 6.
    public static func beadDiameter(forCapacity capacity: Int) -> Double {
        size(forCapacity: capacity).slotDiameter - 6
    }

    /// Seçili kaynağın üst tanesi 8 pt yükselir, kap 4 pt zıplar (§2.2).
    public static let selectionLift = 8.0
    public static let selectionHop = 4.0
    /// Geçersiz hedef: 6 pt yatay titreme, 3 döngü, 240 ms.
    public static let invalidShake = 6.0
    public static let invalidShakeDuration = 0.24
}

/// Dokunma hedefi alt sınırı — her etkileşimli öğe (§2.1, §5).
public enum Layout {
    public static let minimumTapTarget = 44.0
    /// Referans cihaz: iPhone 16, 393 × 852 pt (§0).
    public static let referenceWidth = 393.0
    public static let referenceHeight = 852.0
    public static let safeAreaTop = 59.0
    public static let safeAreaBottom = 34.0
    /// Oyun ekranı tahta alanı (§3.5).
    public static let boardTop = 187.0
    public static let boardHeight = 449.0
}

/// Haptik haritası (§1.8).
public enum Haptic: String, Sendable, CaseIterable {
    case vesselSelected      // .soft
    case beadLanded          // .light
    case invalidMove         // .warning
    case bloomed             // .medium
    case levelComplete       // .success
    case platePressed        // .rigid
    case button              // .selection
}
