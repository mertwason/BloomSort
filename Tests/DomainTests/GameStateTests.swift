import XCTest
@testable import BloomsortDomain

/// Motor testleri — `CLAUDE.md`: "Domain'de test edilmemiş fonksiyon merge edilmez."
final class GameStateTests: XCTestCase {

    // MARK: - Kap

    func testKapUstRunUzunlugu() {
        let vessel = Vessel(capacity: 4, beads: [Bead(color: 0), Bead(color: 1), Bead(color: 1)])
        XCTAssertEqual(vessel.topRunLength, 2)
        XCTAssertEqual(vessel.runCount, 2)
        XCTAssertEqual(vessel.freeSpace, 1)
        XCTAssertFalse(vessel.isMono)
    }

    func testBosKabinOzellikleri() {
        let vessel = Vessel(capacity: 5)
        XCTAssertTrue(vessel.isEmpty)
        XCTAssertEqual(vessel.topRunLength, 0)
        XCTAssertEqual(vessel.runCount, 0)
        XCTAssertNil(vessel.top)
        XCTAssertTrue(vessel.isEmptyOrMono)
        XCTAssertFalse(vessel.isMono)
        XCTAssertFalse(vessel.isBloomed)
    }

    func testTekRenkleDolanKapCicekAcar() {
        let vessel = Vessel(capacity: 3, beads: (0..<3).map { _ in Bead(color: 2) })
        XCTAssertTrue(vessel.isMono)
        XCTAssertTrue(vessel.isFull)
        XCTAssertTrue(vessel.isBloomed)
    }

    func testTekRenkAmaDoluDegilCicekAcmaz() {
        let vessel = Vessel(capacity: 4, beads: (0..<2).map { _ in Bead(color: 2) })
        XCTAssertTrue(vessel.isMono)
        XCTAssertFalse(vessel.isBloomed)
    }

    // MARK: - Hamle yasallığı

    func testBosKaynaktanHamleYasadisi() {
        let state = GameState(capacities: [4, 4], contents: [[], [0]])
        XCTAssertFalse(state.isLegal(from: 0, to: 1))
        XCTAssertNil(state.move(from: 0, to: 1))
    }

    func testDoluHedefeHamleYasadisi() {
        let state = GameState(capacities: [4, 2], contents: [[1], [1, 1]])
        XCTAssertFalse(state.isLegal(from: 0, to: 1))
    }

    func testBosHedefeHamleYasal() {
        let state = GameState(capacities: [4, 4], contents: [[0, 1], []])
        XCTAssertTrue(state.isLegal(from: 0, to: 1))
    }

    func testAyniRenkUstuneHamleYasal() {
        let state = GameState(capacities: [4, 4], contents: [[0, 1], [1]])
        XCTAssertTrue(state.isLegal(from: 0, to: 1))
    }

    func testFarkliRenkUstuneHamleYasadisi() {
        let state = GameState(capacities: [4, 4], contents: [[0, 1], [2]])
        XCTAssertFalse(state.isLegal(from: 0, to: 1))
    }

    func testAyniKabaHamleYasadisi() {
        let state = GameState(capacities: [4], contents: [[0]])
        XCTAssertFalse(state.isLegal(from: 0, to: 0))
    }

    func testKapsamDisiIndeksYasadisi() {
        let state = GameState(capacities: [4, 4], contents: [[0], []])
        XCTAssertFalse(state.isLegal(from: 0, to: 5))
        XCTAssertFalse(state.isLegal(from: -1, to: 1))
    }

    // MARK: - Toplu taşıma

    func testTopluTasimaTekHamleSayilir() {
        let state = GameState(capacities: [4, 4], contents: [[0, 1, 1, 1], []])
        let move = state.move(from: 0, to: 1)
        XCTAssertEqual(move?.count, 3)
        let next = state.applying(move!)!
        XCTAssertEqual(next.moveCount, 1)
        XCTAssertEqual(next.vessels[0].beads.map(\.color.index), [0])
        XCTAssertEqual(next.vessels[1].beads.map(\.color.index), [1, 1, 1])
    }

    func testTopluTasimaHedeftekiBoslukKadar() {
        let state = GameState(capacities: [4, 4], contents: [[1, 1, 1, 1], [1, 1]])
        let move = state.move(from: 0, to: 1)
        XCTAssertEqual(move?.count, 2, "hedefte 2 boşluk var, 4 tane değil 2 tane gitmeli")
        let next = state.applying(move!)!
        XCTAssertEqual(next.vessels[0].count, 2)
        XCTAssertTrue(next.vessels[1].isBloomed)
    }

