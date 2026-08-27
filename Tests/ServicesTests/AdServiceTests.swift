import XCTest
@testable import BloomsortServices

final class AdServiceTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    // MARK: - Banner yerleşimi

    func testOyunTahtasindaHicbirReklamYuzeyiYok() {
        XCTAssertFalse(AdSurface.board.allowsBanner)
        XCTAssertFalse(AdSurface.path.allowsBanner)
        XCTAssertFalse(AdSurface.levelComplete.allowsBanner)
        XCTAssertFalse(AdSurface.onboarding.allowsBanner)
    }

    func testBannerYalnizcaMetaEkranlarinda() {
        let allowed = AdSurface.allCases.filter(\.allowsBanner)
        XCTAssertEqual(Set(allowed), [.herbarium, .garden, .hive, .settings, .season])
    }

    // MARK: - Ödül telafisi

    func testReklamYuklenemezseOdulYineDeVerilir() {
        var policy = RewardFallbackPolicy(day: now)
        for _ in 0..<RewardFallbackPolicy.dailyGrants {
            XCTAssertEqual(policy.resolveFailedLoad(now: now), .grantedWithoutAd)
        }
        XCTAssertEqual(policy.resolveFailedLoad(now: now), .unavailable,
                       "günlük hak dolunca telafi bitmeli")
    }

    func testTelafiHakkiErtesiGunSifirlanir() {
        var policy = RewardFallbackPolicy(day: now)
        for _ in 0..<RewardFallbackPolicy.dailyGrants { _ = policy.resolveFailedLoad(now: now) }
        let tomorrow = now.addingTimeInterval(26 * 3600)
        XCTAssertEqual(policy.resolveFailedLoad(now: tomorrow), .grantedWithoutAd)
    }

    // MARK: - App Open

    func testAppOpenD0daGosterilmez() {
        XCTAssertFalse(AppOpenPolicy.canShowAppOpen(isColdStart: true, now: now,
                                                    installDate: now.addingTimeInterval(-3600),
                                                    lastAppOpen: nil, hasRemoveAds: false))
    }

    func testAppOpenDortSaatteBirKez() {
        let installDate = now.addingTimeInterval(-3 * 24 * 3600)
        XCTAssertFalse(AppOpenPolicy.canShowAppOpen(isColdStart: true, now: now,
                                                    installDate: installDate,
                                                    lastAppOpen: now.addingTimeInterval(-3599 * 3),
                                                    hasRemoveAds: false))
        XCTAssertTrue(AppOpenPolicy.canShowAppOpen(isColdStart: true, now: now,
                                                   installDate: installDate,
                                                   lastAppOpen: now.addingTimeInterval(-4 * 3600),
                                                   hasRemoveAds: false))
    }

    func testAppOpenYalnizcaSogukBaslatmada() {
        let installDate = now.addingTimeInterval(-3 * 24 * 3600)
        XCTAssertFalse(AppOpenPolicy.canShowAppOpen(isColdStart: false, now: now,
                                                    installDate: installDate,
                                                    lastAppOpen: nil, hasRemoveAds: false))
    }

    func testAppOpenReklamsizSatinAlindiysaGosterilmez() {
        let installDate = now.addingTimeInterval(-3 * 24 * 3600)
        XCTAssertFalse(AppOpenPolicy.canShowAppOpen(isColdStart: true, now: now,
                                                    installDate: installDate,
                                                    lastAppOpen: nil, hasRemoveAds: true))
    }

    // MARK: - Sahte servis

    func testHazirDegilseInterstitialAtlanir() async {
        let service = FakeAdService(now: now)
        service.interstitialReady = false
        let shown = await service.showInterstitial()
        XCTAssertFalse(shown, "hazır değilse bekleme ekranı değil, atlama")
        XCTAssertEqual(service.interstitialsShown, 0)
    }

    func testOdulluReklamYuklenemezseTelafi() async {
        let service = FakeAdService(now: now)
        service.rewardedReady = false
        let outcome = await service.showRewarded(.extraBee)
        XCTAssertEqual(outcome, .grantedWithoutAd)
    }

    func testOdulluReklamIzlenince() async {
        let service = FakeAdService(now: now)
        let outcome = await service.showRewarded(.hint)
        XCTAssertEqual(outcome, .watched)
        XCTAssertEqual(service.rewardedShown, [.hint])
    }
}

final class ConsentTests: XCTestCase {
    func testATTBesinciSeviyeSonundaIsteniyor() {
        for level in 1...4 {
            XCTAssertFalse(TrackingPrompt.shouldRequest(afterCompletingLevel: level,
                                                        alreadyRequested: false),
                           "seviye \(level): erken istenmemeli")
        }
        XCTAssertTrue(TrackingPrompt.shouldRequest(afterCompletingLevel: 5, alreadyRequested: false))
    }

    func testATTBirKezIsteniyor() {
        XCTAssertFalse(TrackingPrompt.shouldRequest(afterCompletingLevel: 9, alreadyRequested: true))
    }

    func testRizaAlinmadanReklamIstenmiyor() {
        let consent = FakeConsentService()
        consent.state.canRequestAds = false
        XCTAssertFalse(consent.state.canRequestAds)
    }
}

final class StoreTests: XCTestCase {
    func testGeriYuklemeVar() async {
        let store = FakeIAPService()
        _ = await store.purchase(.removeAds)
        let restored = await store.restorePurchases()
        XCTAssertTrue(restored)
        XCTAssertEqual(store.restoreCallCount, 1)
    }

    func testReklamsizSatinAlmaHakkiVeriyor() async {
        let store = FakeIAPService()
        XCTAssertFalse(store.hasRemoveAds)
        _ = await store.purchase(.removeAds)
        XCTAssertTrue(store.hasRemoveAds)
    }

    func testBaslangicPaketiDeReklamsizVeriyor() async {
        let store = FakeIAPService()
        _ = await store.purchase(.starter)
        XCTAssertTrue(store.hasRemoveAds)
    }

    func testIptalEdilenSatinAlmaHakVermez() async {
        let store = FakeIAPService()
        store.nextOutcome = .cancelled
        let outcome = await store.purchase(.removeAds)
        XCTAssertEqual(outcome, .cancelled)
        XCTAssertFalse(store.hasRemoveAds)
    }

    func testHataMesajlariSpecdekiMetinler() {
        XCTAssertEqual(StoreMessage.purchaseFailed, "Satın alma tamamlanmadı. Ücret alınmadı.")
        XCTAssertEqual(StoreMessage.restoreEmpty,
                       "Bu Apple Kimliği'nde geri yüklenecek satın alma yok.")
    }
}
