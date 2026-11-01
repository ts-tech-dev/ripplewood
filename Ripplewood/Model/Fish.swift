import Foundation

enum Rarity: Int, Codable, CaseIterable, Comparable {
    case common, uncommon, rare, legendary

    static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .common: "Common"
        case .uncommon: "Uncommon"
        case .rare: "Rare"
        case .legendary: "Legendary"
        }
    }

    /// Rarer fish have slightly tighter timing windows so they feel earned.
    var windowMultiplier: Double {
        switch self {
        case .common: 1.0
        case .uncommon: 0.92
        case .rare: 0.82
        case .legendary: 0.7
        }
    }
}

enum FishShape: String {
    case fish, longFish, turtle
}

struct FishConditions: Hashable {
    /// nil = any time of day
    var times: Set<TimeOfDay>? = nil
    /// nil = any weather
    var weather: Set<Weather>? = nil
    var upgrades: Set<UpgradeID> = []
    var fullRestoration = false

    func isMet(by conditions: PondConditions, owned: Set<UpgradeID>) -> Bool {
        if let times, !times.contains(conditions.time) { return false }
        if let weather, !weather.contains(conditions.weather) { return false }
        if !upgrades.isSubset(of: owned) { return false }
        if fullRestoration && owned.count < UpgradeID.allCases.count { return false }
        return true
    }
}

struct FishSpecies: Identifiable, Hashable {
    let id: String
    let name: String
    let rarity: Rarity
    let baseValue: Int
    /// Length in centimetres.
    let sizeRange: ClosedRange<Double>
    let conditions: FishConditions
    /// Multiplier on the bite timing window (1 = normal, < 1 = trickier).
    let biteWindow: Double
    let color: UInt32
    let accent: UInt32
    let shape: FishShape
    let flavor: String
    /// Shown in the Fish Log before the fish has been caught.
    let hint: String

    init(id: String, name: String, rarity: Rarity, baseValue: Int, size: ClosedRange<Double>,
         conditions: FishConditions = FishConditions(), biteWindow: Double = 1.0,
         color: UInt32, accent: UInt32, shape: FishShape = .fish,
         flavor: String, hint: String) {
        self.id = id
        self.name = name
        self.rarity = rarity
        self.baseValue = baseValue
        self.sizeRange = size
        self.conditions = conditions
        self.biteWindow = biteWindow
        self.color = color
        self.accent = accent
        self.shape = shape
        self.flavor = flavor
        self.hint = hint
    }

    /// Name of an optional image in the asset catalog that replaces the placeholder drawing.
    var artName: String { "fish_\(id)" }
}

struct CaughtFish: Codable, Identifiable, Hashable {
    var id = UUID()
    let speciesID: String
    let size: Double
    let value: Int
    let caughtAt: Date
    var perfect = false

    var species: FishSpecies? { FishCatalog.species(id: speciesID) }
}

struct LogEntry: Codable, Hashable {
    var count: Int
    var biggest: Double
    var firstCaught: Date
}
