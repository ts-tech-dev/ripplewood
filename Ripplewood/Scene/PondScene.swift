import SpriteKit
import UIKit

/// The pond. Laid out in a fixed 390×844 design space and aspect-filled to the screen.
///
/// Fishing loop: ready → (tap) casting → waiting (nibbles) → biting (timing window)
/// → resolving (catch / escape / spooked) → ready.
final class PondScene: SKScene {

    // MARK: Layout

    static let designSize = CGSize(width: 390, height: 844)
    static let pondRect = CGRect(x: 15, y: 225, width: 360, height: 330)
    static let rodBase = CGPoint(x: 356, y: 44)
    static let rodLocalTip: CGPoint = {
        let length: CGFloat = 215, angle: CGFloat = 1.95
        return CGPoint(x: length * cos(angle), y: length * sin(angle))
    }()

    static func make() -> PondScene {
        let scene = PondScene(size: designSize)
        scene.scaleMode = .aspectFill
        scene.anchorPoint = .zero
        return scene
    }

    weak var store: GameStore?

    // MARK: Fishing state

    enum FishingState { case ready, casting, waiting, biting, resolving }
    var state: FishingState = .ready
    var nibbleUntil: TimeInterval = 0
    var biteStart: TimeInterval = 0
    var hooked: FishSpecies?
    var perfectWindow = Balance.perfectWindow
    var goodWindow = Balance.goodWindow

    // MARK: World state

    var built = false
    var owned: Set<UpgradeID> = []
    var conditions = PondConditions(time: .day, weather: .clear)
    var palette = PondPalette()
    var cleanWater: Bool { owned.contains(.water) }
    var weedsVisible = true
    var murkVisible = true
    var fenceBroken = true
    var raining = false

    // MARK: Nodes

    let skySprite = SKSpriteNode()
    let skyFade = SKSpriteNode()
    let starsNode = SKNode()
    let sun = SKShapeNode(circleOfRadius: 24)
    let moon = SKShapeNode(circleOfRadius: 18)
    let cloudsNode = SKNode()
    var cloudPuffs: [SKShapeNode] = []
    let ground = SKShapeNode(rect: CGRect(x: -60, y: -60, width: 510, height: 640))
    let hill = SKShapeNode()
    let pondRim = SKShapeNode(ellipseIn: PondScene.pondRect.insetBy(dx: -7, dy: -6))
    let pond = SKShapeNode(ellipseIn: PondScene.pondRect)
    let murk = SKNode()
    let weeds = SKNode()
    let brokenFence = SKNode()
    var decor: [UpgradeID: SKNode] = [:]
    var glowSprites: [SKSpriteNode] = []
    let overlay = SKSpriteNode(color: .black, size: CGSize(width: 700, height: 1200))
    let rain = SKEmitterNode()

    let rod = SKNode()
    let bobber = SKNode()
    let bobberBody = SKNode()
    let line = SKShapeNode()
    let hintLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    let messageLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    let exclaim = SKLabelNode(fontNamed: "AvenirNext-Heavy")

