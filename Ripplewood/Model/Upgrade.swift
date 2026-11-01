import Foundation

/// Order here is the restoration order shown in the Restore screen.
enum UpgradeID: String, Codable, CaseIterable {
    case weeds, water, lilyPads, dock, cattails, stonePath, lanterns, boathouse, cherryTree, fireflies
}

struct UpgradeEffect {
    /// Fraction shaved off the wait for a bite.
    var waitReduction = 0.0
    var uncommonBoost = 0.0
    var rareBoost = 0.0
    /// Extra coin value on every catch.
    var coinBonus = 0.0
    /// Extra idle coins while away.
    var idleBonus = 0.0

    static func + (lhs: UpgradeEffect, rhs: UpgradeEffect) -> UpgradeEffect {
        UpgradeEffect(
            waitReduction: lhs.waitReduction + rhs.waitReduction,
            uncommonBoost: lhs.uncommonBoost + rhs.uncommonBoost,
            rareBoost: lhs.rareBoost + rhs.rareBoost,
            coinBonus: lhs.coinBonus + rhs.coinBonus,
            idleBonus: lhs.idleBonus + rhs.idleBonus)
    }
}

/// Anything that can be bought with coins. Upgrades are the only kind in v1, but a future
/// shop (decorations, bait, cosmetics…) can add more types without touching the wallet code.
protocol Purchasable {
    var cost: Int { get }
}

struct Upgrade: Identifiable, Purchasable {
    let id: UpgradeID
    let name: String
    let cost: Int
    let blurb: String
    let perks: String
    let symbol: String
    let effect: UpgradeEffect
}

enum UpgradeCatalog {
    static let all: [Upgrade] = [
        Upgrade(id: .weeds, name: "Clear the weeds", cost: 60,
                blurb: "Pull the tangled weeds from the banks and shallows.",
                perks: "Bites come a little faster",
                symbol: "scissors",
                effect: UpgradeEffect(waitReduction: 0.10)),
        Upgrade(id: .water, name: "Clean the water", cost: 180,
                blurb: "Skim away the murk until the pond sparkles.",
                perks: "More uncommon fish · +5% coins",
                symbol: "drop.fill",
                effect: UpgradeEffect(uncommonBoost: 0.10, coinBonus: 0.05)),
        Upgrade(id: .lilyPads, name: "Lily pads", cost: 400,
                blurb: "Float a few lily pads across the water.",
                perks: "More uncommon fish",
                symbol: "leaf.fill",
                effect: UpgradeEffect(uncommonBoost: 0.15)),
        Upgrade(id: .dock, name: "Wooden dock", cost: 800,
                blurb: "Build a little dock out over the water.",
                perks: "More rare fish · faster bites",
                symbol: "figure.fishing",
                effect: UpgradeEffect(waitReduction: 0.05, rareBoost: 0.20)),
        Upgrade(id: .cattails, name: "Cattails & reeds", cost: 1400,
                blurb: "Plant swaying cattails along the shore.",
                perks: "More uncommon fish · more coins while away",
                symbol: "camera.macro",
                effect: UpgradeEffect(uncommonBoost: 0.15, idleBonus: 0.5)),
        Upgrade(id: .stonePath, name: "Stone path", cost: 2200,
                blurb: "Lay a stone path to the water and mend the old fence.",
                perks: "+10% coins · more coins while away",
                symbol: "shoeprints.fill",
                effect: UpgradeEffect(coinBonus: 0.10, idleBonus: 0.5)),
        Upgrade(id: .lanterns, name: "Hanging lanterns", cost: 3400,
                blurb: "String warm lanterns across the far bank.",
                perks: "Rare fish are drawn to the light",
                symbol: "lightbulb.fill",
                effect: UpgradeEffect(rareBoost: 0.25)),
        Upgrade(id: .boathouse, name: "Little boathouse", cost: 4800,
                blurb: "A cosy boathouse with a rowboat tied up out front.",
                perks: "+15% coins · many more coins while away",
                symbol: "house.fill",
                effect: UpgradeEffect(coinBonus: 0.15, idleBonus: 1.0)),
        Upgrade(id: .cherryTree, name: "Cherry blossom tree", cost: 6600,
                blurb: "Plant a cherry tree that scatters petals on the water.",
                perks: "More uncommon fish · faster bites",
                symbol: "tree.fill",
                effect: UpgradeEffect(waitReduction: 0.05, uncommonBoost: 0.10)),
        Upgrade(id: .fireflies, name: "Fireflies", cost: 9000,
                blurb: "Invite fireflies to dance over the water at night.",
                perks: "More rare fish · completes Ripplewood…",
                symbol: "sparkles",
                effect: UpgradeEffect(rareBoost: 0.30)),
    ]

    static func upgrade(_ id: UpgradeID) -> Upgrade {
        all.first { $0.id == id }!
    }
}
