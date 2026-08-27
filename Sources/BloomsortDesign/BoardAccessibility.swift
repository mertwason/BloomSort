/// VoiceOver metinleri (`docs/ui-spec.md` §5, `CLAUDE.md`).
///
/// Metinler burada, sunum katmanında değil: erişilebilirlik "sonradan
/// eklenmez, baştan yazılır" ve buradaki hâli testlenebiliyor.
public enum BoardAccessibility {

    /// Kabı anlatan bir cümle:
    /// `"Kap 3. 4 kapasiteli. Üstte sarı polen. 2 dolu."`
    public static func vesselLabel(index: Int, capacity: Int, filled: Int,
                                   topColorIndex: Int?, lockCountdown: Int = 0,
                                   hasDew: Bool = false) -> String {
        var parts = ["Kap \(index + 1).", "\(capacity) kapasiteli."]
        if let topColorIndex {
            parts.append("Üstte \(Palette.pollen(topColorIndex).name.lowercased()) polen.")
            parts.append("\(filled) dolu.")
        } else {
            parts.append("Boş.")
        }
        if lockCountdown > 0 {
            parts.append("Kilitli, \(lockCountdown) polen kaldı.")
        }
        if hasDew { parts.append("Donmuş polen var.") }
        return parts.joined(separator: " ")
    }

    /// Hamle duyurusu: `"Sarı polen kap 3'ten kap 7'ye taşındı."`
    public static func moveAnnouncement(colorIndex: Int, from source: Int, to destination: Int) -> String {
        "\(Palette.pollen(colorIndex).name) polen kap \(source + 1)'ten kap \(destination + 1)'ye taşındı."
    }

    /// Çiçek açma duyurusu: `"Kap 5 çiçek açtı. 4 renk kaldı."`
    public static func bloomAnnouncement(vessel: Int, remainingColors: Int) -> String {
        "Kap \(vessel + 1) çiçek açtı. \(remainingColors) renk kaldı."
    }

    /// Rüzgâr uyarısı (§3.5): `"3 hamle sonra kap 2 ile kap 5 yer değiştirecek."`
    public static func windAnnouncement(movesAway: Int, first: Int, second: Int) -> String {
        "\(movesAway) hamle sonra kap \(first + 1) ile kap \(second + 1) yer değiştirecek."
    }
}
