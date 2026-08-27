import XCTest
@testable import BloomsortDomain

/// Engel kuralları — `docs/gdd.md` §4.2.
final class ObstacleTests: XCTestCase {

    // MARK: - Kapalı tomurcuk

    func testKilitliKapKaynakOlamaz() {
        let state = GameState(vessels: [
            Vessel(capacity: 4, beads: [Bead(color: 0)], lockCountdown: 3),
            Vessel(capacity: 4),
        ])
        XCTAssertFalse(state.isLegal(from: 0, to: 1))
        XCTAssertTrue(state.vessels[0].isLocked)
    }

    func testKilitliKapHedefOlamaz() {
        let state = GameState(vessels: [
            Vessel(capacity: 4, beads: [Bead(color: 0)]),
            Vessel(capacity: 4, lockCountdown: 2),
        ])
        XCTAssertFalse(state.isLegal(from: 0, to: 1))
    }

    func testKilitSayaciTasinanTaneKadarDuser() throws {
        let state = GameState(vessels: [
            Vessel(capacity: 4, beads: [Bead(color: 0), Bead(color: 1), Bead(color: 1)]),
            Vessel(capacity: 4),
            Vessel(capacity: 4, beads: [Bead(color: 2)], lockCountdown: 5),
        ])
        let next = try XCTUnwrap(state.applying(from: 0, to: 1))
        XCTAssertEqual(next.vessels[1].count, 2, "iki tane taşındı")
        XCTAssertEqual(next.vessels[2].lockCountdown, 3, "kilit iki düştü")
    }

    func testKilitSifirlanincaAcilir() throws {
        var state = GameState(vessels: [
            Vessel(capacity: 4, beads: [Bead(color: 0)]),
            Vessel(capacity: 4),
            Vessel(capacity: 4, beads: [Bead(color: 1)], lockCountdown: 1),
        ])
        state = try XCTUnwrap(state.applying(from: 0, to: 1))
        XCTAssertFalse(state.vessels[2].isLocked)
        XCTAssertTrue(state.isLegal(from: 2, to: 0), "açılan kap artık kaynak olabilir")
    }

    func testKilitHedefeYapilanHamledeDusmez() throws {
        // Kilit "başka yere yerleşince" düşer; hedefin kendi sayacı düşmez.
        let state = GameState(vessels: [
            Vessel(capacity: 4, beads: [Bead(color: 0)]),
            Vessel(capacity: 4),
            Vessel(capacity: 4, lockCountdown: 4),
        ])
        let next = try XCTUnwrap(state.applying(from: 0, to: 1))
        XCTAssertEqual(next.vessels[2].lockCountdown, 3)
    }

    // MARK: - Çiy damlası

    func testDonmusUstTaneTasinamaz() {
        let state = GameState(vessels: [
            Vessel(capacity: 4, beads: [Bead(color: 0), Bead(color: 1)],
                   dewIndex: 1, dewCountdown: 2),
            Vessel(capacity: 4),
        ])
        XCTAssertTrue(state.vessels[0].isTopFrozen)
        XCTAssertEqual(state.vessels[0].movableRunLength, 0)
        XCTAssertFalse(state.isLegal(from: 0, to: 1))
    }

    func testDonmusTaneninUstundekilerTasinabilir() throws {
        let state = GameState(vessels: [
            Vessel(capacity: 4,
                   beads: [Bead(color: 0), Bead(color: 1), Bead(color: 1)],
                   dewIndex: 0, dewCountdown: 2),
            Vessel(capacity: 4),
        ])
        XCTAssertEqual(state.vessels[0].movableRunLength, 2)
        let next = try XCTUnwrap(state.applying(from: 0, to: 1))
        XCTAssertEqual(next.vessels[0].beads.map(\.color.index), [0])
        XCTAssertEqual(next.vessels[1].count, 2)
    }

