import Foundation

/// Ters hamle yöntemiyle seviye üretimi — `docs/gdd.md` §4.1.
///
/// Üretim çözülmüş durumdan geriye çalışır, bu yüzden çözülebilirlik
/// matematiksel olarak garantidir. Yine de her seviye çözücüyle doğrulanır.
public enum LevelGenerator {

    /// Kabul filtrelerinin sonucu — reddedilen seviyelerin nedenini taşır.
    public enum Rejection: String, Error, Sendable {
        case optimalOutOfBand    = "M* banda oturmadı"
        case staleBoard          = "bayat tahta"
        case lowBranching        = "dallanma faktörü düşük"
    }

    /// Dallanma faktörü alt sınırı (§4.1, kabul koşulu 5).
    public static let minimumBranchingFactor = 2.2
    /// Bayat tahta filtresi: ilk 3 hamlede "otomatik" çözülen kap sayısı üst sınırı.
    public static let maximumEarlyCompletions = 1

    // MARK: - Genel üretim

    /// Verilen seviye numarası için kabul filtrelerinden geçen ilk seviyeyi üretir.
    ///
    /// Reddedilen her denemede seed bir artar (§4.1 adım 6).
    public static func generate(level: Int, startingSeed: UInt64,
                                attempts: Int = 400) -> (level: Level, seed: UInt64)? {
        var seed = startingSeed
        for _ in 0..<attempts {
            if let candidate = attempt(level: level, seed: seed) {
                return (candidate, seed &+ 1)
            }
            seed &+= 1
        }
        return nil
    }

    /// Tek bir seed denemesi. Reddedilirse `nil`.
    public static func attempt(level: Int, seed: UInt64) -> Level? {
        try? make(level: level, seed: seed).get()
    }

    /// Tek bir seed denemesi, ret nedeniyle birlikte (teşhis ve testler için).
    public static func make(level: Int, seed: UInt64) -> Result<Level, Rejection> {
        let parameters = Parameters(level: level, seed: seed)
        let band = Difficulty.optimalMoveRange(for: level)
        var rng = SplitMix64(seed: seed)
        _ = parameters.consume(&rng)   // parametre çekilişini birebir tekrarla
        let target = rng.int(in: band)

        // 2. adım: ters hamlelerle karıştır.
        let path = reverseWalk(parameters: parameters,
                               depth: walkDepth(for: band),
                               rng: &rng)

        // 4. adım: çözücüyle doğrula → M*
        guard let hit = depthReaching(path: path, target: target, band: band) else {
            return .failure(.optimalOutOfBand)
        }
        let state = Position(vessels: path[hit.depth]).gameState
        let solution = hit.solution

        // 5. adım, kabul filtreleri
        guard earlyCompletions(state, solution: solution) <= maximumEarlyCompletions else {
            return .failure(.staleBoard)
        }
        let branching = branchingFactor(state, solution: solution)
        guard branching >= minimumBranchingFactor else { return .failure(.lowBranching) }

        return .success(Level(id: level,
                              seed: seed,
                              colors: parameters.colors,
                              emptyVessels: parameters.emptyVessels,
                              capacities: parameters.capacities,
                              reverseMoves: hit.depth,
                              optimalMoves: solution.count,
                              branchingFactor: branching))
    }

    /// Yürüyüş derinliği: hedef bandın üst sınırının katı.
    ///
    /// Bu bir uygulama bütçesidir, oyun tasarımı sayısı değil — yolun `M*`
    /// hedef bandı geçecek kadar uzaması yeterli, fazlası yalnızca ikili
    /// aramanın tarayacağı aralığı büyütür.
    static func walkDepth(for band: ClosedRange<Int>) -> Int { band.upperBound * 4 }

    /// Kaydedilmiş bir seviyenin tahtasını seed'den birebir yeniden kurar.
    ///
    /// Oyun bunu her seviye açılışında çağırır: tahta diskte durmaz, seed'den
    /// yeniden yürünür (bkz. `docs/gdd.md` §4.1).
    public static func board(for level: Level) -> GameState {
        let parameters = Parameters(level: level.id, seed: level.seed)
        var rng = SplitMix64(seed: level.seed)
        _ = parameters.consume(&rng)
        _ = rng.int(in: Difficulty.optimalMoveRange(for: level.id))   // hedef çekilişi
        let path = reverseWalk(parameters: parameters, depth: level.reverseMoves, rng: &rng)
        precondition(path.count == level.reverseMoves + 1,
                     "Kaydedilmiş seviye yeniden kurulamadı: \(level.id)")
        return Position(vessels: path[level.reverseMoves]).gameState
    }

