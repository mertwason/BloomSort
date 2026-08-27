import XCTest
@testable import BloomsortDomain

/// Kural mantığı iki yerde yaşıyor: oyunun kullandığı `GameState` ve çözücünün
/// kullandığı sıkıştırılmış `Position`. İkisinin ayrışması, çözücünün
/// oynanamayan çözümler üretmesi demek olurdu. Bu test rastgele hamle
/// dizilerini iki yoldan da oynatıp tahtaları karşılaştırıyor.
final class ObstacleParityTests: XCTestCase {

    private func randomObstacleBoard(seed: UInt64) -> GameState {
        var rng = SplitMix64(seed: seed)
        let colorCount = rng.int(in: 3...5)
        let capacities = (0..<(colorCount + 2)).map { _ in rng.pick([3, 4, 5]) }
        var vessels: [Vessel] = []
        for color in 0..<colorCount {
            let capacity = capacities[color]
            var beads = (0..<capacity).map { _ in Bead(color: color) }
            // Renkleri biraz karıştır: bazı tanelerin rengini komşuya çevir.
            if rng.int(below: 2) == 0, beads.count > 1 {
                beads[beads.count - 1] = Bead(color: (color + 1) % colorCount)
            }
            vessels.append(Vessel(capacity: capacity, beads: beads))
        }
        vessels.append(Vessel(capacity: capacities[colorCount]))
        vessels.append(Vessel(capacity: capacities[colorCount + 1]))

        // Engelleri serp.
        var result: [Vessel] = []
        for (index, vessel) in vessels.enumerated() {
            var lock = 0
            var dewIndex: Int?
            var dewCountdown = 0
            if index % 4 == 1 { lock = rng.int(in: 1...5) }
            if index % 4 == 2, !vessel.beads.isEmpty {
                dewIndex = rng.int(below: vessel.beads.count)
                dewCountdown = rng.int(in: 1...2)
            }
            result.append(vessel.settingObstacles(lockCountdown: lock,
                                                  dewIndex: dewIndex,
                                                  dewCountdown: dewCountdown))
        }

        let windy = seed % 2 == 0
        let pairs = (0..<6).map { _ -> WindSchedule.Pair in
            let first = rng.int(below: result.count)
            var second = rng.int(below: result.count - 1)
            if second >= first { second += 1 }
            return WindSchedule.Pair(first, second)
        }
        return GameState(vessels: result, wind: windy ? WindSchedule(pairs: pairs) : nil)
    }

    func testGameStateVePositionAyniSonucuVeriyor() {
        var checkedMoves = 0
        for seed in UInt64(1)...120 {
            var state = randomObstacleBoard(seed: seed)
            var position = Position(state)
            XCTAssertEqual(position.gameState.vessels, state.vessels, "seed \(seed): kurulum")

            var rng = SplitMix64(seed: seed &* 7 &+ 1)
            for step in 0..<12 {
                let moves = state.legalMoves()
                guard !moves.isEmpty else { break }
                let move = moves[rng.int(below: moves.count)]
                guard let nextState = state.applying(move) else {
                    return XCTFail("seed \(seed) adım \(step): yasal hamle uygulanamadı")
                }
                let nextPosition = position.applying(source: move.source,
                                                     destination: move.destination,
                                                     count: move.count,
                                                     color: move.color.index)
                XCTAssertEqual(nextPosition.gameState.vessels, nextState.vessels,
                               "seed \(seed) adım \(step): kaplar ayrıştı")
                XCTAssertEqual(nextPosition.moveIndex, nextState.moveCount,
                               "seed \(seed) adım \(step): hamle sayacı ayrıştı")
                XCTAssertEqual(nextPosition.isSolved, nextState.isSolved,
                               "seed \(seed) adım \(step): bitiş kararı ayrıştı")
                state = nextState
                position = nextPosition
                checkedMoves += 1
            }
        }
        XCTAssertGreaterThan(checkedMoves, 300, "yeterli hamle karşılaştırılmadı")
    }

    func testYasalHamleKumeleriAyni() {
        for seed in UInt64(1)...80 {
            var state = randomObstacleBoard(seed: seed)
            var rng = SplitMix64(seed: seed &* 13 &+ 5)
            for _ in 0..<8 {
                let position = Position(state)
                let stateMoves = Set(state.legalMoves().map { [$0.source, $0.destination, $0.count] })
                let searchMoves = Set(Solver.candidateMovesForTesting(position)
                    .map { [$0.source, $0.destination, $0.count] })
                XCTAssertTrue(searchMoves.isSubset(of: stateMoves),
                              "seed \(seed): çözücü yasadışı hamle üretti")
                let moves = state.legalMoves()
                guard !moves.isEmpty else { break }
                guard let next = state.applying(moves[rng.int(below: moves.count)]) else { break }
                state = next
            }
        }
    }
}
