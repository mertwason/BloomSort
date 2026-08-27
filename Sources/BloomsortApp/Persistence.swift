#if canImport(SwiftData)
import BloomsortServices
import Foundation
import SwiftData

/// SwiftData kalıcılık şeması (`docs/gdd.md` §8.1).
///
/// Profil, koleksiyon ve ayarlar burada; uygulama kapanıp açılınca ilerleme
/// korunuyor (lansman checklist'i Faz 3).
@Model
public final class PlayerProfile {
    /// Tek satır: profil.
    public var seeds: Int
    public var bees: Int
    public var streakDays: Int
    public var lastPlayedDay: Date?
    public var hasRemoveAds: Bool
    public var installDate: Date
    /// Reklam/rıza durumu.
    public var trackingRequested: Bool
    public var lastAppOpenAd: Date?

    @Relationship(deleteRule: .cascade)
    public var plates: [CollectedPlate]

    public init(seeds: Int = 0, bees: Int = Economy.startingBees, streakDays: Int = 0,
                lastPlayedDay: Date? = nil, hasRemoveAds: Bool = false,
                installDate: Date = Date(), trackingRequested: Bool = false,
                lastAppOpenAd: Date? = nil, plates: [CollectedPlate] = []) {
        self.seeds = seeds
        self.bees = bees
        self.streakDays = streakDays
        self.lastPlayedDay = lastPlayedDay
        self.hasRemoveAds = hasRemoveAds
        self.installDate = installDate
        self.trackingRequested = trackingRequested
        self.lastAppOpenAd = lastAppOpenAd
        self.plates = plates
    }
}

/// Toplanan botanik levha (§5.1).
@Model
public final class CollectedPlate {
    @Attribute(.unique) public var levelID: Int
    public var stars: Int
    public var bestMoves: Int
    public var speciesName: String
    public var discoveredAt: Date

    public init(levelID: Int, stars: Int, bestMoves: Int,
                speciesName: String, discoveredAt: Date = Date()) {
        self.levelID = levelID
        self.stars = stars
        self.bestMoves = bestMoves
        self.speciesName = speciesName
        self.discoveredAt = discoveredAt
    }
}

/// SwiftData ↔ saf `Progress` köprüsü. Oyun mantığı saf tip üzerinden çalışır
/// (Linux'ta test edilebilsin), kalıcılık burada.
public enum ProgressStore {
    public static func read(_ profile: PlayerProfile) -> Progress {
        var stars: [Int: Int] = [:]
        var bestMoves: [Int: Int] = [:]
        for plate in profile.plates {
            stars[plate.levelID] = plate.stars
            bestMoves[plate.levelID] = plate.bestMoves
        }
        return Progress(stars: stars, bestMoves: bestMoves,
                        seeds: profile.seeds, bees: profile.bees,
                        streakDays: profile.streakDays, hasRemoveAds: profile.hasRemoveAds)
    }

    public static func write(_ progress: Progress, to profile: PlayerProfile,
                             naming: PlateNaming = PlateNaming(), now: Date = Date()) {
        profile.seeds = progress.seeds
        profile.bees = progress.bees
        profile.streakDays = progress.streakDays
        profile.hasRemoveAds = progress.hasRemoveAds
        for (levelID, stars) in progress.stars {
            if let existing = profile.plates.first(where: { $0.levelID == levelID }) {
                existing.stars = max(existing.stars, stars)
                existing.bestMoves = min(existing.bestMoves, progress.bestMoves[levelID] ?? existing.bestMoves)
            } else {
                profile.plates.append(CollectedPlate(
                    levelID: levelID,
                    stars: stars,
                    bestMoves: progress.bestMoves[levelID] ?? 0,
                    speciesName: naming.name(forLevel: levelID),
                    discoveredAt: now))
            }
        }
    }
}
#endif
