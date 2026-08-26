import XCTest
@testable import BloomsortServices

/// `docs/gdd.md` §6.2 — sekiz kuralın her biri için ayrı test
/// (`CLAUDE.md`: "her kural için ayrı bir birim test yazılır").
final class InterstitialPolicyTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    /// Bütün kuralların geçtiği temel bağlam. Her test yalnızca ilgilendiği
    /// alanı bozar, böylece hangi kuralın engellediği net olur.
    private func passingContext() -> InterstitialContext {
        InterstitialContext(level: 12,
                            stars: 3,
                            now: now,
                            sessionStart: now.addingTimeInterval(-600),
                            lastInterstitial: now.addingTimeInterval(-200),
                            lastRewarded: now.addingTimeInterval(-300),
                            shownOnPreviousLevel: false,
                            recentImpressions: [now.addingTimeInterval(-200)],
                            hasRemoveAds: false)
    }

    func testTemelBaglamGosterimeIzinVerir() {
        XCTAssertTrue(InterstitialPolicy.canShowInterstitial(context: passingContext()))
        XCTAssertEqual(InterstitialPolicy.blockingRules(context: passingContext()), [])
    }

    // 1. Seviye ≥ 8
    func testKural1SekizinciSeviyedenOnceGosterilmez() {
        var context = passingContext()
        context = InterstitialContext(level: 7, stars: context.stars, now: context.now,
                                      sessionStart: context.sessionStart,
                                      lastInterstitial: context.lastInterstitial,
                                      lastRewarded: context.lastRewarded,
                                      recentImpressions: context.recentImpressions)
        XCTAssertTrue(InterstitialRule.minimumLevel.blocks(context))
        XCTAssertFalse(InterstitialPolicy.canShowInterstitial(context: context))

        let atBoundary = InterstitialContext(level: 8, stars: 3, now: now,
                                             sessionStart: now.addingTimeInterval(-600),
                                             lastInterstitial: now.addingTimeInterval(-200),
                                             lastRewarded: now.addingTimeInterval(-300),
                                             recentImpressions: [now.addingTimeInterval(-200)])
        XCTAssertFalse(InterstitialRule.minimumLevel.blocks(atBoundary))
    }

    // 2. Son interstitial'dan ≥ 90 sn
    func testKural2DoksanSaniyeBekleme() {
        let tooSoon = InterstitialContext(level: 12, stars: 3, now: now,
                                          sessionStart: now.addingTimeInterval(-600),
                                          lastInterstitial: now.addingTimeInterval(-89),
                                          recentImpressions: [now.addingTimeInterval(-89)])
        XCTAssertTrue(InterstitialRule.cooldown.blocks(tooSoon))

        let justEnough = InterstitialContext(level: 12, stars: 3, now: now,
                                             sessionStart: now.addingTimeInterval(-600),
                                             lastInterstitial: now.addingTimeInterval(-90),
                                             recentImpressions: [now.addingTimeInterval(-90)])
        XCTAssertFalse(InterstitialRule.cooldown.blocks(justEnough))
    }

    func testKural2HicGosterimYoksaEngellemez() {
        let fresh = InterstitialContext(level: 12, stars: 3, now: now,
                                        sessionStart: now.addingTimeInterval(-600))
        XCTAssertFalse(InterstitialRule.cooldown.blocks(fresh))
    }

    // 3. Son 45 sn içinde rewarded izlenmemiş
    func testKural3OdulluReklamdanSonraKirkBesSaniye() {
        let tooSoon = InterstitialContext(level: 12, stars: 3, now: now,
                                          sessionStart: now.addingTimeInterval(-600),
                                          lastRewarded: now.addingTimeInterval(-44))
        XCTAssertTrue(InterstitialRule.rewardedCooldown.blocks(tooSoon))

        let fine = InterstitialContext(level: 12, stars: 3, now: now,
                                       sessionStart: now.addingTimeInterval(-600),
                                       lastRewarded: now.addingTimeInterval(-45))
        XCTAssertFalse(InterstitialRule.rewardedCooldown.blocks(fine))
    }

    // 4. Arka arkaya iki seviyede gösterilmez
    func testKural4ArkaArkayaGosterilmez() {
        let context = InterstitialContext(level: 12, stars: 3, now: now,
                                          sessionStart: now.addingTimeInterval(-600),
                                          shownOnPreviousLevel: true)
        XCTAssertTrue(InterstitialRule.notBackToBack.blocks(context))
        XCTAssertFalse(InterstitialPolicy.canShowInterstitial(context: context))
    }

    // 5. 1★ ile biten seviyeden sonra gösterilmez
    func testKural5TekYildizdanSonraGosterilmez() {
        var blocked = passingContext()
        blocked = InterstitialContext(level: blocked.level, stars: 1, now: blocked.now,
                                      sessionStart: blocked.sessionStart,
                                      lastInterstitial: blocked.lastInterstitial,
                                      lastRewarded: blocked.lastRewarded,
                                      recentImpressions: blocked.recentImpressions)
        XCTAssertTrue(InterstitialRule.notAfterOneStar.blocks(blocked))

        for stars in [2, 3] {
            let allowed = InterstitialContext(level: 12, stars: stars, now: now,
                                              sessionStart: now.addingTimeInterval(-600))
            XCTAssertFalse(InterstitialRule.notAfterOneStar.blocks(allowed))
        }
    }

    // 6. Saatte en fazla 6
    func testKural6SaatlikTavan() {
        let sixInTheLastHour = (1...6).map { now.addingTimeInterval(-Double($0) * 300) }
        let blocked = InterstitialContext(level: 12, stars: 3, now: now,
                                          sessionStart: now.addingTimeInterval(-7200),
                                          recentImpressions: sixInTheLastHour)
        XCTAssertTrue(InterstitialRule.hourlyCap.blocks(blocked))

        // Bir saatten eski gösterimler sayılmaz.
        let aged = sixInTheLastHour.map { $0.addingTimeInterval(-3600) }
        let allowed = InterstitialContext(level: 12, stars: 3, now: now,
                                          sessionStart: now.addingTimeInterval(-7200),
                                          recentImpressions: aged)
        XCTAssertFalse(InterstitialRule.hourlyCap.blocks(allowed))
    }

    func testKural6BesGosterimEngellemez() {
        let five = (1...5).map { now.addingTimeInterval(-Double($0) * 300) }
        let context = InterstitialContext(level: 12, stars: 3, now: now,
                                          sessionStart: now.addingTimeInterval(-7200),
                                          recentImpressions: five)
        XCTAssertFalse(InterstitialRule.hourlyCap.blocks(context))
    }

    // 7. Oturumun ilk 3 dakikasında en fazla 1
    func testKural7OturumAcilisiTavani() {
        let sessionStart = now.addingTimeInterval(-120)   // oturum 2 dakikalık
        let blocked = InterstitialContext(level: 12, stars: 3, now: now,
                                          sessionStart: sessionStart,
                                          recentImpressions: [sessionStart.addingTimeInterval(30)])
        XCTAssertTrue(InterstitialRule.sessionOpeningCap.blocks(blocked))

        let firstOfSession = InterstitialContext(level: 12, stars: 3, now: now,
                                                 sessionStart: sessionStart)
        XCTAssertFalse(InterstitialRule.sessionOpeningCap.blocks(firstOfSession))
    }

    func testKural7UcDakikaSonrasiSerbest() {
        let sessionStart = now.addingTimeInterval(-200)   // 3 dakikayı geçti
        let context = InterstitialContext(level: 12, stars: 3, now: now,
                                          sessionStart: sessionStart,
                                          recentImpressions: [sessionStart.addingTimeInterval(30)])
        XCTAssertFalse(InterstitialRule.sessionOpeningCap.blocks(context))
    }

    // 8. "Reklamsız" satın alındıysa hiç
    func testKural8ReklamsizSatinAlma() {
        let context = InterstitialContext(level: 12, stars: 3, now: now,
                                          sessionStart: now.addingTimeInterval(-600),
                                          hasRemoveAds: true)
        XCTAssertTrue(InterstitialRule.removeAdsPurchase.blocks(context))
        XCTAssertFalse(InterstitialPolicy.canShowInterstitial(context: context))
    }

    func testSekizKuralinHepsiSayilabiliyor() {
        XCTAssertEqual(InterstitialRule.allCases.count, 8)
    }

    func testBirdenFazlaKuralAyniAndaRaporlanir() {
        let context = InterstitialContext(level: 3, stars: 1, now: now,
                                          sessionStart: now.addingTimeInterval(-600),
                                          hasRemoveAds: true)
        let blocking = Set(InterstitialPolicy.blockingRules(context: context))
        XCTAssertEqual(blocking, [.minimumLevel, .notAfterOneStar, .removeAdsPurchase])
    }
}
