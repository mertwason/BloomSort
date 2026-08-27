import XCTest
@testable import BloomsortDesign

/// `docs/ui-spec.md` §1.3–§1.8 ve §2.2 tokenlarının bağlanması.
final class TokenTests: XCTestCase {

    func testKapOlculeriSpecdekiTablo() {
        XCTAssertEqual(VesselMetrics.size(forCapacity: 3).width, 62)
        XCTAssertEqual(VesselMetrics.size(forCapacity: 3).height, 108)
        XCTAssertEqual(VesselMetrics.size(forCapacity: 4).height, 134)
        XCTAssertEqual(VesselMetrics.size(forCapacity: 5).height, 162)
        XCTAssertEqual(VesselMetrics.size(forCapacity: 6).height, 188)
        XCTAssertEqual(VesselMetrics.size(forCapacity: 5).slotDiameter, 42)
    }

    func testKapYuksekligiKapasiteyleArtiyor() {
        let heights = (3...6).map { VesselMetrics.size(forCapacity: $0).height }
        XCTAssertEqual(heights, heights.sorted())
        XCTAssertEqual(Set(heights).count, 4)
    }

    /// §3.5'in ham ölçüleri en yoğun tahtada **sığmıyor**: 3 satır × 188 pt
    /// (6 kapasiteli kap) = 564 pt, tahta alanı ise 449 pt. Spec genişliği
    /// ölçekliyor ama yüksekliği ölçeklemiyor. `BoardLayout` bu yüzden düzgün
    /// bir ölçek katsayısı uyguluyor; buradaki test bulgunun kendisini
    /// sabitliyor ki ölçekleme sessizce kaldırılmasın.
    func testHamSpecOlculeriEnYogunTahtadaSigmiyor() {
        let tallest = VesselMetrics.size(forCapacity: 6).height
        XCTAssertGreaterThan(tallest * 3, Layout.boardHeight)
        // BoardLayout ölçekleyerek sığdırıyor.
        let scaled = BoardLayout.compute(capacities: Array(repeating: 6, count: 12))
        XCTAssertLessThan(scaled.scale, 1.0)
        XCTAssertLessThanOrEqual(scaled.frames.map(\.baseY).max()!,
                                 Layout.boardTop + Layout.boardHeight + 0.001)
    }

    func testTaneCapiYuvadanKucuk() {
        for capacity in 3...6 {
            let slot = VesselMetrics.size(forCapacity: capacity).slotDiameter
            XCTAssertEqual(VesselMetrics.beadDiameter(forCapacity: capacity), slot - 6)
        }
    }

    func testAzaltilmisHareketButunSureleriKisaltiyor() {
        XCTAssertEqual(Motion.duration(Motion.bloom, reduceMotion: false), 0.42, accuracy: 0.0001)
        XCTAssertEqual(Motion.duration(Motion.bloom, reduceMotion: true), 0.168, accuracy: 0.0001)
        for base in [Motion.tap, Motion.micro, Motion.beeMax, Motion.plate, Motion.sheet] {
            XCTAssertLessThan(Motion.duration(base, reduceMotion: true), base)
        }
    }

    func testAralikOlcegiDortPtTabanli() {
        for value in [Spacing.s1, Spacing.s2, Spacing.s3, Spacing.s4,
                      Spacing.s5, Spacing.s6, Spacing.s7, Spacing.s8] {
            XCTAssertEqual(value.truncatingRemainder(dividingBy: 4), 0, "\(value) 4'ün katı olmalı")
        }
    }

    func testTipografiOlcegiTutarli() {
        XCTAssertEqual(Typography.all.count, 9)
        XCTAssertEqual(Set(Typography.all.map(\.name)).count, 9)
        for style in Typography.all {
            XCTAssertGreaterThanOrEqual(style.lineHeight, style.size, "\(style.name)")
        }
        // Display stilleri en fazla %130 ölçeklenir, gövde metni tam ölçeklenir.
        XCTAssertEqual(Typography.displayL.maximumScale, 1.3)
        XCTAssertTrue(Typography.body.scales)
        XCTAssertFalse(Typography.displayL.scales)
    }

    func testDokunmaHedefiKirkDortPt() {
        XCTAssertEqual(Layout.minimumTapTarget, 44)
    }

    func testHaptikHaritasiTamamlanmis() {
        XCTAssertEqual(Haptic.allCases.count, 7)
    }
}
