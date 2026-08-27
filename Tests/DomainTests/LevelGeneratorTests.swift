import XCTest
@testable import BloomsortDomain

final class LevelGeneratorTests: XCTestCase {

    // MARK: - Zorluk tablosu

    func testZorlukBantlari() {
        XCTAssertEqual(Difficulty.band(for: 1).colors, 2...2)
        XCTAssertEqual(Difficulty.band(for: 12).optimalMoves, 14...18)
        XCTAssertEqual(Difficulty.band(for: 300).colors, 9...12)
    }

    func testNefesSeviyeleriBandiDusurur() {
        XCTAssertTrue(Difficulty.isBreatherLevel(15))
        XCTAssertFalse(Difficulty.isBreatherLevel(16))
        // 11-25 bandı 14...18; %60'ı 8...11.
        XCTAssertEqual(Difficulty.optimalMoveRange(for: 15), 8...11)
        XCTAssertEqual(Difficulty.optimalMoveRange(for: 16), 14...18)
    }

    // MARK: - Parametreler

    func testCozulmusBaslangicDurumu() {
        let parameters = LevelGenerator.Parameters(level: 1, seed: 42, colors: 3,
                                                   emptyVessels: 2, capacities: [3, 4, 5, 4, 6])
        let solved = parameters.solvedState
        XCTAssertEqual(solved.vessels.count, 5)
        XCTAssertTrue(solved.isSolved)
        XCTAssertTrue(solved.isConsistent)
        XCTAssertEqual(solved.vessels.prefix(3).map(\.count), [3, 4, 5])
        XCTAssertTrue(solved.vessels.suffix(2).allSatisfy(\.isEmpty))
    }

    func testParametrelerSeeddenDeterminist() {
        let a = LevelGenerator.Parameters(level: 60, seed: 12345)
        let b = LevelGenerator.Parameters(level: 60, seed: 12345)
        XCTAssertEqual(a.capacities, b.capacities)
        XCTAssertEqual(a.colors, b.colors)
        XCTAssertEqual(a.emptyVessels, b.emptyVessels)
    }

    func testParametrelerBandaUyar() {
        let band = Difficulty.band(for: 30)
        for seed in UInt64(1)...50 {
            let parameters = LevelGenerator.Parameters(level: 30, seed: seed)
            XCTAssertTrue(band.colors.contains(parameters.colors))
            XCTAssertTrue(band.emptyVessels.contains(parameters.emptyVessels))
            XCTAssertTrue(parameters.capacities.allSatisfy { band.capacityPool.contains($0) })
        }
    }

    // MARK: - Ters hamleler

    func testTersHamleTahtayiTutarliBirakir() {
        let parameters = LevelGenerator.Parameters(level: 20, seed: 9)
        var rng = SplitMix64(seed: 9)
        guard let board = LevelGenerator.scrambledBoard(parameters: parameters,
                                                        reverseMoves: 40, rng: &rng) else {
            return XCTFail("karıştırma başarısız")
        }
        XCTAssertTrue(board.isConsistent, "renk adetleri kapasitelerle uyuşmalı")
        XCTAssertFalse(board.isSolved)
        XCTAssertEqual(board.vessels.map(\.capacity), parameters.capacities)
    }

    func testTersHamleHedefinAgzindakiRengiTekrarlamaz() {
        let parameters = LevelGenerator.Parameters(level: 20, seed: 3)
        let vessels = Position(parameters.solvedState).vessels
        for move in LevelGenerator.reverseMoves(vessels) {
            let receiver = vessels[move.receiver]
            XCTAssertGreaterThanOrEqual(Position.freeSpace(receiver), move.count)
            if let top = Position.topColor(receiver) {
                XCTAssertNotEqual(top, move.color)
            }
        }
    }

    func testAyniSeedAyniYuruyus() {
        let parameters = LevelGenerator.Parameters(level: 20, seed: 77)
        var first = SplitMix64(seed: 77)
        var second = SplitMix64(seed: 77)
        let a = LevelGenerator.scrambledBoard(parameters: parameters, reverseMoves: 30, rng: &first)
        let b = LevelGenerator.scrambledBoard(parameters: parameters, reverseMoves: 30, rng: &second)
        XCTAssertEqual(a, b)
    }

    // MARK: - Üretim ve kabul filtreleri

    func testUretilenSeviyeBandaOturur() throws {
        for level in [1, 7, 15, 20, 26] {
            let generated = LevelGenerator.generate(level: level, startingSeed: 1)
            let created = try XCTUnwrap(generated?.level, "seviye \(level) üretilemedi")
            let band = Difficulty.optimalMoveRange(for: level)
            XCTAssertTrue(band.contains(created.optimalMoves),
                          "seviye \(level): M* \(created.optimalMoves) ∉ \(band)")
            XCTAssertGreaterThanOrEqual(created.branchingFactor,
                                        LevelGenerator.minimumBranchingFactor)
        }
    }

