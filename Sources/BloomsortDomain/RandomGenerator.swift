/// Determinist sözde-rastgele üreteç (SplitMix64).
///
/// Aynı seed her cihazda **aynı tahtayı** vermek zorunda (bkz. `docs/gdd.md`
/// §4.1). Sistemin `SystemRandomNumberGenerator`'ı bunu garanti etmez, bu
/// yüzden üretim ve yeniden kurma tamamen bu üretece bağlıdır.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// `0..<upperBound` aralığında düzgün dağılımlı tamsayı.
    public mutating func int(below upperBound: Int) -> Int {
        precondition(upperBound > 0)
        return Int(next() % UInt64(upperBound))
    }

    public mutating func int(in range: ClosedRange<Int>) -> Int {
        range.lowerBound + int(below: range.count)
    }

    public mutating func pick<T>(_ elements: [T]) -> T {
        elements[int(below: elements.count)]
    }
}