    // MARK: - Parametreler

    /// Seed'den türetilen tahta parametreleri (§4.1 girdi kümesi).
    public struct Parameters: Sendable {
        public let level: Int
        public let seed: UInt64
        public let colors: Int
        public let emptyVessels: Int
        public let capacities: [Int]

        /// Doğrudan parametre verir — çözücü ölçümü ve testler için.
        public init(level: Int, seed: UInt64, colors: Int, emptyVessels: Int, capacities: [Int]) {
            precondition(capacities.count == colors + emptyVessels,
                         "Kapasite sayısı kap sayısına eşit olmalı")
            self.level = level
            self.seed = seed
            self.colors = colors
            self.emptyVessels = emptyVessels
            self.capacities = capacities
        }

        public init(level: Int, seed: UInt64) {
            let band = Difficulty.band(for: level)
            var rng = SplitMix64(seed: seed)
            let colors = rng.int(in: band.colors)
            let emptyVessels = rng.int(in: band.emptyVessels)
            var capacities: [Int] = []
            capacities.reserveCapacity(colors + emptyVessels)
            for _ in 0..<(colors + emptyVessels) { capacities.append(rng.pick(band.capacityPool)) }
            self.level = level
            self.seed = seed
            self.colors = colors
            self.emptyVessels = emptyVessels
            self.capacities = capacities
        }

        /// Kurucudaki çekilişleri dışarıdaki üreteçte de tüketir, böylece
        /// üretim ve yeniden kurma aynı rastgele akışı görür.
        func consume(_ rng: inout SplitMix64) -> Int {
            let band = Difficulty.band(for: level)
            _ = rng.int(in: band.colors)
            _ = rng.int(in: band.emptyVessels)
            for _ in 0..<(colors + emptyVessels) { _ = rng.pick(band.capacityPool) }
            return capacities.count
        }

        /// Çözülmüş başlangıç durumu: her renk kendi kabını tam doldurur,
        /// ardından E boş kap gelir (§4.1 adım 1).
        public var solvedState: GameState {
            var vessels: [Vessel] = []
            for color in 0..<colors {
                let capacity = capacities[color]
                vessels.append(Vessel(capacity: capacity,
                                      beads: Array(repeating: Bead(color: color), count: capacity)))
            }
            for index in 0..<emptyVessels {
                vessels.append(Vessel(capacity: capacities[colors + index]))
            }
            return GameState(vessels: vessels)
        }
    }

    // MARK: - Ters karıştırma

    /// Ters karıştırma yürüyüşünün bir adımı.
    struct ReverseMove {
        let giver: Int
        let receiver: Int
        let count: Int
        let color: Int
    }

    /// Bir tahtaya uygulanabilecek bütün ters hamleler.
    ///
    /// GDD §4.1'in tanımı: "dolu bir kabın üstünden j tane alıp, yasal olacak
    /// şekilde başka bir kaba koymak". Alınan taneler tek renk olmalı (üst run
    /// içinden), hedefte yer olmalı ve hedefin ağzındaki renk farklı olmalı —
    /// aksi hâlde iki blok tek run'a kaynar ve hamle geri alınabilir olmaz.
    static func reverseMoves(_ vessels: [UInt64]) -> [ReverseMove] {
        var moves: [ReverseMove] = []
        for giver in vessels.indices {
            let giverPacked = vessels[giver]
            let giverCount = Position.count(giverPacked)
            guard giverCount > 0 else { continue }
            let color = Position.bead(giverPacked, giverCount - 1)
            let runLength = Position.topRunLength(giverPacked)
            for count in 1...runLength {
                for receiver in vessels.indices where receiver != giver {
                    let receiverPacked = vessels[receiver]
                    guard Position.freeSpace(receiverPacked) >= count else { continue }
                    if let receiverTop = Position.topColor(receiverPacked), receiverTop == color { continue }
                    moves.append(ReverseMove(giver: giver, receiver: receiver,
                                             count: count, color: color))
                }
            }
        }
        return moves
    }

