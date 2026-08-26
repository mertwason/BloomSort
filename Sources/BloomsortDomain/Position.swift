/// Çözücü ve üretici için sıkıştırılmış tahta temsili.
///
/// Her kap tek bir `UInt64`'e paketlenir:
/// `bit 0-7` kapasite · `bit 8-15` dolu tane sayısı · `bit 16+` her tane 4 bit
/// (tabandan ağza). Kullanılmayan yuvalar daima sıfırdır, böylece iki eşdeğer
/// tahta bit düzeyinde de eşit olur.
///
/// Sınırlar: kapasite ≤ 12, renk indeksi ≤ 15. Zorluk tablosu (§4.2) en fazla
/// 6 kapasite ve 12 renk kullanır.
struct Position: Hashable {
    var vessels: [UInt64]

    static let maxCapacity = 12

    init(vessels: [UInt64]) { self.vessels = vessels }

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
    }

    var gameState: GameState {
        GameState(vessels: vessels.map { packed in
            let capacity = Position.capacity(packed)
            let count = Position.count(packed)
            return Vessel(capacity: capacity,
                          beads: (0..<count).map { Bead(color: Position.bead(packed, $0)) })
        })
    }

    // MARK: - Bit işlemleri

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

    /// Kap sırasından bağımsız kimlik. Aynı kapasiteli kaplar birbirinin
    /// yerine geçebildiği için transposition table bu anahtarı kullanır.
    var canonicalKey: [UInt64] { vessels.sorted() }

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
