/// Geri al yığını.
///
/// `CLAUDE.md`: "Geri al = eski state'i sakla." Hamleyi tersine çevirerek geri
/// almak engeller devreye girince mümkün değil — çözülmüş bir çiy damlasını
/// geri dondurmak, sıfıra inmiş bir kilit sayacını geri yükseltmek için
/// hamlenin kendisi yetmiyor. Anlık görüntü saklamak hem kesin hem ucuz:
/// bir `GameState` en fazla 18 kap × 6 tane.
public struct UndoStack: Sendable {
    /// Seviyenin başlangıç tahtası — "Sıfırla" buraya döner.
    public let initialState: GameState
    public private(set) var current: GameState
    private var snapshots: [GameState]

    public init(_ state: GameState) {
        initialState = state
        current = state
        snapshots = []
    }

    public var canUndo: Bool { !snapshots.isEmpty }
    /// Kaç hamle geri alınabilir.
    public var undoCount: Int { snapshots.count }

    /// Hamleyi uygular. Yasal değilse tahtayı değiştirmez ve `false` döner.
    @discardableResult
    public mutating func apply(_ move: Move) -> Bool {
        guard let next = current.applying(move) else { return false }
        snapshots.append(current)
        current = next
        return true
    }

    @discardableResult
    public mutating func apply(from source: Int, to destination: Int) -> Bool {
        guard let move = current.move(from: source, to: destination) else { return false }
        return apply(move)
    }

    /// Son hamleyi geri alır.
    @discardableResult
    public mutating func undo() -> Bool {
        guard let previous = snapshots.popLast() else { return false }
        current = previous
        return true
    }

    /// Tahtayı seviyenin başına döndürür ("Sıfırla", `docs/ui-spec.md` §2.6).
    public mutating func reset() {
        current = initialState
        snapshots.removeAll(keepingCapacity: true)
    }

    /// Tahtaya bir arı salar. Geri alınabilir.
    @discardableResult
    public mutating func addBee(capacity: Int) -> Bool {
        snapshots.append(current)
        current = current.addingBee(capacity: capacity)
        return true
    }

    /// Sıkışma hâlinde otomatik geri al önerisi (`docs/ui-spec.md` §6).
    public var shouldSuggestUndo: Bool { current.isStuck && canUndo }
}
