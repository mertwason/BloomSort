/// Tahtanın tamamı. Değer tipi ve mutasyonsuz: her hamle yeni bir `GameState`
/// üretir (bkz. `CLAUDE.md` — "Teknik kısıtlar").
///
/// `Equatable`/`Hashable` **yalnızca `vessels`** üzerinden tanımlıdır: aynı
/// tahtaya farklı hamle dizileriyle gelinmiş olması pozisyonu farklı yapmaz.
/// Çözücünün transposition table'ı ve üreticinin tekrar filtresi buna dayanır.
public struct GameState: Equatable, Hashable, Sendable {
    public private(set) var vessels: [Vessel]
    /// Sayaçtaki hamle sayısı (toplu taşıma 1 sayılır).
    public private(set) var moveCount: Int
    /// Bu seviyede harcanan arı sayısı (her arı tahtaya bir boş kap ekler).
    public private(set) var beesUsed: Int
    /// Geri al zinciri.
    public private(set) var history: [Move]

    public init(vessels: [Vessel], moveCount: Int = 0, beesUsed: Int = 0, history: [Move] = []) {
        self.vessels = vessels
        self.moveCount = moveCount
        self.beesUsed = beesUsed
        self.history = history
    }

    /// Kapasiteler ve renk indeksleri üzerinden kısa kurucu — testler ve
    /// üretici için.
    public init(capacities: [Int], contents: [[Int]]) {
        precondition(capacities.count == contents.count, "Kapasite ve içerik sayısı eşleşmeli")
        self.init(vessels: zip(capacities, contents).map { capacity, colors in
            Vessel(capacity: capacity, beads: colors.map { Bead(color: $0) })
        })
    }

    public static func == (lhs: GameState, rhs: GameState) -> Bool { lhs.vessels == rhs.vessels }
    public func hash(into hasher: inout Hasher) { hasher.combine(vessels) }

    // MARK: - Sorgular

    /// Kazanma: her kap ya boş ya **tek renkle dolu** (bkz. `docs/gdd.md` §2.4).
    ///
    /// GDD §8.2'deki kod taslağı bunu `isEmptyOrMono` diye yazıyor, §2.4'ün
    /// metni ise "tek renkle **dolu**" diyor. İkisi aynı şey değil: bir rengin
    /// taneleri iki ayrı kaba tek renk hâlinde dağılmış olabilir. Belirleyici
    /// olan §2.5: bir kap **dolduğu an** çiçek açar ve tahtadan ayrılır, yani
    /// seviye ancak bütün renkler çiçek açtığında biter. Bu yüzden dolu olma
    /// koşulu aranıyor.
    public var isSolved: Bool { vessels.allSatisfy { $0.isEmpty || $0.isBloomed } }

    /// Tahtadaki renk sayısı.
    public var colorCount: Int {
        var seen = Set<PollenColor>()
        for vessel in vessels { for bead in vessel.beads { seen.insert(bead.color) } }
        return seen.count
    }

    /// Her rengin toplam adedi, o rengin tek başına dolduracağı bir kabın
    /// kapasitesine eşit mi? Üretilen her seviyenin sağlaması gereken koşul.
    public var isConsistent: Bool {
        var counts: [PollenColor: Int] = [:]
        for vessel in vessels { for bead in vessel.beads { counts[bead.color, default: 0] += 1 } }
        var availableCapacities = vessels.map(\.capacity).sorted()
        for count in counts.values.sorted() {
            guard let index = availableCapacities.firstIndex(of: count) else { return false }
            availableCapacities.remove(at: index)
        }
        return true
    }

    // MARK: - Hamleler

    /// `source → destination` hamlesi yasal mı?
    ///
    /// Yasal ⟺ kaynak boş değil **ve** hedef dolu değil **ve** (hedef boş
    /// **veya** hedefin üstü kaynağın üstüyle aynı renk).
    public func isLegal(from source: Int, to destination: Int) -> Bool {
        guard source != destination,
              vessels.indices.contains(source),
              vessels.indices.contains(destination),
              let top = vessels[source].top,
              !vessels[destination].isFull
        else { return false }
        guard let destinationTop = vessels[destination].top else { return true }
        return destinationTop.color == top.color
    }

