import XCTest
@testable import BloomsortServices

final class EconomyTests: XCTestCase {
    func testSeviyeOdulleriEkAdakiDegerler() {
        XCTAssertEqual(Economy.seedReward(stars: 3), 15)
        XCTAssertEqual(Economy.seedReward(stars: 2), 10)
        XCTAssertEqual(Economy.seedReward(stars: 1), 6)
    }

    func testSeriCarpanlari() {
        XCTAssertEqual(Economy.streakMultiplier(days: 0), 1.0)
        XCTAssertEqual(Economy.streakMultiplier(days: 3), 1.2)
        XCTAssertEqual(Economy.streakMultiplier(days: 7), 1.5)
        XCTAssertEqual(Economy.streakMultiplier(days: 14), 2.0)
        XCTAssertEqual(Economy.streakMultiplier(days: 30), 3.0)
        XCTAssertEqual(Economy.streakMultiplier(days: 365), 3.0)
    }

    func testSeriCarpaniOduleUygulaniyor() {
        XCTAssertEqual(Economy.seedReward(stars: 3, streakDays: 7), 23)  // 15 × 1,5
        XCTAssertEqual(Economy.seedReward(stars: 1, streakDays: 30), 18) // 6 × 3
    }

    func testIAPUrunleri() {
        XCTAssertEqual(StoreProduct.allCases.count, 6)
        XCTAssertTrue(StoreProduct.bees60.isConsumable)
        XCTAssertFalse(StoreProduct.removeAds.isConsumable)
        XCTAssertEqual(StoreProduct.bees200.beeGrant, 200)
        XCTAssertTrue(StoreProduct.starter.grantsRemoveAds, "başlangıç paketi reklamsız içerir")
    }
}

final class HerbariumTests: XCTestCase {
    func testOnIkiLevhaBirAlbum() {
        XCTAssertEqual(Herbarium.albumIndex(forLevel: 1), 0)
        XCTAssertEqual(Herbarium.albumIndex(forLevel: 12), 0)
        XCTAssertEqual(Herbarium.albumIndex(forLevel: 13), 1)
        XCTAssertEqual(Herbarium.plateIndexInAlbum(forLevel: 13), 0)
    }

    func testAlbumTamamlama() {
        XCTAssertTrue(Herbarium.completesAlbum(level: 12))
        XCTAssertFalse(Herbarium.completesAlbum(level: 13))
        XCTAssertTrue(Herbarium.completesAlbum(level: 24))
    }

    func testAlbumIlerlemeEtiketi() {
        XCTAssertEqual(Herbarium.progressLabel(forLevel: 11), "Çayır · 11/12")
        XCTAssertEqual(Herbarium.progressLabel(forLevel: 13), "Orman Altı · 1/12")
    }

    func testIsimsizAlbumlerIsaretli() {
        XCTAssertTrue(Herbarium.hasName(0))
        XCTAssertTrue(Herbarium.hasName(7))
        XCTAssertFalse(Herbarium.hasName(8), "GDD 8 biyom sayıyor, gerisi açık")
        XCTAssertEqual(Herbarium.albumName(8), "Bölge 9")
    }

    func testLansmanPaketiOnYediAlbumEdiyor() {
        // 200 seviye / 12 = 17 albüm (§9.1).
        XCTAssertEqual(Herbarium.albumIndex(forLevel: 200) + 1, 17)
    }

    func testLevhaAdlariDeterministVeCesitli() {
        let naming = PlateNaming()
        XCTAssertEqual(naming.name(forLevel: 1), naming.name(forLevel: 1))
        let names = Set((1...200).map { naming.name(forLevel: $0) })
        XCTAssertGreaterThan(names.count, 150, "200 seviyede adlar büyük ölçüde farklı olmalı")
        XCTAssertTrue(naming.name(forLevel: 5).contains(" "), "Cins + tür")
        XCTAssertGreaterThan(naming.capacity, 400)
    }
}

final class ProgressTests: XCTestCase {
    func testBaslangicDurumu() {
        let progress = Progress()
        XCTAssertEqual(progress.currentLevel, 1)
        XCTAssertEqual(progress.bees, 5, "başlangıç arısı Ek A'dan")
        XCTAssertEqual(progress.seeds, 0)
        XCTAssertTrue(progress.isUnlocked(1))
        XCTAssertFalse(progress.isUnlocked(2))
    }

    func testSeviyeTamamlamaTohumVeriyor() {
        var progress = Progress()
        let reward = progress.complete(level: 1, stars: 3, moves: 10)
        XCTAssertEqual(reward, 15)
        XCTAssertEqual(progress.seeds, 15)
        XCTAssertEqual(progress.currentLevel, 2)
        XCTAssertEqual(progress.totalStars, 3)
    }

