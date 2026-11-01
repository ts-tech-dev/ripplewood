import Foundation
import Observation

struct CatchEvent: Identifiable, Equatable {
    let id = UUID()
    let fish: CaughtFish
    let species: FishSpecies
    let isNew: Bool
}

struct AwayReport: Identifiable, Equatable {
    let id = UUID()
    let duration: TimeInterval
    let coins: Int
    let fish: [CaughtFish]
}

enum UpgradeStatus: Equatable {
    case owned
    case available(affordable: Bool)
    case locked
}

/// The single source of truth for game state. Used from the main thread only
/// (SwiftUI views and the SpriteKit scene).
@Observable
final class GameStore {
    private(set) var data: SaveData
    private(set) var conditions: PondConditions
    private(set) var timeOverride: TimeOfDay?
    private(set) var weatherOverride: Weather?
    var presentedCatch: CatchEvent?
    var awayReport: AwayReport?

    init() {
        data = SaveStore.load() ?? SaveData()
        conditions = PondConditions.at(Date())
        applySettings()
    }

    // MARK: - Derived state

    var coins: Int { data.coins }
    var bucket: [CaughtFish] { data.bucket }
    var owned: Set<UpgradeID> { data.upgrades }
    var settings: GameSettings { data.settings }
    var bucketValue: Int { data.bucket.reduce(0) { $0 + $1.value } }
    var discoveredCount: Int { data.log.count }

    var restoration: Double {
        Double(data.upgrades.count) / Double(UpgradeID.allCases.count)
    }

    var effects: UpgradeEffect {
        UpgradeCatalog.all
            .filter { data.upgrades.contains($0.id) }
            .map(\.effect)
            .reduce(UpgradeEffect(), +)
    }

    var isBeginner: Bool { data.totalCaught < 3 }

    // MARK: - Conditions

    func refreshConditions(now: Date = Date()) {
        let fresh = PondConditions(time: timeOverride ?? .at(now),
                                   weather: weatherOverride ?? .at(now))
        if fresh != conditions { conditions = fresh }
    }

    func setTimeOverride(_ time: TimeOfDay?) {
        timeOverride = time
        refreshConditions()
    }

    func setWeatherOverride(_ weather: Weather?) {
        weatherOverride = weather
        refreshConditions()
    }

    // MARK: - Fishing

    func waitDuration() -> TimeInterval {
        let reduction = min(effects.waitReduction, Balance.maxWaitReduction)
        return Double.random(in: Balance.waitRange) * (1 - reduction)
    }

    func rollBite() -> FishSpecies {
        FishPicker.pick(conditions: conditions, owned: data.upgrades, effects: effects)
    }

    func windows(for species: FishSpecies) -> (perfect: Double, good: Double) {
        let m = species.rarity.windowMultiplier * species.biteWindow
        return (Balance.perfectWindow * m, Balance.goodWindow * m)
    }

    /// Lands a hooked fish. A perfect hook gets a bonus rarity roll (keep the rarer fish),
    /// a bias toward bigger sizes, and +25% coins.
    @discardableResult
    func landFish(_ hooked: FishSpecies, perfect: Bool) -> CatchEvent {
        var species = hooked
        if perfect {
            let bonus = rollBite()
            if bonus.rarity > species.rarity { species = bonus }
        }
        let fish = makeFish(species, perfect: perfect)
        let isNew = data.log[species.id] == nil
        data.bucket.append(fish)
        record(fish)
        data.totalCaught += 1
        data.lastActive = Date()
        save()

        let event = CatchEvent(fish: fish, species: species, isNew: isNew)
        presentedCatch = event
        DispatchQueue.main.asyncAfter(deadline: .now() + Balance.catchCardDuration) { [weak self] in
            guard let self, self.presentedCatch?.id == event.id else { return }
            self.presentedCatch = nil
        }
        return event
    }

    private func makeFish(_ species: FishSpecies, perfect: Bool) -> CaughtFish {
        var t = Double.random(in: 0...1)
        if perfect { t = max(t, Double.random(in: 0...1)) }
        let range = species.sizeRange
        let size = range.lowerBound + (range.upperBound - range.lowerBound) * t
        var value = Double(species.baseValue) * (0.8 + 0.4 * t) * (1 + effects.coinBonus)
        if perfect { value *= 1 + Balance.perfectCoinBonus }
        return CaughtFish(speciesID: species.id,
                          size: (size * 10).rounded() / 10,
                          value: max(1, Int(value.rounded())),
                          caughtAt: Date(),
                          perfect: perfect)
    }