    func testDonmusTaneUstteDegilseAltindakilerKilitli() {
        // Donmuş tane 1. sırada; run onun üstünden başlıyor, 2 tane taşınabilir.
        let state = GameState(vessels: [
            Vessel(capacity: 5,
                   beads: [Bead(color: 0), Bead(color: 2), Bead(color: 1), Bead(color: 1)],
                   dewIndex: 1, dewCountdown: 1),
            Vessel(capacity: 5),
        ])
        XCTAssertEqual(state.vessels[0].topRunLength, 2)
        XCTAssertEqual(state.vessels[0].movableRunLength, 2)
    }

    func testCiySayaciYalnizcaOKabaYapilanHamlelerdeDuser() throws {
        var state = GameState(vessels: [
            Vessel(capacity: 4, beads: [Bead(color: 0), Bead(color: 1)],
                   dewIndex: 0, dewCountdown: 2),
            Vessel(capacity: 4, beads: [Bead(color: 1)]),
            Vessel(capacity: 4),
        ])
        // 1 → 2: çiyli kaba dokunmuyor, sayaç aynı kalmalı.
        state = try XCTUnwrap(state.applying(from: 1, to: 2))
        XCTAssertEqual(state.vessels[0].dewCountdown, 2)
        // 2 → 0: çiyli kaba hamle, sayaç düşer.
        state = try XCTUnwrap(state.applying(from: 2, to: 0))
        XCTAssertEqual(state.vessels[0].dewCountdown, 1)
        XCTAssertTrue(state.vessels[0].hasDew)
    }

    func testIkiHamleSonundaCiyCozulur() throws {
        var state = GameState(vessels: [
            Vessel(capacity: 5, beads: [Bead(color: 0), Bead(color: 1)],
                   dewIndex: 0, dewCountdown: 2),
            Vessel(capacity: 5, beads: [Bead(color: 1)]),
            Vessel(capacity: 5, beads: [Bead(color: 1)]),
        ])
        state = try XCTUnwrap(state.applying(from: 1, to: 0))
        XCTAssertTrue(state.vessels[0].hasDew)
        XCTAssertEqual(state.vessels[0].dewCountdown, 1)
        state = try XCTUnwrap(state.applying(from: 2, to: 0))
        XCTAssertFalse(state.vessels[0].hasDew, "iki hamle sonunda çözülmeli")
        XCTAssertEqual(state.vessels[0].dewCountdown, 0)
    }

    // MARK: - Rüzgâr

    /// Rüzgâr çifti (0, 1); 2 ve 3 numaralı kaplar hamle saymak için mekik.
    private func windBoard(pairs: [WindSchedule.Pair],
                           first: Vessel = Vessel(capacity: 6, beads: [Bead(color: 0)]),
                           second: Vessel = Vessel(capacity: 6, beads: [Bead(color: 1)])) -> GameState {
        GameState(vessels: [
            first,
            second,
            Vessel(capacity: 6, beads: [Bead(color: 2)]),
            Vessel(capacity: 6),
        ], wind: WindSchedule(pairs: pairs))
    }

    /// Mekik: 2 ↔ 3 arasında tek taneyi gezdirerek hamle sayacını ilerletir.
    private func shuttle(_ state: GameState, moves: Int) throws -> GameState {
        var current = state
        for step in 0..<moves {
            // Taneyi hangi kapta olduğuna göre gönder: hamle sayacının paritesi.
            let from = current.vessels[2].isEmpty ? 3 : 2
            let to = from == 2 ? 3 : 2
            current = try XCTUnwrap(current.applying(from: from, to: to),
                                    "adım \(step): mekik hamlesi yasal olmalı")
        }
        return current
    }

    func testRuzgarBesinciHamledenSonraEser() throws {
        var state = windBoard(pairs: [WindSchedule.Pair(0, 1)])
        state = try shuttle(state, moves: 4)
        XCTAssertEqual(state.moveCount, 4)
        XCTAssertEqual(state.vessels[0].top?.color.index, 0)
        XCTAssertEqual(state.vessels[1].top?.color.index, 1)

        state = try shuttle(state, moves: 1)
        XCTAssertEqual(state.moveCount, 5)
        XCTAssertEqual(state.vessels[0].top?.color.index, 1, "üstler takas edilmeli")
        XCTAssertEqual(state.vessels[1].top?.color.index, 0)
    }

