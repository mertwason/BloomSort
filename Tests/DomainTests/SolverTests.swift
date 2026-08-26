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

    func testDugumButcesiAramayiSinirlar() {
        guard let board = randomBoard(seed: 3, colors: 8, empties: 2, depth: 120) else {
            return XCTFail("tahta üretilemedi")
        }
        XCTAssertNil(Solver.solve(board, nodeLimit: 500),
                     "düğüm bütçesi dolunca arama durmalı")
    }
}
