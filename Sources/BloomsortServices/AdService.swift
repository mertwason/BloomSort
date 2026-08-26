import Foundation

/// Reklam yüzeyleri (`docs/gdd.md` §6, `docs/ui-spec.md` §4).
public enum AdSurface: String, Sendable, CaseIterable {
    case splash
    case onboarding
    case path            // Patika
    case board           // Oyun tahtası
    case levelComplete
    case herbarium
    case garden          // Bahçem
    case hive            // Kovan
    case settings
    case season

    /// Banner yalnızca Herbaryum, Bahçem, Kovan, Ayarlar ve Mevsim'de.
    /// **Oyun tahtasında hiçbir reklam yüzeyi olamaz.**
    public var allowsBanner: Bool {
        switch self {
        case .herbarium, .garden, .hive, .settings, .season: return true
        case .splash, .onboarding, .path, .board, .levelComplete: return false
        }
    }
}

/// Ödüllü reklam yerleşimleri (`docs/gdd.md` §6.1).
public enum RewardedPlacement: String, Sendable, CaseIterable {
    case extraBee        = "rewarded_bee"        // R1
    case extraUndos      = "rewarded_undo"       // R2
    case hint            = "rewarded_hint"       // R3
    case doubleReward    = "rewarded_double"     // R4
    case streakRepair    = "rewarded_streak"     // R5
    case flowerOfTheDay  = "rewarded_flower"     // R6
    case seasonBoost     = "rewarded_season"     // R7
}

/// Reklam gösteriminin sonucu.
public enum RewardOutcome: Sendable, Equatable {
    /// Reklam izlendi, ödül verildi.
    case watched
    /// Oyuncu vazgeçti, ödül yok.
    case dismissed
    /// Reklam yüklenemedi ama ödül **yine de** verildi (günlük telafi hakkı).
    case grantedWithoutAd
    /// Reklam yüklenemedi ve günlük telafi hakkı bitti.
    case unavailable
}

/// Reklam servisinin sözleşmesi.
///
/// Gerçek SDK çağrıları `AdMobAdService`'te yaşar (Google Mobile Ads + UMP,
/// yalnızca iOS hedefinde derlenir). Testler `FakeAdService` kullanır.
public protocol AdServiceProtocol: AnyObject {
    /// §6.2'deki 8 kural. Karar tek kapıdan geçer.
    func canShowInterstitial(context: InterstitialContext) -> Bool
    /// Interstitial gösterir. Hazır değilse **atlanır**, bekleme ekranı yok.
    func showInterstitial() async -> Bool
    /// Ödüllü reklam gösterir.
    func showRewarded(_ placement: RewardedPlacement) async -> RewardOutcome
    /// Bu yüzeyde banner gösterilmeli mi?
    func shouldShowBanner(on surface: AdSurface) -> Bool
}

/// Ödüllü reklam yüklenemediğinde ödülün yine de verilmesi
/// (`docs/gdd.md` §6.1, `docs/ui-spec.md` §6).
///
/// "Oyuncu asla teknik bir hatanın cezasını çekmez" — ama sınırsız da değil,
/// yoksa uçak modunda oynamak ödülleri bedavaya çevirir.
public struct RewardFallbackPolicy: Sendable {
    /// Günde en fazla kaç kez reklamsız ödül verilir.
    public static let dailyGrants = 3

    public private(set) var grantsToday: Int
    public private(set) var day: Date

    public init(grantsToday: Int = 0, day: Date) {
        self.grantsToday = grantsToday
        self.day = day
    }

    /// Reklam yüklenemedi; ödül verilsin mi?
    public mutating func resolveFailedLoad(now: Date,
                                           calendar: Calendar = .current) -> RewardOutcome {
        if !calendar.isDate(now, inSameDayAs: day) {
            day = now
            grantsToday = 0
        }
        guard grantsToday < Self.dailyGrants else { return .unavailable }
        grantsToday += 1
        return .grantedWithoutAd
    }
}

/// App Open reklam kuralları (`docs/gdd.md` §6.3).
public enum AppOpenPolicy {
    /// 4 saatte en fazla 1.
    public static let cooldown: TimeInterval = 4 * 3600

    /// Yalnızca soğuk başlatmada, 4 saatte 1 kez, **D0'da hiç**.
    public static func canShowAppOpen(isColdStart: Bool, now: Date, installDate: Date,
                                      lastAppOpen: Date?, hasRemoveAds: Bool,
                                      calendar: Calendar = .current) -> Bool {
        guard isColdStart, !hasRemoveAds else { return false }
        // D0: kurulum günü açılış reklamı yok — D1 retention'ı kırıyor.
        guard !calendar.isDate(now, inSameDayAs: installDate) else { return false }
        guard let lastAppOpen else { return true }
        return now.timeIntervalSince(lastAppOpen) >= cooldown
    }
}
