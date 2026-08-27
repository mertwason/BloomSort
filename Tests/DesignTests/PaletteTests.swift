import XCTest
@testable import BloomsortDesign

/// Paletin erişilebilirlik iddiaları burada kanıtlanıyor.
/// `docs/ui-spec.md` §1.1 kontrast tablosunu ve §1.2 polen renklerini bağlar.
final class PaletteTests: XCTestCase {

    // MARK: - §1.1 kontrast tablosu

    /// §1.1'deki oranlar taslakta yanlıştı (13,9 / 6,4 / 11,2 / 9,7); hex'lerden
    /// hesaplanan doğru değerlerle güncellendi. Test bir daha kaymalarını önlüyor.
    func testCekirdekKontrastlariSpecdekiDegerlerleUyusuyor() {
        let cases: [(String, RGB, RGB, Double)] = [
            ("mist / dusk",    Palette.mist,    Palette.dusk,   14.3),
            ("mistDim / dusk", Palette.mistDim, Palette.dusk,    7.0),
            ("dusk / pollen",  Palette.dusk,    Palette.pollen, 10.3),
            ("mist / moss",    Palette.mist,    Palette.moss,   10.3),
        ]
        for (name, a, b, expected) in cases {
            let measured = ColorMath.contrastRatio(a, b)
            XCTAssertEqual(measured, expected, accuracy: 0.15,
                           "\(name): ölçülen \(String(format: "%.2f", measured)), spec \(expected)")
        }
    }

    func testMetinRenkleriWCAGAAGeciyor() {
        XCTAssertGreaterThanOrEqual(ColorMath.contrastRatio(Palette.mist, Palette.dusk), 4.5)
        XCTAssertGreaterThanOrEqual(ColorMath.contrastRatio(Palette.mistDim, Palette.dusk), 4.5)
        XCTAssertGreaterThanOrEqual(ColorMath.contrastRatio(Palette.mist, Palette.moss), 4.5)
        XCTAssertGreaterThanOrEqual(ColorMath.contrastRatio(Palette.dusk, Palette.pollen), 4.5,
                                    "birincil CTA metni")
    }

    func testLevhaKagidiUzerindekiMetinOkunuyor() {
        XCTAssertGreaterThanOrEqual(ColorMath.contrastRatio(Palette.plateInk, Palette.platePaper), 4.5)
    }

    // MARK: - §1.2 polen renkleri

    func testOnIkiPolenRengiVeSiralamaDogru() {
        XCTAssertEqual(Palette.pollens.count, 12)
        XCTAssertEqual(Palette.pollens.map(\.index), Array(0..<12))
    }

    func testIlkSekizRenkSpecdekiDegerler() {
        let expected = ["#F5C24B", "#E86A5C", "#A971E8", "#6FD8C4",
                        "#7BB5F0", "#F2A0C8", "#9BD466", "#E8925C"]
        XCTAssertEqual(Palette.pollens.prefix(8).map(\.color.hex), expected)
    }

    func testPolenTaneleriTahtaZemininGorunurOlacakKadarParlak() {
        for pollen in Palette.pollens {
            let ratio = ColorMath.contrastRatio(pollen.color, Palette.duskDeep)
            XCTAssertGreaterThanOrEqual(ratio, 3.0,
                                        "\(pollen.name): kontrast \(String(format: "%.2f", ratio))")
        }
    }

    func testRenklerBirbirindenAyirtEdilebiliyor() {
        // Paletin mevcut en yakın çifti Mercan ↔ Kayısı, ΔE2000 15,7.
        // Sonradan eklenen renkler bu tabanı düşürmemeli.
        var closest = (distance: Double.greatestFiniteMagnitude, first: "", second: "")
        for (index, first) in Palette.pollens.enumerated() {
            for second in Palette.pollens[(index + 1)...] {
                let distance = ColorMath.deltaE2000(first.color, second.color)
                if distance < closest.distance {
                    closest = (distance, first.name, second.name)
                }
            }
        }
        XCTAssertGreaterThanOrEqual(closest.distance, 15.0,
                                    "en yakın çift \(closest.first) ↔ \(closest.second): ΔE \(closest.distance)")
    }

    func testSonradanEklenenRenklerMevcutlardanYeterinceUzak() {
        let added = Palette.pollens.suffix(4)
        for pollen in added {
            let closest = Palette.pollens
                .filter { $0.index != pollen.index }
                .map { (ColorMath.deltaE2000(pollen.color, $0.color), $0.name) }
                .min { $0.0 < $1.0 }!
            XCTAssertGreaterThanOrEqual(closest.0, 15.7,
                                        "\(pollen.name) ↔ \(closest.1): ΔE \(closest.0)")
            XCTAssertGreaterThanOrEqual(ColorMath.contrastRatio(pollen.color, Palette.duskDeep), 7.0,
                                        "\(pollen.name) tahtada ışımalı")
        }
    }

    func testHerRenginBenzersizSembolu() {
        let symbols = Palette.pollens.map(\.symbol)
        XCTAssertEqual(Set(symbols).count, 12, "renk körlüğü modunda semboller çakışamaz")
        XCTAssertTrue(symbols.allSatisfy { !$0.isEmpty })
    }

    // MARK: - Renk matematiği

    func testHexGidisDonus() {
        XCTAssertEqual(RGB(hex: "#F5C24B").hex, "#F5C24B")
        XCTAssertEqual(RGB(hex: "0A1418").hex, "#0A1418")
    }

    func testAyniRenginFarkiSifir() {
        XCTAssertEqual(ColorMath.deltaE2000(Palette.pollen, Palette.pollen), 0, accuracy: 0.0001)
        XCTAssertEqual(ColorMath.contrastRatio(Palette.mist, Palette.mist), 1, accuracy: 0.0001)
    }

    func testSiyahBeyazKontrastiYirmiBir() {
        let ratio = ColorMath.contrastRatio(RGB(hex: "#000000"), RGB(hex: "#FFFFFF"))
        XCTAssertEqual(ratio, 21, accuracy: 0.01)
    }
}
