/// Bir polen tanesinin rengi.
///
/// Domain katmanı rengi yalnızca bir indeks olarak bilir; hex değerleri ve
/// renk körlüğü sembolleri sunum katmanına aittir (bkz. `docs/ui-spec.md` §1.2).
public struct PollenColor: Hashable, Sendable, Codable, Comparable, CustomStringConvertible {
    /// 0 tabanlı palet indeksi.
    public let index: Int

    public init(_ index: Int) {
        precondition(index >= 0 && index < PollenColor.maxColors,
                     "Polen rengi indeksi 0..<\(PollenColor.maxColors) aralığında olmalı")
        self.index = index
    }

    /// Çözücü tahtayı kap başına 32 bitte paketler (bkz. `Solver`), bu da
    /// renk başına 4 bit bırakır.
    public static let maxColors = 16

    public static func < (lhs: PollenColor, rhs: PollenColor) -> Bool { lhs.index < rhs.index }

    public var description: String { "renk\(index)" }
}

/// Tek bir polen tanesi.
///
/// Şimdilik yalnızca rengi taşır; çiy damlası gibi engeller v1'de yok
/// (bkz. `docs/gdd.md` §4.2, engeller sonraki iş paketinde).
public struct Bead: Hashable, Sendable, Codable {
    public let color: PollenColor

    public init(_ color: PollenColor) { self.color = color }
    public init(color index: Int) { self.color = PollenColor(index) }
}
