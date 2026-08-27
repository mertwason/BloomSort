import XCTest
@testable import BloomsortDesign

final class BeeFlightTests: XCTestCase {

    func testKontrolNoktasiOrtaNoktanin40PtUstunde() {
        let start = Point(x: 0, y: 100)
        let end = Point(x: 200, y: 140)
        let control = BeeFlight.controlPoint(from: start, to: end)
        XCTAssertEqual(control.x, 100, accuracy: 0.001)
        XCTAssertEqual(control.y, 180, accuracy: 0.001, "yüksek ucun 40 pt üstü")
    }

    func testUcusSuresiMesafeyleArtiyorAmaSinirliyor() {
        XCTAssertEqual(BeeFlight.duration(distance: 0), 0.34, accuracy: 0.0001)
        XCTAssertEqual(BeeFlight.duration(distance: 100), 0.38, accuracy: 0.0001)
        XCTAssertEqual(BeeFlight.duration(distance: 10_000), Motion.beeMax, accuracy: 0.0001,
                       "üst sınır motion-bee tokenı")
    }

    func testAzaltilmisHareketUcusuKisaltiyor() {
        let normal = BeeFlight.duration(distance: 200)
        let reduced = BeeFlight.duration(distance: 200, reduceMotion: true)
        XCTAssertLessThan(reduced, normal)
        XCTAssertEqual(reduced, normal * Motion.reducedMotionScale, accuracy: 0.0001)
    }

    func testEgriIkiUcArasindaYukseliyor() {
        let start = Point(x: 0, y: 0)
        let end = Point(x: 100, y: 0)
        let middle = BeeFlight.point(onCurveFrom: start, to: end, t: 0.5)
        XCTAssertGreaterThan(middle.y, 0, "arı düz gitmiyor, kavis çiziyor")
        XCTAssertEqual(middle.x, 50, accuracy: 0.001)
        XCTAssertEqual(BeeFlight.point(onCurveFrom: start, to: end, t: 0).x, start.x, accuracy: 0.001)
        XCTAssertEqual(BeeFlight.point(onCurveFrom: start, to: end, t: 1).x, end.x, accuracy: 0.001)
    }
}

final class AnimationQueueTests: XCTestCase {

    func testUcAriyaKadarAyniAndaUcuyor() {
        var queue = AnimationQueue<Int>(concurrencyLimit: 3)
        XCTAssertNotNil(queue.submit(1))
        XCTAssertNotNil(queue.submit(2))
        XCTAssertNotNil(queue.submit(3))
        XCTAssertEqual(queue.running, 3)
        XCTAssertNil(queue.submit(4), "dördüncü kuyruğa girmeli")
        XCTAssertEqual(queue.queued, 1)
    }

    func testKuyruktakiIsBittikceSirayla() {
        var queue = AnimationQueue<Int>(concurrencyLimit: 2)
        _ = queue.submit(1)
        _ = queue.submit(2)
        _ = queue.submit(3)
        _ = queue.submit(4)
        XCTAssertEqual(queue.queued, 2)
        XCTAssertEqual(queue.finish(), 3, "FIFO")
        XCTAssertEqual(queue.finish(), 4)
        XCTAssertNil(queue.finish())
        XCTAssertNil(queue.finish())
        XCTAssertTrue(queue.isIdle)
    }

    func testIptalKuyruguBosaltiyor() {
        var queue = AnimationQueue<Int>(concurrencyLimit: 1)
        _ = queue.submit(1)
        _ = queue.submit(2)
        queue.cancelAll()
        XCTAssertEqual(queue.queued, 0)
        XCTAssertNil(queue.finish())
    }
}

final class BoardAccessibilityTests: XCTestCase {

    func testKapEtiketiCLAUDEmdOrnegiyleAyni() {
        let label = BoardAccessibility.vesselLabel(index: 2, capacity: 4, filled: 2, topColorIndex: 0)
        XCTAssertEqual(label, "Kap 3. 4 kapasiteli. Üstte sarı polen. 2 dolu.")
    }

    func testBosKapEtiketi() {
        let label = BoardAccessibility.vesselLabel(index: 0, capacity: 6, filled: 0, topColorIndex: nil)
        XCTAssertEqual(label, "Kap 1. 6 kapasiteli. Boş.")
    }

    func testEngellerEtiketeGiriyor() {
        let label = BoardAccessibility.vesselLabel(index: 4, capacity: 5, filled: 3,
                                                   topColorIndex: 3, lockCountdown: 7, hasDew: true)
        XCTAssertTrue(label.contains("Kilitli, 7 polen kaldı."))
        XCTAssertTrue(label.contains("Donmuş polen var."))
    }

    func testHamleVeCicekDuyurulari() {
        XCTAssertEqual(BoardAccessibility.moveAnnouncement(colorIndex: 0, from: 2, to: 6),
                       "Sarı polen kap 3'ten kap 7'ye taşındı.")
        XCTAssertEqual(BoardAccessibility.bloomAnnouncement(vessel: 4, remainingColors: 4),
                       "Kap 5 çiçek açtı. 4 renk kaldı.")
        XCTAssertEqual(BoardAccessibility.windAnnouncement(movesAway: 3, first: 1, second: 4),
                       "3 hamle sonra kap 2 ile kap 5 yer değiştirecek.")
    }

    func testHicbirEtiketBosDegil() {
        for index in 0..<12 {
            let label = BoardAccessibility.vesselLabel(index: index, capacity: 4, filled: 1,
                                                       topColorIndex: index)
            XCTAssertFalse(label.isEmpty)
            XCTAssertTrue(label.contains(Palette.pollen(index).name.lowercased()))
        }
    }
}
