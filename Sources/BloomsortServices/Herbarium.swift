import BloomsortDomain
import Foundation

/// Herbaryum — `docs/gdd.md` §5.1.
///
/// Her tamamlanan seviye bir botanik levha verir; 12 levha bir albüm eder,
/// albümler biyomlardır.
public enum Herbarium {
    /// 12 levha = 1 albüm.
    public static let platesPerAlbum = 12

    /// GDD §5.1'de adı geçen biyomlar.
    ///
    /// Sekiz tane sayılmış, cümle "..." ile bitiyor. 200 seviyelik lansman
    /// paketi 17 albüm demek, yani **9 biyom adı eksik**. Eksikler
    /// uydurulmadı; `albumName(_:)` isimsiz albümler için numaralı bir ad
    /// döndürüyor ve README'deki açık içerik listesinde duruyor.
    public static let namedBiomes = [
        "Çayır", "Orman Altı", "Kıyı", "Bozkır",
        "Yayla", "Bahçe", "Sulak", "Kayalık",
    ]

    public static func albumIndex(forLevel level: Int) -> Int {
        precondition(level >= 1, "Seviye numarası 1'den başlar")
        return (level - 1) / platesPerAlbum
    }

    public static func plateIndexInAlbum(forLevel level: Int) -> Int {
        (level - 1) % platesPerAlbum
    }

    public static func albumName(_ index: Int) -> String {
        namedBiomes.indices.contains(index) ? namedBiomes[index] : "Bölge \(index + 1)"
    }

    /// Albümün adı belirlenmiş mi? İsimsizler içerik listesinde bekliyor.
    public static func hasName(_ index: Int) -> Bool {
        namedBiomes.indices.contains(index)
    }

    /// Albüm ilerlemesi: "Çayır · 11/12" (§2.4).
    public static func progressLabel(forLevel level: Int) -> String {
        let album = albumIndex(forLevel: level)
        let position = plateIndexInAlbum(forLevel: level) + 1
        return "\(albumName(album)) · \(position)/\(platesPerAlbum)"
    }

    /// Bu seviye albümün son levhası mı? Cam fanus kutlaması buna bakar (§3.7).
    public static func completesAlbum(level: Int) -> Bool {
        plateIndexInAlbum(forLevel: level) == platesPerAlbum - 1
    }
}

/// Levha türü adı üretici (§5.1: "üretilen Latince-benzeri ad, ör. *Papaver noctis*").
///
/// Determinist: aynı seviye her cihazda aynı adı alır.
public struct PlateNaming: Sendable {
    static let genera = [
        "Papaver", "Silene", "Aster", "Viola", "Salvia", "Lupinus", "Iris", "Malva",
        "Anemone", "Cistus", "Digitalis", "Echium", "Geranium", "Linum", "Nigella",
        "Origanum", "Primula", "Scilla", "Thymus", "Verbena", "Achillea", "Campanula",
    ]
    static let epithets = [
        "noctis", "vespertina", "lunaris", "umbrata", "serotina", "crepusculi",
        "stellata", "nivalis", "aurea", "cyanea", "purpurea", "candida",
        "montana", "littoralis", "palustris", "rupestris", "silvatica", "pratensis",
        "borealis", "australis", "gracilis", "mirabilis",
    ]

    public init() {}

    /// Seviye numarasından tür adı üretir.
    ///
    /// Çarpma-mod ile karıştırmak yetmiyordu: liste uzunlukları ortak çarpan
    /// paylaşınca tür adı birkaç seçeneğe çöküyor. Determinist üreteçle
    /// çekiliyor, `PlateNaming` testi dağılımı ölçüyor.
    public func name(forLevel level: Int) -> String {
        var rng = SplitMix64(seed: UInt64(level) &* 0x9E37_79B9 &+ 0x1234_5678)
        let genus = Self.genera[rng.int(below: Self.genera.count)]
        let epithet = Self.epithets[rng.int(below: Self.epithets.count)]
        return "\(genus) \(epithet)"
    }

    /// Kaç farklı ad üretilebilir.
    public var capacity: Int { Self.genera.count * Self.epithets.count }
}
