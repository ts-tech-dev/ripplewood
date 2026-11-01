import Foundation

struct GameSettings: Codable, Equatable {
    var sound = true
    var music = true
    var haptics = true

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sound = try c.decodeIfPresent(Bool.self, forKey: .sound) ?? true
        music = try c.decodeIfPresent(Bool.self, forKey: .music) ?? true
        haptics = try c.decodeIfPresent(Bool.self, forKey: .haptics) ?? true
    }
}

/// Everything that persists between launches. Decoding is tolerant of missing or unknown
/// fields so older saves keep working as the game grows.
struct SaveData: Codable {
    var coins = 0
    var lifetimeCoins = 0
    var bucket: [CaughtFish] = []
    var log: [String: LogEntry] = [:]
    var upgrades: Set<UpgradeID> = []
    var settings = GameSettings()
    var lastActive = Date()
    var totalCaught = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        coins = try c.decodeIfPresent(Int.self, forKey: .coins) ?? 0
        lifetimeCoins = try c.decodeIfPresent(Int.self, forKey: .lifetimeCoins) ?? 0
        bucket = (try? c.decodeIfPresent([CaughtFish].self, forKey: .bucket)) ?? []
        bucket.removeAll { $0.species == nil }
        log = (try? c.decodeIfPresent([String: LogEntry].self, forKey: .log)) ?? [:]
        let rawUpgrades = (try? c.decodeIfPresent([String].self, forKey: .upgrades)) ?? []
        upgrades = Set(rawUpgrades.compactMap(UpgradeID.init(rawValue:)))
        settings = (try? c.decodeIfPresent(GameSettings.self, forKey: .settings)) ?? GameSettings()
        lastActive = try c.decodeIfPresent(Date.self, forKey: .lastActive) ?? Date()
        totalCaught = try c.decodeIfPresent(Int.self, forKey: .totalCaught) ?? 0
    }
}

/// Codable JSON in the app's Documents directory.
enum SaveStore {
    static var url: URL {
        URL.documentsDirectory.appending(path: "ripplewood-save.json")
    }

    static func load() -> SaveData? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SaveData.self, from: data)
    }

    static func save(_ save: SaveData) {
        do {
            let data = try JSONEncoder().encode(save)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Ripplewood: failed to save – \(error)")
        }
    }
}
