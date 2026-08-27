/// Çözücü ve üretici için sıkıştırılmış tahta temsili.
///
/// Her kabın içeriği tek bir `UInt64`'e paketlenir:
/// `bit 0-7` kapasite · `bit 8-15` dolu tane sayısı · `bit 16+` her tane 4 bit
/// (tabandan ağza). Kullanılmayan yuvalar daima sıfırdır, böylece iki eşdeğer
/// tahta bit düzeyinde de eşit olur.
///
/// Engeller ayrı bir `UInt32` dizisinde durur:
/// `bit 0-7` kilit sayacı · `bit 8-15` donmuş tanenin yeri + 1 (0 = yok) ·
/// `bit 16-23` çiy sayacı. Engelsiz tahtalarda bu dizi **boştur** ve sıcak yol
/// eskisi gibi çalışır.
///
/// Sınırlar: kapasite ≤ 12, renk indeksi ≤ 15. Zorluk tablosu (§4.2) en fazla
/// 6 kapasite ve 12 renk kullanır.
struct Position: Hashable {
    var vessels: [UInt64]
    /// Engel yoksa boş.
    var obstacles: [UInt32]
    /// Yapılmış hamle sayısı — rüzgâr çizelgesi buna bakar.
    var moveIndex: Int
    var wind: WindSchedule?

    static let maxCapacity = 12

    init(vessels: [UInt64], obstacles: [UInt32] = [], moveIndex: Int = 0,
         wind: WindSchedule? = nil) {
        self.vessels = vessels
        self.obstacles = obstacles
        self.moveIndex = moveIndex
        self.wind = wind
    }

    init(_ state: GameState) {
        vessels = state.vessels.map { vessel in
            precondition(vessel.capacity <= Position.maxCapacity,
                         "Çözücü en fazla \(Position.maxCapacity) kapasiteli kabı destekler")
            var packed = UInt64(vessel.capacity) | (UInt64(vessel.beads.count) << 8)
            for (index, bead) in vessel.beads.enumerated() {
                precondition(bead.color.index < 16, "Çözücü en fazla 16 rengi destekler")
                packed |= UInt64(bead.color.index) << UInt64(16 + 4 * index)
            }
            return packed
        }
        let hasObstacles = state.vessels.contains { $0.isLocked || $0.hasDew }
        obstacles = hasObstacles ? state.vessels.map { vessel in
            var packed = UInt32(vessel.lockCountdown & 0xFF)
            if let dewIndex = vessel.dewIndex {
                packed |= UInt32((dewIndex + 1) & 0xFF) << 8
                packed |= UInt32(vessel.dewCountdown & 0xFF) << 16
            }
            return packed
        } : []
        moveIndex = state.moveCount
        wind = state.wind
    }

    var gameState: GameState {
        let built = vessels.enumerated().map { index, packed -> Vessel in
            let capacity = Position.capacity(packed)
            let count = Position.count(packed)
            let beads = (0..<count).map { Bead(color: Position.bead(packed, $0)) }
            guard !obstacles.isEmpty else { return Vessel(capacity: capacity, beads: beads) }
            let obstacle = obstacles[index]
            let storedDew = Int((obstacle >> 8) & 0xFF)
            return Vessel(capacity: capacity,
                          beads: beads,
                          lockCountdown: Int(obstacle & 0xFF),
                          dewIndex: storedDew == 0 ? nil : storedDew - 1,
                          dewCountdown: storedDew == 0 ? 0 : Int((obstacle >> 16) & 0xFF))
        }
        return GameState(vessels: built, moveCount: moveIndex, wind: wind)
    }

    // MARK: - Bit işlemleri: içerik

    @inline(__always) static func capacity(_ packed: UInt64) -> Int { Int(packed & 0xFF) }
    @inline(__always) static func count(_ packed: UInt64) -> Int { Int((packed >> 8) & 0xFF) }
    @inline(__always) static func bead(_ packed: UInt64, _ index: Int) -> Int {
        Int((packed >> UInt64(16 + 4 * index)) & 0xF)
    }
    @inline(__always) static func isEmpty(_ packed: UInt64) -> Bool { count(packed) == 0 }
    @inline(__always) static func isFull(_ packed: UInt64) -> Bool { count(packed) == capacity(packed) }
    @inline(__always) static func freeSpace(_ packed: UInt64) -> Int { capacity(packed) - count(packed) }

