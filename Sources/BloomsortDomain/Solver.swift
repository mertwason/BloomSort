import Foundation

/// IDA* çözücü.
///
/// Kullanım alanları (bkz. `docs/gdd.md` §8.3): (a) üretilen seviyenin
/// doğrulanması, (b) `M*` → yıldız eşiği, (c) İpucu.
///
/// **Heuristik hakkında bir not.** GDD §8.3 heuristiği
/// "(tek renk olmayan kap sayısı) + (kesintiye uğramış renk blokları)" diye
/// tarif ediyor. Bu toplam *kabul edilebilir (admissible)* değil: örneğin
/// `[R,R,B] · [B,B,_]` tahtası tek hamlede çözülür ama formül 2 verir.
/// Kabul edilebilir olmayan heuristik IDA*'ın bulduğu `M*`'ı optimalin
/// üstüne çıkarır; `M*` hem yıldız eşiğini hem seviye kabul bandını
/// beslediği için bu değer doğru olmak zorunda. Bu yüzden aşağıda iki ayrı
/// kabul edilebilir alt sınırın maksimumu kullanılıyor — ikisi de "her hamle
/// bu değeri en fazla 1 azaltabilir" özelliğini sağlar:
///
/// 1. **Fazla blok sayısı:** Σ (kaptaki renk bloğu sayısı − 1)
/// 2. **Bitmemiş kap sayısının yarısı:** ⌈(boş da olmayan, tek renkle dolu da
///    olmayan kap sayısı) / 2⌉ — bir hamle en fazla iki kabı bitirebilir.
///
/// Bir zamanlar üçüncü bir terim daha vardı: Σ_renk (o rengi içeren kap
/// sayısı − 1). **Kabul edilebilir değil** ve `SolverTests` bunu yakaladı:
/// aynı renk iki ayrı kabı tam doldurarak da bitebiliyor (karışık kapasitede
/// 6 tane sarı, iki adet 3'lük kabı doldurur), yani hedefte bu terim sıfır
/// olmak zorunda değil. Kaldırıldı.
public enum Solver {
    public struct Statistics: Sendable {
        public var nodes: Int
        public var iterations: Int
        public var seconds: Double
    }

    public struct Result: Sendable {
        public let moves: [Move]
        public let statistics: Statistics
        /// Optimal hamle sayısı (`M*`).
        public var optimalMoves: Int { moves.count }
    }

    /// Varsayılan arama sınırı — bu derinlikte çözüm bulunamazsa `nil` döner.
    /// Zorluk tablosunun en üst bandı `M* ≤ 70` (bkz. §4.2).
    public static let defaultLimit = 120

    /// Varsayılan düğüm bütçesi. Aşılırsa arama `nil` döner.
    ///
    /// Sınırsız arama tek bir tahtada dakikalarca sürebilir; ne seviye üretimi
    /// ne de İpucu bunu kaldırır. Bütçe dolduğunda üretici o seed'i reddedip
    /// bir sonrakine geçer.
    public static let defaultNodeLimit = 2_000_000

    /// Optimal çözümü döner. Çözülemiyorsa ya da `limit` aşılırsa `nil`.
    public static func solve(_ state: GameState, limit: Int = defaultLimit,
                             nodeLimit: Int = defaultNodeLimit) -> [Move]? {
        detailedSolve(state, limit: limit, nodeLimit: nodeLimit)?.moves
    }

    /// Optimal ilk hamle — İpucu için (bkz. `docs/ui-spec.md` §2.6).
    public static func hint(_ state: GameState, limit: Int = defaultLimit,
                            nodeLimit: Int = defaultNodeLimit) -> Move? {
        solve(state, limit: limit, nodeLimit: nodeLimit)?.first
    }

    /// Çözüm + arama istatistikleri.
    public static func detailedSolve(_ state: GameState, limit: Int = defaultLimit,
                                     nodeLimit: Int = defaultNodeLimit) -> Result? {
        let start = DispatchTime.now().uptimeNanoseconds
        var search = Search(position: Position(state), limit: limit, nodeLimit: nodeLimit)
        let moves = search.run()
        let seconds = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
        guard let moves else { return nil }
        return Result(moves: moves,
                      statistics: Statistics(nodes: search.nodes,
                                             iterations: search.iterations,
                                             seconds: seconds))
    }

