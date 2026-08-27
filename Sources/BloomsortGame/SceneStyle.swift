#if canImport(SpriteKit)
import BloomsortDesign
import SpriteKit

/// `BloomsortDesign` tokenlarını SpriteKit tiplerine çevirir.
///
/// Tasarım katmanı bilerek çatıdan bağımsız (Linux'ta test edilebiliyor);
/// köprü burada.
public extension SKColor {
    convenience init(_ rgb: RGB) {
        self.init(red: CGFloat(rgb.red), green: CGFloat(rgb.green),
                  blue: CGFloat(rgb.blue), alpha: CGFloat(rgb.alpha))
    }
}

/// Sahnenin okuduğu oyuncu ayarları (`docs/ui-spec.md` §5).
public struct BoardPresentation: Sendable, Equatable {
    /// Renk körlüğü modu: her polen sembol taşır.
    public var colorBlindSymbols: Bool
    /// Azaltılmış hareket: süreler ×0,4, parçacıklar kapalı, çiçek açma
    /// tek kareli çapraz geçiş.
    public var reduceMotion: Bool
    /// Düşük güç modu: parçacıklar yarıya iner.
    public var lowPower: Bool

    public init(colorBlindSymbols: Bool = false,
                reduceMotion: Bool = false,
                lowPower: Bool = false) {
        self.colorBlindSymbols = colorBlindSymbols
        self.reduceMotion = reduceMotion
        self.lowPower = lowPower
    }

    public func duration(_ base: Double) -> TimeInterval {
        Motion.duration(base, reduceMotion: reduceMotion)
    }

    public var particlesEnabled: Bool { !reduceMotion }

    public func particleCount(_ base: Int) -> Int {
        guard particlesEnabled else { return 0 }
        return lowPower ? base / 2 : base
    }
}

/// Sahnede kullanılan z sıraları — arı her zaman en üstte (§3.5).
enum ZOrder {
    static let background: CGFloat = -100
    static let vessel: CGFloat = 0
    static let bead: CGFloat = 10
    static let selection: CGFloat = 20
    static let bloom: CGFloat = 30
    static let bee: CGFloat = 100
}
#endif
