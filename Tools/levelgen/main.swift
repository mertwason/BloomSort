import BloomsortDomain
import Foundation

// levelgen — seviye üretimi ve doğrulama CLI'ı (bkz. docs/gdd.md §4.1).
//
//   swift run levelgen --count 200 --out Resources/levels.json
//   swift run levelgen --verify Resources/levels.json
//   swift run levelgen --benchmark 100

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("hata: \(message)\n".utf8))
    exit(1)
}

func usage() -> Never {
    print("""
    levelgen — Bloomsort seviye üreticisi

      --count <n>        Üretilecek seviye sayısı (varsayılan 200)
      --from <n>         İlk seviye numarası (varsayılan 1)
      --seed <n>         Başlangıç seed'i (varsayılan 1)
      --out <yol>        Çıktı JSON dosyası (varsayılan Resources/levels.json)
      --verify <yol>     Var olan bir paketi yeniden kurup çözerek doğrula
      --benchmark <n>    n rastgele 12 renkli tahtada çözücü süresini ölç
      --diagnose <n>     n. seviye için ret nedenlerinin dağılımını yaz
      --depth <n>        --benchmark için ters hamle derinliği (varsayılan 280)
      --level-budget <sn> Seviye başına üst süre sınırı (varsayılan yok)
      --diagnose-count <n> --diagnose için denenecek seed sayısı (varsayılan 20)
      --resume           Var olan çıktı dosyasının kaldığı yerden devam et
      --probe <n>        n. seviyenin parametreleriyle ulaşılabilir en yüksek M*'ı ölç
      --quiet            Seviye seviye ilerleme yazma
    """)
    exit(0)
}

var count = 200
var firstLevel = 1
var seed: UInt64 = 1
var outputPath = "Resources/levels.json"
var verifyPath: String?
var benchmark: Int?
var diagnose: Int?
var benchmarkDepth = 280
var levelBudget: TimeInterval?
var diagnoseCount = 20
var resume = false
var probe: Int?
var quiet = false

var arguments = Array(CommandLine.arguments.dropFirst())
while let argument = arguments.first {
    arguments.removeFirst()
    func value(_ name: String) -> String {
        guard let next = arguments.first else { fail("\(name) bir değer bekliyor") }
        arguments.removeFirst()
        return next
    }
    func intValue(_ name: String) -> Int {
        guard let parsed = Int(value(name)) else { fail("\(name) sayı olmalı") }
        return parsed
    }
    switch argument {
    case "--count":     count = intValue("--count")
    case "--from":      firstLevel = intValue("--from")
    case "--seed":      seed = UInt64(intValue("--seed"))
    case "--out":       outputPath = value("--out")
    case "--verify":    verifyPath = value("--verify")
    case "--benchmark": benchmark = intValue("--benchmark")
    case "--diagnose":  diagnose = intValue("--diagnose")
    case "--depth":     benchmarkDepth = intValue("--depth")
    case "--level-budget": levelBudget = TimeInterval(intValue("--level-budget"))
    case "--diagnose-count": diagnoseCount = intValue("--diagnose-count")
    case "--resume":    resume = true
    case "--probe":     probe = intValue("--probe")
    case "--quiet":     quiet = true
    case "-h", "--help": usage()
    default: fail("bilinmeyen argüman: \(argument)")
    }
}

// MARK: - Doğrulama

if let verifyPath {
    guard let data = FileManager.default.contents(atPath: verifyPath) else {
        fail("dosya okunamadı: \(verifyPath)")
    }
    let pack = try JSONDecoder().decode(LevelPack.self, from: data)
    var worst = 0.0
    var total = 0.0
    for level in pack.levels {
        let board = level.board
        guard board.isConsistent else { fail("seviye \(level.id): renk adetleri kapasitelerle uyuşmuyor") }
        guard !board.isSolved else { fail("seviye \(level.id): tahta zaten çözülmüş") }
        guard board.vessels.map(\.capacity) == level.capacities else {
            fail("seviye \(level.id): yeniden kurulan kapasiteler kayıtla uyuşmuyor")
        }
        // Üretimdeki bütçenin aynısı; oyun içi varsayılan bütçe derin
        // seviyeleri kanıtlamaya yetmiyor.
        guard let result = Solver.detailedSolve(board, limit: level.optimalMoves,
                                                nodeLimit: LevelGenerator.solverNodeLimit) else {
            fail("seviye \(level.id): çözülemedi")
        }
        guard result.optimalMoves == level.optimalMoves else {
            fail("seviye \(level.id): M* \(result.optimalMoves), kayıtta \(level.optimalMoves)")
        }
        var state = board
        for move in result.moves {
            guard let next = state.applying(move) else { fail("seviye \(level.id): çözüm yolunda yasadışı hamle") }
            state = next
        }
        guard state.isSolved else { fail("seviye \(level.id): çözüm yolu tahtayı bitirmiyor") }
        total += result.statistics.seconds
        worst = max(worst, result.statistics.seconds)
    }
    let average = pack.levels.isEmpty ? 0 : total / Double(pack.levels.count)
    print("\(pack.levels.count) seviye doğrulandı · ortalama çözüm \(String(format: "%.1f", average * 1000)) ms · en yavaş \(String(format: "%.1f", worst * 1000)) ms")
    exit(0)
}

