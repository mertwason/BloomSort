/// Çiçek kabı — LIFO yığın.
///
/// `beads[0]` tabandaki tane, `beads.last` ağızdaki tanedir.
public struct Vessel: Hashable, Sendable, Codable {
    /// Kapasite C ∈ {3,4,5,6} (bkz. `docs/gdd.md` §2.1). Domain daha geniş
    /// değerlere izin verir; sınırı zorluk tablosu koyar.
    public let capacity: Int
    public private(set) var beads: [Bead]

    /// **Kapalı tomurcuk** (§4.2, seviye 41+): kalan sayaç. Sıfırdan büyükse
    /// kap kilitlidir — ne kaynak ne hedef olabilir. Başka kaplara her polen
    /// yerleştiğinde sayaç düşer.
    public private(set) var lockCountdown: Int

    /// **Çiy damlası** (§4.2, seviye 61+): donmuş tanenin dizideki yeri.
    /// Donmuş tane taşınamaz; üstündekiler taşınabilir.
    public private(set) var dewIndex: Int?

    /// Çiy sayacı: bu kaba yapılan her hamlede düşer, sıfırlanınca tane çözülür.
    /// ("üstüne 2 hamle yapılınca çözülür" — hamle = bu kabı hedefleyen hamle.)
    public private(set) var dewCountdown: Int

    public init(capacity: Int, beads: [Bead] = [],
                lockCountdown: Int = 0, dewIndex: Int? = nil, dewCountdown: Int = 0) {
        precondition(capacity > 0, "Kap kapasitesi pozitif olmalı")
        precondition(beads.count <= capacity, "Kap kapasitesinden fazla polen taşıyamaz")
        precondition(lockCountdown >= 0, "Kilit sayacı negatif olamaz")
        if let dewIndex {
            precondition(beads.indices.contains(dewIndex), "Donmuş tane kapta yok")
            precondition(dewCountdown > 0, "Donmuş tanenin sayacı pozitif olmalı")
        }
        self.capacity = capacity
        self.beads = beads
        self.lockCountdown = lockCountdown
        self.dewIndex = dewIndex
        self.dewCountdown = dewCountdown
    }

    public var count: Int { beads.count }
    public var isEmpty: Bool { beads.isEmpty }
    public var isFull: Bool { beads.count == capacity }
    public var freeSpace: Int { capacity - beads.count }

    /// Kilitli mi? Kilitli kap ne kaynak ne hedef olabilir.
    public var isLocked: Bool { lockCountdown > 0 }
    /// Donmuş bir tane taşıyor mu?
    public var hasDew: Bool { dewIndex != nil }

    /// Ağızdaki tane.
    public var top: Bead? { beads.last }

    /// Ağızdan aşağı doğru aynı renkli ardışık tane sayısı (üst run uzunluğu).
    public var topRunLength: Int {
        guard let top else { return 0 }
        var length = 0
        var i = beads.count - 1
        while i >= 0, beads[i].color == top.color {
            length += 1
            i -= 1
        }
        return length
    }

    /// Gerçekten taşınabilecek üst run uzunluğu — donmuş tane ve altı sabittir.
    public var movableRunLength: Int {
        guard let dewIndex else { return topRunLength }
        let aboveDew = beads.count - 1 - dewIndex
        return min(topRunLength, max(0, aboveDew))
    }

    /// Kaptaki kesintisiz aynı renk blok (run) sayısı.
    public var runCount: Int {
        guard !beads.isEmpty else { return 0 }
        var runs = 1
        for i in 1..<beads.count where beads[i].color != beads[i - 1].color {
            runs += 1
        }
        return runs
    }

    /// Boş değil ve tek renk taşıyor.
    public var isMono: Bool { !beads.isEmpty && runCount == 1 }

    /// Kazanma koşulunun kap başına karşılığı: boş ya da tek renkli
    /// (bkz. `docs/gdd.md` §2.4, §8.2).
    public var isEmptyOrMono: Bool { beads.isEmpty || runCount == 1 }

    /// Tek renkle **dolu** — çiçek açma tetikleyicisi (bkz. `docs/gdd.md` §2.5).
    public var isBloomed: Bool { isFull && runCount == 1 }

    // MARK: - Mutasyonlar (yalnızca `GameState` üzerinden)

    /// Ağızdan `n` tane alır ve döner (üstten sıralı: dönen dizinin son
    /// elemanı yine ağızdakidir).
    mutating func removeTop(_ n: Int) -> [Bead] {
        precondition(n <= movableRunLength, "Donmuş tane ya da yetersiz polen")
        let taken = Array(beads.suffix(n))
        beads.removeLast(n)
        return taken
    }

    mutating func append(_ newBeads: [Bead]) {
        precondition(beads.count + newBeads.count <= capacity, "Kap taşıyor")
        beads.append(contentsOf: newBeads)
    }

    /// Bu kaba bir hamle yapıldı: çiy sayacı düşer, sıfırlanınca tane çözülür.
    mutating func registerIncomingMove() {
        guard dewIndex != nil else { return }
        dewCountdown -= 1
        if dewCountdown <= 0 {
            dewIndex = nil
            dewCountdown = 0
        }
    }

    /// Başka bir kaba `placed` tane yerleşti: kilit sayacı düşer.
    mutating func registerElsewherePlacement(_ placed: Int) {
        guard lockCountdown > 0 else { return }
        lockCountdown = max(0, lockCountdown - placed)
    }

    /// Üstteki tane donmuş mu? Donmuşsa kap kaynak olamaz.
    public var isTopFrozen: Bool { dewIndex != nil && dewIndex == beads.count - 1 }

    /// Rüzgârın kullandığı koşulsuz alma — donmuş tane kontrolü çağıran tarafta.
    mutating func forceRemoveTop(_ n: Int) -> [Bead] {
        precondition(n <= beads.count, "Kapta yeterli polen yok")
        let taken = Array(beads.suffix(n))
        beads.removeLast(n)
        return taken
    }

    /// Ters karıştırma ve testler için — engelleri doğrudan kurar.
    func settingObstacles(lockCountdown: Int = 0,
                          dewIndex: Int? = nil,
                          dewCountdown: Int = 0) -> Vessel {
        Vessel(capacity: capacity, beads: beads,
               lockCountdown: lockCountdown, dewIndex: dewIndex, dewCountdown: dewCountdown)
    }
}
