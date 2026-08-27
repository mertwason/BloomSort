import XCTest
@testable import BloomsortDomain

final class SolverTests: XCTestCase {

    /// Referans çözücü: küçük tahtalarda kesin optimal. IDA*'ı buna karşı
    /// doğruluyoruz — çünkü `M*` yıldız eşiğini ve seviye kabul bandını
    /// besliyor, yanlış olamaz.
    private func breadthFirstOptimal(_ state: GameState, limit: Int = 24) -> Int? {
        if state.isSolved { return 0 }
        var frontier = [state]
        var seen: Set<GameState> = [state]
        var depth = 0
        while !frontier.isEmpty, depth < limit {
            depth += 1
            var next: [GameState] = []
            for current in frontier {
                for move in current.legalMoves() {
                    guard let child = current.applying(move) else { continue }
                    if child.isSolved { return depth }
                    guard seen.insert(child).inserted else { continue }
                    next.append(child)
                }
            }
            frontier = next
        }
        return nil
    }

    /// Küçük ama gerçekçi rastgele tahtalar.
    private func randomBoard(seed: UInt64, colors: Int, empties: Int,
                             depth: Int) -> GameState? {
        var rng = SplitMix64(seed: seed)
        let capacities = (0..<(colors + empties)).map { _ in rng.pick([3, 4]) }
        let parameters = LevelGenerator.Parameters(level: 1, seed: seed, colors: colors,
                                                   emptyVessels: empties, capacities: capacities)
        return LevelGenerator.scrambledBoard(parameters: parameters, reverseMoves: depth, rng: &rng)
    }

    func testCozulmusTahtaSifirHamle() {
        let state = GameState(capacities: [3, 3], contents: [[0, 0, 0], [1, 1, 1]])
        XCTAssertEqual(Solver.solve(state)?.count, 0)
    }

    func testTekHamlelikTahta() {
        let state = GameState(capacities: [3, 3, 3], contents: [[0, 0, 0], [1, 1], [1]])
        let moves = Solver.solve(state)
        XCTAssertEqual(moves?.count, 1)
        // 1→2 de 2→1 de tek hamlede bitiriyor; hangisi seçilirse seçilsin
        // tahta çözülmüş olmalı.
        XCTAssertTrue(state.applying(moves![0])!.isSolved)
    }

    func testCozulemezTahtaNilDoner() {
        // İki kap da dolu, üstleri farklı → hiçbir hamle yok, çözülmemiş.
        let state = GameState(capacities: [2, 2], contents: [[0, 1], [1, 0]])
        XCTAssertNil(Solver.solve(state))
    }

    func testSinirAsilirsaNilDoner() {
        guard let board = randomBoard(seed: 7, colors: 5, empties: 2, depth: 40) else {
            return XCTFail("tahta üretilemedi")
        }
        XCTAssertNil(Solver.solve(board, limit: 1), "1 hamlede çözülemeyecek tahta")
    }

    func testIpucuOptimalIlkHamleyiVerir() {
        let state = GameState(capacities: [3, 3, 3], contents: [[0, 0, 0], [1, 1], [1]])
        XCTAssertEqual(Solver.hint(state), Solver.solve(state)?.first)
    }

    func testHeuristikKabulEdilebilir() {
        // h ≤ M* olmak zorunda; aksi hâlde IDA* optimalden uzun çözüm döner.
        var checked = 0
        for seed in UInt64(1)...60 {
            guard let board = randomBoard(seed: seed, colors: 4, empties: 2, depth: 20),
                  let optimal = breadthFirstOptimal(board) else { continue }
            XCTAssertLessThanOrEqual(Solver.heuristic(board), optimal,
                                     "seed \(seed): heuristik optimali aşıyor")
            checked += 1
        }
        XCTAssertGreaterThan(checked, 30, "yeterli örnek doğrulanmadı")
    }

