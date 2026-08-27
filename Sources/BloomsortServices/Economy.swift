import Foundation

/// Ekonomi değerleri — `docs/gdd.md` Ek A. Hepsi tablodan, hiçbiri uydurma.
/// Remote Config ile ayarlanabilir olmaları planlandığı için tek yerde duruyorlar.
public enum Economy {
    /// Seviye ödülü: 3★ / 2★ / 1★ → 15 / 10 / 6 tohum.
    public static func seedReward(stars: Int) -> Int {
        switch stars {
        case 3: return 15
        case 2: return 10
        default: return 6
        }
    }

    /// Albüm tamamlama: 250 tohum + 5 arı + 1 bahçe bitkisi.
    public static let albumSeedReward = 250
    public static let albumBeeReward = 5
    public static let albumPlantReward = 1

    /// Günün Çiçeği: 40 tohum + 2 arı.
    public static let dailyFlowerSeeds = 40
    public static let dailyFlowerBees = 2

    /// Oyuncunun başlangıç arısı.
    public static let startingBees = 5

    /// Kozmetik fiyat aralığı (tohum).
    public static let cosmeticPriceRange = 400...1800

    /// Seri çarpanı: 3g ×1,2 · 7g ×1,5 · 14g ×2 · 30g ×3.
    public static func streakMultiplier(days: Int) -> Double {
        switch days {
        case ..<3:   return 1.0
        case 3..<7:  return 1.2
        case 7..<14: return 1.5
        case 14..<30: return 2.0
        default:     return 3.0
        }
    }

    /// Seri çarpanı uygulanmış ödül.
    public static func seedReward(stars: Int, streakDays: Int) -> Int {
        Int((Double(seedReward(stars: stars)) * streakMultiplier(days: streakDays)).rounded())
    }

    /// Seri kırılınca ayda bir ücretsiz onarım, bir de ödüllü videoyla ikinci hak.
    public static let freeStreakRepairsPerMonth = 1
    public static let rewardedStreakRepairsPerMonth = 1
}

/// IAP ürünleri — `docs/gdd.md` §6.7 ve lansman checklist'i Faz 5.
public enum StoreProduct: String, CaseIterable, Sendable {
    case removeAds = "com.mokka.bloomsort.removeads"
    case bees10    = "com.mokka.bloomsort.bees10"
    case bees60    = "com.mokka.bloomsort.bees60"
    case bees200   = "com.mokka.bloomsort.bees200"
    case season    = "com.mokka.bloomsort.season"
    case starter   = "com.mokka.bloomsort.starter"

    public var isConsumable: Bool {
        switch self {
        case .bees10, .bees60, .bees200: return true
        case .removeAds, .season, .starter: return false
        }
    }

    /// Tüketilebilir ürünlerin verdiği arı sayısı.
    public var beeGrant: Int {
        switch self {
        case .bees10: return 10
        case .bees60: return 60
        case .bees200: return 200
        case .starter: return 30
        default: return 0
        }
    }

    /// "Reklamsız" hakkı veren ürünler.
    public var grantsRemoveAds: Bool {
        self == .removeAds || self == .starter
    }
}