    func testRuzgarUcHamleOncedenBildirilir() throws {
        var state = windBoard(pairs: [WindSchedule.Pair(0, 1)])
        XCTAssertNil(state.announcedWind, "5 hamle uzaktayken gösterge yok")
        state = try shuttle(state, moves: 1)
        XCTAssertNil(state.announcedWind, "4 hamle kaldı, hâlâ yok")
        state = try shuttle(state, moves: 1)
        let announced = try XCTUnwrap(state.announcedWind)
        XCTAssertEqual(announced.movesAway, 3)
        XCTAssertEqual(announced.pair, WindSchedule.Pair(0, 1))
    }

    func testRuzgarBosKabaTekTaneTasir() throws {
        var state = windBoard(pairs: [WindSchedule.Pair(0, 1)],
                              second: Vessel(capacity: 6))
        state = try shuttle(state, moves: 5)
        XCTAssertTrue(state.vessels[0].isEmpty)
        XCTAssertEqual(state.vessels[1].beads.map(\.color.index), [0])
    }

    func testRuzgarKilitliKabiAtlar() throws {
        var state = windBoard(pairs: [WindSchedule.Pair(0, 1)],
                              second: Vessel(capacity: 6, beads: [Bead(color: 1)], lockCountdown: 99))
        state = try shuttle(state, moves: 5)
        XCTAssertEqual(state.vessels[0].beads.map(\.color.index), [0], "kilitli kap dokunulmaz")
        XCTAssertEqual(state.vessels[1].beads.map(\.color.index), [1])
    }

    func testRuzgarDonmusUstTaneyiAtlar() throws {
        var state = windBoard(pairs: [WindSchedule.Pair(0, 1)],
                              second: Vessel(capacity: 6, beads: [Bead(color: 1)],
                                             dewIndex: 0, dewCountdown: 9))
        state = try shuttle(state, moves: 5)
        XCTAssertEqual(state.vessels[1].beads.map(\.color.index), [1], "donmuş tane yerinde kalır")
        XCTAssertEqual(state.vessels[0].beads.map(\.color.index), [0])
    }

    func testRuzgarCozulmusTahtayiBozmaz() throws {
        // Sayaç 4'te; bir sonraki hamle hem tahtayı bitiriyor hem rüzgâr vakti.
        let state = GameState(vessels: [
            Vessel(capacity: 2, beads: [Bead(color: 0), Bead(color: 0)]),
            Vessel(capacity: 2, beads: [Bead(color: 1)]),
            Vessel(capacity: 2, beads: [Bead(color: 1)]),
        ], moveCount: 4, wind: WindSchedule(pairs: [WindSchedule.Pair(0, 1)]))
        let next = try XCTUnwrap(state.applying(from: 1, to: 2))
        XCTAssertEqual(next.moveCount, 5)
        XCTAssertTrue(next.isSolved, "bitmiş tahtada rüzgâr esmemeli")
    }

    func testRuzgarCizelgesiBitinceEsmez() throws {
        var state = windBoard(pairs: [WindSchedule.Pair(0, 1)])
        state = try shuttle(state, moves: 5)   // tek rüzgâr esti
        let afterFirst = state.vessels.map { $0.beads.map(\.color.index) }
        state = try shuttle(state, moves: 5)   // çizelge bitti
        XCTAssertEqual(state.vessels[0].beads.map(\.color.index), afterFirst[0])
        XCTAssertEqual(state.vessels[1].beads.map(\.color.index), afterFirst[1])
    }

    // MARK: - Arı bütçesi

    func testAriButcesiIkiYildizEsigi() {
        let level = Level(id: 120, seed: 1, colors: 9, emptyVessels: 3,
                          capacities: Array(repeating: 4, count: 12),
                          reverseMoves: 40, optimalMoves: 20, branchingFactor: 3)
        XCTAssertEqual(level.moveBudget, 25, "M* × 1,25")
        XCTAssertEqual(level.stars(forMoves: level.moveBudget), 2)
        XCTAssertEqual(level.stars(forMoves: level.moveBudget + 1), 1)
    }
}