    func testIDAStarOptimalCozumBulur() {
        var checked = 0
        for seed in UInt64(1)...60 {
            guard let board = randomBoard(seed: seed, colors: 4, empties: 2, depth: 20),
                  let reference = breadthFirstOptimal(board) else { continue }
            XCTAssertEqual(Solver.solve(board)?.count, reference, "seed \(seed)")
            checked += 1
        }
        XCTAssertGreaterThan(checked, 30, "yeterli örnek doğrulanmadı")
    }

    func testHamleSiralamasiOptimaliDegistirmez() {
        // Hamle sıralaması yalnızca hızı etkilemeli; bulunan M* aynı kalmalı.
        var checked = 0
        for seed in UInt64(1)...40 {
            guard let board = randomBoard(seed: seed, colors: 5, empties: 2, depth: 26),
                  let reference = breadthFirstOptimal(board, limit: 20) else { continue }
            XCTAssertEqual(Solver.solve(board)?.count, reference, "seed \(seed)")
            checked += 1
        }
        XCTAssertGreaterThan(checked, 20, "yeterli örnek doğrulanmadı")
    }

    func testCozumYoluGercektenCozuyor() {
        for seed in UInt64(1)...30 {
            guard let board = randomBoard(seed: seed, colors: 6, empties: 2, depth: 30),
                  let solution = Solver.solve(board) else { continue }
            var state = board
            for move in solution {
                guard let next = state.applying(move) else {
                    return XCTFail("seed \(seed): çözüm yolunda yasadışı hamle")
                }
                state = next
            }
            XCTAssertTrue(state.isSolved, "seed \(seed): çözüm yolu tahtayı bitirmiyor")
        }
    }

    func testAyniRenkIkiKabiDoldurarakBitebilir() {
        // 6 tane 0 rengi, iki adet 3'lük kabı doldurarak bitiyor. Kazanma
        // koşulu "her kap boş ya da tek renkle dolu" olduğu için bu geçerli
        // bir bitiş; heuristik burada sıfır vermek zorunda.
        let solved = GameState(capacities: [3, 3, 4, 4],
                               contents: [[0, 0, 0], [0, 0, 0], [1, 1, 1, 1], []])
        XCTAssertTrue(solved.isSolved)
        XCTAssertEqual(Solver.heuristic(solved), 0)
        XCTAssertEqual(Solver.solve(solved)?.count, 0)
    }

    func testRenginBolunerekBittigiTahtadaOptimalBulunur() throws {
        // Aynı kurgu, karışmış hâlde: "her rengi tek kaba topla" varsayan bir
        // heuristik burada optimali aşıyor ve IDA* uzun çözüm döndürüyordu.
        let state = GameState(capacities: [3, 3, 4, 4],
                              contents: [[0, 1, 0], [1, 0, 1], [0, 1, 0, 0], []])
        let reference = try XCTUnwrap(breadthFirstOptimal(state))
        XCTAssertEqual(Solver.solve(state)?.count, reference)
    }

    func testHeuristikCozumYolununTamamindaKabulEdilebilir() {
        // Kök yeterli değil: kabul edilebilirlik yolun her düğümünde geçerli
        // olmalı, yoksa IDA* eşiği erken atlıyor.
        var checked = 0
        for seed in UInt64(1)...40 {
            guard let board = randomBoard(seed: seed, colors: 5, empties: 2, depth: 26),
                  let solution = Solver.solve(board) else { continue }
            var state = board
            for (index, move) in solution.enumerated() {
                XCTAssertLessThanOrEqual(Solver.heuristic(state), solution.count - index,
                                         "seed \(seed), adım \(index)")
                state = state.applying(move)!
                checked += 1
            }
        }
        XCTAssertGreaterThan(checked, 100, "yeterli örnek doğrulanmadı")
    }

    // MARK: - Engelli tahtalar

