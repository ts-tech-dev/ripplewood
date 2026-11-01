import SpriteKit
import UIKit

/// Pond restoration: each upgrade visibly changes the scene, with a bloom + sparkle + chime.
extension PondScene {

    /// Delay so the Restore sheet has time to slide away before the bloom starts.
    static let bloomDelay: TimeInterval = 0.5

    func applyUpgrades(_ newOwned: Set<UpgradeID>, animating: Set<UpgradeID>) {
        owned = newOwned
        guard built else { return }

        setWeeds(visible: !newOwned.contains(.weeds), animated: animating.contains(.weeds))
        setMurk(visible: !newOwned.contains(.water), animated: animating.contains(.water))
        setFence(broken: !newOwned.contains(.stonePath))
        for id in UpgradeID.allCases where id != .weeds && id != .water {
            setDecor(id, visible: newOwned.contains(id), animated: animating.contains(id))
        }
        if !animating.isEmpty {
            run(.sequence([
                .wait(forDuration: Self.bloomDelay),
                .run {
                    AudioManager.shared.play(.upgrade)
                    Haptics.success()
                },
            ]))
        }
    }

    // MARK: - Overgrowth

    private func setWeeds(visible: Bool, animated: Bool) {
        guard visible != weedsVisible else { return }
        weedsVisible = visible
        weeds.removeAllActions()
        if visible {
            weeds.isHidden = false
            for clump in weeds.children {
                clump.removeAction(forKey: "clear")
                clump.xScale = 1
                clump.yScale = 1
                clump.alpha = 1
            }
            return
        }
        guard animated else { weeds.isHidden = true; return }
        for (i, clump) in weeds.children.enumerated() {
            let delay = Self.bloomDelay + .random(in: 0...0.8)
            clump.run(.sequence([
                .wait(forDuration: delay),
                .group([.scaleY(to: 0.01, duration: 0.35), .fadeOut(withDuration: 0.35)]),
            ]), withKey: "clear")
            if i % 3 == 0 {
                let p = clump.position
                run(.sequence([.wait(forDuration: delay), .run { [weak self] in self?.sparkle(at: p, count: 4, spread: 14) }]))
            }
        }
        weeds.run(.sequence([.wait(forDuration: Self.bloomDelay + 1.4), .hide()]))
    }

    private func setMurk(visible: Bool, animated: Bool) {
        guard visible != murkVisible else { return }
        murkVisible = visible
        let water = palette.water(clean: !visible)
        if visible {
            murk.removeAllActions()
            murk.isHidden = false
            murk.alpha = 1
            recolor(pond, to: water, duration: 0)
            return
        }
        guard animated else {
            murk.isHidden = true
            recolor(pond, to: water, duration: 0)
            return
        }
        murk.run(.sequence([.wait(forDuration: Self.bloomDelay), .fadeOut(withDuration: 2.0), .hide()]))
        run(.sequence([
            .wait(forDuration: Self.bloomDelay),
            .run { [weak self] in
                guard let self else { return }
                self.recolor(self.pond, to: self.palette.water(clean: self.cleanWater), duration: 2.5)
                for _ in 0..<6 { self.sparkle(at: self.randomPondPoint(maxR: 0.8), count: 4, spread: 30) }
            },
        ]))
    }

    private func setFence(broken: Bool) {
        guard broken != fenceBroken else { return }
        fenceBroken = broken
        brokenFence.removeAllActions()
        if broken {
            brokenFence.isHidden = false
            brokenFence.alpha = 1
        } else {
            brokenFence.run(.sequence([.wait(forDuration: Self.bloomDelay), .fadeOut(withDuration: 0.4), .hide()]))
        }
    }

    // MARK: - Decorations

    private func setDecor(_ id: UpgradeID, visible: Bool, animated: Bool) {
        guard let node = decorNode(for: id) else { return }
        guard visible == node.isHidden else { return }   // already in the requested state

        if !visible {
            node.isHidden = true
            if id == .cherryTree { removeAction(forKey: "petals") }
            return
        }

        node.isHidden = false
        if id == .fireflies {
            startFireflies(node)
            if animated {
                run(.sequence([
                    .wait(forDuration: Self.bloomDelay),
                    .run { [weak self] in
                        guard let self else { return }
                        for _ in 0..<5 { self.sparkle(at: self.randomPondPoint(maxR: 0.9), count: 3, spread: 30) }
                    },
                ]))
            }
        } else if animated {
            bloom(node)
        } else {
            for child in node.children { child.setScale(1); child.alpha = 1 }
        }
        if id == .cherryTree {
            run(.repeatForever(.sequence([
                .wait(forDuration: 1.1, withRange: 0.8),
                .run { [weak self] in self?.spawnPetal() },
            ])), withKey: "petals")
        }
    }

