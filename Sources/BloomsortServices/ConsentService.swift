import Foundation

/// Rıza durumu — GDPR/TCF v2.2 (UMP) ve ATT.
public struct ConsentState: Sendable, Equatable {
    /// UMP: reklam isteyebilir miyiz?
    public var canRequestAds: Bool
    /// UMP gizlilik seçenekleri girişi gösterilebilir mi? (Ayarlar → "Reklam
    /// tercihlerini yönet", lansman checklist'i Faz 4.2)
    public var privacyOptionsRequired: Bool
    /// ATT izni istendi mi?
    public var trackingRequested: Bool
    /// ATT izni verildi mi?
    public var trackingAuthorized: Bool

    public init(canRequestAds: Bool = false, privacyOptionsRequired: Bool = false,
                trackingRequested: Bool = false, trackingAuthorized: Bool = false) {
        self.canRequestAds = canRequestAds
        self.privacyOptionsRequired = privacyOptionsRequired
        self.trackingRequested = trackingRequested
        self.trackingAuthorized = trackingAuthorized
    }
}

/// Rıza servisinin sözleşmesi.
public protocol ConsentServiceProtocol: AnyObject {
    var state: ConsentState { get }
    /// Açılışta: rıza bilgisini tazele, gerekiyorsa formu göster.
    func requestConsentInfoUpdate() async
    /// Ayarlardan çağrılır: UMP gizlilik seçenekleri formu.
    func presentPrivacyOptions() async
    /// ATT izni — **5. seviye sonunda**, açılışta değil (§6.6).
    func requestTrackingAuthorization() async
}

/// ATT'nin ne zaman isteneceği (`docs/gdd.md` §6.6, `docs/ui-spec.md` §3.2).
public enum TrackingPrompt {
    /// İzin 5. seviye **sonunda** istenir; öncesinde neden ekranı gösterilir.
    public static func shouldRequest(afterCompletingLevel level: Int,
                                     alreadyRequested: Bool) -> Bool {
        !alreadyRequested && level >= Onboarding.attRequestLevel
    }
}

public final class FakeConsentService: ConsentServiceProtocol, @unchecked Sendable {
    public var state = ConsentState(canRequestAds: true)
    public private(set) var infoUpdateCount = 0
    public private(set) var privacyOptionsShown = 0
    public private(set) var trackingRequests = 0

    public init() {}

    public func requestConsentInfoUpdate() async { infoUpdateCount += 1 }
    public func presentPrivacyOptions() async { privacyOptionsShown += 1 }
    public func requestTrackingAuthorization() async {
        trackingRequests += 1
        state.trackingRequested = true
    }
}