    private func record(_ fish: CaughtFish) {
        if var entry = data.log[fish.speciesID] {
            entry.count += 1
            entry.biggest = max(entry.biggest, fish.size)
            data.log[fish.speciesID] = entry
        } else {
            data.log[fish.speciesID] = LogEntry(count: 1, biggest: fish.size, firstCaught: fish.caughtAt)
        }
    }

    // MARK: - Wallet

    private func earn(_ amount: Int) {
        data.coins += amount
        data.lifetimeCoins += amount
    }

    private func spend(_ amount: Int) -> Bool {
        guard data.coins >= amount else { return false }
        data.coins -= amount
        return true
    }

    func sell(_ fish: CaughtFish) {
        guard let index = data.bucket.firstIndex(where: { $0.id == fish.id }) else { return }
        data.bucket.remove(at: index)
        earn(fish.value)
        save()
        AudioManager.shared.play(.coin)
        Haptics.tap()
    }

    @discardableResult
    func sellAll() -> Int {
        let total = bucketValue
        guard total > 0 else { return 0 }
        data.bucket.removeAll()
        earn(total)
        save()
        AudioManager.shared.play(.coin)
        Haptics.success()
        return total
    }

    // MARK: - Restoration

    var nextUpgrade: Upgrade? {
        UpgradeCatalog.all.first { !data.upgrades.contains($0.id) }
    }

    var canAffordNextUpgrade: Bool {
        guard let next = nextUpgrade else { return false }
        return data.coins >= next.cost
    }

    func status(of upgrade: Upgrade) -> UpgradeStatus {
        if data.upgrades.contains(upgrade.id) { return .owned }
        if nextUpgrade?.id == upgrade.id { return .available(affordable: data.coins >= upgrade.cost) }
        return .locked
    }

    @discardableResult
    func buy(_ upgrade: Upgrade) -> Bool {
        guard nextUpgrade?.id == upgrade.id, spend(upgrade.cost) else { return false }
        data.upgrades.insert(upgrade.id)
        save()
        return true
    }

    // MARK: - Idle rewards

    func appBecameActive(now: Date = Date()) {
        refreshConditions(now: now)
        let elapsed = min(max(0, now.timeIntervalSince(data.lastActive)), Balance.idleCap)
        data.lastActive = now
        guard elapsed >= Balance.idleMinimum else { save(); return }

        let minutes = elapsed / 60
        let coins = Int((minutes * Balance.idleCoinsPerMinute * (1 + effects.idleBonus)).rounded())
        let fishCount = min(Int(minutes / Balance.idleMinutesPerFish), Balance.idleMaxFish)
        let commons = FishCatalog.all.filter {
            $0.rarity == .common && $0.conditions.upgrades.isSubset(of: data.upgrades)
        }
        var fish: [CaughtFish] = []
        for _ in 0..<fishCount {
            if let species = commons.randomElement() { fish.append(makeFish(species, perfect: false)) }
        }
        guard coins > 0 || !fish.isEmpty else { save(); return }

        earn(coins)
        data.bucket.append(contentsOf: fish)
        save()
        awayReport = AwayReport(duration: elapsed, coins: coins, fish: fish)
    }

    func appWentToBackground(now: Date = Date()) {
        data.lastActive = now
        save()
    }

    // MARK: - Settings

    func setSound(_ on: Bool) { data.settings.sound = on; applySettings(); save() }
    func setMusic(_ on: Bool) { data.settings.music = on; applySettings(); save() }
    func setHaptics(_ on: Bool) { data.settings.haptics = on; applySettings(); save() }

    private func applySettings() {
        AudioManager.shared.sfxEnabled = data.settings.sound
        AudioManager.shared.musicEnabled = data.settings.music
        Haptics.enabled = data.settings.haptics
    }

    func resetProgress() {
        let settings = data.settings
        data = SaveData()
        data.settings = settings
        presentedCatch = nil
        awayReport = nil
        save()
    }

    // MARK: - Debug helpers

    func debugAddCoins(_ amount: Int) { earn(amount); save() }

    func debugSimulateAway(hours: Double) {
        data.lastActive = Date().addingTimeInterval(-hours * 3600)
        appBecameActive()
    }

    func debugUnlockAll() {
        data.upgrades = Set(UpgradeID.allCases)
        save()
    }

    // MARK: - Persistence

    private func save() { SaveStore.save(data) }
}
