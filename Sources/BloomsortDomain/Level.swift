/// Bir seviyenin diskteki hâli.
///
/// Tahta saklanmaz; `seed` + parametreler saklanır ve oyun tahtayı üreticiyle
/// yeniden kurar (bkz. `docs/gdd.md` §4.1). Böylece 500 seviye ~40 KB'ta kalır
/// ve her cihazda birebir aynı tahta çıkar.
public struct Level: Codable, Hashable, Sendable {
    public let id: Int
    public let seed: UInt64
    /// Renk sayısı K.
    public let colors: Int
    /// Boş kap sayısı E.
    public let emptyVessels: Int
    /// Kap kapasiteleri: önce K renk kabı, sonra E boş kap.
    public let capacities: [Int]
    /// Uygulanan ters hamle sayısı R — tahtayı seed'den yeniden kurmak için
    /// gereken tek sayı.
    public let reverseMoves: Int
    /// Optimal hamle sayısı M*.
    public let optimalMoves: Int
    /// Ölçülen dallanma faktörü (kabul filtresi, ≥ 2,2).
    public let branchingFactor: Double

    public init(id: Int, seed: UInt64, colors: Int, emptyVessels: Int, capacities: [Int],
                reverseMoves: Int, optimalMoves: Int, branchingFactor: Double) {
        self.id = id
        self.seed = seed
        self.colors = colors
        self.emptyVessels = emptyVessels
        self.capacities = capacities
        self.reverseMoves = reverseMoves
        self.optimalMoves = optimalMoves
        self.branchingFactor = branchingFactor
    }

    /// Toplam kap sayısı.
    public var vesselCount: Int { colors + emptyVessels }

    /// Tahtayı seed'den yeniden kurar.
    public var board: GameState { LevelGenerator.board(for: self) }

    // NOT: Yıldız eşikleri burada YOK. GDD §8.3 "M* → yıldız eşiği" diyor ama
    // eşiğin kendisini (2★ ve 1★ için hamle çarpanlarını) hiçbir yerde
    // vermiyor. Sayı uydurmamak için boş bırakıldı; değerler netleşince
    // `stars(forMoves:)` buraya eklenecek.
}

/// `levels.json` dosyasının kökü.
public struct LevelPack: Codable, Hashable, Sendable {
    public let version: Int
    public let levels: [Level]

    public init(version: Int = 1, levels: [Level]) {
        self.version = version
        self.levels = levels
    }
}
