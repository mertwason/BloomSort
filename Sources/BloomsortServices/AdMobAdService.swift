#if canImport(GoogleMobileAds)
import Foundation
import GoogleMobileAds
#if canImport(UIKit)
import UIKit
#endif

/// Google Mobile Ads ile gerçek reklam servisi.
///
/// Kural mantığı burada **yok**: 8 interstitial kuralı `InterstitialPolicy`'de
/// ve SDK'sız test ediliyor. Burası yalnızca SDK köprüsü.
///
/// SDK projede yoksa bu dosya derlenmez; kural motoru ve testler etkilenmez.
@MainActor
public final class AdMobAdService: NSObject, AdServiceProtocol {
    /// Ad unit kimlikleri — lansman checklist'i Faz 4.1.
    public struct AdUnits: Sendable {
        public let interstitial: String
        public let rewardedBee: String
        public let rewardedUndo: String
        public let rewardedHint: String
        public let rewardedDouble: String
        public let rewardedStreak: String
        public let appOpen: String
        public let banner: String

        public init(interstitial: String, rewardedBee: String, rewardedUndo: String,
                    rewardedHint: String, rewardedDouble: String, rewardedStreak: String,
                    appOpen: String, banner: String) {
            self.interstitial = interstitial
            self.rewardedBee = rewardedBee
            self.rewardedUndo = rewardedUndo
            self.rewardedHint = rewardedHint
            self.rewardedDouble = rewardedDouble
            self.rewardedStreak = rewardedStreak
            self.appOpen = appOpen
            self.banner = banner
        }

        public func unit(for placement: RewardedPlacement) -> String {
            switch placement {
            case .extraBee:       return rewardedBee
            case .extraUndos:     return rewardedUndo
            case .hint:           return rewardedHint
            case .doubleReward:   return rewardedDouble
            case .streakRepair, .flowerOfTheDay, .seasonBoost: return rewardedStreak
            }
        }
    }

    private let units: AdUnits
    private var interstitial: InterstitialAd?
    private var rewarded: [RewardedPlacement: RewardedAd] = [:]
    private var fallback: RewardFallbackPolicy
    /// "Reklamsız" satın alındıysa hiçbir yüzey gösterilmez (§6.7).
    public var hasRemoveAds = false

    public init(units: AdUnits, now: Date = Date()) {
        self.units = units
        self.fallback = RewardFallbackPolicy(day: now)
        super.init()
    }

    /// Yaş derecesi 4+ ama uygulama çocuklara yönelik değil:
    /// `maxAdContentRating = G`, `tagForChildDirectedTreatment` **ayarlanmaz**
    /// (`docs/gdd.md` §6.6).
    public static func configureRequestSettings() {
        MobileAds.shared.requestConfiguration.maxAdContentRating = .general
    }

    /// SDK'yı başlatır. UMP rızası alınmadan çağrılmamalı.
    public static func start() async {
        configureRequestSettings()
        await MobileAds.shared.start()
    }

    // MARK: - Ön yükleme
    //
    // Her unit için preload; gösterimden önce hazır değilse **atlanır**,
    // asla bekleme ekranı gösterilmez (§6.6).

    public func preloadInterstitial() {
        guard !hasRemoveAds else { return }
        Task {
            interstitial = try? await InterstitialAd.load(with: units.interstitial,
                                                          request: Request())
        }
    }

    public func preloadRewarded(_ placement: RewardedPlacement) {
        Task {
            rewarded[placement] = try? await RewardedAd.load(with: units.unit(for: placement),
                                                             request: Request())
        }
    }

    // MARK: - AdServiceProtocol

    public func canShowInterstitial(context: InterstitialContext) -> Bool {
        InterstitialPolicy.canShowInterstitial(context: context)
    }

    public func showInterstitial() async -> Bool {
        guard !hasRemoveAds, let ad = interstitial,
              let controller = Self.topViewController() else { return false }
        interstitial = nil
        ad.present(from: controller)
        preloadInterstitial()
        return true
    }

    public func showRewarded(_ placement: RewardedPlacement) async -> RewardOutcome {
        // "Reklamsız" alan oyuncuya ödüllü teklifler tek dokunuşla ücretsiz
        // verilir (§6.7) — reklam hiç istenmez.
        if hasRemoveAds { return .watched }
        guard let ad = rewarded[placement], let controller = Self.topViewController() else {
            return fallback.resolveFailedLoad(now: Date())
        }
        rewarded[placement] = nil
        var granted = false
        ad.present(from: controller) { granted = true }
        preloadRewarded(placement)
        return granted ? .watched : .dismissed
    }

    public func shouldShowBanner(on surface: AdSurface) -> Bool {
        !hasRemoveAds && surface.allowsBanner
    }

    #if canImport(UIKit)
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var controller = scene?.keyWindow?.rootViewController
        while let presented = controller?.presentedViewController { controller = presented }
        return controller
    }
    #else
    private static func topViewController() -> Never? { nil }
    #endif
}
#endif