    /// Yalnızca alt sınır — testler ve teşhis için.
    public static func heuristic(_ state: GameState) -> Int {
        Search.heuristic(Position(state).vessels)
    }
}

// MARK: - Arama

struct Search {
    let root: Position
    let limit: Int
    let nodeLimit: Int
    var nodes = 0
    var exhaustedBudget = false
    /// Bu yinelemede eşik yüzünden kesilen bir dal oldu mu?
    var truncated = false
    var iterations = 0
    /// Bu yineleme içinde bir pozisyona ulaşılan en küçük `g`.
    var visited: [[UInt64]: Int] = [:]
    var path: [Move] = []

    init(position: Position, limit: Int, nodeLimit: Int) {
        self.root = position
        self.limit = limit
        self.nodeLimit = nodeLimit
    }

    mutating func run() -> [Move]? {
        // Eşik her yinelemede **birer birer** artıyor.
        //
        // Klasik IDA* eşiği "sınırı aşan en küçük f" değerine sıçratır; bu,
        // transposition table ile birlikte kullanıldığında yanlış sonuç verir:
        // f = eşik+1 üreten dalların hepsi tabloyla budanırsa o f hiç görülmez
        // ve eşik onu atlar, arama optimalden uzun bir çözüm döner. (Bu tam
        // olarak yaşandı; `SolverTests.testIDAStarOptimalCozumBulur` yakaladı.)
        // Hamle maliyeti 1 olduğu için birer birer artırmanın maliyeti düşük.
        var threshold = Search.heuristic(root.vessels)
        while threshold <= limit {
            iterations += 1
            visited.removeAll(keepingCapacity: true)
            path.removeAll(keepingCapacity: true)
            truncated = false
            if search(root.vessels, g: 0, threshold: threshold) { return path }
            if exhaustedBudget { return nil }   // düğüm bütçesi doldu
            // Hiçbir dal eşik yüzünden kesilmediyse ulaşılabilir bütün
            // durumlar tarandı ve çözüm yok.
            if !truncated { return nil }
            threshold += 1
        }
        return nil
    }

    /// `f = g + h > threshold` olan dalları budayan derinlik öncelikli arama.
    private mutating func search(_ vessels: [UInt64], g: Int, threshold: Int) -> Bool {
        if nodes >= nodeLimit { exhaustedBudget = true; return false }
        nodes += 1
        let h = Search.heuristic(vessels)
        let f = g + h
        if f > threshold {
            truncated = true
            return false
        }
        // Hedef testi eşik kontrolünden **sonra** gelmek zorunda. Heuristik
        // sıfır olduğu hâlde tahtanın bitmediği durumlar var (tek renkli ama
        // dolmamış kaplar), bu yüzden eşiği aşan derinlikte bir hedefe
        // rastlanabiliyor ve önce test edilirse optimalden uzun çözüm dönüyor.
        if Position(vessels: vessels).isSolved { return true }

        let key = vessels.sorted()
        if let seen = visited[key], seen <= g { return false }
        visited[key] = g

        for candidate in Search.moves(vessels) {
            var next = vessels
            next[candidate.source] = Position.removingTop(next[candidate.source], candidate.count)
            next[candidate.destination] = Position.appending(next[candidate.destination],
                                                             color: candidate.color,
                                                             n: candidate.count)
            path.append(Move(source: candidate.source,
                             destination: candidate.destination,
                             count: candidate.count,
                             color: PollenColor(candidate.color)))
            if search(next, g: g + 1, threshold: threshold) { return true }
            path.removeLast()
        }
        return false
    }

    // MARK: Heuristik