    /// Pieces pop in one after another with a little overshoot and a sparkle.
    private func bloom(_ container: SKNode) {
        let pieces = container.children
        let sparkleCount = pieces.count <= 2 ? 14 : 5
        for (i, child) in pieces.enumerated() {
            child.setScale(0.01)
            child.alpha = 0
            let delay = Self.bloomDelay + Double(i) * 0.07
            child.run(.sequence([
                .wait(forDuration: delay),
                .group([.fadeIn(withDuration: 0.25), .scale(to: 1.15, duration: 0.28)]),
                .scale(to: 1, duration: 0.16),
            ]))
            if pieces.count <= 4 || i % 2 == 0 {
                let p = child.position
                run(.sequence([
                    .wait(forDuration: delay),
                    .run { [weak self] in self?.sparkle(at: p, count: sparkleCount, spread: sparkleCount > 5 ? 50 : 18) },
                ]))
            }
        }
    }

    func decorNode(for id: UpgradeID) -> SKNode? {
        if let node = decor[id] { return node }
        let node: SKNode
        switch id {
        case .weeds, .water: return nil
        case .lilyPads: node = buildLilyPads()
        case .dock: node = buildDock()
        case .cattails: node = buildCattails()
        case .stonePath: node = buildStonePath()
        case .lanterns: node = buildLanterns()
        case .boathouse: node = buildBoathouse()
        case .cherryTree: node = buildCherryTree()
        case .fireflies: node = buildFireflies()
        }
        node.isHidden = true
        addChild(node)
        decor[id] = node
        return node
    }

    /// A soft additive glow that renders above the night overlay.
    private func makeGlow(color: UIColor, size: CGFloat, ancestorsZ: CGFloat) -> SKSpriteNode {
        let glow = SKSpriteNode(texture: SceneTextures.glow)
        glow.size = CGSize(width: size, height: size)
        glow.color = color
        glow.colorBlendFactor = 1
        glow.blendMode = .add
        glow.zPosition = Z.glow - ancestorsZ
        glow.alpha = palette.glowAlpha
        glowSprites.append(glow)
        return glow
    }

    // MARK: Builders (all placeholder shapes; drop art named "decor_<id>" into the asset catalog to replace)

    private func artOrNil(_ name: String, height: CGFloat, at p: CGPoint) -> SKNode? {
        guard let sprite = Art.sprite(named: name, height: height) else { return nil }
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
        sprite.position = p
        return sprite
    }

    private func buildLilyPads() -> SKNode {
        let c = SKNode()
        c.zPosition = Z.water + 0.3
        let spots: [(CGFloat, CGFloat, CGFloat, Bool)] = [
            (80, 300, 17, true), (150, 482, 13, false), (300, 300, 15, false), (60, 410, 12, false),
            (250, 505, 14, true), (160, 262, 11, false), (330, 450, 12, false),
        ]
        for (x, y, r, flower) in spots {
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addArc(center: .zero, radius: r, startAngle: 0.3, endAngle: 2 * .pi - 0.3, clockwise: false)
            path.closeSubpath()
            var t = CGAffineTransform(rotationAngle: .random(in: 0...(2 * .pi)))
                .concatenating(CGAffineTransform(scaleX: 1, y: 0.6))
            let pad = SKShapeNode(path: path.copy(using: &t) ?? path)
            pad.fillColor = UIColor(r: 0.36, g: 0.62, b: 0.36)
            pad.strokeColor = UIColor(r: 0.27, g: 0.50, b: 0.30)
            pad.lineWidth = 1
            pad.position = CGPoint(x: x, y: y)
            if flower {
                let flowerNode = SKShapeNode(circleOfRadius: 5.5)
                flowerNode.fillColor = UIColor(r: 0.98, g: 0.70, b: 0.80)
                flowerNode.strokeColor = UIColor(r: 0.92, g: 0.55, b: 0.68)
                flowerNode.position = CGPoint(x: 2, y: 3)
                let center = SKShapeNode(circleOfRadius: 2)
                center.fillColor = UIColor(r: 1, g: 0.88, b: 0.45)
                center.strokeColor = .clear
                flowerNode.addChild(center)
                pad.addChild(flowerNode)
            }
            let d = Double.random(in: 1.8...2.6)
            pad.run(.repeatForever(.sequence([.moveBy(x: 0, y: 1.5, duration: d), .moveBy(x: 0, y: -1.5, duration: d)])))
            c.addChild(pad)
        }
        return c
    }

