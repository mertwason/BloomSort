/// Bir hamle: kaynak kaptan hedef kaba polen taşınması.
///
/// `count` toplu taşınan tane sayısıdır; sayaçta **1 hamle** yazar
/// (bkz. `docs/gdd.md` §2.3).
public struct Move: Hashable, Sendable, Codable {
    public let source: Int
    public let destination: Int
    public let count: Int
    public let color: PollenColor

    public init(source: Int, destination: Int, count: Int, color: PollenColor) {
        self.source = source
        self.destination = destination
        self.count = count
        self.color = color
    }

    /// Bu hamlenin tersi (geri al için).
    public var inverted: Move {
        Move(source: destination, destination: source, count: count, color: color)
    }
}