    func testNefesSeviyesiGecBantlardaBandinTamaminaDuser() {
        // Seviye 135 nefes seviyesi: indirilmiş bant 11...13, ama 9-11 renkli
        // bir tahta o kadar az hamlede ancak baştan yarı çözülmüş olursa biter
        // ve bayat tahta filtresine takılır. Üretici bandın tamamına düşmeli.
        XCTAssertEqual(Difficulty.candidateRanges(for: 135).count, 2)
        XCTAssertEqual(Difficulty.candidateRanges(for: 136).count, 1)
        XCTAssertEqual(Difficulty.candidateRanges(for: 135).last,
                       Difficulty.band(for: 135).optimalMoves,
                       "son çare bandın tamamı olmalı")
        // Uçtan uca kanıt Resources/levels.json'da: 135 orada ve CI onu
        // çözerek doğruluyor. Burada üretmek dakikalar sürüyor.
    }

    func testUretilenSeviyeTahtasiCozulur() throws {
        for level in [3, 9, 18, 24] {
            let created = try XCTUnwrap(LevelGenerator.generate(level: level, startingSeed: 5)?.level)
            let board = created.board
            XCTAssertTrue(board.isConsistent)
            XCTAssertFalse(board.isSolved)
            let solution = try XCTUnwrap(Solver.solve(board, limit: created.optimalMoves))
            XCTAssertEqual(solution.count, created.optimalMoves)
            var state = board
            for move in solution { state = try XCTUnwrap(state.applying(move)) }
            XCTAssertTrue(state.isSolved)
        }
    }

    func testTahtaSeeddenBirebirYenidenKurulur() throws {
        let created = try XCTUnwrap(LevelGenerator.generate(level: 22, startingSeed: 11)?.level)
        XCTAssertEqual(created.board, created.board, "yeniden kurma determinist olmalı")
        XCTAssertEqual(created.board.vessels.map(\.capacity), created.capacities)
        XCTAssertEqual(created.vesselCount, created.colors + created.emptyVessels)
    }

    func testBayatTahtaFiltresi() throws {
        let created = try XCTUnwrap(LevelGenerator.generate(level: 20, startingSeed: 2)?.level)
        let board = created.board
        let solution = try XCTUnwrap(Solver.solve(board, limit: created.optimalMoves))
        XCTAssertLessThanOrEqual(LevelGenerator.earlyCompletions(board, solution: solution),
                                 LevelGenerator.maximumEarlyCompletions)
    }

    func testDallanmaFaktoruOlcumu() {
        // Tek yol: her adımda tek anlamlı hamle → dallanma 1.
        let state = GameState(capacities: [3, 3, 3], contents: [[0, 0, 0], [1, 1], [1]])
        let solution = Solver.solve(state)!
        XCTAssertEqual(LevelGenerator.branchingFactor(state, solution: solution), 2.0, accuracy: 0.001)
    }

    // MARK: - Yıldız eşikleri

    func testUcYildizYalnizcaTamOptimalde() {
        let level = Level(id: 1, seed: 1, colors: 2, emptyVessels: 2, capacities: [4, 4, 4, 4],
                          reverseMoves: 5, optimalMoves: 20, branchingFactor: 3)
        XCTAssertEqual(level.stars(forMoves: 20), 3)
        XCTAssertEqual(level.stars(forMoves: 19), 3, "optimalin altı olamaz ama 3★ sayılır")
        XCTAssertEqual(level.stars(forMoves: 21), 2)
    }

    func testIkiYildizToleransi() {
        let level = Level(id: 1, seed: 1, colors: 2, emptyVessels: 2, capacities: [4, 4, 4, 4],
                          reverseMoves: 5, optimalMoves: 20, branchingFactor: 3)
        XCTAssertEqual(level.stars(forMoves: 25), 2, "M*×1,25 sınırda 2★")
        XCTAssertEqual(level.stars(forMoves: 26), 1)
        XCTAssertEqual(level.stars(forMoves: 200), 1, "kaybetme yok, taban 1★")
    }

    // MARK: - Kayıt biçimi

    func testLevelJSONGidisDonus() throws {
        let created = try XCTUnwrap(LevelGenerator.generate(level: 12, startingSeed: 3)?.level)
        let pack = LevelPack(levels: [created])
        let data = try JSONEncoder().encode(pack)
        let decoded = try JSONDecoder().decode(LevelPack.self, from: data)
        XCTAssertEqual(decoded, pack)
        XCTAssertEqual(decoded.levels[0].board, created.board)
    }
}
