import Foundation

/// Basit nokta — `CGPoint` Linux'ta yok, tasarım katmanı ise platformdan
/// bağımsız kalmak zorunda (testler burada koşuyor).
public struct Point: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// Arı uçuşunun geometrisi ve zamanlaması (`docs/ui-spec.md` §2.3, §2.6).
///
/// SpriteKit'ten bağımsız tutuldu ki eğrinin ve sürenin spec'e uyduğu
/// test edilebilsin.
public enum BeeFlight {
    /// Kontrol noktası, iki ucun orta noktasının 40 pt üstünde.
    public static let controlPointRise = 40.0

    public static func controlPoint(from start: Point, to end: Point) -> Point {
        Point(x: (start.x + end.x) / 2, y: max(start.y, end.y) + controlPointRise)
    }

    /// `0,34 sn + 0,04 sn × mesafe/100`, `motion-bee` üst sınırında kırpılır.
    public static func duration(distance: Double, reduceMotion: Bool = false) -> Double {
        let raw = min(Motion.beeMin + 0.04 * distance / 100, Motion.beeMax)
        return Motion.duration(raw, reduceMotion: reduceMotion)
    }

    public static func distance(from start: Point, to end: Point) -> Double {
        (pow(end.x - start.x, 2) + pow(end.y - start.y, 2)).squareRoot()
    }

    /// Kuadratik Bézier üzerindeki nokta — testler eğrinin gerçekten
    /// yükseldiğini doğruluyor.
    public static func point(onCurveFrom start: Point, to end: Point, t: Double) -> Point {
        let control = controlPoint(from: start, to: end)
        let inverse = 1 - t
        return Point(
            x: inverse * inverse * start.x + 2 * inverse * t * control.x + t * t * end.x,
            y: inverse * inverse * start.y + 2 * inverse * t * control.y + t * t * end.y)
    }

    /// Uçuş izi: 5 nokta, çap 3 → 1, opaklık %40 → 0 (§2.3).
    public static let trailDotCount = 5
    public static let trailStartDiameter = 3.0
    public static let trailEndDiameter = 1.0
    public static let trailStartOpacity = 0.4
}
