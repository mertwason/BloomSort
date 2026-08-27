/// Zorluk eğrisi — `docs/gdd.md` §4.2 tablosunun kod karşılığı.
///
/// Sayılar tablodan; tek sapma `M*` tavanının 30'a çekilmesi (aşağıda
/// gerekçesiyle birlikte, `docs/gdd.md` §4.2'ye de işlendi). Tabloda olmayan
/// tek parametre karıştırma derinliği `R`'dir: üretici onu sabit almak yerine
/// `M*` hedef banda oturana kadar yürür (bkz. `LevelGenerator`).
public struct DifficultyBand: Sendable, Hashable {
    public let levels: ClosedRange<Int>
    public let colors: ClosedRange<Int>
    public let emptyVessels: ClosedRange<Int>
    /// Kapasite havuzu; tek elemanlıysa sabit kapasite demektir.
    public let capacityPool: [Int]
    public let optimalMoves: ClosedRange<Int>
    /// Bu bantta devreye giren yeni mekanik (henüz uygulanmadı, bkz. README).
    public let newMechanic: String?

    public init(levels: ClosedRange<Int>, colors: ClosedRange<Int>,
                emptyVessels: ClosedRange<Int>, capacityPool: [Int],
                optimalMoves: ClosedRange<Int>, newMechanic: String? = nil) {
        self.levels = levels
        self.colors = colors
        self.emptyVessels = emptyVessels
        self.capacityPool = capacityPool
        self.optimalMoves = optimalMoves
        self.newMechanic = newMechanic
    }
}

public enum Difficulty {
    /// Zorluk tablosu — §4.2, **`M*` bantları düşürülmüş hâliyle**.
    ///
    /// Renk sayısı, boş kap sayısı ve kapasite havuzu tabloda yazdığı gibi.
    /// `M*` bantları ise 26. seviyeden itibaren aşağı çekildi: §4.2 geç
    /// seviyeler için 40-70 istiyor, kesin optimal çözücü ise 12 renk / 15 kap
    /// mertebesinde `M* ≈ 32`'den sonra saniyelerden dakikalara çıkıyor ve
    /// üretimi doğrulayamıyor (ölçümler README'de). Karar: `M*` tavanı 30'da
    /// tutuluyor, zorluk **renk ve kapasite çeşitliliğiyle** artmaya devam
    /// ediyor. Taban her bantta bir tık yükseliyor ki eğri düzleşmesin.
    public static let bands: [DifficultyBand] = [
        DifficultyBand(levels: 1...3,      colors: 2...2,  emptyVessels: 2...2, capacityPool: [4],
                       optimalMoves: 3...6),
        DifficultyBand(levels: 4...10,     colors: 3...4,  emptyVessels: 2...2, capacityPool: [4],
                       optimalMoves: 8...14),
        DifficultyBand(levels: 11...25,    colors: 5...7,  emptyVessels: 2...2, capacityPool: [4],
                       optimalMoves: 16...26),
        DifficultyBand(levels: 26...40,    colors: 6...8,  emptyVessels: 2...2, capacityPool: [3, 4, 5, 6],
                       optimalMoves: 22...28, newMechanic: "Kapasite çeşitliliği"),
        DifficultyBand(levels: 41...60,    colors: 7...9,  emptyVessels: 2...2, capacityPool: [3, 4, 5, 6],
                       optimalMoves: 24...29, newMechanic: "Kapalı tomurcuk"),
        DifficultyBand(levels: 61...85,    colors: 8...10, emptyVessels: 2...3, capacityPool: [3, 4, 5, 6],
                       optimalMoves: 25...30, newMechanic: "Çiy damlası"),
        DifficultyBand(levels: 86...115,   colors: 8...10, emptyVessels: 2...3, capacityPool: [3, 4, 5, 6],
                       optimalMoves: 26...30, newMechanic: "Rüzgâr"),
        DifficultyBand(levels: 116...150,  colors: 9...11, emptyVessels: 3...3, capacityPool: [3, 4, 5, 6],
                       optimalMoves: 27...30, newMechanic: "Arı bütçesi"),
        DifficultyBand(levels: 151...9999, colors: 9...12, emptyVessels: 2...4, capacityPool: [3, 4, 5, 6],
                       optimalMoves: 28...30),
    ]

    public static func band(for level: Int) -> DifficultyBand {
        precondition(level >= 1, "Seviye numarası 1'den başlar")
        return bands.first { $0.levels.contains(level) } ?? bands[bands.count - 1]
    }

    /// Zorluk zikzağı: her 5 seviyede bir kasıtlı nefes seviyesi
    /// (bkz. `docs/gdd.md` §4.2 — "M* hedef bandın %60'ı").
    public static func isBreatherLevel(_ level: Int) -> Bool { level % 5 == 0 }

    /// Seviyenin gerçek `M*` bandı — nefes seviyelerinde %60'a çekilmiş hâli.
    public static func optimalMoveRange(for level: Int) -> ClosedRange<Int> {
        let band = band(for: level).optimalMoves
        guard isBreatherLevel(level) else { return band }
        let lower = max(1, Int((Double(band.lowerBound) * 0.6).rounded()))
        let upper = max(lower, Int((Double(band.upperBound) * 0.6).rounded()))
        return lower...upper
    }
}
