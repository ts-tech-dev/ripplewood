import Foundation

enum SoundEffect: CaseIterable {
    case cast, plop, nibble, splash, chime, escape, spook, coin, upgrade
}

/// All game audio is synthesised at launch, so there are no third-party or licensed sound
/// files. To use recorded sounds later, swap `AudioManager.makeBuffer` inputs for files.
enum Synth {
    static let sampleRate: Double = 44_100

    struct Noise {
        private var gen: SeededGenerator
        init(seed: UInt64) { gen = SeededGenerator(seed: seed) }
        /// Uniform in -1...1
        mutating func next() -> Double { Double(gen.next() >> 11) * 0x1.0p-53 * 2 - 1 }
    }

    static func silence(_ seconds: Double) -> [Float] {
        [Float](repeating: 0, count: Int(seconds * sampleRate))
    }

    /// Adds a (optionally sweeping) tone with an exponential decay envelope.
    static func tone(_ buf: inout [Float], at start: Double, length: Double, freq: Double,
                     to endFreq: Double? = nil, amp: Double, attack: Double = 0.004,
                     decay: Double = 8, partials: [(Double, Double)] = [(1, 1)]) {
        let s0 = Int(start * sampleRate)
        let n = Int(length * sampleRate)
        let target = endFreq ?? freq
        var phase = 0.0
        for i in 0..<n {
            let idx = s0 + i
            if idx >= buf.count { break }
            let t = Double(i) / sampleRate
            let f = freq + (target - freq) * (t / length)
            phase += 2 * Double.pi * f / sampleRate
            let env = min(1, t / attack) * exp(-decay * t)
            var v = 0.0
            for p in partials { v += p.1 * sin(phase * p.0) }
            buf[idx] += Float(v * amp * env)
        }
    }

    /// Adds low-passed noise (smooth: 0…1, lower = darker) with an envelope.
    static func noise(_ buf: inout [Float], at start: Double, length: Double, amp: Double,
                      smooth: Double, attack: Double = 0.003, decay: Double = 10, seed: UInt64 = 7) {
        var rng = Noise(seed: seed)
        var y = 0.0
        let s0 = Int(start * sampleRate)
        let n = Int(length * sampleRate)
        for i in 0..<n {
            let idx = s0 + i
            if idx >= buf.count { break }
            let t = Double(i) / sampleRate
            y += smooth * (rng.next() - y)
            let env = min(1, t / attack) * exp(-decay * t)
            buf[idx] += Float(y * amp * env)
        }
    }

    // MARK: - Effects

    static func effect(_ e: SoundEffect) -> [Float] {
        let bell: [(Double, Double)] = [(1, 1), (2, 0.35), (3.01, 0.12)]
        switch e {
        case .cast:
            var b = silence(0.32)
            noise(&b, at: 0, length: 0.32, amp: 0.3, smooth: 0.12, attack: 0.09, decay: 9, seed: 11)
            return b
        case .plop:
            var b = silence(0.35)
            tone(&b, at: 0, length: 0.2, freq: 620, to: 170, amp: 0.45, attack: 0.002, decay: 16)
            noise(&b, at: 0, length: 0.15, amp: 0.12, smooth: 0.35, decay: 25, seed: 3)
            return b
        case .nibble:
            var b = silence(0.1)
            tone(&b, at: 0, length: 0.08, freq: 900, to: 650, amp: 0.2, attack: 0.002, decay: 40)
            return b
        case .splash:
            var b = silence(0.55)
            noise(&b, at: 0, length: 0.55, amp: 0.6, smooth: 0.45, attack: 0.002, decay: 7, seed: 21)
            tone(&b, at: 0, length: 0.22, freq: 240, to: 90, amp: 0.3, attack: 0.002, decay: 14)
            return b
        case .chime:
            var b = silence(1.3)
            for (i, f) in [784.0, 988.0, 1175.0, 1568.0].enumerated() {
                tone(&b, at: Double(i) * 0.075, length: 1.0, freq: f, amp: 0.13, decay: 4.5, partials: bell)
            }
            return b
        case .escape:
            var b = silence(0.45)
            noise(&b, at: 0, length: 0.3, amp: 0.3, smooth: 0.5, decay: 12, seed: 33)
            tone(&b, at: 0.05, length: 0.3, freq: 560, to: 300, amp: 0.12, decay: 8)
            return b
        case .spook:
            var b = silence(0.3)
            tone(&b, at: 0, length: 0.18, freq: 330, to: 200, amp: 0.25, decay: 14)
            noise(&b, at: 0, length: 0.12, amp: 0.08, smooth: 0.3, decay: 20, seed: 5)
            return b
        case .coin:
            var b = silence(0.45)
            tone(&b, at: 0, length: 0.3, freq: 1319, amp: 0.13, decay: 12, partials: bell)
            tone(&b, at: 0.07, length: 0.35, freq: 1760, amp: 0.13, decay: 10, partials: bell)
            return b
        case .upgrade:
            var b = silence(2.0)
            for (i, f) in [523.0, 659.0, 784.0, 1047.0, 1319.0].enumerated() {
                tone(&b, at: Double(i) * 0.09, length: 1.6, freq: f, amp: 0.12, decay: 2.8, partials: bell)
            }
            noise(&b, at: 0.1, length: 1.5, amp: 0.035, smooth: 0.9, attack: 0.2, decay: 3, seed: 77)
            return b
        }
    }