// MARK: - Teşhis

// MARK: - Ulaşılabilir zorluk ölçümü

if let probe {
    // Ters yürüyüşün en derin noktasındaki M*, o bandın parametreleriyle
    // ulaşılabilecek zorluğun üst sınırı. Bant bunun altında kalmak zorunda.
    var reached: [Int] = []
    var currentSeed = seed
    for _ in 0..<diagnoseCount {
        let parameters = LevelGenerator.Parameters(level: probe, seed: currentSeed)
        currentSeed &+= 1
        var rng = SplitMix64(seed: parameters.seed)
        guard let deepest = LevelGenerator.scrambledBoard(parameters: parameters,
                                                          reverseMoves: 140, rng: &rng) else {
            print("  karıştırma tıkandı")
            continue
        }
        let solved = Solver.solve(deepest, limit: 60, nodeLimit: LevelGenerator.solverNodeLimit)
        let text = solved.map { "\($0.count)" } ?? "bütçe aşıldı"
        print("  K=\(parameters.colors) E=\(parameters.emptyVessels) toplam kapasite=\(parameters.capacities.reduce(0,+)) → en derin M* \(text)")
        if let solved { reached.append(solved.count) }
    }
    if !reached.isEmpty {
        print("seviye \(probe): ulaşılan M* \(reached.min()!)–\(reached.max()!), ortanca \(reached.sorted()[reached.count/2])")
    }
    exit(0)
}

if let diagnose {
    var histogram: [String: Int] = [:]
    var accepted = 0
    var currentSeed = seed
    let started = Date()
    for _ in 0..<diagnoseCount {
        let seedStart = Date()
        switch LevelGenerator.make(level: diagnose, seed: currentSeed) {
        case .success(let level):
            accepted += 1
            print(String(format: "  seed %d → kabul · K=%d M*=%d · %.1f sn",
                         currentSeed, level.colors, level.optimalMoves,
                         Date().timeIntervalSince(seedStart)))
        case .failure(let reason):
            histogram[reason.rawValue, default: 0] += 1
            print(String(format: "  seed %d → %@ · %.1f sn", currentSeed, reason.rawValue,
                         Date().timeIntervalSince(seedStart)))
        }
        currentSeed &+= 1
    }
    print("seviye \(diagnose) · M* bandı \(Difficulty.optimalMoveRange(for: diagnose)) · \(diagnoseCount) seed · \(String(format: "%.1f", Date().timeIntervalSince(started))) sn")
    print("  kabul: \(accepted)")
    for (reason, count) in histogram.sorted(by: { $0.value > $1.value }) {
        print("  \(reason): \(count)")
    }
    exit(0)
}

// MARK: - Çözücü ölçümü