    var rodTipWorld: CGPoint { rod.convert(Self.rodLocalTip, to: self) }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        guard !built else { return }
        built = true
        backgroundColor = UIColor(r: 0.56, g: 0.75, b: 0.48)
        buildWorld()
        buildOvergrowth()
        buildGear()
        buildLabels()
        startAmbientLife()
        if let store {
            applyUpgrades(store.owned, animating: [])
            applyConditions(store.conditions, animated: false)
        } else {
            applyConditions(conditions, animated: false)
        }
        showHint()
    }

    /// Hook the scene up to game state. Safe to call before or after the scene is presented.
    func attach(store: GameStore) {
        self.store = store
        guard built else { return }
        applyUpgrades(store.owned, animating: [])
        applyConditions(store.conditions, animated: false)
        showHint()
    }

    override func update(_ currentTime: TimeInterval) {
        guard built, !line.isHidden else { return }
        let tip = rodTipWorld
        let end = CGPoint(x: bobber.position.x,
                          y: bobber.position.y + (bobberBody.position.y + 7) * bobber.yScale)
        let sag: CGFloat
        switch state {
        case .biting: sag = 0
        case .casting: sag = 8
        default: sag = 22
        }
        let path = CGMutablePath()
        path.move(to: tip)
        path.addQuadCurve(to: end, control: CGPoint(x: (tip.x + end.x) / 2, y: (tip.y + end.y) / 2 - sag))
        line.path = path
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleTap(at: touch.timestamp)
    }

    private func handleTap(at time: TimeInterval) {
        switch state {
        case .ready: cast()
        case .waiting: spook(onNibble: time <= nibbleUntil)
        case .biting: hook(reaction: time - biteStart)
        case .casting, .resolving: break
        }
    }

    // MARK: - Fishing

    private func cast() {
        guard store != nil else { return }
        state = .casting
        hideHint()
        AudioManager.shared.play(.cast)

        rod.run(.sequence([.rotate(toAngle: -0.18, duration: 0.1), .rotate(toAngle: 0, duration: 0.3)]))

        let start = rodTipWorld
        let target = randomPondPoint(maxR: 0.55) + CGPoint(x: 0, y: 25)
        bobber.removeAllActions()
        bobberBody.removeAllActions()
        bobberBody.position = .zero
        bobber.position = start
        bobber.setScale(0.6)
        bobber.alpha = 1
        bobber.isHidden = false
        line.isHidden = false

        let path = CGMutablePath()
        path.move(to: start)
        path.addQuadCurve(to: target, control: CGPoint(x: (start.x + target.x) / 2, y: max(start.y, target.y) + 170))
        let fly = SKAction.follow(path, asOffset: false, orientToPath: false, duration: 0.65)
        fly.timingMode = .easeInEaseOut
        let arcScale = SKAction.sequence([.scale(to: 1.25, duration: 0.3), .scale(to: 1.0, duration: 0.35)])
        bobber.run(.sequence([
            .wait(forDuration: 0.08),
            .group([fly, arcScale]),
            .run { [weak self] in self?.bobberLanded() },
        ]), withKey: "cast")
    }

    private func bobberLanded() {
        guard state == .casting else { return }
        state = .waiting
        AudioManager.shared.play(.plop)
        ripple(at: bobber.position, size: 36, alpha: 0.7)
        splash(at: bobber.position, count: 4, spread: 14)
        bobberBody.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 2.5, duration: 0.9),
            .moveBy(x: 0, y: -2.5, duration: 0.9),
        ])), withKey: "bob")
        if store?.isBeginner == true { showHint("Wait for the splash…", pulse: false) }
        scheduleBite()
    }

    private func scheduleBite() {
        guard let store else { return }
        let wait = store.waitDuration()
        var actions: [SKAction] = []
        var t = 0.0
        let nibbleTimes = (0..<Int.random(in: 0...3))
            .map { _ in Double.random(in: 0.6...max(0.7, wait - 0.7)) }
            .sorted()
        for nt in nibbleTimes {
            actions.append(.wait(forDuration: nt - t))
            actions.append(.run { [weak self] in self?.nibble() })
            t = nt
        }
        actions.append(.wait(forDuration: max(0.2, wait - t)))
        actions.append(.run { [weak self] in self?.bite() })
        run(.sequence(actions), withKey: "fishing")
    }

    private func nibble() {
        guard state == .waiting else { return }
        nibbleUntil = ProcessInfo.processInfo.systemUptime + 0.4
        bobberBody.run(.sequence([.moveBy(x: 0, y: -4, duration: 0.07), .moveBy(x: 0, y: 4, duration: 0.15)]))
        ripple(at: bobber.position, size: 22, alpha: 0.5, duration: 0.8)
        Haptics.nibble()
        AudioManager.shared.play(.nibble)
    }

    private func bite() {
        guard state == .waiting, let store else { return }
        let species = store.rollBite()
        let windows = store.windows(for: species)
        hooked = species
        perfectWindow = windows.perfect
        goodWindow = windows.good
        state = .biting
        biteStart = ProcessInfo.processInfo.systemUptime

        bobberBody.removeAction(forKey: "bob")
        bobberBody.position = .zero
        bobberBody.run(.sequence([
            .moveBy(x: 0, y: -10, duration: 0.05),
            .repeatForever(.sequence([.moveBy(x: -1.5, y: 0, duration: 0.04), .moveBy(x: 1.5, y: 0, duration: 0.04)])),
        ]), withKey: "bite")
        ripple(at: bobber.position, size: 50, alpha: 0.9, duration: 0.9)
        splash(at: bobber.position, count: 7, spread: 22)
        hideHint()

        exclaim.position = bobber.position + CGPoint(x: 0, y: 34)
        exclaim.removeAllActions()
        exclaim.setScale(0.2)
        exclaim.alpha = 1
        exclaim.isHidden = false
        exclaim.run(.scale(to: 1, duration: 0.08))

        Haptics.bite()
        AudioManager.shared.play(.splash)

        run(.sequence([.wait(forDuration: goodWindow), .run { [weak self] in self?.escape() }]), withKey: "escape")
    }

    private func hook(reaction: TimeInterval) {
        guard let species = hooked, let store else { return }
        removeAction(forKey: "escape")
        let r = max(0, reaction)
        guard r <= goodWindow else { escape(); return }
        let perfect = r <= perfectWindow
        state = .resolving
        hideExclaim()

        let event = store.landFish(species, perfect: perfect)
        if perfect {
            showMessage("Perfect!", color: UIColor(r: 1, g: 0.86, b: 0.4))
        } else {
            showMessage("Nice catch!", color: .white)
        }
        leap(event.species, from: bobber.position)
        Haptics.success()
        AudioManager.shared.play(.chime)
        reelIn(after: 0.2)
    }

    private func escape() {
        guard state == .biting else { return }
        removeAction(forKey: "escape")
        state = .resolving
        hooked = nil
        hideExclaim()
        splash(at: bobber.position, count: 9, spread: 26)
        ripple(at: bobber.position, size: 44, alpha: 0.6)
        showMessage(["It got away!", "So close!", "Next time!"].randomElement() ?? "It got away!",
                    color: UIColor(r: 0.85, g: 0.93, b: 1))
        AudioManager.shared.play(.escape)
        reelIn(after: 0.35)
    }

    private func spook(onNibble: Bool) {
        removeAction(forKey: "fishing")
        state = .resolving
        ripple(at: bobber.position, size: 30, alpha: 0.5)
        showMessage(onNibble ? "Just a nibble!" : "Too early!", color: UIColor(r: 0.85, g: 0.93, b: 1))
        AudioManager.shared.play(.spook)
        reelIn(after: 0.1)
    }

    private func reelIn(after delay: TimeInterval) {
        bobber.removeAction(forKey: "cast")
        bobber.run(.sequence([
            .wait(forDuration: delay),
            .run { [weak self] in
                guard let self else { return }
                self.bobberBody.removeAllActions()
                self.bobberBody.position = .zero
                let tip = self.rodTipWorld
                self.bobber.run(.sequence([
                    .group([.move(to: tip, duration: 0.35), .scale(to: 0.5, duration: 0.35)]),
                    .run { [weak self] in self?.finishRound() },
                ]), withKey: "reel")
            },
        ]))
    }

    private func finishRound() {
        bobber.isHidden = true
        line.isHidden = true
        hooked = nil
        state = .ready
        showHint()
    }
}
