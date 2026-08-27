/// Engeller — `docs/gdd.md` §4.2.
///
/// Dört mekanik var ve ikisinin kuralı GDD'de tek cümleyle geçiyor. Buradaki
/// okuma birebir metne dayanıyor; belirsiz kalan yerler her tipin yanında
/// açıkça yazılı.
public enum ObstacleKind: String, Codable, Hashable, Sendable, CaseIterable {
    /// Seviye 41+: "kap kilitli, X polen başka yere yerleşince açılır".
    case closedBud
    /// Seviye 61+: "bir polen donmuş; üstüne 2 hamle yapılınca çözülür".
    case dewDrop
    /// Seviye 86+: "5 hamlede bir iki kabın üstü yer değiştirir;
    /// 3 hamle önceden gösterilir".
    case wind
    /// Seviye 116+: "yumuşak hamle limiti; aşmak seviyeyi kaybettirmez,
    /// sadece yıldızı düşürür".
    case beeBudget

    public var turkishName: String {
        switch self {
        case .closedBud: return "Kapalı tomurcuk"
        case .dewDrop:   return "Çiy damlası"
        case .wind:      return "Rüzgâr"
        case .beeBudget: return "Arı bütçesi"
        }
    }
}

/// Rüzgâr çizelgesi.
///
/// Rüzgâr **rastgele değildir** (`docs/gdd.md` §4.2, kritik tasarım kuralı):
/// hangi iki kabın kaçıncı hamlede yer değiştireceği önceden bellidir ve
/// üst barda 3 hamle önceden gösterilir. Çizelge seed'den türetilir, yani
/// hem oyuncu hem çözücü ileriyi görebilir.
public struct WindSchedule: Codable, Hashable, Sendable {
    /// Kaç hamlede bir esiyor.
    public static let interval = 5
    /// Kaç hamle önceden gösteriliyor.
    public static let announceLead = 3

    /// Sırayla esecek kap çiftleri. `pairs[0]` ilk rüzgârda takas edilir.
    public let pairs: [Pair]

    public struct Pair: Codable, Hashable, Sendable {
        public let first: Int
        public let second: Int
        public init(_ first: Int, _ second: Int) {
            self.first = first
            self.second = second
        }
    }

    public init(pairs: [Pair]) { self.pairs = pairs }

    /// `moveCount` hamle yapıldıktan sonra rüzgâr eser mi?
    public static func blows(afterMoveCount moveCount: Int) -> Bool {
        moveCount > 0 && moveCount % interval == 0
    }

    /// `moveCount` hamleden sonraki rüzgârın çizelgedeki sırası.
    public static func eventIndex(afterMoveCount moveCount: Int) -> Int {
        moveCount / interval - 1
    }

    /// `moveCount` hamle yapılmışken sıradaki rüzgârın çifti ve kaç hamle kaldığı.
    /// Gösterge yalnızca `announceLead` hamle kala görünür (`docs/ui-spec.md` §3.5).
    public func upcoming(atMoveCount moveCount: Int) -> (pair: Pair, movesAway: Int)? {
        let nextEvent = moveCount / WindSchedule.interval
        guard pairs.indices.contains(nextEvent) else { return nil }
        let movesAway = (nextEvent + 1) * WindSchedule.interval - moveCount
        return (pairs[nextEvent], movesAway)
    }

    /// Toplam kaç rüzgâr olayı planlanmış.
    public var count: Int { pairs.count }
}