    @inline(__always) static func topColor(_ packed: UInt64) -> Int? {
        let count = count(packed)
        return count == 0 ? nil : bead(packed, count - 1)
    }

    @inline(__always) static func topRunLength(_ packed: UInt64) -> Int {
        let count = count(packed)
        guard count > 0 else { return 0 }
        let color = bead(packed, count - 1)
        var length = 1
        var index = count - 2
        while index >= 0, bead(packed, index) == color {
            length += 1
            index -= 1
        }
        return length
    }

    @inline(__always) static func removingTop(_ packed: UInt64, _ n: Int) -> UInt64 {
        let newCount = count(packed) - n
        // Sayaç alanını güncelle, boşalan yuvaları sıfırla.
        var result = (packed & ~UInt64(0xFF00)) | (UInt64(newCount) << 8)
        let keepBits = UInt64(16 + 4 * newCount)
        let mask: UInt64 = keepBits >= 64 ? .max : (UInt64(1) << keepBits) - 1
        result &= mask
        return result
    }

    @inline(__always) static func appending(_ packed: UInt64, color: Int, n: Int) -> UInt64 {
        let oldCount = count(packed)
        var result = (packed & ~UInt64(0xFF00)) | (UInt64(oldCount + n) << 8)
        for index in oldCount..<(oldCount + n) {
            result |= UInt64(color) << UInt64(16 + 4 * index)
        }
        return result
    }

    // MARK: - Bit işlemleri: engeller

    @inline(__always) static func lockCountdown(_ obstacle: UInt32) -> Int { Int(obstacle & 0xFF) }
    /// Donmuş tanenin yeri, yoksa `nil`.
    @inline(__always) static func dewIndex(_ obstacle: UInt32) -> Int? {
        let stored = Int((obstacle >> 8) & 0xFF)
        return stored == 0 ? nil : stored - 1
    }
    @inline(__always) static func dewCountdown(_ obstacle: UInt32) -> Int {
        Int((obstacle >> 16) & 0xFF)
    }
    @inline(__always) static func makeObstacle(lock: Int, dewIndex: Int?, dewCountdown: Int) -> UInt32 {
        var packed = UInt32(lock & 0xFF)
        if let dewIndex {
            packed |= UInt32((dewIndex + 1) & 0xFF) << 8
            packed |= UInt32(dewCountdown & 0xFF) << 16
        }
        return packed
    }

    /// Taşınabilir üst run — donmuş tane ve altı sabit.
    @inline(__always) func movableRunLength(_ index: Int) -> Int {
        let run = Position.topRunLength(vessels[index])
        guard !obstacles.isEmpty, let dew = Position.dewIndex(obstacles[index]) else { return run }
        let aboveDew = Position.count(vessels[index]) - 1 - dew
        return min(run, max(0, aboveDew))
    }

    @inline(__always) func isLocked(_ index: Int) -> Bool {
        !obstacles.isEmpty && Position.lockCountdown(obstacles[index]) > 0
    }

    @inline(__always) func isTopFrozen(_ index: Int) -> Bool {
        guard !obstacles.isEmpty, let dew = Position.dewIndex(obstacles[index]) else { return false }
        return dew == Position.count(vessels[index]) - 1
    }

    var hasObstacles: Bool { !obstacles.isEmpty }

    // MARK: - Hamle uygulama

    /// Hamleyi uygular: taneleri taşır, çiy ve kilit sayaçlarını işletir,
    /// gerekiyorsa rüzgârı estirir. Kural denetimi çağıran tarafta.
    ///
    /// `GameState.applying(_:)` ile birebir aynı davranmak zorunda;
    /// `ObstacleParityTests` ikisini rastgele hamle dizileriyle karşılaştırıyor.
    func applying(source: Int, destination: Int, count moved: Int, color: Int) -> Position {
        var next = self
        next.vessels[source] = Position.removingTop(next.vessels[source], moved)
        next.vessels[destination] = Position.appending(next.vessels[destination],
                                                       color: color, n: moved)
        if !next.obstacles.isEmpty {
            // Hedefin çiy sayacı düşer, sıfırlanınca tane çözülür.
            if let dew = Position.dewIndex(next.obstacles[destination]) {
                let remaining = Position.dewCountdown(next.obstacles[destination]) - 1
                next.obstacles[destination] = remaining <= 0
                    ? Position.makeObstacle(lock: Position.lockCountdown(next.obstacles[destination]),
                                            dewIndex: nil, dewCountdown: 0)
                    : Position.makeObstacle(lock: Position.lockCountdown(next.obstacles[destination]),
                                            dewIndex: dew, dewCountdown: remaining)
            }
            // Başka kaplara polen yerleşti: kilit sayaçları düşer.
            for index in next.obstacles.indices where index != destination {
                let lock = Position.lockCountdown(next.obstacles[index])
                guard lock > 0 else { continue }
                next.obstacles[index] = Position.makeObstacle(
                    lock: max(0, lock - moved),
                    dewIndex: Position.dewIndex(next.obstacles[index]),
                    dewCountdown: Position.dewCountdown(next.obstacles[index]))
            }
        }
        next.moveIndex += 1
        next.applyWindIfDue()
        return next
    }

