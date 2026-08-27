#if canImport(SwiftUI)
import BloomsortDesign
import BloomsortDomain
import BloomsortServices
import Foundation
import SwiftUI

/// Uygulamanın servis kabı.
///
/// Protokoller üzerinden bağlanır: önizlemede ve testte sahte servisler,
/// üründe gerçekleri. `CLAUDE.md`: gerçek SDK çağrıları ayrı implementasyonda.
@Observable
public final class AppEnvironment {
    public let levels: [Level]
    public var progress: Progress
    public var settings: GameSettings

    public let ads: AdServiceProtocol
    public let store: IAPServiceProtocol
    public let analytics: AnalyticsServiceProtocol
    public let audio: AudioEngineProtocol
    public let haptics: HapticEngineProtocol
    public let consent: ConsentServiceProtocol
    public let naming = PlateNaming()

    /// Oturum başlangıcı ve interstitial geçmişi — §6.2'nin bağlamı.
    public private(set) var sessionStart = Date()
    public private(set) var interstitialTimestamps: [Date] = []
    public private(set) var lastRewardedAt: Date?
    public private(set) var shownOnPreviousLevel = false

    public init(levels: [Level],
                progress: Progress = Progress(),
                settings: GameSettings = .load(),
                ads: AdServiceProtocol = FakeAdService(),
                store: IAPServiceProtocol = FakeIAPService(),
                analytics: AnalyticsServiceProtocol = FakeAnalyticsService(),
                audio: AudioEngineProtocol = FakeAudioEngine(),
                haptics: HapticEngineProtocol = FakeHapticEngine(),
                consent: ConsentServiceProtocol = FakeConsentService()) {
        self.levels = levels
        self.progress = progress
        self.settings = settings
        self.ads = ads
        self.store = store
        self.analytics = analytics
        self.audio = audio
        self.haptics = haptics
        self.consent = consent
    }

    public func level(_ id: Int) -> Level? {
        levels.first { $0.id == id }
    }

    /// Sunum ayarları — sahne bunları okur.
    public var presentation: BoardPresentation {
        BoardPresentation(colorBlindSymbols: settings.colorBlindMode,
                          reduceMotion: settings.reduceMotion)
    }

    // MARK: - Reklam bağlamı (§6.2)

    public func interstitialContext(level: Int, stars: Int, now: Date = Date()) -> InterstitialContext {
        InterstitialContext(level: level,
                            stars: stars,
                            now: now,
                            sessionStart: sessionStart,
                            lastInterstitial: interstitialTimestamps.last,
                            lastRewarded: lastRewardedAt,
                            shownOnPreviousLevel: shownOnPreviousLevel,
                            recentImpressions: interstitialTimestamps,
                            hasRemoveAds: progress.hasRemoveAds)
    }

    public func recordInterstitial(at date: Date = Date()) {
        interstitialTimestamps.append(date)
        // Bir saatten eski kayıtlar kurala girmiyor, tutmaya da gerek yok.
        interstitialTimestamps.removeAll { date.timeIntervalSince($0) > InterstitialPolicy.hourlyWindow }
        shownOnPreviousLevel = true
    }

    public func recordLevelWithoutInterstitial() { shownOnPreviousLevel = false }
    public func recordRewarded(at date: Date = Date()) { lastRewardedAt = date }
    public func beginSession(at date: Date = Date()) { sessionStart = date }

    // MARK: - Ses ve haptik

    public func play(_ haptic: HapticKind) {
        guard settings.hapticsEnabled else { return }
        haptics.play(haptic)
    }

    public func playSound(_ effect: SoundEffect) {
        guard settings.soundEnabled else { return }
        audio.play(effect)
    }

    public func playNote(depth: Int) {
        guard settings.soundEnabled else { return }
        audio.playBeadLanded(depth: depth)
    }
}

/// Uygulama sekmeleri (`docs/ui-spec.md` §3.0).
public enum AppTab: String, CaseIterable, Identifiable {
    case path, herbarium, garden, hive

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .path: return "Patika"
        case .herbarium: return "Herbaryum"
        case .garden: return "Bahçem"
        case .hive: return "Kovan"
        }
    }

    public var systemImage: String {
        switch self {
        case .path: return "leaf.fill"
        case .herbarium: return "book.closed.fill"
        case .garden: return "camera.macro"
        case .hive: return "drop.fill"
        }
    }

    /// Banner yalnızca meta ekranlarda (§4).
    public var adSurface: AdSurface {
        switch self {
        case .path: return .path
        case .herbarium: return .herbarium
        case .garden: return .garden
        case .hive: return .hive
        }
    }
}

/// Bundle'daki `levels.json`'ı okur.
public enum LevelLoader {
    public static func load(from bundle: Bundle = .main) -> [Level] {
        guard let url = bundle.url(forResource: "levels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let pack = try? JSONDecoder().decode(LevelPack.self, from: data)
        else { return [] }
        return pack.levels
    }
}
#endif