    /// Yasalsa hamleyi kurar: taşınan miktar = min(üst run uzunluğu, hedefteki boşluk).
    public func move(from source: Int, to destination: Int) -> Move? {
        guard isLegal(from: source, to: destination), let top = vessels[source].top else { return nil }
        let count = min(vessels[source].topRunLength, vessels[destination].freeSpace)
        return Move(source: source, destination: destination, count: count, color: top.color)
    }

    /// Tahtadaki tüm yasal hamleler.
    public func legalMoves() -> [Move] {
        var moves: [Move] = []
        for source in vessels.indices where !vessels[source].isEmpty {
            for destination in vessels.indices where destination != source {
                if let move = move(from: source, to: destination) { moves.append(move) }
            }
        }
        return moves
    }

    /// Anlamlı hamleler: yasal hamlelerden ilerleme sağlamayanlar ve simetrik
    /// tekrarlar ayıklanmış hâli. Dallanma faktörü bu küme üzerinden ölçülür
    /// (bkz. `docs/gdd.md` §4.1, kabul filtresi 5).
    public func meaningfulMoves() -> [Move] {
        var moves: [Move] = []
        var usedEmptyCapacities = Set<Int>()
        for source in vessels.indices {
            let sourceVessel = vessels[source]
            guard !sourceVessel.isEmpty else { continue }
            let sourceIsWholeRun = sourceVessel.topRunLength == sourceVessel.count
            usedEmptyCapacities.removeAll(keepingCapacity: true)
            for destination in vessels.indices where destination != source {
                let destinationVessel = vessels[destination]
                if destinationVessel.isEmpty {
                    // Tek renkli bir kabın tamamını aynı kapasitede boş bir kaba
                    // taşımak yalnızca yer değiştirmektir. Farklı kapasitedeki
                    // boş kap gerekebilir (renk oraya sığmak zorunda olabilir),
                    // o yüzden yalnızca eşit kapasite eleniyor.
                    if sourceIsWholeRun && destinationVessel.capacity == sourceVessel.capacity { continue }
                    // Aynı kapasiteli boş kaplar birbirinin aynısıdır; biri yeter.
                    guard usedEmptyCapacities.insert(destinationVessel.capacity).inserted else { continue }
                }
                if let move = move(from: source, to: destination) { moves.append(move) }
            }
        }
        return moves
    }

    /// Hamleyi uygular ve **yeni** bir tahta döner. Hamle yasal değilse `nil`.
    public func applying(_ move: Move) -> GameState? {
        guard isLegal(from: move.source, to: move.destination),
              vessels[move.source].topRunLength >= move.count,
              vessels[move.destination].freeSpace >= move.count,
              vessels[move.source].top?.color == move.color
        else { return nil }

        var next = self
        let beads = next.vessels[move.source].removeTop(move.count)
        next.vessels[move.destination].append(beads)
        next.moveCount += 1
        next.history.append(move)
        return next
    }

    /// `source → destination` hamlesini kurar ve uygular.
    public func applying(from source: Int, to destination: Int) -> GameState? {
        guard let move = move(from: source, to: destination) else { return nil }
        return applying(move)
    }

    /// Son hamleyi geri alır. Hamle geçmişi boşsa `nil`.
    ///
    /// Geri al, hamlenin tersini uygulayarak çalışır: taşınan taneler hedefin
    /// ağzında hâlâ üst üste durduğu için ters hamle daima yasaldır.
    public func undoing() -> GameState? {
        guard let last = history.last else { return nil }
        var previous = self
        let beads = previous.vessels[last.destination].removeTop(last.count)
        previous.vessels[last.source].append(beads)
        previous.moveCount -= 1
        previous.history.removeLast()
        return previous
    }

    /// Tahtaya bir arı salar: verilen kapasitede boş bir kap eklenir
    /// (bkz. `docs/gdd.md` §2.1 — arı = ekstra boş kap).
    public func addingBee(capacity: Int) -> GameState {
        var next = self
        next.vessels.append(Vessel(capacity: capacity))
        next.beesUsed += 1
        return next
    }

    /// Bu tahtada başka yasal hamle var mı? Yoksa oyun çıkmazdadır ve
    /// UI otomatik geri al önerir (bkz. `docs/ui-spec.md` §6).
    public var isStuck: Bool { !isSolved && legalMoves().isEmpty }
}
