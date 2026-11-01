import Foundation

enum FishPicker {
    static func eligible(_ conditions: PondConditions, owned: Set<UpgradeID>) -> [FishSpecies] {
        FishCatalog.all.filter { $0.conditions.isMet(by: conditions, owned: owned) }
    }

    /// Rolls a rarity tier (weighted, boosted by upgrades), then a fish within that tier.
    /// Tiers with no eligible fish under the current conditions are skipped.
    static func pick(conditions: PondConditions, owned: Set<UpgradeID>, effects: UpgradeEffect) -> FishSpecies {
        let pool = eligible(conditions, owned: owned)
        let fallback = FishCatalog.all[0]
        guard !pool.isEmpty else { return fallback }

        let legendaries = pool.filter { $0.rarity == .legendary }
        if !legendaries.isEmpty, Double.random(in: 0..<1) < Balance.legendaryChance,
           let legend = legendaries.randomElement() {
            return legend
        }

        var tiers: [(rarity: Rarity, weight: Double)] = []
        for rarity in [Rarity.common, .uncommon, .rare] where pool.contains(where: { $0.rarity == rarity }) {
            tiers.append((rarity, Balance.tierWeight(rarity, effects: effects)))
        }
        let total = tiers.reduce(0) { $0 + $1.weight }
        guard total > 0 else { return pool.randomElement() ?? fallback }

        var roll = Double.random(in: 0..<total)
        var chosen = tiers.first?.rarity ?? .common
        for tier in tiers {
            if roll < tier.weight { chosen = tier.rarity; break }
            roll -= tier.weight
        }
        return pool.filter { $0.rarity == chosen }.randomElement() ?? fallback
    }
}
