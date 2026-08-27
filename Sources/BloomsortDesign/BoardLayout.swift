import Foundation

/// Tahta yerleşimi — `docs/ui-spec.md` §3.5.
///
/// Spec'in algoritması kap sayısına göre satır/sütun seçiyor ve genişliği
/// ölçekliyor, ama **yüksekliği ölçeklemiyor**: 3 satır × 6 kapasiteli kap
/// 3 × 188 = 564 pt eder, tahta alanı ise 449 pt. Bu yüzden burada tek bir
/// düzgün ölçek katsayısı hesaplanıyor ve hem yükseklik hem genişlik ona
/// bağlanıyor; ölçek 1'i asla aşmıyor, yani sığan tahtalar spec'teki
/// ölçüleriyle çiziliyor.
public enum BoardLayout {

    public struct Frame: Hashable, Sendable {
        /// `capacities` dizisindeki sıra.
        public let vesselIndex: Int
        public let row: Int
        public let column: Int
        /// Kabın **taban orta noktası**. Kaplar satır içinde tabandan hizalanır
        /// (§3.5: "vazolar bir rafta durur gibi").
        public let baseCenterX: Double
        public let baseY: Double
        public let width: Double
        public let height: Double

        public var top: Double { baseY - height }
    }

    public struct Result: Hashable, Sendable {
        public let frames: [Frame]
        public let rows: Int
        public let columns: Int
        /// Spec ölçülerine uygulanan düzgün ölçek (≤ 1).
        public let scale: Double
        public let horizontalGap: Double
        public let verticalGap: Double
    }

    public static let minimumHorizontalGap = 12.0
    public static let minimumVerticalGap = 16.0

    /// §3.5'teki satır/sütun ve genişlik ölçeği tablosu.
    static func grid(forVesselCount count: Int) -> (rows: Int, columns: Int, widthScale: Double) {
        switch count {
        case ...8:  return (2, 4, 1.00)
        case ...12: return (3, 4, 1.00)
        case ...15: return (3, 5, 0.88)
        default:    return (3, 6, 0.74)
        }
    }

    /// Kapasitelerden tahta yerleşimini hesaplar.
    ///
    /// - Parameters:
    ///   - capacities: kapların kapasiteleri, tahtadaki sırasıyla.
    ///   - area: kullanılabilir tahta dikdörtgeni (varsayılan §3.5'in 449 pt'lik alanı).
    public static func compute(capacities: [Int],
                               width: Double = Layout.referenceWidth,
                               height: Double = Layout.boardHeight,
                               top: Double = Layout.boardTop) -> Result {
        precondition(!capacities.isEmpty, "Tahtada en az bir kap olmalı")
        let (rows, columns, widthScale) = grid(forVesselCount: capacities.count)

        // Satırlara satır-öncelikli dağıt.
        var rowContents: [[Int]] = Array(repeating: [], count: rows)
        for (index, _) in capacities.enumerated() {
            rowContents[min(index / columns, rows - 1)].append(index)
        }

        func size(_ index: Int) -> VesselMetrics.Size {
            VesselMetrics.size(forCapacity: capacities[index])
        }

        // Satır yüksekliği = satırdaki en yüksek kap (tabanlar hizalı).
        let rowHeights = rowContents.map { row in row.map { size($0).height }.max() ?? 0 }
        let usedRows = rowContents.filter { !$0.isEmpty }.count
        let totalHeight = rowHeights.reduce(0, +)

        // Dikey ölçek: satırlar + minimum boşluklar alana sığmalı.
        let verticalBudget = height - Double(usedRows + 1) * minimumVerticalGap
        var scale = totalHeight > 0 ? min(1.0, verticalBudget / totalHeight) : 1.0

        // Yatay ölçek: en dolu satır kenar boşluklarına sığmalı.
        let usableWidth = width - 2 * Spacing.screenMargin
        for row in rowContents where !row.isEmpty {
            let rowWidth = row.map { size($0).width * widthScale }.reduce(0, +)
            let gaps = Double(max(row.count - 1, 0)) * minimumHorizontalGap
            if rowWidth + gaps > usableWidth {
                scale = min(scale, (usableWidth - gaps) / rowWidth)
            }
        }
        scale = max(scale, 0.1)

        let scaledRowHeights = rowHeights.map { $0 * scale }
        let scaledTotalHeight = scaledRowHeights.reduce(0, +)
        let verticalGap = max(minimumVerticalGap,
                              (height - scaledTotalHeight) / Double(usedRows + 1))

        var frames: [Frame] = []
        var cursorY = top + verticalGap
        var widestGap = Double.greatestFiniteMagnitude

        for (rowIndex, row) in rowContents.enumerated() where !row.isEmpty {
            let widths = row.map { size($0).width * widthScale * scale }
            let rowWidth = widths.reduce(0, +)
            let gap = row.count > 1
                ? max(minimumHorizontalGap, (usableWidth - rowWidth) / Double(row.count - 1))
                : 0
            widestGap = min(widestGap, row.count > 1 ? gap : widestGap)
            let contentWidth = rowWidth + gap * Double(row.count - 1)
            var cursorX = (width - contentWidth) / 2
            let baseY = cursorY + scaledRowHeights[rowIndex]

            for (columnIndex, vesselIndex) in row.enumerated() {
                let vesselWidth = widths[columnIndex]
                frames.append(Frame(vesselIndex: vesselIndex,
                                    row: rowIndex,
                                    column: columnIndex,
                                    baseCenterX: cursorX + vesselWidth / 2,
                                    baseY: baseY,
                                    width: vesselWidth,
                                    height: size(vesselIndex).height * scale))
                cursorX += vesselWidth + gap
            }
            cursorY = baseY + verticalGap
        }

        return Result(frames: frames.sorted { $0.vesselIndex < $1.vesselIndex },
                      rows: usedRows,
                      columns: columns,
                      scale: scale,
                      horizontalGap: widestGap == .greatestFiniteMagnitude ? 0 : widestGap,
                      verticalGap: verticalGap)
    }
}
