import Foundation

/// Oyuncunun ilerlemesi — Patika, yıldızlar, tohum, arı, seri.
///
/// Saf değer tipi: kalıcılık katmanı (SwiftData) bunu okur/yazar, oyun mantığı
/// buradan geçer. Böylece ilerleme kuralları Linux'ta test edilebiliyor.
public struct Progress: Codable, Hashable, Sendable {
    /// Seviye numarası → alınan en iyi yıldız.
    public private(set) var stars: [Int: Int]
    /// Seviye numarası → en iyi hamle sayısı.
    public private(set) var bestMoves: [Int: Int]
    public private(set) var seeds: Int
    public private(set) var bees: Int
    /// Ardışık gün sayısı.
    public private(set) var streakDays: Int
    public private(set) var hasRemoveAds: Bool

    public init(stars: [Int: Int] = [:], bestMoves: [Int: Int] = [:],
                seeds: Int = 0, bees: Int = Economy.startingBees,
                streakDays: Int = 0, hasRemoveAds: Bool = false) {
        self.stars = stars
        self.bestMoves = bestMoves
        self.seeds = seeds
        self.bees = bees
        self.streakDays = streakDays
        self.hasRemoveAds = hasRemoveAds
    }

    /// Oynanabilir en yüksek seviye: tamamlananların bir fazlası.
    public var currentLevel: Int { (stars.keys.max() ?? 0) + 1 }
    public var completedLevels: Int { stars.count }
    public var totalStars: Int { stars.values.reduce(0, +) }
    public var collectedPlates: Int { completedLevels }

    public func isCompleted(_ level: Int) -> Bool { stars[level] != nil }
    public func isUnlocked(_ level: Int) -> Bool { level <= currentLevel }

    /// Seviye bitti: yıldız ve en iyi hamle güncellenir, tohum eklenir.
    /// Daha kötü bir sonuç mevcut kaydı düşürmez.
    @discardableResult
    public mutating func complete(level: Int, stars newStars: Int, moves: Int) -> Int {
        let previous = stars[level] ?? 0
        stars[level] = max(previous, newStars)
        bestMoves[level] = min(bestMoves[level] ?? moves, moves)
        let reward = Economy.seedReward(stars: newStars, streakDays: streakDays)
        seeds += reward
        if Herbarium.completesAlbum(level: level), previous == 0 {
            seeds += Economy.albumSeedReward
            bees += Economy.albumBeeReward
        }
        return reward
    }

    public mutating func spendBee() -> Bool {
        guard bees > 0 else { return false }
        bees -= 1
        return true
    }

    public mutating func grantBees(_ count: Int) { bees += count }
    public mutating func grantSeeds(_ count: Int) { seeds += count }

    public mutating func spendSeeds(_ count: Int) -> Bool {
        guard seeds >= count else { return false }
        seeds -= count
        return true
    }

    public mutating func setRemoveAds(_ purchased: Bool) { hasRemoveAds = purchased }
    public mutating func setStreak(days: Int) { streakDays = max(0, days) }
}

/// Onboarding — `docs/ui-spec.md` §3.2. Öğretici ayrı ekran değil, seviye
/// 1-8'in içinde yaşıyor.
public enum Onboarding {
    /// Bu seviyede hangi ipucu gösterilecek.
    public enum Hint: String, Sendable, Equatable {
        case tapToTap        // 1: dokun-dokun hamlesi
        case bulkTransfer    // 2: toplu taşıma
        case emptyAndBloom   // 3: boş kap ve çiçek açma
        case undo            // 4: geri al
        case bee             // 8: arı
    }

    public static func hint(forLevel level: Int) -> Hint? {
        switch level {
        case 1: return .tapToTap
        case 2: return .bulkTransfer
        case 3: return .emptyAndBloom
        case 4: return .undo
        case 8: return .bee
        default: return nil
        }
    }

    /// İlk 5 seviye tamamen temiz: reklam yok, IAP yok, ATT yok (§3.2).
    public static func isCleanLevel(_ level: Int) -> Bool { level <= 5 }

    /// ATT izni 5. seviye sonunda istenir (§6.6).
    public static let attRequestLevel = 5

    /// İlk arı ücretsiz verilir, reklam istenmez (§3.2, seviye 8).
    public static let freeBeeLevel = 8
}