    /// Engelli tahtalarda da IDA* optimali bulmalı: kilit ve çiy sayaçları
    /// hamle uzunluğunu değiştiriyor, rüzgâr ise heuristiğin alt sınırını.
    func testEngelliTahtalardaOptimalBulunuyor() {
        var checked = 0
        for seed in UInt64(1)...50 {
            var rng = SplitMix64(seed: seed)
            let colors = 3
            let capacities = (0..<(colors + 2)).map { _ in rng.pick([3, 4]) }
            let parameters = LevelGenerator.Parameters(level: 1, seed: seed, colors: colors,
                                                       emptyVessels: 2, capacities: capacities)
            guard let plain = LevelGenerator.scrambledBoard(parameters: parameters,
                                                            reverseMoves: 14, rng: &rng) else { continue }
            // Bir kaba kilit, bir kaba çiy koy.
            var vessels = plain.vessels
            if let lockTarget = vessels.indices.first(where: { vessels[$0].isEmpty }) {
                vessels[lockTarget] = vessels[lockTarget].settingObstacles(lockCountdown: 2)
            }
            if let dewTarget = vessels.indices.first(where: { vessels[$0].count >= 2 }) {
                vessels[dewTarget] = vessels[dewTarget].settingObstacles(dewIndex: 0, dewCountdown: 1)
            }
            let board = GameState(vessels: vessels)
            guard let reference = breadthFirstOptimal(board, limit: 18) else { continue }
            XCTAssertEqual(Solver.solve(board)?.count, reference, "seed \(seed)")
            checked += 1
        }
        XCTAssertGreaterThan(checked, 15, "yeterli örnek doğrulanmadı")
    }

    func testRuzgarliTahtalardaOptimalBulunuyor() {
        var checked = 0
        for seed in UInt64(1)...40 {
            var rng = SplitMix64(seed: seed &* 3)
            let capacities = (0..<5).map { _ in rng.pick([3, 4]) }
            let parameters = LevelGenerator.Parameters(level: 1, seed: seed, colors: 3,
                                                       emptyVessels: 2, capacities: capacities)
            guard let plain = LevelGenerator.scrambledBoard(parameters: parameters,
                                                            reverseMoves: 12, rng: &rng) else { continue }
            let pairs = (0..<4).map { _ -> WindSchedule.Pair in
                let first = rng.int(below: plain.vessels.count)
                var second = rng.int(below: plain.vessels.count - 1)
                if second >= first { second += 1 }
                return WindSchedule.Pair(first, second)
            }
            let board = GameState(vessels: plain.vessels, wind: WindSchedule(pairs: pairs))
            guard let reference = breadthFirstOptimal(board, limit: 16) else { continue }
            XCTAssertEqual(Solver.solve(board)?.count, reference, "seed \(seed)")
            checked += 1
        }
        XCTAssertGreaterThan(checked, 10, "yeterli örnek doğrulanmadı")
    }

    func testRuzgarliHeuristikKabulEdilebilir() {
        // Rüzgâr, oyuncu hamlesi olmadan da heuristiği düşürebiliyor; alt sınır
        // bunu hesaba katmazsa IDA* optimalden uzun çözüm döner.
        for seed in UInt64(1)...30 {
            var rng = SplitMix64(seed: seed &* 11)
            let capacities = (0..<5).map { _ in rng.pick([3, 4]) }
            let parameters = LevelGenerator.Parameters(level: 1, seed: seed, colors: 3,
                                                       emptyVessels: 2, capacities: capacities)
            guard let plain = LevelGenerator.scrambledBoard(parameters: parameters,
                                                            reverseMoves: 12, rng: &rng) else { continue }
            let pairs = (0..<4).map { _ in WindSchedule.Pair(0, 1) }
            let board = GameState(vessels: plain.vessels, wind: WindSchedule(pairs: pairs))
            guard let solution = Solver.solve(board, limit: 16) else { continue }
            var state = board
            for (index, move) in solution.enumerated() {
                XCTAssertLessThanOrEqual(Solver.heuristic(state), solution.count - index,
                                         "seed \(seed), adım \(index)")
                state = state.applying(move)!
            }
        }
    }

    func testDugumButcesiAramayiSinirlar() {
        guard let board = randomBoard(seed: 3, colors: 8, empties: 2, depth: 120) else {
            return XCTFail("tahta üretilemedi")
        }
        XCTAssertNil(Solver.solve(board, nodeLimit: 500),
                     "düğüm bütçesi dolunca arama durmalı")
    }
}
