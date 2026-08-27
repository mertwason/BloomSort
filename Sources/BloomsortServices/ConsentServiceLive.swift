#if canImport(UserMessagingPlatform)
import Foundation
import UserMessagingPlatform
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Google UMP + ATT rıza akışı (lansman checklist'i Faz 4.2).
///
/// Her açılışta `requestConsentInfoUpdate`, gerekiyorsa form, reklam
/// istemeden önce `canRequestAds` kontrolü.
@MainActor
public final class ConsentService: ConsentServiceProtocol {
    public private(set) var state = ConsentState()

    public init() {}

    public func requestConsentInfoUpdate() async {
        let parameters = RequestParameters()
        await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { _ in
                continuation.resume()
            }
        }
        await loadAndPresentIfRequired()
        state.canRequestAds = ConsentInformation.shared.canRequestAds
        state.privacyOptionsRequired =
            ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private func loadAndPresentIfRequired() async {
        guard let controller = Self.topViewController() else { return }
        await withCheckedContinuation { continuation in
            ConsentForm.loadAndPresentIfRequired(from: controller) { _ in
                continuation.resume()
            }
        }
    }

    public func presentPrivacyOptions() async {
        guard let controller = Self.topViewController() else { return }
        await withCheckedContinuation { continuation in
            ConsentForm.presentPrivacyOptionsForm(from: controller) { _ in
                continuation.resume()
            }
        }
    }

    public func requestTrackingAuthorization() async {
        #if canImport(AppTrackingTransparency)
        let status = await ATTrackingManager.requestTrackingAuthorization()
        state.trackingRequested = true
        state.trackingAuthorized = status == .authorized
        #else
        state.trackingRequested = true
        #endif
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