    func testDahaKotuSonucKaydiDusurmuyor() {
        var progress = Progress()
        progress.complete(level: 1, stars: 3, moves: 10)
        progress.complete(level: 1, stars: 1, moves: 25)
        XCTAssertEqual(progress.stars[1], 3, "yıldız düşmez")
        XCTAssertEqual(progress.bestMoves[1], 10, "en iyi hamle korunur")
    }

    func testAlbumTamamlamaBonusu() {
        var progress = Progress()
        for level in 1...11 { progress.complete(level: level, stars: 2, moves: 20) }
        let seedsBefore = progress.seeds
        let beesBefore = progress.bees
        progress.complete(level: 12, stars: 2, moves: 20)
        XCTAssertEqual(progress.seeds, seedsBefore + 10 + Economy.albumSeedReward)
        XCTAssertEqual(progress.bees, beesBefore + Economy.albumBeeReward)
    }

    func testAriVeTohumHarcama() {
        var progress = Progress(seeds: 100, bees: 1)
        XCTAssertTrue(progress.spendBee())
        XCTAssertFalse(progress.spendBee(), "arı bitti")
        XCTAssertTrue(progress.spendSeeds(100))
        XCTAssertFalse(progress.spendSeeds(1))
    }
}

final class OnboardingTests: XCTestCase {
    func testOgreticiIpuclariSpecdekiSeviyelerde() {
        XCTAssertEqual(Onboarding.hint(forLevel: 1), .tapToTap)
        XCTAssertEqual(Onboarding.hint(forLevel: 2), .bulkTransfer)
        XCTAssertEqual(Onboarding.hint(forLevel: 3), .emptyAndBloom)
        XCTAssertEqual(Onboarding.hint(forLevel: 4), .undo)
        XCTAssertEqual(Onboarding.hint(forLevel: 8), .bee)
        XCTAssertNil(Onboarding.hint(forLevel: 9))
    }

    func testIlkBesSeviyeTemiz() {
        for level in 1...5 { XCTAssertTrue(Onboarding.isCleanLevel(level)) }
        XCTAssertFalse(Onboarding.isCleanLevel(6))
        XCTAssertEqual(Onboarding.attRequestLevel, 5)
    }

    func testOnboardingSeviyelerindeInterstitialYok() {
        // §6.2 kural 1 zaten seviye < 8'i kesiyor; onboarding bunun içinde.
        for level in 1...5 {
            let context = InterstitialContext(level: level, stars: 3,
                                              now: Date(timeIntervalSince1970: 1_800_000_000),
                                              sessionStart: Date(timeIntervalSince1970: 1_799_999_000))
            XCTAssertFalse(InterstitialPolicy.canShowInterstitial(context: context))
        }
    }
}

final class AnalyticsTests: XCTestCase {
    func testOlaySemasiGDDdekiOnOlay() {
        let events: [AnalyticsEvent] = [
            .levelStart(levelID: 1, attempt: 1, beesOwned: 5, seed: 42),
            .levelComplete(levelID: 1, moves: 12, optimalMoves: 10, stars: 2,
                           durationMilliseconds: 45_000, undos: 1, hints: 0, beesUsed: 0),
            .levelAbandon(levelID: 2, moves: 3, durationMilliseconds: 9_000, lastAction: "undo"),
            .beeSpend(source: .rewarded, levelID: 3),
            .adImpression(unit: "interstitial_level_end", placementID: "level_end",
                          levelID: 9, ecpmBucket: "mid"),
            .adRewardGrant(placementID: "rewarded_bee", fallback: true),
            .iapPurchase(productID: StoreProduct.removeAds.rawValue, priceLocal: 249.99, currency: "TRY"),
            .plateCollect(plateID: 12, albumID: 0, albumPercent: 1.0),
            .albumComplete(albumID: 0, daysSinceInstall: 3),
            .streakChange(value: 7, direction: .up),
            .seasonTierUp(tier: 12, isPassHolder: false),
        ]
        XCTAssertEqual(Set(events.map(\.name)).count, 11)
        for event in events {
            XCTAssertFalse(event.name.isEmpty)
            XCTAssertFalse(event.parameters.isEmpty)
        }
    }

    func testOlayAdlariSpecdekiYazimla() {
        XCTAssertEqual(AnalyticsEvent.levelStart(levelID: 1, attempt: 1, beesOwned: 0, seed: 0).name,
                       "level_start")
        XCTAssertEqual(AnalyticsEvent.plateCollect(plateID: 1, albumID: 0, albumPercent: 0).name,
                       "plate_collect")
    }

