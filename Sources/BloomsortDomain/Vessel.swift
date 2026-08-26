/// Çiçek kabı — LIFO yığın.
///
/// `beads[0]` tabandaki tane, `beads.last` ağızdaki tanedir.
public struct Vessel: Hashable, Sendable, Codable {
    /// Kapasite C ∈ {3,4,5,6} (bkz. `docs/gdd.md` §2.1). Domain daha geniş
    /// değerlere izin verir; sınırı zorluk tablosu koyar.
    public let capacity: Int
    public private(set) var beads: [Bead]

    public init(capacity: Int, beads: [Bead] = []) {
        precondition(capacity > 0, "Kap kapasitesi pozitif olmalı")
        precondition(beads.count <= capacity, "Kap kapasitesinden fazla polen taşıyamaz")
        self.capacity = capacity
        self.beads = beads
    }

    public var count: Int { beads.count }
    public var isEmpty: Bool { beads.isEmpty }
    public var isFull: Bool { beads.count == capacity }
    public var freeSpace: Int { capacity - beads.count }

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

    /// Ağızdan `n` tane alır ve döner (üstten sıralı: dönen dizinin son
    /// elemanı yine ağızdakidir).
    mutating func removeTop(_ n: Int) -> [Bead] {
        precondition(n <= beads.count, "Kapta yeterli polen yok")
        let taken = Array(beads.suffix(n))
        beads.removeLast(n)
        return taken
    }

    mutating func append(_ newBeads: [Bead]) {
        precondition(beads.count + newBeads.count <= capacity, "Kap taşıyor")
        beads.append(contentsOf: newBeads)
    }
}
