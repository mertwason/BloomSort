import XCTest
@testable import BloomsortDesign

final class BoardLayoutTests: XCTestCase {

    private func layout(_ capacities: [Int]) -> BoardLayout.Result {
        BoardLayout.compute(capacities: capacities)
    }

    func testSatirSutunTablosuSpecleUyusuyor() {
        XCTAssertEqual(BoardLayout.grid(forVesselCount: 8).rows, 2)
        XCTAssertEqual(BoardLayout.grid(forVesselCount: 8).columns, 4)
        XCTAssertEqual(BoardLayout.grid(forVesselCount: 12).rows, 3)
        XCTAssertEqual(BoardLayout.grid(forVesselCount: 15).widthScale, 0.88)
        XCTAssertEqual(BoardLayout.grid(forVesselCount: 18).widthScale, 0.74)
    }

    func testHerKapTahtaAlaninaSigiyor() {
        // En zorlu hâl: 18 kabın hepsi 6 kapasiteli.
        for count in [4, 8, 12, 15, 18] {
            for capacity in [3, 4, 5, 6] {
                let result = layout(Array(repeating: capacity, count: count))
                for frame in result.frames {
                    XCTAssertGreaterThanOrEqual(frame.top, Layout.boardTop - 0.001,
                                                "\(count)×\(capacity): kap üstten taşıyor")
                    XCTAssertLessThanOrEqual(frame.baseY,
                                             Layout.boardTop + Layout.boardHeight + 0.001,
                                             "\(count)×\(capacity): kap alttan taşıyor")
                    XCTAssertGreaterThanOrEqual(frame.baseCenterX - frame.width / 2,
                                                Spacing.screenMargin - 0.001,
                                                "\(count)×\(capacity): kap soldan taşıyor")
                    XCTAssertLessThanOrEqual(frame.baseCenterX + frame.width / 2,
                                             Layout.referenceWidth - Spacing.screenMargin + 0.001,
                                             "\(count)×\(capacity): kap sağdan taşıyor")
                }
            }
        }
    }

    func testKarisikKapasitelerdeTabanlarHizali() {
        let result = layout([3, 6, 4, 5, 3, 6, 4, 5])
        let byRow = Dictionary(grouping: result.frames, by: \.row)
        for (row, frames) in byRow {
            let bases = Set(frames.map { ($0.baseY * 1000).rounded() })
            XCTAssertEqual(bases.count, 1, "satır \(row): tabanlar hizalı olmalı")
        }
    }

    func testKaplarCakismiyor() {
        let result = layout(Array(repeating: 6, count: 18))
        let byRow = Dictionary(grouping: result.frames, by: \.row)
        for (_, frames) in byRow {
            let sorted = frames.sorted { $0.baseCenterX < $1.baseCenterX }
            for (left, right) in zip(sorted, sorted.dropFirst()) {
                let leftEdge = left.baseCenterX + left.width / 2
                let rightEdge = right.baseCenterX - right.width / 2
                XCTAssertGreaterThanOrEqual(rightEdge - leftEdge,
                                            BoardLayout.minimumHorizontalGap - 0.001)
            }
        }
    }

    func testSiganTahtalarSpecOlculeriyleCiziliyor() {
        // 8 kap × 4 kapasite: 2 satır × 134 = 268 pt, alana rahat sığar.
        let result = layout(Array(repeating: 4, count: 8))
        XCTAssertEqual(result.scale, 1.0, accuracy: 0.0001, "sığan tahta ölçeklenmemeli")
        XCTAssertEqual(result.frames[0].height, 134, accuracy: 0.0001)
        XCTAssertEqual(result.frames[0].width, 62, accuracy: 0.0001)
    }

    func testSigmayanTahtaOlcekleniyor() {
        // 3 satır × 6 kapasite = 564 pt > 449 pt: ölçek devreye girmeli.
        let result = layout(Array(repeating: 6, count: 12))
        XCTAssertLessThan(result.scale, 1.0)
        XCTAssertGreaterThan(result.scale, 0.5, "okunamayacak kadar küçülmemeli")
    }

    func testTahtaDikeydeOrtalanmis() {
        let result = layout(Array(repeating: 4, count: 8))
        let top = result.frames.map(\.top).min()!
        let bottom = result.frames.map(\.baseY).max()!
        let topInset = top - Layout.boardTop
        let bottomInset = (Layout.boardTop + Layout.boardHeight) - bottom
        XCTAssertEqual(topInset, bottomInset, accuracy: 1.0, "tahta dikeyde ortalanmalı")
    }

    func testTekKapliTahta() {
        let result = layout([4])
        XCTAssertEqual(result.frames.count, 1)
        XCTAssertEqual(result.frames[0].baseCenterX, Layout.referenceWidth / 2, accuracy: 0.001)
    }

    func testYerlesimKapSirasiniKoruyor() {
        let result = layout([3, 4, 5, 6, 3, 4])
        XCTAssertEqual(result.frames.map(\.vesselIndex), Array(0..<6))
    }
}