    static func heuristic(_ vessels: [UInt64]) -> Int {
        var extraRuns = 0
        var unfinished = 0
        for packed in vessels {
            let count = Position.count(packed)
            guard count > 0 else { continue }
            var runs = 1
            var previous = Position.bead(packed, 0)
            for index in 1..<count {
                let color = Position.bead(packed, index)
                if color != previous { runs += 1 }
                previous = color
            }
            extraRuns += runs - 1
            if runs > 1 || count != Position.capacity(packed) { unfinished += 1 }
        }
        return max(extraRuns, (unfinished + 1) / 2)
    }

    // MARK: Hamle üretimi

    struct Candidate {
        let source: Int
        let destination: Int
        let count: Int
        let color: Int
        let score: Int
    }

    /// Yasal hamleler; ilerleme sağlamayanlar ve simetrik tekrarlar ayıklanmış,
    /// umut verici olanlar öne alınmış hâlde.
    ///
    /// Budamaların hiçbiri optimalliği bozmaz:
    /// - Tamamı tek renk olan bir kabı **aynı kapasitede** boş bir kaba taşımak
    ///   yalnızca yer değiştirmektir. Farklı kapasitedeki boş kap elenmez:
    ///   bir renk yalnızca kendi adedine eşit kapasitedeki kapta çiçek açar.
    /// - Aynı kapasiteli boş kaplar birbirinin aynısıdır; biri denenir.
    ///
    /// Çiçek açmış kaptan hamle üretmemek de denendi ve `SolverTests` bunun
    /// optimali kestiğini gösterdi: karışık kapasitede bir renk kendi
    /// adedinden küçük bir kabı doldurabiliyor, o kabın sonradan bozulması
    /// gerekebiliyor. Bkz. README "Açık tasarım soruları".
    static func moves(_ vessels: [UInt64]) -> [Candidate] {
        var candidates: [Candidate] = []
        candidates.reserveCapacity(16)
        for source in vessels.indices {
            let sourcePacked = vessels[source]
            let sourceCount = Position.count(sourcePacked)
            guard sourceCount > 0 else { continue }
            let color = Position.bead(sourcePacked, sourceCount - 1)
            let runLength = Position.topRunLength(sourcePacked)
            let sourceIsWholeRun = runLength == sourceCount
            let sourceCapacity = Position.capacity(sourcePacked)
            var triedEmptyCapacities: UInt16 = 0

            for destination in vessels.indices where destination != source {
                let destinationPacked = vessels[destination]
                let free = Position.freeSpace(destinationPacked)
                guard free > 0 else { continue }
                let destinationCount = Position.count(destinationPacked)
                let destinationCapacity = Position.capacity(destinationPacked)

                if destinationCount == 0 {
                    if sourceIsWholeRun && destinationCapacity == sourceCapacity { continue }
                    let bit = UInt16(1) << UInt16(destinationCapacity)
                    if triedEmptyCapacities & bit != 0 { continue }
                    triedEmptyCapacities |= bit
                } else if Position.bead(destinationPacked, destinationCount - 1) != color {
                    continue
                }

                let moved = min(runLength, free)
                // Hedefi çiçek açtıran hamle: kap tamamen dolar ve tek renk kalır.
                let bloomsDestination = destinationCount + moved == destinationCapacity
                    && (destinationCount == 0
                        || Position.topRunLength(destinationPacked) == destinationCount)
                // Sıralama puanı: çiçek açtıran ve kaynağı boşaltan hamleler önce.
                var score = 0
                if bloomsDestination { score += 16 }
                if moved == sourceCount { score += 4 }
                if destinationCount > 0 { score += 2 }
                if moved == runLength { score += 1 }
                candidates.append(Candidate(source: source, destination: destination,
                                            count: moved, color: color, score: score))
            }
        }
        // NOT: "çiçek açtıran hamle varsa yalnızca onu dene" diye bir budama
        // denendi ve `SolverTests` bunun `M*`'ı değiştirdiğini gösterdi —
        // bazı tahtalarda çözümü tamamen kesiyor. Puan yalnızca **sıralama**
        // için kullanılıyor, budama için değil.
        candidates.sort { $0.score > $1.score }
        return candidates
    }
}
