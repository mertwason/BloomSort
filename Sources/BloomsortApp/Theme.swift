#if canImport(SwiftUI)
import BloomsortDesign
import SwiftUI

/// `BloomsortDesign` tokenlarını SwiftUI tiplerine çevirir.
public extension Color {
    init(_ rgb: RGB) {
        self.init(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.alpha)
    }
}

/// Palet kısayolları.
public enum Theme {
    public static let dusk = Color(Palette.dusk)
    public static let duskDeep = Color(Palette.duskDeep)
    public static let moss = Color(Palette.moss)
    public static let mossHigh = Color(Palette.mossHigh)
    public static let mist = Color(Palette.mist)
    public static let mistDim = Color(Palette.mistDim)
    public static let pollen = Color(Palette.pollen)
    public static let pollenDeep = Color(Palette.pollenDeep)
    public static let erguvan = Color(Palette.erguvan)
    public static let dew = Color(Palette.dew)
    public static let ember = Color(Palette.ember)
    public static let platePaper = Color(Palette.platePaper)
    public static let plateInk = Color(Palette.plateInk)

    public static func pollenColor(_ index: Int) -> Color {
        Color(Palette.pollen(index).color)
    }
}

/// Tipografi (`docs/ui-spec.md` §1.3).
///
/// Display ailesi Fraunces; sistemde yoksa yuvarlatılmış serif'e düşer.
/// `display-*` en fazla %130 ölçeklenir ki düzen bozulmasın.
public extension Font {
    static func bloomsort(_ style: TextStyle) -> Font {
        switch style.family {
        case .display:
            return .custom("Fraunces", size: style.size, relativeTo: .title)
        case .ui:
            return .system(size: style.size, weight: weight(style.weight), design: .rounded)
        case .numeric:
            return .system(size: style.size, weight: weight(style.weight), design: .rounded)
                .monospacedDigit()
        }
    }

    private static func weight(_ value: Int) -> Font.Weight {
        switch value {
        case ..<400: return .light
        case 400..<500: return .regular
        case 500..<600: return .medium
        case 600..<700: return .semibold
        default: return .bold
        }
    }
}

public extension View {
    /// Stil + harf aralığı + Dynamic Type sınırı birlikte.
    func textStyle(_ style: TextStyle) -> some View {
        font(.bloomsort(style))
            .tracking(style.tracking)
            .lineSpacing(max(0, style.lineHeight - style.size) / 2)
            .dynamicTypeSize(style.scales ? .xSmall ... .accessibility3 : .large ... .large)
    }
}
#endif
