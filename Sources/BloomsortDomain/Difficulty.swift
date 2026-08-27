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
    /// Bu bantta devreye giren yeni mekanik.
    public let mechanic: ObstacleKind?

    /// Tabloda yazan mekanik adı.
    public var newMechanic: String? { mechanic?.turkishName }

    public init(levels: ClosedRange<Int>, colors: ClosedRange<Int>,
                emptyVessels: ClosedRange<Int>, capacityPool: [Int],
                optimalMoves: ClosedRange<Int>, mechanic: ObstacleKind? = nil) {
        self.levels = levels
        self.colors = colors
        self.emptyVessels = emptyVessels
        self.capacityPool = capacityPool
        self.optimalMoves = optimalMoves
        self.mechanic = mechanic
    }
}

public enum Difficulty {
    /// Zorluk tablosu — §4.2, **`M*` bantları yeniden ölçeklenmiş hâliyle**.
    ///
    /// Renk sayısı, boş kap sayısı ve kapasite havuzu tabloda yazdığı gibi.
    /// `M*` bantları 11. seviyeden itibaren aşağı çekildi, tavan 26. Sebep
    /// ölçüm: üretici her tahtayı **kesin optimal** bir IDA* çözücüyle
    /// doğruluyor ve bu arama `M*` büyüdükçe üstel patlıyor — 12 renkli bir
    /// tahtada `M* = 26` için ~60 sn, `M* = 29` için ~180 sn, `M* ≥ 35` için
    /// bütçe içinde hiç. §4.2'nin geç seviyeler için istediği 40-70 bandı
    /// doğrulanamıyor, `M*` de hem yıldız eşiğini hem kabul filtresini
    /// beslediği için tahmin edilemez.
    ///
    /// Ölçekleme eğrinin **şeklini** koruyor: bantlar örtüşerek yükseliyor,
    /// tavan 26'da duruyor. Zorluk buradan sonra renk sayısı, boş kap sayısı
    /// ve kapasite çeşitliliğiyle artmaya devam ediyor.
    public static let bands: [DifficultyBand] = [
        DifficultyBand(levels: 1...3,      colors: 2...2,  emptyVessels: 2...2, capacityPool: [4],
                       optimalMoves: 3...6),
        DifficultyBand(levels: 4...10,     colors: 3...4,  emptyVessels: 2...2, capacityPool: [4],
                       optimalMoves: 8...14),
        DifficultyBand(levels: 11...25,    colors: 5...7,  emptyVessels: 2...2, capacityPool: [4],
                       optimalMoves: 14...18),
        DifficultyBand(levels: 26...40,    colors: 6...8,  emptyVessels: 2...2, capacityPool: [3, 4, 5, 6],
                       optimalMoves: 17...21, mechanic: nil),
        DifficultyBand(levels: 41...60,    colors: 7...9,  emptyVessels: 2...2, capacityPool: [3, 4, 5, 6],
                       optimalMoves: 19...22, mechanic: .closedBud),
        DifficultyBand(levels: 61...85,    colors: 8...10, emptyVessels: 2...3, capacityPool: [3, 4, 5, 6],
                       optimalMoves: 19...22, mechanic: .dewDrop),
        DifficultyBand(levels: 86...115,   colors: 8...10, emptyVessels: 2...3, capacityPool: [3, 4, 5, 6],
                       optimalMoves: 19...22, mechanic: .wind),
        DifficultyBand(levels: 116...150,  colors: 9...11, emptyVessels: 3...3, capacityPool: [3, 4, 5, 6],
                       optimalMoves: 19...22, mechanic: .beeBudget),
        DifficultyBand(levels: 151...9999, colors: 9...12, emptyVessels: 2...4, capacityPool: [3, 4, 5, 6],
                       optimalMoves: 19...22),
    ]

    public static func band(for level: Int) -> DifficultyBand {
        precondition(level >= 1, "Seviye numarası 1'den başlar")
        return bands.first { $0.levels.contains(level) } ?? bands[bands.count - 1]
    }

    /// Seviyede hangi engeller var.
    ///
    /// Her bant kendi mekaniğini getirir (§4.2 "Yeni mekanik" sütunu). 151.
    /// seviyeden sonra §4.2 "her 15 seviyede engel kombinasyonu rotasyonu"
    /// diyor: tahtayı etkileyen üç mekaniğin boş olmayan kombinasyonları
    /// sırayla dönüyor.
    ///
    /// **Arı bütçesi** tahtayı değiştirmez — yumuşak hamle limiti, yani 2★
    /// eşiği (bkz. `Level.moveBudget`). 116. seviyeden itibaren her seviyede
    /// gösterilir, o yüzden listede sabit durur.
    public static func obstacles(for level: Int) -> [ObstacleKind] {
        var kinds: [ObstacleKind] = []
        if level >= 116 { kinds.append(.beeBudget) }
        guard level >= 151 else {
            if let mechanic = band(for: level).mechanic, mechanic != .beeBudget {
                kinds.append(mechanic)
            }
            return kinds
        }
        let rotation = boardObstacleRotation[((level - 151) / 15) % boardObstacleRotation.count]
        kinds.append(contentsOf: rotation)
        return kinds
    }

    /// Tahtayı etkileyen mekaniklerin rotasyonu (§4.2, seviye 151+).
    static let boardObstacleRotation: [[ObstacleKind]] = [
        [.closedBud],
        [.dewDrop],
        [.wind],
        [.closedBud, .dewDrop],
        [.dewDrop, .wind],
        [.closedBud, .wind],
        [.closedBud, .dewDrop, .wind],
    ]

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

    /// Üreticinin sırayla deneyeceği bantlar.
    ///
    /// Nefes seviyesi kuralı (§4.2, "M* hedef bandın %60'ı") geç bantlarda
    /// bandın kendisiyle çelişiyor: 10 renkli bir tahta 11 hamlede ancak
    /// baştan yarı çözülmüş olursa biter, o da §4.1'in bayat tahta filtresine
    /// takılır. Bu yüzden indirilmiş bant **önce denenir**, tutmazsa bandın
    /// tamamına düşülür — sabit bir kaçış değeri uydurmak yerine.
    public static func candidateRanges(for level: Int) -> [ClosedRange<Int>] {
        let full = band(for: level).optimalMoves
        let preferred = optimalMoveRange(for: level)
        return preferred == full ? [full] : [preferred, full]
    }
}