    private func buildDock() -> SKNode {
        let c = SKNode()
        c.zPosition = Z.dock
        if let art = artOrNil("decor_dock", height: 60, at: CGPoint(x: 350, y: 340)) { c.addChild(art); return c }
        let wood = UIColor(r: 0.62, g: 0.45, b: 0.30)
        let dark = UIColor(r: 0.42, g: 0.30, b: 0.20)
        let deck = SKNode()
        deck.position = CGPoint(x: 350, y: 368)
        for px: CGFloat in [-52, -20, 12] {
            let post = SKShapeNode(rect: CGRect(x: px, y: -26, width: 7, height: 22), cornerRadius: 2)
            post.fillColor = dark
            post.strokeColor = .clear
            deck.addChild(post)
        }
        let boards = SKShapeNode(rect: CGRect(x: -62, y: -14, width: 124, height: 30), cornerRadius: 3)
        boards.fillColor = wood
        boards.strokeColor = dark
        boards.lineWidth = 1.5
        deck.addChild(boards)
        let seams = CGMutablePath()
        for i in 1..<8 {
            let x = -62 + CGFloat(i) * 15.5
            seams.move(to: CGPoint(x: x, y: -14))
            seams.addLine(to: CGPoint(x: x, y: 16))
        }
        let planks = SKShapeNode(path: seams)
        planks.strokeColor = dark.withAlphaComponent(0.6)
        planks.lineWidth = 1
        deck.addChild(planks)
        let mooring = SKShapeNode(rect: CGRect(x: -58, y: 10, width: 8, height: 20), cornerRadius: 3)
        mooring.fillColor = dark
        mooring.strokeColor = .clear
        deck.addChild(mooring)
        c.addChild(deck)
        return c
    }

    private func buildCattails() -> SKNode {
        let c = SKNode()
        c.zPosition = Z.front
        let green = UIColor(r: 0.36, g: 0.55, b: 0.30)
        let bases: [CGPoint] = [
            CGPoint(x: 26, y: 318), CGPoint(x: 36, y: 296), CGPoint(x: 48, y: 276), CGPoint(x: 30, y: 345),
            CGPoint(x: 18, y: 372), CGPoint(x: 350, y: 282), CGPoint(x: 362, y: 305), CGPoint(x: 338, y: 264),
            CGPoint(x: 370, y: 330),
        ]
        for base in bases {
            let tail = SKNode()
            tail.position = base
            let h = CGFloat.random(in: 50...80)
            let lean = CGFloat.random(in: -8...8)
            let leaves = SKShapeNode(path: Self.bladePath(blades: 2, height: h * 0.7))
            leaves.fillColor = green.mixed(with: .black, amount: 0.1)
            leaves.strokeColor = .clear
            let stemPath = CGMutablePath()
            stemPath.move(to: .zero)
            stemPath.addQuadCurve(to: CGPoint(x: lean, y: h), control: CGPoint(x: lean * 0.2, y: h * 0.5))
            let stem = SKShapeNode(path: stemPath)
            stem.strokeColor = green
            stem.lineWidth = 2.5
            stem.lineCap = .round
            let head = SKShapeNode(rect: CGRect(x: -3.5, y: 0, width: 7, height: 18), cornerRadius: 3.5)
            head.fillColor = UIColor(r: 0.45, g: 0.30, b: 0.20)
            head.strokeColor = .clear
            head.position = CGPoint(x: lean * 0.85, y: h * 0.72)
            head.zRotation = -lean / h
            tail.addChild(leaves)
            tail.addChild(stem)
            tail.addChild(head)
            let d = Double.random(in: 1.6...2.4)
            tail.run(.repeatForever(.sequence([.rotate(toAngle: 0.05, duration: d), .rotate(toAngle: -0.05, duration: d)])))
            c.addChild(tail)
        }
        return c
    }

