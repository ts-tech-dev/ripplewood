import AVFoundation

/// Ambient loop (water + birds by day, crickets at night, rain layer) and short SFX.
/// Uses the `.ambient` session category so it mixes politely with the player's own music
/// and respects the silent switch.
final class AudioManager {
    static let shared = AudioManager()

    var sfxEnabled = true
    var musicEnabled = true { didSet { updateAmbientVolume() } }

    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: Synth.sampleRate, channels: 1)!
    private var sfxPlayers: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private let ambientPlayer = AVAudioPlayerNode()
    private let rainPlayer = AVAudioPlayerNode()

    private var sfx: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var ambience: [TimeOfDay: AVAudioPCMBuffer] = [:]
    private var rainBuffer: AVAudioPCMBuffer?

    private var wantedTime: TimeOfDay = .day
    private var wantRain = false
    private var playingTime: TimeOfDay?
    private var rainPlaying = false
    private var started = false

    private init() {}

    func start() {
        guard !started else { return }
        started = true

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)

        for _ in 0..<4 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            sfxPlayers.append(player)
        }
        for player in [ambientPlayer, rainPlayer] {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
        engine.mainMixerNode.outputVolume = 0.9
        updateAmbientVolume()

        for effect in SoundEffect.allCases {
            sfx[effect] = makeBuffer(Synth.effect(effect))
        }
        startEngine()

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.resume()
        }

        // Ambient loops are longer — synthesise them off the main thread.
        DispatchQueue.global(qos: .utility).async {
            let day = Synth.ambience(for: .day)
            let dusk = Synth.ambience(for: .dusk)
            let night = Synth.ambience(for: .night)
            let rain = Synth.rain()
            DispatchQueue.main.async {
                self.ambience[.day] = self.makeBuffer(day)
                self.ambience[.dusk] = self.makeBuffer(dusk)
                self.ambience[.night] = self.makeBuffer(night)
                self.rainBuffer = self.makeBuffer(rain)
                self.refreshAmbience()
            }
        }
    }

    func play(_ effect: SoundEffect) {
        guard sfxEnabled, started, let buffer = sfx[effect] else { return }
        ensureRunning()
        guard engine.isRunning else { return }
        let player = sfxPlayers[nextPlayer]
        nextPlayer = (nextPlayer + 1) % sfxPlayers.count
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    func setAmbience(_ time: TimeOfDay, raining: Bool) {
        wantedTime = time
        wantRain = raining
        refreshAmbience()
    }

    /// Call when returning to the foreground or after an interruption.
    func resume() {
        guard started else { return }
        if !engine.isRunning {
            playingTime = nil
            rainPlaying = false
        }
        refreshAmbience()
    }

    // MARK: - Private

    private func startEngine() {
        do { try engine.start() } catch { print("Ripplewood: audio engine failed – \(error)") }
    }

    private func ensureRunning() {
        if !engine.isRunning {
            playingTime = nil
            rainPlaying = false
            startEngine()
        }
    }

    private func refreshAmbience() {
        guard started else { return }
        ensureRunning()
        guard engine.isRunning else { return }

        if playingTime != wantedTime, let buffer = ambience[wantedTime] {
            ambientPlayer.stop()
            ambientPlayer.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
            ambientPlayer.play()
            playingTime = wantedTime
        }
        if wantRain && !rainPlaying, let buffer = rainBuffer {
            rainPlayer.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
            rainPlayer.play()
            rainPlaying = true
        } else if !wantRain && rainPlaying {
            rainPlayer.stop()
            rainPlaying = false
        }
        updateAmbientVolume()
    }

    private func updateAmbientVolume() {
        ambientPlayer.volume = musicEnabled ? 0.6 : 0
        rainPlayer.volume = musicEnabled ? 0.45 : 0
    }

    private func makeBuffer(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard !samples.isEmpty,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { src in
            if let base = src.baseAddress { channel.update(from: base, count: samples.count) }
        }
        return buffer
    }
}
