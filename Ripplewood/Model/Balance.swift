import Foundation

/// Every tuning knob in one place.
///
/// Targets: first upgrade (60 coins) within ~2 minutes; all ten upgrades (29,440 coins)
/// in ~3–5 hours of play; Golden Koi only after full restoration. A simple Monte-Carlo of
/// this table (85% catch rate, 30% perfects, real-world time/weather mix) puts full
/// restoration at ~4 hours of active play, before idle rewards.
enum Balance {
    // Timing (seconds after the bite)
    static let perfectWindow: Double = 0.28
    static let goodWindow: Double = 0.65

    // Waiting for a bite
    static let waitRange: ClosedRange<Double> = 2.0...8.0
    static let maxWaitReduction: Double = 0.4

    // Coins
    static let perfectCoinBonus: Double = 0.25

    // Fish selection
    static let legendaryChance: Double = 0.01

    static func tierWeight(_ rarity: Rarity, effects: UpgradeEffect) -> Double {
        switch rarity {
        case .common: 70
        case .uncommon: 22 * (1 + effects.uncommonBoost)
        case .rare: 8 * (1 + effects.rareBoost)
        case .legendary: 0 // rolled separately
        }
    }

    // Idle rewards
    static let idleCap: TimeInterval = 8 * 3600
    static let idleMinimum: TimeInterval = 10 * 60
    static let idleCoinsPerMinute: Double = 0.25
    static let idleMinutesPerFish: Double = 45
    static let idleMaxFish = 6

    // UI
    static let catchCardDuration: TimeInterval = 3.5
}
