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
    /// Tahtaya konan engeller (§4.2). Engelsiz seviyelerde boş.
    public let obstacles: ObstacleLayout

    /// Bu seviyede hangi engel tipleri var (zorluk tablosundan türetilir).
    public var obstacleKinds: [ObstacleKind] { Difficulty.obstacles(for: id) }

    public init(id: Int, seed: UInt64, colors: Int, emptyVessels: Int, capacities: [Int],
                reverseMoves: Int, optimalMoves: Int, branchingFactor: Double,
                obstacles: ObstacleLayout = .none) {
        self.id = id
        self.seed = seed
        self.colors = colors
        self.emptyVessels = emptyVessels
        self.capacities = capacities
        self.reverseMoves = reverseMoves
        self.optimalMoves = optimalMoves
        self.branchingFactor = branchingFactor
        self.obstacles = obstacles
    }

    /// Eski paketlerde `obstacles` alanı yok; onu boş kabul ederek okuyoruz ki
    /// biçime alan eklemek diskteki dosyayı geçersiz kılmasın.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        seed = try container.decode(UInt64.self, forKey: .seed)
        colors = try container.decode(Int.self, forKey: .colors)
        emptyVessels = try container.decode(Int.self, forKey: .emptyVessels)
        capacities = try container.decode([Int].self, forKey: .capacities)
        reverseMoves = try container.decode(Int.self, forKey: .reverseMoves)
        optimalMoves = try container.decode(Int.self, forKey: .optimalMoves)
        branchingFactor = try container.decode(Double.self, forKey: .branchingFactor)
        obstacles = try container.decodeIfPresent(ObstacleLayout.self, forKey: .obstacles) ?? .none
    }

    /// Toplam kap sayısı.
    public var vesselCount: Int { colors + emptyVessels }

    /// Tahtayı seed'den yeniden kurar.
    public var board: GameState { LevelGenerator.board(for: self) }

    /// Oyuncunun aldığı yıldız (bkz. `docs/gdd.md` §8.3, karar notu).
    ///
    /// 3★ yalnızca **tam optimal** çözümde. 2★ için tolerans `M* × 1,25`.
    /// Üstü 1★ — kaybetme yok, yalnızca yıldız düşer.
    public func stars(forMoves moves: Int) -> Int {
        if moves <= optimalMoves { return 3 }
        if Double(moves) <= Double(optimalMoves) * Level.twoStarTolerance { return 2 }
        return 1
    }

    /// 2★ eşiğinin optimal hamleye oranı.
    public static let twoStarTolerance = 1.25

    /// **Arı bütçesi** (§4.2, seviye 116+): "yumuşak hamle limiti; aşmak
    /// seviyeyi kaybettirmez, sadece yıldızı düşürür".
    ///
    /// Bütçe için ayrı bir sayı uydurmak yerine 2★ eşiğine bağlandı: bütçeyi
    /// aşmak tam olarak 1★'a düşmek demek. `docs/ui-spec.md` §3.5'teki
    /// "12/16" göstergesi bu iki sayıyı gösterir.
    public var moveBudget: Int {
        Int((Double(optimalMoves) * Level.twoStarTolerance).rounded(.down))
    }
}

/// Bir seviyenin tahtasına konan engeller.
///
/// Engeller seed'den de türetilebilirdi ama kayıtta açıkça duruyorlar:
/// dosya zaten küçük ve bir seviyenin neye benzediği kayda bakınca görülüyor.
/// `LevelGenerator` bunları tahtayı kurduktan **sonra** uyguluyor.
public struct ObstacleLayout: Codable, Hashable, Sendable {
    /// Kapalı tomurcuk: kilitli kabın indeksi ve sayacı.
    public let lockedVessel: Int?
    public let lockCountdown: Int
    /// Çiy damlası: donmuş tanenin kabı ve kap içindeki yeri.
    public let dewVessel: Int?
    public let dewBead: Int?
    public let dewCountdown: Int
    /// Rüzgâr çizelgesi. Boşsa rüzgâr yok.
    public let windPairs: [WindSchedule.Pair]

    public static let none = ObstacleLayout(lockedVessel: nil, lockCountdown: 0,
                                            dewVessel: nil, dewBead: nil, dewCountdown: 0,
                                            windPairs: [])

    public init(lockedVessel: Int?, lockCountdown: Int,
                dewVessel: Int?, dewBead: Int?, dewCountdown: Int,
                windPairs: [WindSchedule.Pair]) {
        self.lockedVessel = lockedVessel
        self.lockCountdown = lockCountdown
        self.dewVessel = dewVessel
        self.dewBead = dewBead
        self.dewCountdown = dewCountdown
        self.windPairs = windPairs
    }

    public var isEmpty: Bool {
        lockedVessel == nil && dewVessel == nil && windPairs.isEmpty
    }

    /// Engelleri tahtaya uygular.
    public func applied(to state: GameState) -> GameState {
        guard !isEmpty else { return state }
        var vessels = state.vessels
        if let lockedVessel, vessels.indices.contains(lockedVessel), lockCountdown > 0 {
            vessels[lockedVessel] = vessels[lockedVessel]
                .settingObstacles(lockCountdown: lockCountdown)
        }
        if let dewVessel, let dewBead, vessels.indices.contains(dewVessel),
           vessels[dewVessel].beads.indices.contains(dewBead), dewCountdown > 0 {
            let existingLock = vessels[dewVessel].lockCountdown
            vessels[dewVessel] = vessels[dewVessel]
                .settingObstacles(lockCountdown: existingLock,
                                  dewIndex: dewBead, dewCountdown: dewCountdown)
        }
        return GameState(vessels: vessels,
                         wind: windPairs.isEmpty ? nil : WindSchedule(pairs: windPairs))
    }
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
