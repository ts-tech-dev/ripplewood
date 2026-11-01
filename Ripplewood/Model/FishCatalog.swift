import Foundation

/// All fish in Ripplewood. Add new fish here — everything else picks them up automatically.
enum FishCatalog {
    static let all: [FishSpecies] = [
        // MARK: Commons
        FishSpecies(
            id: "pondMinnow", name: "Pond Minnow", rarity: .common, baseValue: 3, size: 4...9,
            color: 0xA7BCC9, accent: 0x7E97A8,
            flavor: "Tiny, quick, and endlessly curious about bobbers.",
            hint: "Lives in almost any pond."),
        FishSpecies(
            id: "bluegill", name: "Bluegill", rarity: .common, baseValue: 4, size: 12...22,
            conditions: FishConditions(times: [.day, .dusk]),
            color: 0x6C9BC8, accent: 0xF2B34A,
            flavor: "A sunny little fish with a blue blush on its cheeks.",
            hint: "Bites during the day and at dusk."),
        FishSpecies(
            id: "mudCarp", name: "Mud Carp", rarity: .common, baseValue: 5, size: 25...50,
            color: 0x9A8358, accent: 0x6E5C3C,
            flavor: "Content to snuffle through the mud all day long.",
            hint: "Lives in almost any pond."),
        FishSpecies(
            id: "speckledPerch", name: "Speckled Perch", rarity: .common, baseValue: 6, size: 15...30,
            color: 0xD4BC5E, accent: 0x7A6A2A,
            flavor: "Freckled from nose to tail.",
            hint: "Lives in almost any pond."),
        FishSpecies(
            id: "pebbleLoach", name: "Pebble Loach", rarity: .common, baseValue: 7, size: 8...15,
            conditions: FishConditions(upgrades: [.water]),
            color: 0xB39A84, accent: 0x7F6957,
            flavor: "Hides among clean stones. Shy, but sweet.",
            hint: "Appears once the water runs clear."),

        // MARK: Uncommons
        FishSpecies(
            id: "lanternShiner", name: "Lantern Shiner", rarity: .uncommon, baseValue: 14, size: 6...12,
            conditions: FishConditions(times: [.dusk, .night]), biteWindow: 0.95,
            color: 0xFFD27A, accent: 0xFF9F43,
            flavor: "Its scales catch the last light of the day.",
            hint: "Rises at dusk and through the night…"),
        FishSpecies(
            id: "mossbackTurtle", name: "Mossback Turtle", rarity: .uncommon, baseValue: 18, size: 15...30,
            conditions: FishConditions(upgrades: [.lilyPads]), biteWindow: 1.05,
            color: 0x7E9A57, accent: 0x4F6B36, shape: .turtle,
            flavor: "Wears a little garden on its shell, and is very proud of it.",
            hint: "Likes to rest beneath lily pads."),
        FishSpecies(
            id: "rainTrout", name: "Rain Trout", rarity: .uncommon, baseValue: 16, size: 25...45,
            conditions: FishConditions(weather: [.rain]),
            color: 0x93B8AD, accent: 0xD98C8C,
            flavor: "Only leaps when the pond is dimpled with rain.",
            hint: "Bites only when it rains…"),
        FishSpecies(
            id: "reedtailCatfish", name: "Reedtail Catfish", rarity: .uncommon, baseValue: 17, size: 30...60,
            conditions: FishConditions(weather: [.cloudy, .rain], upgrades: [.cattails]),
            color: 0x6B6552, accent: 0x423E31,
            flavor: "Whiskers like reeds, patience like stone.",
            hint: "Hides in tall reeds on grey days."),
        FishSpecies(
            id: "blossomDace", name: "Blossom Dace", rarity: .uncommon, baseValue: 15, size: 10...18,
            conditions: FishConditions(times: [.day, .dusk], upgrades: [.cherryTree]),
            color: 0xF4B2CA, accent: 0xE77FA6,
            flavor: "Pink as a petal and twice as light.",
            hint: "Follows falling blossoms by daylight."),

        // MARK: Rares
        FishSpecies(
            id: "moonscaleKoi", name: "Moonscale Koi", rarity: .rare, baseValue: 45, size: 40...70,
            conditions: FishConditions(times: [.night]),
            color: 0xE9EDF7, accent: 0x9FB3E0,
            flavor: "Silver scales that shimmer like moonlight on still water.",
            hint: "Bites only at night…"),
        FishSpecies(
            id: "copperPike", name: "Copper Pike", rarity: .rare, baseValue: 40, size: 50...90,
            conditions: FishConditions(upgrades: [.dock]), biteWindow: 0.9,
            color: 0xCB8044, accent: 0x8A4B22, shape: .longFish,
            flavor: "A gleaming hunter that lurks by the pilings.",
            hint: "Lurks in the shade of a dock."),
        FishSpecies(
            id: "ghostGar", name: "Ghost Gar", rarity: .rare, baseValue: 50, size: 60...110,
            conditions: FishConditions(weather: [.cloudy, .rain], upgrades: [.water]),
            color: 0xD6DEE2, accent: 0xA3B1B8, shape: .longFish,
            flavor: "Pale and long, glimpsed far more often than caught.",
            hint: "Drifts through clear water on grey days."),
        FishSpecies(
            id: "emberSunfish", name: "Ember Sunfish", rarity: .rare, baseValue: 42, size: 12...20,
            conditions: FishConditions(times: [.dusk, .night], upgrades: [.lanterns]),
            color: 0xF06A45, accent: 0xFFC15E,
            flavor: "Glows warm like the last ember in a lantern.",
            hint: "Drawn to lantern light after sunset."),

        // MARK: Legendary
        FishSpecies(
            id: "goldenKoi", name: "Golden Koi", rarity: .legendary, baseValue: 500, size: 60...95,
            conditions: FishConditions(times: [.night], weather: [.rain], fullRestoration: true),
            color: 0xF7C948, accent: 0xE08A1E,
            flavor: "The heart of Ripplewood. Some say it only visits a pond that is truly loved.",
            hint: "Night. Rain. A pond fully restored."),
    ]

    private static let byID: [String: FishSpecies] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func species(id: String) -> FishSpecies? { byID[id] }

    static func requiring(_ upgrade: UpgradeID) -> [FishSpecies] {
        all.filter { $0.conditions.upgrades.contains(upgrade) }
    }
}