    func testSahteAnalitikOlaylariTutuyor() {
        let analytics = FakeAnalyticsService()
        analytics.log(.streakChange(value: 3, direction: .up))
        analytics.setUserProperty("true", forKey: "remove_ads")
        XCTAssertEqual(analytics.events.count, 1)
        XCTAssertEqual(analytics.properties["remove_ads"], "true")
    }

    func testRemoteConfigVarsayilanlariReklamKurallariylaAyni() {
        let defaults = RemoteConfigDefaults.embedded
        XCTAssertEqual(defaults.interstitialCooldown, 90)
        XCTAssertEqual(defaults.interstitialMinimumLevel, 8)
        XCTAssertEqual(defaults.interstitialHourlyCap, 6)
    }
}

final class AudioTests: XCTestCase {
    func testNotaDerinlikleYukseliyor() {
        let scale = PentatonicScale()
        let frequencies = (0..<8).map { scale.frequency(forDepth: $0) }
        XCTAssertEqual(frequencies, frequencies.sorted(), "derinlik arttıkça nota yükselmeli")
    }

    func testKokNotaD4() {
        let scale = PentatonicScale()
        XCTAssertEqual(scale.frequency(forDepth: 0), 293.6648, accuracy: 0.001)
        XCTAssertEqual(scale.noteName(forDepth: 0), "D4")
    }

    func testBesNotadanSonraOktavDevamEdiyor() {
        let scale = PentatonicScale()
        // Altıncı tane, ilk notanın bir oktav üstü.
        XCTAssertEqual(scale.frequency(forDepth: 5), scale.frequency(forDepth: 0) * 2, accuracy: 0.01)
        XCTAssertEqual(scale.noteName(forDepth: 5), "D5")
    }

    func testDiziPentatonikYarimSesIcermiyor() {
        // Pentatoniğin bütün mesele ettiği şey bu: hangi notalar üst üste
        // binerse binsin uyumlu kalsın.
        let offsets = PentatonicScale.semitoneOffsets
        for (low, high) in zip(offsets, offsets.dropFirst()) {
            XCTAssertGreaterThanOrEqual(high - low, 2, "yarım ses aralığı olmamalı")
        }
    }

    func testSessizModNotaCalmiyor() {
        let audio = FakeAudioEngine()
        audio.isMuted = true
        audio.playBeadLanded(depth: 2)
        audio.play(.bloom)
        XCTAssertTrue(audio.playedEffects.isEmpty)
    }

    func testHaptikAyriKapatilabiliyor() {
        let haptics = FakeHapticEngine()
        haptics.isEnabled = false
        haptics.play(.bloomed)
        XCTAssertTrue(haptics.played.isEmpty)
        haptics.isEnabled = true
        haptics.play(.bloomed)
        XCTAssertEqual(haptics.played, [.bloomed])
    }

    func testHaptikHaritasiUISpecleAyni() {
        XCTAssertEqual(HapticKind.allCases.count, 7)
        XCTAssertEqual(HapticKind.vesselSelected.intensity, 0.4)
        XCTAssertEqual(HapticKind.platePressed.intensity, 1.0)
        XCTAssertNil(HapticKind.levelComplete.intensity, "bildirim haptiğinin şiddeti yok")
    }
}

final class GameSettingsTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suite = UserDefaults(suiteName: "bloomsort.tests.\(UUID().uuidString)")!
        return suite
    }

    func testVarsayilanlarSesAcikHaptikAcik() {
        let settings = GameSettings()
        XCTAssertTrue(settings.soundEnabled)
        XCTAssertTrue(settings.hapticsEnabled)
        XCTAssertFalse(settings.reduceMotion)
        XCTAssertFalse(settings.colorBlindMode)
    }

    func testKaydetVeYukle() {
        let defaults = makeDefaults()
        var settings = GameSettings()
        settings.colorBlindMode = true
        settings.hapticsEnabled = false
        settings.save(to: defaults)
        let loaded = GameSettings.load(from: defaults)
        XCTAssertEqual(loaded, settings)
    }

    func testBozukVeriVarsayilanaDonuyor() {
        let defaults = makeDefaults()
        defaults.set(Data([0x00, 0x01]), forKey: GameSettings.storageKey)
        XCTAssertEqual(GameSettings.load(from: defaults), GameSettings())
    }

    func testHaptikSestenBagimsiz() {
        var settings = GameSettings()
        settings.soundEnabled = false
        XCTAssertTrue(settings.hapticsEnabled, "haptik ayrı kapatılır")
    }
}