    private func buildStonePath() -> SKNode {
        let c = SKNode()
        c.zPosition = Z.ground + 0.5
        let p0 = CGPoint(x: 40, y: 40), ctrl = CGPoint(x: 10, y: 150), p1 = CGPoint(x: 118, y: 232)
        for i in 0..<10 {
            let t = CGFloat(i) / 9
            let w = (30 - t * 10) * .random(in: 0.85...1.15)
            let stone = SKShapeNode(ellipseOf: CGSize(width: w, height: w * 0.45))
            stone.fillColor = UIColor(r: 0.74, g: 0.72, b: 0.68)
            stone.strokeColor = UIColor(r: 0.55, g: 0.54, b: 0.50)
            stone.lineWidth = 1.5
            stone.position = CGPoint.quad(p0, ctrl, p1, t) + CGPoint(x: .random(in: -4...4), y: .random(in: -2...2))
            c.addChild(stone)
        }

        // The mended fence on the far bank
        let fence = SKNode()
        fence.position = CGPoint(x: 210, y: 590)
        fence.zPosition = Z.backDecor - c.zPosition
        let wood = UIColor(r: 0.66, g: 0.50, b: 0.34)
        for x in stride(from: CGFloat(-80), through: 80, by: 32) {
            let post = SKShapeNode(rect: CGRect(x: x - 3, y: 0, width: 6, height: 26), cornerRadius: 1.5)
            post.fillColor = wood
            post.strokeColor = .clear
            fence.addChild(post)
        }
        for y: CGFloat in [8, 17] {
            let rail = SKShapeNode(rect: CGRect(x: -84, y: y, width: 168, height: 4), cornerRadius: 1.5)
            rail.fillColor = wood.mixed(with: .black, amount: 0.08)
            rail.strokeColor = .clear
            fence.addChild(rail)
        }
        c.addChild(fence)
        return c
    }

    private func buildLanterns() -> SKNode {
        let c = SKNode()
        c.zPosition = Z.backDecor + 0.2
        let dark = UIColor(r: 0.36, g: 0.27, b: 0.22)
        let left = CGPoint(x: 14, y: 548), right = CGPoint(x: 380, y: 548)
        let postHeight: CGFloat = 132
        for base in [left, right] {
            let post = SKShapeNode(rect: CGRect(x: -3, y: 0, width: 6, height: postHeight), cornerRadius: 2)
            post.fillColor = dark
            post.strokeColor = .clear
            post.position = base
            c.addChild(post)
        }
        let a = CGPoint(x: left.x, y: left.y + postHeight)
        let b = CGPoint(x: right.x, y: right.y + postHeight)
        let ctrl = CGPoint(x: 197, y: 620)
        let mid = CGPoint(x: 197, y: 650)
        let stringPath = CGMutablePath()
        stringPath.move(to: a - mid)
        stringPath.addQuadCurve(to: b - mid, control: ctrl - mid)
        let string = SKShapeNode(path: stringPath)
        string.position = mid
        string.strokeColor = UIColor(white: 0.2, alpha: 0.8)
        string.lineWidth = 1.2
        c.addChild(string)

        let colors = [UIColor(r: 1, g: 0.72, b: 0.45), UIColor(r: 1, g: 0.62, b: 0.62), UIColor(r: 1, g: 0.86, b: 0.5)]
        for i in 1...7 {
            let lantern = SKNode()
            lantern.position = CGPoint.quad(a, ctrl, b, CGFloat(i) / 8)
            let cord = SKShapeNode(rect: CGRect(x: -0.5, y: -6, width: 1, height: 6))
            cord.fillColor = dark
            cord.strokeColor = .clear
            let body = SKShapeNode(rect: CGRect(x: -5, y: -20, width: 10, height: 14), cornerRadius: 4)
            body.fillColor = colors[i % colors.count]
            body.strokeColor = dark.withAlphaComponent(0.5)
            let glow = makeGlow(color: UIColor(r: 1, g: 0.75, b: 0.4), size: 64, ancestorsZ: c.zPosition)
            glow.position = CGPoint(x: 0, y: -13)
            lantern.addChild(cord)
            lantern.addChild(body)
            lantern.addChild(glow)
            let d = Double.random(in: 1.4...2.0)
            lantern.run(.repeatForever(.sequence([.rotate(toAngle: 0.06, duration: d), .rotate(toAngle: -0.06, duration: d)])))
            c.addChild(lantern)
        }
        return c
    }