if let benchmark {
    // GDD §8.3'ün ölçüsü: 12 renk / 15 kap.
    var rng = SplitMix64(seed: 20260826)
    var durations: [Double] = []
    var optimal: [Int] = []
    var nodes = 0
    var unsolved = 0
    for _ in 0..<benchmark {
        let capacities = (0..<15).map { _ in rng.pick([3, 4, 5, 6]) }
        let parameters = LevelGenerator.Parameters(level: 200, seed: rng.next(),
                                                   colors: 12, emptyVessels: 3,
                                                   capacities: capacities)
        guard let board = LevelGenerator.scrambledBoard(parameters: parameters,
                                                        reverseMoves: benchmarkDepth,
                                                        rng: &rng) else { continue }
        guard let result = Solver.detailedSolve(board, limit: Solver.defaultLimit) else {
            unsolved += 1
            continue
        }
        durations.append(result.statistics.seconds)
        optimal.append(result.optimalMoves)
        nodes += result.statistics.nodes
    }
    guard !durations.isEmpty else { fail("bütçe içinde çözülebilen tahta çıkmadı") }
    let sorted = durations.sorted()
    let average = durations.reduce(0, +) / Double(durations.count)
    print("""
    çözücü ölçümü · 12 renk / 15 kap · \(benchmarkDepth) ters hamle
      çözülen   \(durations.count)/\(benchmark) (bütçe aşan: \(unsolved))
      ortalama  \(String(format: "%.1f", average * 1000)) ms
      medyan    \(String(format: "%.1f", sorted[sorted.count / 2] * 1000)) ms
      en yavaş  \(String(format: "%.1f", sorted[sorted.count - 1] * 1000)) ms
      M* aralığı \(optimal.min()!)–\(optimal.max()!)
      düğüm     \(nodes / durations.count) / tahta
    """)
    exit(0)
}

// MARK: - Üretim

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                        withIntermediateDirectories: true)

/// Paketi diske yazar. Her seviyeden sonra çağrılıyor: derin bantlarda üretim
/// uzun sürüyor, yarıda kesilen bir koşudan da geçerli bir paket çıksın.
func writePack(_ levels: [Level]) throws -> Int {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(LevelPack(levels: levels))
    try data.write(to: outputURL)
    return data.count
}

let start = Date()
var levels: [Level] = []
var nextSeed = seed
var failedLevel: Int?
var firstMissing = firstLevel

// --resume: yarıda kalmış bir koşuyu tam olarak kaldığı yerden sürdürür.
// Seed zinciri kesintisiz bir koşununkiyle birebir aynı: bir seviye kabul
// edildiğinde zincir o seviyenin seed'inin bir fazlasından devam eder.
if resume, let data = FileManager.default.contents(atPath: outputPath),
   let existing = try? JSONDecoder().decode(LevelPack.self, from: data),
   let last = existing.levels.last {
    levels = existing.levels
    nextSeed = last.seed &+ 1
    firstMissing = last.id + 1
    print("kaldığı yerden: \(levels.count) seviye yüklendi, seviye \(firstMissing)'den devam")
}

var byteCount = try writePack(levels)

for id in firstMissing..<(firstLevel + count) {
    let levelStart = Date()
    var found: Level?
    // Nefes seviyelerinde önce indirilmiş bant, tutmazsa bandın tamamı
    // (bkz. Difficulty.candidateRanges). Bütçe **bant başına** veriliyor:
    // aksi hâlde indirilmiş bant bütün süreyi yiyor ve geri düşüşe hiç sıra
    // gelmiyordu.
    for band in Difficulty.candidateRanges(for: id) where found == nil {
        let deadline = levelBudget.map { Date().addingTimeInterval($0) }
        var attempts = 0
        while attempts < 400, found == nil {
            attempts += 1
            if let deadline, Date() >= deadline { break }
            found = LevelGenerator.attempt(level: id, seed: nextSeed, band: band)
            nextSeed &+= 1
        }
    }
    guard let level = found else {
        failedLevel = id
        break
    }
    levels.append(level)
    byteCount = try writePack(levels)
    if !quiet {
        print(String(format: "seviye %3d · K=%2d E=%d M*=%2d R=%4d dallanma=%.2f seed=%d · %.1f sn",
                     level.id, level.colors, level.emptyVessels, level.optimalMoves,
                     level.reverseMoves, level.branchingFactor, level.seed,
                     Date().timeIntervalSince(levelStart)))
    }
}

let elapsed = Date().timeIntervalSince(start)
let bytesPerLevel = levels.isEmpty ? 0 : byteCount / max(levels.count, 1)
print("""
\(levels.count) seviye üretildi · \(String(format: "%.1f", elapsed)) sn
\(outputPath) · \(byteCount) bayt (\(bytesPerLevel) bayt/seviye)
""")
if let failedLevel {
    fail("seviye \(failedLevel) için kabul filtrelerinden geçen tahta bulunamadı; "
         + "üretilen \(levels.count) seviye yine de yazıldı")
}