    private mutating func applyWindIfDue() {
        guard let wind, WindSchedule.blows(afterMoveCount: moveIndex) else { return }
        // Seviye bittiyse rüzgâr esmez: son hamle tahtayı bitirdiyse oyun orada
        // kapanır, aksi hâlde rüzgâr bitmiş bir tahtayı bozabilirdi.
        guard !isSolved else { return }
        let event = WindSchedule.eventIndex(afterMoveCount: moveIndex)
        guard wind.pairs.indices.contains(event) else { return }
        let pair = wind.pairs[event]
        guard vessels.indices.contains(pair.first), vessels.indices.contains(pair.second),
              !isLocked(pair.first), !isLocked(pair.second),
              !isTopFrozen(pair.first), !isTopFrozen(pair.second)
        else { return }

        let firstTop = Position.topColor(vessels[pair.first])
        let secondTop = Position.topColor(vessels[pair.second])
        switch (firstTop, secondTop) {
        case (nil, nil):
            return
        case (let color?, nil):
            vessels[pair.first] = Position.removingTop(vessels[pair.first], 1)
            vessels[pair.second] = Position.appending(vessels[pair.second], color: color, n: 1)
        case (nil, let color?):
            vessels[pair.second] = Position.removingTop(vessels[pair.second], 1)
            vessels[pair.first] = Position.appending(vessels[pair.first], color: color, n: 1)
        case (let first?, let second?):
            vessels[pair.first] = Position.appending(
                Position.removingTop(vessels[pair.first], 1), color: second, n: 1)
            vessels[pair.second] = Position.appending(
                Position.removingTop(vessels[pair.second], 1), color: first, n: 1)
        }
    }

    // MARK: - Kimlik

    /// Kap sırasından bağımsız kimlik. Aynı kapasiteli kaplar birbirinin
    /// yerine geçebildiği için transposition table bu anahtarı kullanır.
    ///
    /// **Rüzgâr varken kaplar birbirinin yerine geçemez** (çizelge belirli kap
    /// indekslerine bakıyor) ve hamle sayacı da pozisyonun parçasıdır; o yüzden
    /// rüzgârlı tahtalarda anahtar sıralanmadan, sayaçla birlikte üretilir.
    var canonicalKey: [UInt64] {
        if wind != nil {
            var key = vessels
            key.append(UInt64(moveIndex))
            key.append(contentsOf: obstacles.map(UInt64.init))
            return key
        }
        if obstacles.isEmpty { return vessels.sorted() }
        // Engelli ama rüzgârsız: kap ile engeli birlikte taşı, çifti sırala.
        var pairs: [(content: UInt64, obstacle: UInt64)] = []
        pairs.reserveCapacity(vessels.count)
        for index in vessels.indices {
            pairs.append((vessels[index], UInt64(obstacles[index])))
        }
        pairs.sort { $0.content == $1.content ? $0.obstacle < $1.obstacle : $0.content < $1.content }
        var key: [UInt64] = []
        key.reserveCapacity(pairs.count * 2)
        for pair in pairs {
            key.append(pair.content)
            key.append(pair.obstacle)
        }
        return key
    }

    /// Her kap ya boş ya tek renkle dolu (bkz. `GameState.isSolved`).
    var isSolved: Bool {
        for packed in vessels {
            let count = Position.count(packed)
            if count == 0 { continue }
            if count != Position.capacity(packed) { return false }
            if Position.topRunLength(packed) != count { return false }
        }
        return true
    }
}
