import Foundation

/// Time of day, derived from the device's real local clock.
enum TimeOfDay: String, Codable, CaseIterable, Identifiable {
    case day, dusk, night

    var id: String { rawValue }

    var label: String {
        switch self {
        case .day: "Day"
        case .dusk: "Dusk"
        case .night: "Night"
        }
    }

    var symbol: String {
        switch self {
        case .day: "sun.max.fill"
        case .dusk: "sunset.fill"
        case .night: "moon.stars.fill"
        }
    }

    static func at(_ date: Date, calendar: Calendar = .current) -> TimeOfDay {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 6..<17: return .day
        case 17..<20: return .dusk
        default: return .night
        }
    }
}

/// Weather changes every few hours. It is derived from a seeded random based on the
/// local date and time block, so it's stable within a block and the same on every launch.
enum Weather: String, Codable, CaseIterable, Identifiable {
    case clear, cloudy, rain

    var id: String { rawValue }

    static let blockHours = 3

    var label: String {
        switch self {
        case .clear: "Clear"
        case .cloudy: "Cloudy"
        case .rain: "Rain"
        }
    }

    var symbol: String {
        switch self {
        case .clear: "sparkle"
        case .cloudy: "cloud.fill"
        case .rain: "cloud.rain.fill"
        }
    }

    static func at(_ date: Date, calendar: Calendar = .current) -> Weather {
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let block = calendar.component(.hour, from: date) / blockHours
        let seed = UInt64(truncatingIfNeeded: day) &* 8 &+ UInt64(block) &+ 0x5EED_0F_A_7D
        var rng = SeededGenerator(seed: seed)
        let roll = Double.random(in: 0..<1, using: &rng)
        switch roll {
        case ..<0.50: return .clear
        case ..<0.78: return .cloudy
        default: return .rain
        }
    }
}

struct PondConditions: Equatable {
    var time: TimeOfDay
    var weather: Weather

    static func at(_ date: Date) -> PondConditions {
        PondConditions(time: .at(date), weather: .at(date))
    }
}

/// SplitMix64 — small, fast, deterministic.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