    private func buildBoathouse() -> SKNode {
        let c = SKNode()
        c.zPosition = Z.backDecor + 0.1
        if let art = artOrNil("decor_boathouse", height: 80, at: CGPoint(x: 80, y: 545)) { c.addChild(art); return c }

        let house = SKNode()
        house.position = CGPoint(x: 80, y: 560)
        let wood = UIColor(r: 0.62, g: 0.45, b: 0.30)
        let ramp = CGMutablePath()
        ramp.move(to: CGPoint(x: -28, y: 0))
        ramp.addLine(to: CGPoint(x: -6, y: 0))
        ramp.addLine(to: CGPoint(x: 4, y: -48))
        ramp.addLine(to: CGPoint(x: -20, y: -48))
        ramp.closeSubpath()
        let rampNode = SKShapeNode(path: ramp)
        rampNode.fillColor = wood
        rampNode.strokeColor = .clear
        house.addChild(rampNode)
        let walls = SKShapeNode(rect: CGRect(x: -36, y: 0, width: 72, height: 40), cornerRadius: 3)
        walls.fillColor = UIColor(r: 0.66, g: 0.42, b: 0.33)
        walls.strokeColor = UIColor(r: 0.45, g: 0.28, b: 0.24)
        walls.lineWidth = 1.5
        house.addChild(walls)
        let roof = CGMutablePath()
        roof.move(to: CGPoint(x: -44, y: 36))
        roof.addLine(to: CGPoint(x: 0, y: 66))
        roof.addLine(to: CGPoint(x: 44, y: 36))
        roof.closeSubpath()
        let roofNode = SKShapeNode(path: roof)
        roofNode.fillColor = UIColor(r: 0.38, g: 0.28, b: 0.30)
        roofNode.strokeColor = .clear
        house.addChild(roofNode)
        let door = SKShapeNode(rect: CGRect(x: -28, y: 0, width: 24, height: 28), cornerRadius: 2)
        door.fillColor = UIColor(r: 0.30, g: 0.22, b: 0.20)
        door.strokeColor = .clear
        house.addChild(door)
        let window = SKShapeNode(rect: CGRect(x: 8, y: 16, width: 14, height: 12), cornerRadius: 2)
        window.fillColor = UIColor(r: 1, g: 0.86, b: 0.56)
        window.strokeColor = UIColor(r: 0.45, g: 0.28, b: 0.24)
        house.addChild(window)
        let windowGlow = makeGlow(color: UIColor(r: 1, g: 0.8, b: 0.45), size: 70, ancestorsZ: c.zPosition)
        windowGlow.position = CGPoint(x: 15, y: 22)
        house.addChild(windowGlow)
        c.addChild(house)

        let boat = SKNode()
        boat.position = CGPoint(x: 85, y: 470)
        boat.zPosition = Z.water + 0.4 - c.zPosition
        let hull = CGMutablePath()
        hull.addArc(center: .zero, radius: 22, startAngle: .pi, endAngle: 2 * .pi, clockwise: false)
        hull.closeSubpath()
        var squash = CGAffineTransform(scaleX: 1, y: 0.45)
        let hullNode = SKShapeNode(path: hull.copy(using: &squash) ?? hull)
        hullNode.fillColor = UIColor(r: 0.55, g: 0.35, b: 0.25)
        hullNode.strokeColor = UIColor(r: 0.38, g: 0.24, b: 0.18)
        hullNode.lineWidth = 2
        boat.addChild(hullNode)
        boat.run(.repeatForever(.sequence([
            .group([.moveBy(x: 0, y: 2, duration: 1.6), .rotate(toAngle: 0.04, duration: 1.6)]),
            .group([.moveBy(x: 0, y: -2, duration: 1.6), .rotate(toAngle: -0.04, duration: 1.6)]),
        ])))
        c.addChild(boat)
        return c
    }

