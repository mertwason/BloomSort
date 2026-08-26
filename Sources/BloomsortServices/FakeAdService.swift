import Foundation

/// Testlerde ve SwiftUI önizlemelerinde kullanılan sahte reklam servisi.
///
/// Gerçek `AdMobAdService` Google Mobile Ads SDK'sına bağlı olduğu için
/// yalnızca iOS hedefinde derlenir; kural mantığı buradaki gibi platformdan
/// bağımsız durur ve testlerde tek başına koşar.
public final class FakeAdService: AdServiceProtocol, @unchecked Sendable {
    public var interstitialReady = true
    public var rewardedReady = true
    public private(set) var interstitialsShown = 0
    public private(set) var rewardedShown: [RewardedPlacement] = []
    public var fallback: RewardFallbackPolicy

    public init(now: Date = Date()) {
        fallback = RewardFallbackPolicy(day: now)
    }

    public func canShowInterstitial(context: InterstitialContext) -> Bool {
        InterstitialPolicy.canShowInterstitial(context: context)
    }

    public func showInterstitial() async -> Bool {
        // Hazır değilse atlanır — asla bekleme ekranı gösterilmez.
        guard interstitialReady else { return false }
        interstitialsShown += 1
        return true
    }

    public func showRewarded(_ placement: RewardedPlacement) async -> RewardOutcome {
        guard rewardedReady else { return fallback.resolveFailedLoad(now: Date()) }
        rewardedShown.append(placement)
        return .watched
    }

    public func shouldShowBanner(on surface: AdSurface) -> Bool {
        surface.allowsBanner
    }
}
