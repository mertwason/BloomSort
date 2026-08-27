import Foundation

/// Analitik olay şeması — `docs/gdd.md` §8.5.
///
/// Olaylar tip güvenli: alan adı yanlış yazıldığında derleme hatası çıkar,
/// canlıda eksik veri değil. Firebase adaptörü `parameters`'ı olduğu gibi
/// gönderir.
public enum AnalyticsEvent: Sendable, Equatable {
    case levelStart(levelID: Int, attempt: Int, beesOwned: Int, seed: UInt64)
    case levelComplete(levelID: Int, moves: Int, optimalMoves: Int, stars: Int,
                       durationMilliseconds: Int, undos: Int, hints: Int, beesUsed: Int)
    case levelAbandon(levelID: Int, moves: Int, durationMilliseconds: Int, lastAction: String)
    case beeSpend(source: BeeSource, levelID: Int)
    case adImpression(unit: String, placementID: String, levelID: Int?, ecpmBucket: String)
    case adRewardGrant(placementID: String, fallback: Bool)
    case iapPurchase(productID: String, priceLocal: Double, currency: String)
    case plateCollect(plateID: Int, albumID: Int, albumPercent: Double)
    case albumComplete(albumID: Int, daysSinceInstall: Int)
    case streakChange(value: Int, direction: StreakDirection)
    case seasonTierUp(tier: Int, isPassHolder: Bool)

    public enum BeeSource: String, Sendable { case rewarded, iap, reward, season }
    public enum StreakDirection: String, Sendable { case up, down, reset }

    public var name: String {
        switch self {
        case .levelStart:     return "level_start"
        case .levelComplete:  return "level_complete"
        case .levelAbandon:   return "level_abandon"
        case .beeSpend:       return "bee_spend"
        case .adImpression:   return "ad_impression"
        case .adRewardGrant:  return "ad_reward_grant"
        case .iapPurchase:    return "iap_purchase"
        case .plateCollect:   return "plate_collect"
        case .albumComplete:  return "album_complete"
        case .streakChange:   return "streak_change"
        case .seasonTierUp:   return "season_tier_up"
        }
    }

    public var parameters: [String: AnalyticsValue] {
        switch self {
        case let .levelStart(levelID, attempt, beesOwned, seed):
            return ["level_id": .int(levelID), "attempt": .int(attempt),
                    "bees_owned": .int(beesOwned), "seed": .string(String(seed))]
        case let .levelComplete(levelID, moves, optimal, stars, duration, undos, hints, bees):
            return ["level_id": .int(levelID), "moves": .int(moves),
                    "optimal_moves": .int(optimal), "stars": .int(stars),
                    "duration_ms": .int(duration), "undos": .int(undos),
                    "hints": .int(hints), "bees_used": .int(bees)]
        case let .levelAbandon(levelID, moves, duration, lastAction):
            return ["level_id": .int(levelID), "moves": .int(moves),
                    "duration_ms": .int(duration), "last_action": .string(lastAction)]
        case let .beeSpend(source, levelID):
            return ["source": .string(source.rawValue), "level_id": .int(levelID)]
        case let .adImpression(unit, placementID, levelID, bucket):
            var parameters: [String: AnalyticsValue] = [
                "unit": .string(unit), "placement_id": .string(placementID),
                "ecpm_bucket": .string(bucket),
            ]
            if let levelID { parameters["level_id"] = .int(levelID) }
            return parameters
        case let .adRewardGrant(placementID, fallback):
            return ["placement_id": .string(placementID), "fallback": .bool(fallback)]
        case let .iapPurchase(productID, price, currency):
            return ["product_id": .string(productID), "price_local": .double(price),
                    "currency": .string(currency)]
        case let .plateCollect(plateID, albumID, percent):
            return ["plate_id": .int(plateID), "album_id": .int(albumID),
                    "album_pct": .double(percent)]
        case let .albumComplete(albumID, days):
            return ["album_id": .int(albumID), "days_since_install": .int(days)]
        case let .streakChange(value, direction):
            return ["value": .int(value), "direction": .string(direction.rawValue)]
        case let .seasonTierUp(tier, isPassHolder):
            return ["tier": .int(tier), "is_pass_holder": .bool(isPassHolder)]
        }
    }
}

public enum AnalyticsValue: Sendable, Equatable {
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
}

/// Analitik servisinin sözleşmesi. Firebase adaptörü ayrı, testlerde sahte.
public protocol AnalyticsServiceProtocol: AnyObject, Sendable {
    func log(_ event: AnalyticsEvent)
    /// Kullanıcı özelliği (ör. "reklamsız").
    func setUserProperty(_ value: String?, forKey key: String)
}

/// Testlerde ve önizlemelerde kullanılan sahte analitik.
public final class FakeAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    public private(set) var events: [AnalyticsEvent] = []
    public private(set) var properties: [String: String?] = [:]

    public init() {}

    public func log(_ event: AnalyticsEvent) { events.append(event) }
    public func setUserProperty(_ value: String?, forKey key: String) { properties[key] = value }
}

/// Remote Config parametreleri — lansman checklist'i Faz 7.
///
/// Varsayılanlar uygulamada gömülü: çevrimdışıyken oyun bozulmuyor.
public struct RemoteConfigDefaults: Sendable, Equatable {
    public var interstitialCooldown: TimeInterval
    public var interstitialMinimumLevel: Int
    public var interstitialHourlyCap: Int
    public var difficultyMultiplier: Double

    public static let embedded = RemoteConfigDefaults(
        interstitialCooldown: InterstitialPolicy.cooldown,
        interstitialMinimumLevel: InterstitialPolicy.minimumLevel,
        interstitialHourlyCap: InterstitialPolicy.hourlyCap,
        difficultyMultiplier: 1.0)

    public init(interstitialCooldown: TimeInterval, interstitialMinimumLevel: Int,
                interstitialHourlyCap: Int, difficultyMultiplier: Double) {
        self.interstitialCooldown = interstitialCooldown
        self.interstitialMinimumLevel = interstitialMinimumLevel
        self.interstitialHourlyCap = interstitialHourlyCap
        self.difficultyMultiplier = difficultyMultiplier
    }
}
