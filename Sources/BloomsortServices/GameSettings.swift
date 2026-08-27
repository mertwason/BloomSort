import Foundation

/// Oyuncu ayarları (`docs/ui-spec.md` §3.12).
///
/// `UserDefaults`'ta tutuluyor (`docs/gdd.md` §8.1): küçük, sık okunan,
/// ilişkisiz veriler. SwiftData'ya bağlı olmadığı için burada test edilebiliyor
/// ve gizlilik manifestindeki `CA92.1` beyanının tek sebebi bu.
public struct GameSettings: Codable, Equatable, Sendable {
    public var soundEnabled: Bool
    public var musicEnabled: Bool
    public var hapticsEnabled: Bool
    /// Sistem ayarından **bağımsız** oyun içi anahtar (`CLAUDE.md`).
    /// Sunum katmanı bunu `UIAccessibility.isReduceMotionEnabled` ile
    /// birleştirir: ikisinden biri açıksa hareket azaltılır.
    public var reduceMotion: Bool
    public var colorBlindMode: Bool

    public init(soundEnabled: Bool = true, musicEnabled: Bool = true,
                hapticsEnabled: Bool = true, reduceMotion: Bool = false,
                colorBlindMode: Bool = false) {
        self.soundEnabled = soundEnabled
        self.musicEnabled = musicEnabled
        self.hapticsEnabled = hapticsEnabled
        self.reduceMotion = reduceMotion
        self.colorBlindMode = colorBlindMode
    }

    public static let storageKey = "bloomsort.settings"

    public static func load(from defaults: UserDefaults = .standard) -> GameSettings {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(GameSettings.self, from: data)
        else { return GameSettings() }
        return decoded
    }

    public func save(to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