    // MARK: - Ambience (seamless loops)

    static let ambienceLoop: Double = 8

    static func ambience(for time: TimeOfDay) -> [Float] {
        let fade = 0.5
        var b = silence(ambienceLoop + fade)
        let seed: UInt64
        switch time {
        case .day: seed = 101
        case .dusk: seed = 202
        case .night: seed = 303
        }
        var rng = Noise(seed: seed)

        // Gentle water: dark noise with slow "lapping".
        var y = 0.0
        for i in 0..<b.count {
            let t = Double(i) / sampleRate
            y += 0.02 * (rng.next() - y)
            let lap = 0.65 + 0.35 * sin(2 * .pi * 0.25 * t) * sin(2 * .pi * 0.125 * t + 1)
            b[i] = Float(y * 2.2 * lap)
        }

        switch time {
        case .day:
            birds(&b, count: 6, seed: seed + 1)
        case .dusk:
            birds(&b, count: 2, seed: seed + 1)
            crickets(&b, freq: 4300, amp: 0.012, period: 0.6, seed: seed + 2)
        case .night:
            crickets(&b, freq: 4300, amp: 0.026, period: 0.55, seed: seed + 2)
            crickets(&b, freq: 3800, amp: 0.018, period: 0.8, seed: seed + 3)
            let frog: [(Double, Double)] = [(1, 1), (2, 0.5), (3, 0.25)]
            tone(&b, at: 2.3, length: 0.25, freq: 150, to: 125, amp: 0.07, decay: 10, partials: frog)
            tone(&b, at: 6.1, length: 0.25, freq: 140, to: 118, amp: 0.06, decay: 10, partials: frog)
        }
        return loopable(b, loop: ambienceLoop, fade: fade)
    }

    static func rain() -> [Float] {
        let loop = 6.0, fade = 0.5
        var b = silence(loop + fade)
        var rng = Noise(seed: 404)
        var y = 0.0
        for i in 0..<b.count {
            y += 0.5 * (rng.next() - y)
            b[i] = Float(y * 0.22)
        }
        for _ in 0..<70 {
            let at = (rng.next() + 1) / 2 * loop
            let f = 1500 + (rng.next() + 1) * 900
            tone(&b, at: at, length: 0.03, freq: f, to: f * 0.7, amp: 0.05, attack: 0.001, decay: 120)
        }
        return loopable(b, loop: loop, fade: fade)
    }

    private static func birds(_ b: inout [Float], count: Int, seed: UInt64) {
        var rng = Noise(seed: seed)
        for _ in 0..<count {
            let start = (rng.next() + 1) / 2 * (ambienceLoop - 0.6)
            let base = 2400 + (rng.next() + 1) * 600
            let notes = 2 + Int((rng.next() + 1) * 1.5)
            for k in 0..<notes {
                tone(&b, at: start + Double(k) * 0.11, length: 0.08, freq: base, to: base * 1.35,
                     amp: 0.05, attack: 0.01, decay: 20)
            }
        }
    }

    private static func crickets(_ b: inout [Float], freq: Double, amp: Double, period: Double, seed: UInt64) {
        var rng = Noise(seed: seed)
        var t = (rng.next() + 1) * 0.2
        while t < ambienceLoop + 0.3 {
            for k in 0..<3 {
                tone(&b, at: t + Double(k) * 0.045, length: 0.03, freq: freq, amp: amp, attack: 0.003, decay: 60)
            }
            t += period + (rng.next() + 1) * 0.12
        }
    }

    /// Crossfades the tail into the head so the buffer loops without a click.
    private static func loopable(_ b: [Float], loop: Double, fade: Double) -> [Float] {
        let n = Int(loop * sampleRate)
        let f = Int(fade * sampleRate)
        guard b.count >= n + f else { return b }
        var out = Array(b[0..<n])
        for i in 0..<f {
            let w = Float(i) / Float(f)
            out[i] = b[i] * w + b[n + i] * (1 - w)
        }
        return out
    }
}
