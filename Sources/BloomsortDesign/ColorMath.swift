import Foundation

/// Renk — sRGB, 0...1 bileşenlerle. Saf veri; hiçbir UI çatısına bağlı değil,
/// böylece paletin kontrastı ve ayırt edilebilirliği testlerde ölçülebiliyor.
public struct RGB: Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// `#RRGGBB` ya da `RRGGBB`.
    public init(hex: String) {
        var digits = hex
        if digits.hasPrefix("#") { digits.removeFirst() }
        precondition(digits.count == 6, "Hex renk 6 basamak olmalı: \(hex)")
        let value = UInt32(digits, radix: 16)!
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }

    public var hex: String {
        String(format: "#%02X%02X%02X",
               Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }

    public func opacity(_ alpha: Double) -> RGB {
        RGB(red: red, green: green, blue: blue, alpha: alpha)
    }
}

/// Kontrast ve algısal renk farkı hesapları.
///
/// Erişilebilirlik iddiaları testle kanıtlanabilsin diye kodda duruyor:
/// `docs/ui-spec.md` §1.1'deki kontrast tablosu ve 12 polen renginin
/// birbirinden ayırt edilebilirliği `DesignTests` tarafından doğrulanıyor.
public enum ColorMath {

    /// WCAG bağıl parlaklık.
    public static func relativeLuminance(_ color: RGB) -> Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.red) + 0.7152 * linear(color.green) + 0.0722 * linear(color.blue)
    }

    /// WCAG kontrast oranı (1...21).
    public static func contrastRatio(_ a: RGB, _ b: RGB) -> Double {
        let la = relativeLuminance(a), lb = relativeLuminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    /// CIE L*a*b* (D65).
    public static func lab(_ color: RGB) -> (l: Double, a: Double, b: Double) {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        let r = linear(color.red), g = linear(color.green), b = linear(color.blue)
        let x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
        let y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
        let z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041
        func f(_ t: Double) -> Double {
            t > 216.0 / 24389.0 ? cbrt(t) : (841.0 / 108.0) * t + 4.0 / 29.0
        }
        let fx = f(x / 0.95047), fy = f(y / 1.0), fz = f(z / 1.08883)
        return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))
    }

    /// CIEDE2000 renk farkı. ~2 fark "zar zor ayırt edilir", ~15+ "açıkça farklı".
    public static func deltaE2000(_ first: RGB, _ second: RGB) -> Double {
        let (l1, a1, b1) = lab(first)
        let (l2, a2, b2) = lab(second)
        let c1 = hypot(a1, b1), c2 = hypot(a2, b2)
        let meanC = (c1 + c2) / 2
        let pow7 = pow(meanC, 7)
        let g = 0.5 * (1 - (pow7 / (pow7 + pow(25, 7))).squareRoot())
        let a1p = (1 + g) * a1, a2p = (1 + g) * a2
        let c1p = hypot(a1p, b1), c2p = hypot(a2p, b2)
        let h1p = c1p == 0 ? 0 : degrees(atan2(b1, a1p))
        let h2p = c2p == 0 ? 0 : degrees(atan2(b2, a2p))

        let deltaL = l2 - l1
        let deltaC = c2p - c1p
        var deltaSmallH = 0.0
        if c1p * c2p != 0 {
            let difference = h2p - h1p
            if abs(difference) <= 180 { deltaSmallH = difference }
            else if difference > 180 { deltaSmallH = difference - 360 }
            else { deltaSmallH = difference + 360 }
        }
        let deltaH = 2 * (c1p * c2p).squareRoot() * sin(radians(deltaSmallH) / 2)

        let meanL = (l1 + l2) / 2
        let meanCp = (c1p + c2p) / 2
        var meanH = h1p + h2p
        if c1p * c2p != 0 {
            if abs(h1p - h2p) <= 180 { meanH = (h1p + h2p) / 2 }
            else if h1p + h2p < 360 { meanH = (h1p + h2p + 360) / 2 }
            else { meanH = (h1p + h2p - 360) / 2 }
        }
        let t = 1 - 0.17 * cos(radians(meanH - 30))
                  + 0.24 * cos(radians(2 * meanH))
                  + 0.32 * cos(radians(3 * meanH + 6))
                  - 0.20 * cos(radians(4 * meanH - 63))
        let deltaTheta = 30 * exp(-pow((meanH - 275) / 25, 2))
        let meanCp7 = pow(meanCp, 7)
        let rc = 2 * (meanCp7 / (meanCp7 + pow(25, 7))).squareRoot()
        let sl = 1 + (0.015 * pow(meanL - 50, 2)) / (20 + pow(meanL - 50, 2)).squareRoot()
        let sc = 1 + 0.045 * meanCp
        let sh = 1 + 0.015 * meanCp * t
        let rt = -sin(radians(2 * deltaTheta)) * rc

        let termL = deltaL / sl, termC = deltaC / sc, termH = deltaH / sh
        return (termL * termL + termC * termC + termH * termH + rt * termC * termH).squareRoot()
    }

    private static func degrees(_ radians: Double) -> Double {
        let value = radians * 180 / .pi
        return value < 0 ? value + 360 : value
    }
    private static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
}
