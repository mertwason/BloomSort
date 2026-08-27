import XCTest
import Foundation

/// Yerelleştirme dosyalarının tutarlılığı.
///
/// Dizeler SwiftUI'ın `LocalizedStringKey`'i üzerinden çözüldüğü için eksik
/// bir çeviri derleme hatası vermez — kullanıcıya Türkçe metin gösterir.
/// Bu test onu yakalıyor.
final class LocalizationTests: XCTestCase {

    private var appResources: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // DesignTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // kök
            .appendingPathComponent("App/Resources")
    }

    private func keys(_ language: String, table: String = "Localizable") throws -> [String: String] {
        let url = appResources
            .appendingPathComponent("\(language).lproj")
            .appendingPathComponent("\(table).strings")
        let contents = try String(contentsOf: url, encoding: .utf8)
        var result: [String: String] = [:]
        let pattern = try NSRegularExpression(pattern: "^\"((?:[^\"\\\\]|\\\\.)*)\"\\s*=\\s*\"((?:[^\"\\\\]|\\\\.)*)\";",
                                              options: [.anchorsMatchLines])
        let range = NSRange(contents.startIndex..., in: contents)
        for match in pattern.matches(in: contents, range: range) {
            guard let keyRange = Range(match.range(at: 1), in: contents),
                  let valueRange = Range(match.range(at: 2), in: contents) else { continue }
            result[String(contents[keyRange])] = String(contents[valueRange])
        }
        return result
    }

    func testTurkceVeIngilizceAyniAnahtarlaraSahip() throws {
        let turkish = try keys("tr")
        let english = try keys("en")
        XCTAssertFalse(turkish.isEmpty, "Türkçe dosya okunamadı")
        XCTAssertEqual(Set(turkish.keys), Set(english.keys),
                       "eksik çeviri: \(Set(turkish.keys).symmetricDifference(Set(english.keys)))")
    }

    func testHicbirCeviriBosDegil() throws {
        for language in ["tr", "en"] {
            for (key, value) in try keys(language) {
                XCTAssertFalse(value.trimmingCharacters(in: .whitespaces).isEmpty,
                               "\(language): \(key) boş")
            }
        }
    }

    func testIngilizceCevirilerTurkceDenFarkli() throws {
        let turkish = try keys("tr")
        let english = try keys("en")
        // Özel adlar aynı kalabilir; gerisi çevrilmiş olmalı.
        let allowedIdentical: Set<String> = ["Bloomsort", "Herbaryum", "Patika", "Kovan", "Bahçem"]
        var untranslated: [String] = []
        for (key, turkishValue) in turkish {
            guard let englishValue = english[key] else { continue }
            if turkishValue == englishValue, !allowedIdentical.contains(key) {
                untranslated.append(key)
            }
        }
        XCTAssertTrue(untranslated.isEmpty, "çevrilmemiş: \(untranslated)")
    }

    func testATTMetniIkiDildeDeVar() throws {
        for language in ["tr", "en"] {
            let strings = try keys(language, table: "InfoPlist")
            XCTAssertNotNil(strings["NSUserTrackingUsageDescription"],
                            "\(language): ATT metni eksik")
            XCTAssertGreaterThan(strings["NSUserTrackingUsageDescription"]?.count ?? 0, 20,
                                 "\(language): ATT metni dürüst ve açıklayıcı olmalı")
        }
    }

    func testGizlilikManifestiVeInfoPlistVar() {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        for file in ["App/Info.plist", "App/PrivacyInfo.xcprivacy", "App/project.yml"] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(file).path),
                          "\(file) yok")
        }
    }

    func testGercekAdMobIDsiHenuzGirilmemisOlarakIsaretli() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let plist = try String(contentsOf: root.appendingPathComponent("App/Info.plist"),
                               encoding: .utf8)
        // Gönderimden önce gerçek ID girilmeli; testin amacı sahte bir ID'nin
        // sessizce gerçek gibi durmasını engellemek (checklist Faz 4.2).
        XCTAssertTrue(plist.contains("REPLACE_WITH_REAL_ADMOB_APP_ID"),
                      "AdMob App ID girildiyse bu testi güncelle")
        XCTAssertFalse(plist.contains("ca-app-pub-3940256099942544"),
                       "Google'ın test App ID'siyle gönderim = red")
    }
}

/// Uygulama ikonu — App Store 1024 × 1024, **alfa kanalı yok, köşe
/// yuvarlatması yok** (lansman checklist'i Faz 8). İkon `Tools/icon/make_icon.py`
/// ile üretiliyor; elle çizilmiş asset yok.
final class AppIconTests: XCTestCase {
    private var iconURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
    }

    func testIkonVarVeGecerliPNG() throws {
        let data = try Data(contentsOf: iconURL)
        XCTAssertEqual(Array(data.prefix(8)), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    }

    func testIkonBinYirmiDortKareVeAlfasiz() throws {
        let data = try Data(contentsOf: iconURL)
        // IHDR: 16..24 genişlik/yükseklik, 24 bit derinliği, 25 renk tipi.
        func uint32(_ offset: Int) -> UInt32 {
            data[offset..<(offset + 4)].reduce(0) { ($0 << 8) | UInt32($1) }
        }
        XCTAssertEqual(uint32(16), 1024)
        XCTAssertEqual(uint32(20), 1024)
        XCTAssertEqual(data[24], 8, "8 bit kanal")
        XCTAssertEqual(data[25], 2, "renk tipi 2 = alfasız RGB")
    }
}
