import BloomsortDomain
import Foundation

/// Interstitial kararının dayandığı bağlam.
///
/// Karar saf bir fonksiyondur: içeride saat okunmaz, kullanıcı savunması
/// tamamen bu yapıdan gelen verilere dayanır. Testte sahte zaman vermek bu
/// yüzden yeterli.
public struct InterstitialContext: Sendable, Equatable {
    /// Yeni bitirilen seviyenin numarası.
    public let level: Int
    /// Yeni bitirilen seviyeden alınan yıldız.
    public let stars: Int
    public let now: Date
    /// Oturumun (soğuk ya da sıcak başlatma) başladığı an.
    public let sessionStart: Date
    /// Son interstitial gösterimi.
    public let lastInterstitial: Date?
    /// Son izlenen ödüllü reklam.
    public let lastRewarded: Date?
    /// Bir önceki seviyenin sonunda interstitial gösterildi mi?
    public let shownOnPreviousLevel: Bool
    /// Bu oturumdaki ve son bir saatteki bütün interstitial gösterimleri.
    public let recentImpressions: [Date]
    /// "Reklamsız" satın alındı mı?
    public let hasRemoveAds: Bool

    public init(level: Int, stars: Int, now: Date, sessionStart: Date,
                lastInterstitial: Date? = nil, lastRewarded: Date? = nil,
                shownOnPreviousLevel: Bool = false, recentImpressions: [Date] = [],
                hasRemoveAds: Bool = false) {
        self.level = level
        self.stars = stars
        self.now = now
        self.sessionStart = sessionStart
        self.lastInterstitial = lastInterstitial
        self.lastRewarded = lastRewarded
        self.shownOnPreviousLevel = shownOnPreviousLevel
        self.recentImpressions = recentImpressions
        self.hasRemoveAds = hasRemoveAds
    }
}

/// `docs/gdd.md` §6.2'deki 8 kural. Hepsi **aynı anda** sağlanmalı.
///
/// Kurallar tek tek sayılabilir olsun diye enum: her kural için ayrı birim
/// test yazılabiliyor ve hangi kuralın engellediği loglanabiliyor.
public enum InterstitialRule: String, CaseIterable, Sendable {
    /// 1. Seviye ≥ 8 — ilk oturum korunur.
    case minimumLevel
    /// 2. Son interstitial'dan bu yana ≥ 90 saniye.
    case cooldown
    /// 3. Son 45 saniyede ödüllü reklam izlenmemiş.
    case rewardedCooldown
    /// 4. Arka arkaya iki seviyede gösterilmez.
    case notBackToBack
    /// 5. 1★ ile biten seviyeden sonra gösterilmez.
    case notAfterOneStar
    /// 6. Saatte en fazla 6.
    case hourlyCap
    /// 7. Oturumun ilk 3 dakikasında en fazla 1.
    case sessionOpeningCap
    /// 8. "Reklamsız" satın almışsa hiç.
    case removeAdsPurchase

    /// Bu kural gösterimi engelliyor mu?
    public func blocks(_ context: InterstitialContext) -> Bool {
        switch self {
        case .minimumLevel:
            return context.level < InterstitialPolicy.minimumLevel
        case .cooldown:
            guard let last = context.lastInterstitial else { return false }
            return context.now.timeIntervalSince(last) < InterstitialPolicy.cooldown
        case .rewardedCooldown:
            guard let last = context.lastRewarded else { return false }
            return context.now.timeIntervalSince(last) < InterstitialPolicy.rewardedCooldown
        case .notBackToBack:
            return context.shownOnPreviousLevel
        case .notAfterOneStar:
            return context.stars == 1
        case .hourlyCap:
            let window = context.now.addingTimeInterval(-InterstitialPolicy.hourlyWindow)
            let count = context.recentImpressions.filter { $0 > window }.count
            return count >= InterstitialPolicy.hourlyCap
        case .sessionOpeningCap:
            let openingEnd = context.sessionStart.addingTimeInterval(InterstitialPolicy.sessionOpening)
            guard context.now < openingEnd else { return false }
            let count = context.recentImpressions.filter {
                $0 >= context.sessionStart && $0 < openingEnd
            }.count
            return count >= InterstitialPolicy.sessionOpeningCap
        case .removeAdsPurchase:
            return context.hasRemoveAds
        }
    }
}

/// Interstitial sabitleri — hepsi `docs/gdd.md` §6.2'den.
public enum InterstitialPolicy {
    public static let minimumLevel = 8
    public static let cooldown: TimeInterval = 90
    public static let rewardedCooldown: TimeInterval = 45
    public static let hourlyWindow: TimeInterval = 3600
    public static let hourlyCap = 6
    public static let sessionOpening: TimeInterval = 180
    public static let sessionOpeningCap = 1

    /// 8 kuralın tek kapısı. Hepsi geçerse `true`.
    public static func canShowInterstitial(context: InterstitialContext) -> Bool {
        blockingRules(context: context).isEmpty
    }

    /// Gösterimi engelleyen kurallar — teşhis ve analitik için.
    public static func blockingRules(context: InterstitialContext) -> [InterstitialRule] {
        InterstitialRule.allCases.filter { $0.blocks(context) }
    }
}
