import XCTest
import Foundation
@testable import BloomsortDomain

/// `Resources/levels.json` üzerindeki yapısal denetimler.
///
/// Paketin tamamının çözülebilirliği CI'da `levelgen --verify` ile kanıtlanıyor
/// (her seviye seed'den yeniden kurulup çözülüyor, çözüm yolu baştan sona
/// oynanıyor). Burada hızlı koşan denetimler var; çözme yalnızca ilk
/// seviyelerde yapılıyor ki test paketi saniyeler içinde bitsin.
final class LevelPackTests: XCTestCase {

    private func loadPack() throws -> LevelPack {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // DomainTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // kök
            .appendingPathComponent("Resources/levels.json")
        return try JSONDecoder().decode(LevelPack.self, from: Data(contentsOf: url))
    }

    func testPaketTamVeSirali() throws {
        let pack = try loadPack()
        XCTAssertEqual(pack.levels.count, 200, "lansman paketi 200 seviye")
        XCTAssertEqual(pack.levels.map(\.id), Array(1...200))
    }

    func testHerSeviyeSeeddenYenidenKurulabiliyor() throws {
        for level in try loadPack().levels {
            let board = level.board
            XCTAssertEqual(board.vessels.map(\.capacity), level.capacities, "seviye \(level.id)")
            XCTAssertEqual(board.vessels.count, level.vesselCount, "seviye \(level.id)")
            XCTAssertTrue(board.isConsistent,
                          "seviye \(level.id): renk adetleri kapasitelerle uyuşmuyor")
            XCTAssertFalse(board.isSolved, "seviye \(level.id): tahta zaten çözülmüş")
            XCTAssertFalse(board.isStuck, "seviye \(level.id): tahta çıkmazda")
        }
    }

    func testYenidenKurmaDeterminist() throws {
        for level in try loadPack().levels.prefix(40) {
            XCTAssertEqual(level.board, level.board, "seviye \(level.id)")
        }
    }

    func testMStarBandaOturuyor() throws {
        for level in try loadPack().levels {
            // Nefes seviyeleri indirilmiş bandı kullanır, tutmazsa bandın
            // tamamına düşer; ikisinden birine oturmak zorunda.
            let bands = Difficulty.candidateRanges(for: level.id)
            XCTAssertTrue(bands.contains { $0.contains(level.optimalMoves) },
                          "seviye \(level.id): M* \(level.optimalMoves) ∉ \(bands)")
            XCTAssertGreaterThanOrEqual(level.branchingFactor,
                                        LevelGenerator.minimumBranchingFactor,
                                        "seviye \(level.id)")
        }
    }

    func testParametrelerBandaUyuyor() throws {
        for level in try loadPack().levels {
            let band = Difficulty.band(for: level.id)
            XCTAssertTrue(band.colors.contains(level.colors), "seviye \(level.id)")
            XCTAssertTrue(band.emptyVessels.contains(level.emptyVessels), "seviye \(level.id)")
            XCTAssertTrue(level.capacities.allSatisfy { band.capacityPool.contains($0) },
                          "seviye \(level.id)")
        }
    }

    func testIlkSeviyelerKayitliMStarIleCozuluyor() throws {
        for level in try loadPack().levels.prefix(30) {
            let board = level.board
            guard let solution = Solver.solve(board, limit: level.optimalMoves) else {
                return XCTFail("seviye \(level.id): çözülemedi")
            }
            XCTAssertEqual(solution.count, level.optimalMoves, "seviye \(level.id)")
            var state = board
            for move in solution {
                state = try XCTUnwrap(state.applying(move), "seviye \(level.id)")
            }
            XCTAssertTrue(state.isSolved, "seviye \(level.id)")
        }
    }
}