    func testKesintiliRenkBloguTasinmaz() {
        let state = GameState(capacities: [4, 4], contents: [[1, 0, 1], []])
        XCTAssertEqual(state.move(from: 0, to: 1)?.count, 1, "yalnızca üstteki tek tane gider")
    }

    // MARK: - Uygulama ve geri al

    func testUygulamaKaynagiDegistirmez() {
        let state = GameState(capacities: [4, 4], contents: [[0, 0], []])
        _ = state.applying(from: 0, to: 1)
        XCTAssertEqual(state.vessels[0].count, 2, "GameState değer tipi, mutasyonsuz")
        XCTAssertEqual(state.moveCount, 0)
    }

    func testGeriAlSonHamleyiAlir() {
        let state = GameState(capacities: [4, 4], contents: [[0, 1, 1], []])
        var stack = UndoStack(state)
        XCTAssertTrue(stack.apply(from: 0, to: 1))
        XCTAssertTrue(stack.undo())
        XCTAssertEqual(stack.current, state)
        XCTAssertEqual(stack.current.moveCount, 0)
        XCTAssertFalse(stack.canUndo)
    }

    func testGeriAlZinciri() {
        let original = GameState(capacities: [4, 4, 4], contents: [[0, 1, 1], [1], []])
        var stack = UndoStack(original)
        XCTAssertTrue(stack.apply(from: 0, to: 1))
        XCTAssertTrue(stack.apply(from: 0, to: 2))
        XCTAssertTrue(stack.apply(from: 2, to: 0))
        XCTAssertEqual(stack.current.moveCount, 3)
        XCTAssertEqual(stack.undoCount, 3)
        for _ in 0..<3 { XCTAssertTrue(stack.undo()) }
        XCTAssertEqual(stack.current, original)
        XCTAssertFalse(stack.undo(), "geçmiş boşken geri al yok")
    }

    func testGecmisiBosTahtadaGeriAlYok() {
        var stack = UndoStack(GameState(capacities: [4], contents: [[0]]))
        XCTAssertFalse(stack.canUndo)
        XCTAssertFalse(stack.undo())
    }

    func testSifirlaBaslangicaDoner() {
        let original = GameState(capacities: [4, 4, 4], contents: [[0, 1, 1], [1], []])
        var stack = UndoStack(original)
        stack.apply(from: 0, to: 1)
        stack.apply(from: 0, to: 2)
        stack.reset()
        XCTAssertEqual(stack.current, original)
        XCTAssertFalse(stack.canUndo)
    }

    func testYasadisiHamleTahtayiDegistirmez() {
        let original = GameState(capacities: [2, 2], contents: [[0, 1], [1, 0]])
        var stack = UndoStack(original)
        XCTAssertFalse(stack.apply(from: 0, to: 1))
        XCTAssertEqual(stack.current, original)
        XCTAssertFalse(stack.canUndo)
    }

    func testAriGeriAlinabilir() {
        var stack = UndoStack(GameState(capacities: [4], contents: [[0, 1]]))
        XCTAssertTrue(stack.addBee(capacity: 4))
        XCTAssertEqual(stack.current.vessels.count, 2)
        XCTAssertTrue(stack.undo())
        XCTAssertEqual(stack.current.vessels.count, 1)
    }

    func testSikismadaGeriAlOnerilir() {
        // Tek boş yuvayı doldurmak tahtayı çıkmaza sokuyor.
        let start = GameState(capacities: [3, 3, 2, 1],
                              contents: [[1, 2, 0], [0, 0, 1], [2, 1], []])
        var stack = UndoStack(start)
        XCTAssertFalse(start.isStuck)
        XCTAssertFalse(stack.shouldSuggestUndo, "geri alınacak hamle yokken öneri de yok")

        XCTAssertTrue(stack.apply(from: 0, to: 3))
        XCTAssertTrue(stack.current.isStuck, "tek boş yuva dolunca hamle kalmıyor")
        XCTAssertTrue(stack.shouldSuggestUndo)

        XCTAssertTrue(stack.undo())
        XCTAssertFalse(stack.current.isStuck)
        XCTAssertFalse(stack.shouldSuggestUndo)
    }