    private func buildCherryTree() -> SKNode {
        let c = SKNode()
        c.zPosition = Z.backDecor
        if let art = artOrNil("decor_cherryTree", height: 150, at: CGPoint(x: 322, y: 570)) { c.addChild(art); return c }

        let tree = SKNode()
        tree.position = CGPoint(x: 322, y: 575)
        let bark = UIColor(r: 0.42, g: 0.30, b: 0.26)
        let trunkPath = CGMutablePath()
        trunkPath.move(to: .zero)
        trunkPath.addQuadCurve(to: CGPoint(x: -8, y: 82), control: CGPoint(x: 8, y: 40))
        let trunk = SKShapeNode(path: trunkPath)
        trunk.strokeColor = bark
        trunk.lineWidth = 9
        trunk.lineCap = .round
        tree.addChild(trunk)
        let branchPath = CGMutablePath()
        branchPath.move(to: CGPoint(x: -2, y: 50))
        branchPath.addQuadCurve(to: CGPoint(x: 24, y: 86), control: CGPoint(x: 16, y: 58))
        let branch = SKShapeNode(path: branchPath)
        branch.strokeColor = bark
        branch.lineWidth = 5
        branch.lineCap = .round
        tree.addChild(branch)
        let puffs: [(CGFloat, CGFloat, CGFloat)] = [
            (-40, 76, 18), (40, 78, 18), (-12, 78, 22), (18, 76, 22), (-30, 94, 26), (28, 96, 26), (0, 110, 30),
        ]
        for (i, puff) in puffs.enumerated() {
            let blossom = SKShapeNode(circleOfRadius: puff.2)
            blossom.fillColor = i % 2 == 0 ? UIColor(r: 0.98, g: 0.76, b: 0.84) : UIColor(r: 0.95, g: 0.66, b: 0.78)
            blossom.strokeColor = .clear
            blossom.position = CGPoint(x: puff.0, y: puff.1)
            tree.addChild(blossom)
        }
        c.addChild(tree)
        return c
    }

    private func spawnPetal() {
        let petal = SKSpriteNode(texture: SceneTextures.dot)
        petal.size = CGSize(width: 6, height: 4)
        petal.color = UIColor(r: 0.98, g: 0.74, b: 0.84)
        petal.colorBlendFactor = 1
        petal.position = CGPoint(x: 322 + .random(in: -40...40), y: 650 + .random(in: 0...60))
        petal.zPosition = Z.petal
        addChild(petal)
        let end = CGPoint(x: petal.position.x - .random(in: 20...90), y: .random(in: 430...540))
        let duration = Double.random(in: 4...6)
        petal.run(.sequence([
            .group([
                .move(to: end, duration: duration),
                .rotate(byAngle: .random(in: -6...6), duration: duration),
                .sequence([.wait(forDuration: duration - 0.6), .fadeOut(withDuration: 0.6)]),
            ]),
            .run { [weak self] in self?.ripple(at: end, size: 10, alpha: 0.35, duration: 0.8) },
            .removeFromParent(),
        ]))
    }

    private func buildFireflies() -> SKNode {
        let c = SKNode()
        c.zPosition = Z.glow
        c.alpha = palette.fireflyAlpha
        for _ in 0..<16 {
            let fly = SKSpriteNode(texture: SceneTextures.glow)
            fly.size = CGSize(width: 16, height: 16)
            fly.color = UIColor(r: 1, g: 0.95, b: 0.55)
            fly.colorBlendFactor = 1
            fly.blendMode = .add
            fly.position = randomFireflyPoint()
            fly.alpha = 0
            c.addChild(fly)
        }
        return c
    }

    private func randomFireflyPoint() -> CGPoint {
        CGPoint(x: .random(in: 10...380), y: .random(in: 220...640))
    }

    private func startFireflies(_ container: SKNode) {
        for fly in container.children {
            wander(fly)
            let on = Double.random(in: 0.6...1.4)
            fly.run(.repeatForever(.sequence([
                .fadeAlpha(to: .random(in: 0.7...1), duration: on),
                .fadeAlpha(to: 0.1, duration: on * 1.3),
            ])), withKey: "blink")
        }
    }

    private func wander(_ node: SKNode) {
        let target = randomFireflyPoint()
        let move = SKAction.move(to: target, duration: .random(in: 2.5...4.5))
        move.timingMode = .easeInEaseOut
        node.run(.sequence([move, .run { [weak self, weak node] in
            guard let self, let node else { return }
            self.wander(node)
        }]), withKey: "wander")
    }
}