    /// Çözülmüş durumdan geriye doğru `depth` adımlık bir yürüyüş yapar ve
    /// yolun tamamını döner (`path[0]` çözülmüş durum).
    ///
    /// Yürüyüş tamamen determinist: aynı seed → aynı yol. Kayıtlı bir seviyeyi
    /// yeniden kurmak, aynı yolun ilk `R` adımını tekrar yürümek demektir.
    static func reverseWalk(parameters: Parameters, depth: Int,
                            rng: inout SplitMix64) -> [[UInt64]] {
        var current = Position(parameters.solvedState).vessels
        var path: [[UInt64]] = [current]
        var seen: Set<[UInt64]> = [current]
        path.reserveCapacity(depth + 1)

        for _ in 0..<depth {
            var candidates: [[UInt64]] = []
            for move in reverseMoves(current) {
                var next = current
                next[move.giver] = Position.removingTop(next[move.giver], move.count)
                next[move.receiver] = Position.appending(next[move.receiver],
                                                         color: move.color, n: move.count)
                // 3. adım: aynı duruma dönülmüşse bu adımı atla.
                if !seen.contains(next) { candidates.append(next) }
            }
            guard !candidates.isEmpty else { break }
            current = candidates[rng.int(below: candidates.count)]
            seen.insert(current)
            path.append(current)
        }
        return path
    }

    /// Yol üzerinde `M*` hedefe ulaşan ilk derinliği arar.
    ///
    /// `M*` yol boyunca kabaca artar (bir ters hamle `M*`'ı en fazla 1
    /// artırabilir, azaltabilir de). Her derinlikte çözücü çağırmak yerine
    /// ikili arama yapılıyor: adım başına bir optimal çözüm yerine ~log₂(derinlik)
    /// çözüm. Bulunan derinlik sonunda tam olarak doğrulanıyor, yani arama
    /// yanılsa bile kabul edilen seviye yanlış olamaz.
    static func depthReaching(path: [[UInt64]], target: Int,
                              band: ClosedRange<Int>) -> (depth: Int, solution: [Move])? {
        guard path.count > target else { return nil }

        // predicate(i): p[i] artık "yeterince zor" mu?
        // Çözüm bulunamıyorsa (M* > Mmax ya da düğüm bütçesi doldu) da
        // yeterince zor sayılır, ikili arama aşağı iner.
        func isHardEnough(_ index: Int) -> Bool {
            let state = Position(vessels: path[index]).gameState
            guard let solution = Solver.solve(state, limit: band.upperBound) else { return true }
            return solution.count >= target
        }

        var low = target                   // M* ≤ derinlik, bu yüzden altını aramaya gerek yok
        var high = path.count - 1
        guard isHardEnough(high) else { return nil }
        while low < high {
            let middle = (low + high) / 2
            if isHardEnough(middle) { high = middle } else { low = middle + 1 }
        }

        let state = Position(vessels: path[low]).gameState
        guard let solution = Solver.solve(state, limit: band.upperBound),
              band.contains(solution.count) else { return nil }
        return (low, solution)
    }

    /// Belirli sayıda ters hamleyle karıştırılmış tahta — çözücü ölçümü için.
    /// Kabul filtreleri uygulanmaz.
    public static func scrambledBoard(parameters: Parameters, reverseMoves depth: Int,
                                      rng: inout SplitMix64) -> GameState? {
        let path = reverseWalk(parameters: parameters, depth: depth, rng: &rng)
        guard path.count == depth + 1 else { return nil }
        return Position(vessels: path[depth]).gameState
    }

    // MARK: - Kabul filtreleri

    /// Bayat tahta filtresi: başlangıçta zaten çiçek açmış kaplar + optimal
    /// çözümün ilk 3 hamlesinde çiçek açan kaplar (§4.1, kabul koşulu 4).
    static func earlyCompletions(_ state: GameState, solution: [Move]) -> Int {
        var completions = state.vessels.filter(\.isBloomed).count
        var current = state
        for move in solution.prefix(3) {
            guard let next = current.applying(move) else { break }
            if next.vessels[move.destination].isBloomed && !current.vessels[move.destination].isBloomed {
                completions += 1
            }
            current = next
        }
        return completions
    }

    /// Dallanma faktörü: optimal çözüm yolu boyunca ortalama anlamlı hamle
    /// sayısı (§4.1, kabul koşulu 5 — "tek yol yok, nefes payı var").
    static func branchingFactor(_ state: GameState, solution: [Move]) -> Double {
        guard !solution.isEmpty else { return 0 }
        var current = state
        var total = 0
        for move in solution {
            total += current.meaningfulMoves().count
            guard let next = current.applying(move) else { break }
            current = next
        }
        return Double(total) / Double(solution.count)
    }
}