    // MARK: - Kazanma

    func testKazanmaTespiti() {
        let solved = GameState(capacities: [3, 3, 4],
                               contents: [[0, 0, 0], [1, 1, 1], []])
        XCTAssertTrue(solved.isSolved)
    }

    func testTekRenkAmaDoluDegilKazanmaSayilmaz() {
        let state = GameState(capacities: [4, 4], contents: [[0, 0], [0, 0]])
        XCTAssertFalse(state.isSolved, "aynı renk iki kaba bölünmüşse seviye bitmez")
    }

    func testKarisikKapKazanmaSayilmaz() {
        let state = GameState(capacities: [2, 2], contents: [[0, 1], [1, 0]])
        XCTAssertFalse(state.isSolved)
    }

    // MARK: - Hamle listeleri

    func testYasalHamleListesi() {
        let state = GameState(capacities: [4, 4, 4], contents: [[0], [0], []])
        // 0→1, 0→2, 1→0, 1→2
        XCTAssertEqual(state.legalMoves().count, 4)
    }

    func testAnlamliHamlelerAyniKapasitedekiBosKaplariTekler() {
        let state = GameState(capacities: [4, 4, 4], contents: [[0, 1], [], []])
        XCTAssertEqual(state.legalMoves().count, 2)
        XCTAssertEqual(state.meaningfulMoves().count, 1, "iki boş kap birbirinin aynısı")
    }

    func testAnlamliHamlelerAyniKapasitedekiYerDegistirmeyiEler() {
        // Tek renkli kabı aynı kapasitede boş bir kaba taşımak yalnızca yer
        // değiştirmek; hiçbir şeyi değiştirmiyor.
        let sameCapacity = GameState(capacities: [2, 2], contents: [[0, 0], []])
        XCTAssertEqual(sameCapacity.legalMoves().count, 1)
        XCTAssertTrue(sameCapacity.meaningfulMoves().isEmpty)
    }

    func testAnlamliHamlelerFarkliKapasitedekiBosKabaIzinVerir() {
        // Farklı kapasitede boş kap elenemez: bir renk yalnızca kendi adedine
        // eşit kapasitedeki kapta çiçek açar, oraya taşınması gerekebilir.
        let differentCapacity = GameState(capacities: [2, 4], contents: [[0, 0], []])
        XCTAssertEqual(differentCapacity.meaningfulMoves().count, 1)
    }

    func testCikmazTespiti() {
        // İki kap da dolu ve üstleri farklı → hiçbir hamle yok.
        let state = GameState(capacities: [2, 2], contents: [[0, 1], [1, 0]])
        XCTAssertTrue(state.isStuck)
        XCTAssertTrue(state.legalMoves().isEmpty)
    }

    func testCozulmusTahtaCikmazDegildir() {
        let state = GameState(capacities: [2, 2], contents: [[0, 0], [1, 1]])
        XCTAssertFalse(state.isStuck)
    }

    // MARK: - Arı ve tutarlılık

    func testAriTahtayaBosKapEkler() {
        let state = GameState(capacities: [4], contents: [[0, 1]])
        let next = state.addingBee(capacity: 4)
        XCTAssertEqual(next.vessels.count, 2)
        XCTAssertTrue(next.vessels[1].isEmpty)
        XCTAssertEqual(next.beesUsed, 1)
    }

    func testTutarlilikRenkAdediKapasiteyeEsit() {
        let good = GameState(capacities: [3, 4, 4], contents: [[0, 0, 0], [1, 1, 1, 1], []])
        XCTAssertTrue(good.isConsistent)
        let bad = GameState(capacities: [3, 4, 4], contents: [[0, 0], [1, 1, 1, 1], []])
        XCTAssertFalse(bad.isConsistent)
    }

    // MARK: - Sıkıştırılmış temsil

    func testPositionGidisDonus() {
        let state = GameState(capacities: [3, 4, 6],
                              contents: [[0, 1, 2], [3, 3], [4, 5, 6, 7, 0, 1]])
        XCTAssertEqual(Position(state).gameState.vessels, state.vessels)
    }

    func testEsitlikYalnizcaTahtayaBakar() {
        let a = GameState(capacities: [4, 4], contents: [[0, 0], []])
        var stack = UndoStack(a)
        stack.apply(from: 0, to: 1)
        stack.undo()
        let b = stack.current
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }
}
