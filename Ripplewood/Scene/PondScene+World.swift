import SpriteKit
import UIKit

extension PondScene {

    /// The far bank is a quadratic curve; this returns its height at `x`.
    static func hillY(_ x: CGFloat) -> CGFloat {
        let t = (x + 60) / 510
        return (1 - t) * (1 - t) * 606 + 2 * (1 - t) * t * 700 + t * t * 612
    }

    func randomPondPoint(maxR: CGFloat = 0.8) -> CGPoint {
        let r = Self.pondRect
        let angle = CGFloat.random(in: 0..<(2 * .pi))
        let d = sqrt(CGFloat.random(in: 0...1)) * maxR
        return CGPoint(x: r.midX + cos(angle) * d * r.width / 2,
                       y: r.midY + sin(angle) * d * r.height / 2)
    }

    static func bladePath(blades: Int, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for i in 0..<blades {
            let x = CGFloat(i - blades / 2) * 6 + .random(in: -1.5...1.5)
            let h = height * .random(in: 0.6...1.1)
            let lean = CGFloat.random(in: -6...6)
            path.move(to: CGPoint(x: x - 2.5, y: 0))
            path.addQuadCurve(to: CGPoint(x: x + lean, y: h), control: CGPoint(x: x - 2 + lean * 0.2, y: h * 0.6))
            path.addQuadCurve(to: CGPoint(x: x + 2.5, y: 0), control: CGPoint(x: x + 2 + lean * 0.4, y: h * 0.5))
            path.closeSubpath()
        }
        return path
    }

    // MARK: - Building

    func buildWorld() {
        // Sky (two sprites so palette changes can cross-fade)
        for (i, sprite) in [skySprite, skyFade].enumerated() {
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
            sprite.size = CGSize(width: 560, height: 380)
            sprite.position = CGPoint(x: 195, y: 540)
            sprite.zPosition = Z.sky + CGFloat(i) * 0.1
            addChild(sprite)
        }
        skyFade.alpha = 0

        starsNode.zPosition = Z.stars
        addChild(starsNode)
        for _ in 0..<50 {
            let star = SKSpriteNode(texture: SceneTextures.dot)
            let s = CGFloat.random(in: 1.5...3.5)
            star.size = CGSize(width: s, height: s)
            star.position = CGPoint(x: .random(in: 0...390), y: .random(in: 650...900))
            star.alpha = .random(in: 0.4...1)
            let d = Double.random(in: 0.8...2.4)
            star.run(.repeatForever(.sequence([.fadeAlpha(to: 0.25, duration: d), .fadeAlpha(to: 1, duration: d)])))
            starsNode.addChild(star)
        }

        sun.fillColor = palette.sunColor
        sun.strokeColor = .clear
        sun.zPosition = Z.celestial
        let sunGlow = SKSpriteNode(texture: SceneTextures.glow)
        sunGlow.size = CGSize(width: 150, height: 150)
        sunGlow.color = UIColor(r: 1, g: 0.95, b: 0.78)
        sunGlow.colorBlendFactor = 1
        sunGlow.alpha = 0.7
        sunGlow.zPosition = -0.05
        sun.addChild(sunGlow)
        addChild(sun)

        moon.fillColor = UIColor(r: 0.96, g: 0.95, b: 0.88)
        moon.strokeColor = .clear
        moon.position = CGPoint(x: 305, y: 780)
        moon.zPosition = Z.celestial
        let moonGlow = SKSpriteNode(texture: SceneTextures.glow)
        moonGlow.size = CGSize(width: 110, height: 110)
        moonGlow.alpha = 0.35
        moonGlow.zPosition = -0.05
        moon.addChild(moonGlow)
        addChild(moon)

        cloudsNode.zPosition = Z.clouds
        addChild(cloudsNode)
        for i in 0..<5 {
            let cloud = SKNode()
            let w = CGFloat.random(in: 70...120)
            let puffs = [
                CGRect(x: -w / 2, y: -10, width: w, height: 26),
                CGRect(x: -w * 0.3, y: -2, width: w * 0.45, height: 34),
                CGRect(x: -w * 0.02, y: -6, width: w * 0.4, height: 28),
            ]
            for rect in puffs {
                let puff = SKShapeNode(ellipseIn: rect)
                puff.fillColor = .white
                puff.strokeColor = .clear
                cloud.addChild(puff)
                cloudPuffs.append(puff)
            }
            let x = CGFloat.random(in: -40...430)
            cloud.position = CGPoint(x: x, y: CGFloat(690 + i * 34) + .random(in: -10...10))
            cloudsNode.addChild(cloud)
            let speed = CGFloat.random(in: 4...9)
            cloud.run(.sequence([
                .moveTo(x: 490, duration: TimeInterval((490 - x) / speed)),
                .repeatForever(.sequence([
                    .moveTo(x: -110, duration: 0),
                    .moveTo(x: 490, duration: TimeInterval(600 / speed)),
                ])),
            ]))
        }

        // Ground, far bank, pond
        ground.strokeColor = .clear
        ground.zPosition = Z.ground
        addChild(ground)

        let tufts = SKShapeNode(path: { () -> CGPath in
            let p = CGMutablePath()
            for _ in 0..<14 {
                let base = CGPoint(x: .random(in: 10...380), y: .random(in: 20...200))
                var t = CGAffineTransform(translationX: base.x, y: base.y)
                if let blades = Self.bladePath(blades: 3, height: .random(in: 8...14)).copy(using: &t) {
                    p.addPath(blades)
                }
            }
            return p
        }())
        tufts.fillColor = UIColor(r: 0.44, g: 0.64, b: 0.38, a: 0.7)
        tufts.strokeColor = .clear
        tufts.zPosition = Z.ground + 0.1
        addChild(tufts)

        let hillPath = CGMutablePath()
        hillPath.move(to: CGPoint(x: -60, y: 500))
        hillPath.addLine(to: CGPoint(x: -60, y: 606))
        hillPath.addQuadCurve(to: CGPoint(x: 450, y: 612), control: CGPoint(x: 195, y: 700))
        hillPath.addLine(to: CGPoint(x: 450, y: 500))
        hillPath.closeSubpath()
        hill.path = hillPath
        hill.strokeColor = .clear
        hill.zPosition = Z.hill
        addChild(hill)

        pondRim.strokeColor = .clear
        pondRim.zPosition = Z.rim
        addChild(pondRim)

        pond.strokeColor = UIColor(white: 1, alpha: 0.12)
        pond.lineWidth = 2
        pond.zPosition = Z.pond
        addChild(pond)

        for _ in 0..<3 {
            let shine = SKShapeNode(ellipseOf: CGSize(width: .random(in: 60...110), height: 5))
            shine.fillColor = UIColor(white: 1, alpha: 0.16)
            shine.strokeColor = .clear
            shine.position = randomPondPoint(maxR: 0.55)
            shine.zPosition = Z.pond + 0.1
            let dx = CGFloat.random(in: 12...24)
            shine.run(.repeatForever(.sequence([
                .moveBy(x: dx, y: 0, duration: 4), .moveBy(x: -dx, y: 0, duration: 4),
            ])))
            addChild(shine)
        }

        // Night/dusk/rain tint over everything except glows
        overlay.position = CGPoint(x: 195, y: 422)
        overlay.zPosition = Z.overlay
        overlay.alpha = 0
        addChild(overlay)

        // Rain
        rain.particleTexture = SceneTextures.raindrop
        rain.particleBirthRate = 0
        rain.particleLifetime = 1.6
        rain.particlePositionRange = CGVector(dx: 560, dy: 0)
        rain.position = CGPoint(x: 215, y: 900)
        rain.emissionAngle = -.pi / 2 - 0.1
        rain.particleSpeed = 620
        rain.particleSpeedRange = 120
        rain.particleAlpha = 0.45
        rain.particleAlphaRange = 0.2
        rain.particleScale = 1
        rain.particleScaleRange = 0.4
        rain.particleRotation = -0.1
        rain.particleColor = .white
        rain.particleColorBlendFactor = 1
        rain.zPosition = Z.rain
        addChild(rain)
    }

    /// The starting state: murky water, weeds everywhere, broken fence.
    func buildOvergrowth() {
        murk.zPosition = Z.water
        addChild(murk)
        for _ in 0..<12 {
            let w = CGFloat.random(in: 26...60)
            let blob = SKShapeNode(ellipseOf: CGSize(width: w, height: w * 0.32))
            blob.fillColor = UIColor(r: 0.36, g: 0.38, b: 0.2, a: 0.55)
            blob.strokeColor = .clear
            blob.position = randomPondPoint(maxR: 0.85)
            let dx = CGFloat.random(in: -8...8)
            blob.run(.repeatForever(.sequence([.moveBy(x: dx, y: 0, duration: 5), .moveBy(x: -dx, y: 0, duration: 5)])))
            murk.addChild(blob)
        }

        weeds.zPosition = Z.front - 0.5
        addChild(weeds)
        let r = Self.pondRect
        for k in 0..<18 {
            let a = CGFloat(k) / 18 * 2 * .pi + .random(in: -0.12...0.12)
            let p = CGPoint(x: r.midX + cos(a) * r.width / 2 * 0.98,
                            y: r.midY + sin(a) * r.height / 2 * 0.98 - 4)
            addWeedClump(at: p, height: .random(in: 22...40))
        }
        for _ in 0..<9 {
            addWeedClump(at: CGPoint(x: .random(in: 15...330), y: .random(in: 110...205)), height: .random(in: 18...32))
        }
        for _ in 0..<5 {
            addWeedClump(at: CGPoint(x: .random(in: 10...380), y: .random(in: 562...592)), height: .random(in: 16...26))
        }
        for _ in 0..<6 {
            let tangle = SKShapeNode(ellipseOf: CGSize(width: .random(in: 24...40), height: 9))
            tangle.fillColor = UIColor(r: 0.28, g: 0.38, b: 0.18, a: 0.85)
            tangle.strokeColor = .clear
            tangle.position = randomPondPoint(maxR: 0.92)
            weeds.addChild(tangle)
        }

        brokenFence.zPosition = Z.backDecor
        addChild(brokenFence)
        let wood = UIColor(r: 0.55, g: 0.42, b: 0.30)
        for (i, x) in stride(from: CGFloat(130), through: 290, by: 32).enumerated() where i != 2 {
            let post = SKShapeNode(rect: CGRect(x: -3, y: 0, width: 6, height: .random(in: 16...26)), cornerRadius: 1.5)
            post.fillColor = wood
            post.strokeColor = .clear
            post.position = CGPoint(x: x, y: 590)
            post.zRotation = .random(in: -0.35...0.35)
            brokenFence.addChild(post)
        }
        for (x, y, rot) in [(150.0, 600.0, 0.15), (240.0, 596.0, -0.25), (275.0, 606.0, 0.1)] {
            let rail = SKShapeNode(rect: CGRect(x: -16, y: -2, width: 32, height: 4), cornerRadius: 1.5)
            rail.fillColor = wood
            rail.strokeColor = .clear
            rail.position = CGPoint(x: x, y: y)
            rail.zRotation = rot
            brokenFence.addChild(rail)
        }
    }

    private func addWeedClump(at p: CGPoint, height: CGFloat) {
        let clump = SKShapeNode(path: Self.bladePath(blades: Int.random(in: 3...6), height: height))
        clump.fillColor = Bool.random() ? UIColor(r: 0.33, g: 0.43, b: 0.20) : UIColor(r: 0.42, g: 0.50, b: 0.22)
        clump.strokeColor = .clear
        clump.position = p
        let d = Double.random(in: 1.5...2.2)
        clump.run(.repeatForever(.sequence([.rotate(toAngle: 0.05, duration: d), .rotate(toAngle: -0.05, duration: d)])))
        weeds.addChild(clump)
    }

    func buildGear() {
        rod.position = Self.rodBase
        rod.zPosition = Z.rod
        let rodPath = CGMutablePath()
        rodPath.move(to: .zero)
        rodPath.addLine(to: Self.rodLocalTip)
        let pole = SKShapeNode(path: rodPath)
        pole.strokeColor = UIColor(r: 0.45, g: 0.30, b: 0.20)
        pole.lineWidth = 5
        pole.lineCap = .round
        rod.addChild(pole)
        let reel = SKShapeNode(circleOfRadius: 8)
        reel.fillColor = UIColor(r: 0.35, g: 0.38, b: 0.42)
        reel.strokeColor = UIColor(r: 0.2, g: 0.22, b: 0.25)
        reel.lineWidth = 2
        reel.position = CGPoint(x: Self.rodLocalTip.x * 0.18 + 8, y: Self.rodLocalTip.y * 0.18)
        rod.addChild(reel)
        addChild(rod)

        line.strokeColor = UIColor(white: 1, alpha: 0.75)
        line.lineWidth = 1.2
        line.zPosition = Z.line
        line.isHidden = true
        addChild(line)

        if let art = Art.sprite(named: "bobber", height: 20) {
            art.anchorPoint = CGPoint(x: 0.5, y: 0.3)
            bobberBody.addChild(art)
        } else {
            let lower = CGMutablePath()
            lower.addArc(center: .zero, radius: 8, startAngle: .pi, endAngle: 2 * .pi, clockwise: false)
            lower.closeSubpath()
            let bottom = SKShapeNode(path: lower)
            bottom.fillColor = .white
            bottom.strokeColor = .clear
            let upper = CGMutablePath()
            upper.addArc(center: .zero, radius: 8, startAngle: 0, endAngle: .pi, clockwise: false)
            upper.closeSubpath()
            let top = SKShapeNode(path: upper)
            top.fillColor = UIColor(r: 0.92, g: 0.32, b: 0.30)
            top.strokeColor = .clear
            let stick = SKShapeNode(rect: CGRect(x: -1, y: 7, width: 2, height: 6))
            stick.fillColor = UIColor(r: 0.92, g: 0.32, b: 0.30)
            stick.strokeColor = .clear
            bobberBody.addChild(bottom)
            bobberBody.addChild(top)
            bobberBody.addChild(stick)
        }
        bobber.addChild(bobberBody)
        bobber.zPosition = Z.bobber
        bobber.isHidden = true
        addChild(bobber)
    }

    func buildLabels() {
        for (label, size) in [(hintLabel, CGFloat(19)), (messageLabel, CGFloat(32))] {
            label.fontSize = size
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.zPosition = Z.label
            let shadow = SKLabelNode(fontNamed: label.fontName)
            shadow.fontSize = size
            shadow.fontColor = UIColor(white: 0, alpha: 0.3)
            shadow.verticalAlignmentMode = .center
            shadow.position = CGPoint(x: 1.5, y: -1.5)
            shadow.zPosition = -0.1
            label.addChild(shadow)
            label.alpha = 0
            addChild(label)
        }
        hintLabel.position = CGPoint(x: 195, y: 190)
        messageLabel.position = CGPoint(x: 195, y: 610)

        exclaim.text = "!"
        exclaim.fontSize = 34
        exclaim.fontColor = UIColor(r: 1, g: 0.9, b: 0.45)
        exclaim.verticalAlignmentMode = .center
        exclaim.zPosition = Z.label
        exclaim.isHidden = true
        addChild(exclaim)
    }

    private func setText(_ label: SKLabelNode, _ text: String) {
        label.text = text
        (label.children.first as? SKLabelNode)?.text = text
    }

    // MARK: - Labels

    func showHint(_ text: String = "Tap anywhere to cast", pulse: Bool = true) {
        setText(hintLabel, text)
        hintLabel.removeAllActions()
        if pulse {
            hintLabel.run(.sequence([
                .fadeAlpha(to: 0.95, duration: 0.4),
                .repeatForever(.sequence([.fadeAlpha(to: 0.5, duration: 1.1), .fadeAlpha(to: 0.95, duration: 1.1)])),
            ]))
        } else {
            hintLabel.run(.fadeAlpha(to: 0.8, duration: 0.4))
        }
    }

    func hideHint() {
        hintLabel.removeAllActions()
        hintLabel.run(.fadeOut(withDuration: 0.15))
    }

    func showMessage(_ text: String, color: UIColor) {
        setText(messageLabel, text)
        messageLabel.fontColor = color
        messageLabel.removeAllActions()
        messageLabel.setScale(0.6)
        messageLabel.alpha = 0
        messageLabel.position = CGPoint(x: 195, y: 610)
        messageLabel.run(.sequence([
            .group([.fadeIn(withDuration: 0.12), .scale(to: 1.08, duration: 0.18)]),
            .scale(to: 1, duration: 0.1),
            .wait(forDuration: 0.9),
            .group([.fadeOut(withDuration: 0.4), .moveBy(x: 0, y: 16, duration: 0.4)]),
        ]))
    }

    func hideExclaim() {
        exclaim.removeAllActions()
        exclaim.run(.sequence([.fadeOut(withDuration: 0.1), .hide()]))
    }

    // MARK: - Effects

    func ripple(at p: CGPoint, size: CGFloat, alpha: CGFloat = 0.6, duration: TimeInterval = 1.2) {
        let ring = SKShapeNode(ellipseOf: CGSize(width: size, height: size * 0.42))
        ring.strokeColor = UIColor(white: 1, alpha: alpha)
        ring.fillColor = .clear
        ring.lineWidth = 1.5
        ring.position = p
        ring.zPosition = Z.ripple
        ring.setScale(0.3)
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 1.6, duration: duration), .fadeOut(withDuration: duration)]),
            .removeFromParent(),
        ]))
    }

    func splash(at p: CGPoint, count: Int, spread: CGFloat) {
        for _ in 0..<count {
            let drop = SKSpriteNode(texture: SceneTextures.dot)
            let s = CGFloat.random(in: 3...6)
            drop.size = CGSize(width: s, height: s)
            drop.color = UIColor(r: 0.9, g: 0.97, b: 1)
            drop.colorBlendFactor = 1
            drop.position = p
            drop.zPosition = Z.ripple + 0.1
            addChild(drop)
            let dx = CGFloat.random(in: -spread...spread)
            let up = SKAction.moveBy(x: dx, y: .random(in: 18...40), duration: 0.22)
            up.timingMode = .easeOut
            let down = SKAction.moveBy(x: dx * 0.4, y: -38, duration: 0.28)
            down.timingMode = .easeIn
            drop.run(.sequence([up, .group([down, .fadeOut(withDuration: 0.28)]), .removeFromParent()]))
        }
    }

    func sparkle(at p: CGPoint, count: Int = 8, spread: CGFloat = 36, color: UIColor = UIColor(r: 1, g: 0.97, b: 0.8)) {
        for _ in 0..<count {
            let s = SKSpriteNode(texture: SceneTextures.glow)
            s.size = CGSize(width: 20, height: 20)
            s.color = color
            s.colorBlendFactor = 1
            s.blendMode = .add
            s.position = p + CGPoint(x: .random(in: -spread...spread), y: .random(in: -spread * 0.6...spread * 0.6))
            s.zPosition = Z.sparkle
            s.setScale(0.1)
            s.alpha = 0
            addChild(s)
            s.run(.sequence([
                .wait(forDuration: .random(in: 0...0.35)),
                .group([
                    .fadeIn(withDuration: 0.15),
                    .scale(to: .random(in: 0.8...1.5), duration: 0.3),
                    .moveBy(x: 0, y: 16, duration: 0.8),
                ]),
                .fadeOut(withDuration: 0.5),
                .removeFromParent(),
            ]))
        }
    }

    func leap(_ species: FishSpecies, from p: CGPoint) {
        let fish = FishSprite.make(species)
        fish.position = p
        fish.zPosition = Z.leap
        fish.setScale(0.4)
        addChild(fish)
        let tip = rodTipWorld
        let end = CGPoint(x: tip.x, y: tip.y + 30)
        let path = CGMutablePath()
        path.move(to: p)
        path.addQuadCurve(to: end, control: CGPoint(x: (p.x + end.x) / 2, y: max(p.y, end.y) + 150))
        fish.run(.sequence([
            .group([
                .follow(path, asOffset: false, orientToPath: false, duration: 0.8),
                .scale(to: 1.1, duration: 0.4),
                .sequence([.rotate(toAngle: 0.5, duration: 0.25), .rotate(toAngle: -0.4, duration: 0.3), .rotate(toAngle: 0.15, duration: 0.25)]),
            ]),
            .group([.fadeOut(withDuration: 0.25), .scale(to: 0.3, duration: 0.25)]),
            .removeFromParent(),
        ]))
        splash(at: p, count: 10, spread: 28)
        if species.rarity >= .rare {
            sparkle(at: p + CGPoint(x: 0, y: 60), count: species.rarity == .legendary ? 24 : 12, spread: 60,
                    color: UIColor(hex: species.color))
        }
    }

    // MARK: - Ambient life

    func startAmbientLife() {
        run(.repeatForever(.sequence([
            .wait(forDuration: 2.2, withRange: 2.0),
            .run { [weak self] in
                guard let self else { return }
                self.ripple(at: self.randomPondPoint(maxR: 0.85), size: 26, alpha: 0.3, duration: 1.6)
            },
        ])), withKey: "ambientRipples")

        run(.repeatForever(.sequence([
            .wait(forDuration: 8, withRange: 6),
            .run { [weak self] in self?.fishShadow() },
        ])), withKey: "fishShadows")
    }

    private func fishShadow() {
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 34, height: 11))
        shadow.fillColor = .black
        shadow.strokeColor = .clear
        shadow.alpha = 0
        shadow.zPosition = Z.shadow
        let start = randomPondPoint(maxR: 0.6)
        let angle = CGFloat.random(in: 0..<(2 * .pi))
        let end = start + CGPoint(x: cos(angle) * 60, y: sin(angle) * 30)
        shadow.position = start
        shadow.zRotation = atan2(end.y - start.y, end.x - start.x)
        addChild(shadow)
        let a: CGFloat = cleanWater ? 0.16 : 0.06
        shadow.run(.sequence([
            .group([
                .move(to: end, duration: 3.2),
                .sequence([.fadeAlpha(to: a, duration: 0.8), .wait(forDuration: 1.6), .fadeOut(withDuration: 0.8)]),
            ]),
            .removeFromParent(),
        ]))
    }

    // MARK: - Time & weather

    func recolor(_ shape: SKShapeNode, to color: UIColor, duration: TimeInterval) {
        shape.removeAction(forKey: "recolor")
        guard duration > 0 else { shape.fillColor = color; return }
        let from = shape.fillColor
        shape.run(.customAction(withDuration: duration) { node, elapsed in
            (node as? SKShapeNode)?.fillColor = from.mixed(with: color, amount: elapsed / CGFloat(duration))
        }, withKey: "recolor")
    }

    func applyConditions(_ c: PondConditions, animated: Bool) {
        conditions = c
        guard built else { return }
        palette = PondPalette.make(c)
        let d: TimeInterval = animated ? 2.5 : 0

        let texture = SceneTextures.gradient(top: palette.skyTop, bottom: palette.skyBottom)
        skyFade.removeAllActions()
        if animated {
            skyFade.texture = texture
            skyFade.alpha = 0
            skyFade.run(.sequence([
                .fadeIn(withDuration: d),
                .run { [weak self] in
                    self?.skySprite.texture = texture
                    self?.skyFade.alpha = 0
                },
            ]))
        } else {
            skySprite.texture = texture
            skyFade.alpha = 0
        }

        recolor(ground, to: palette.ground, duration: d)
        recolor(hill, to: palette.hill, duration: d)
        recolor(pondRim, to: palette.rim, duration: d)
        recolor(pond, to: palette.water(clean: cleanWater), duration: d)
        recolor(sun, to: palette.sunColor, duration: d)
        for puff in cloudPuffs { recolor(puff, to: palette.cloud, duration: d) }

        cloudsNode.run(.fadeAlpha(to: palette.cloudAlpha, duration: d))
        starsNode.run(.fadeAlpha(to: palette.starAlpha, duration: d))
        sun.run(.group([.fadeAlpha(to: palette.sunAlpha, duration: d), .move(to: palette.sunPosition, duration: d)]))
        moon.run(.fadeAlpha(to: palette.moonAlpha, duration: d))
        overlay.run(.group([
            .colorize(with: palette.overlay, colorBlendFactor: 1, duration: d),
            .fadeAlpha(to: palette.overlayAlpha, duration: d),
        ]))
        for glow in glowSprites { glow.run(.fadeAlpha(to: palette.glowAlpha, duration: d)) }
        decor[.fireflies]?.run(.fadeAlpha(to: palette.fireflyAlpha, duration: d))

        let shouldRain = c.weather == .rain
        if shouldRain != raining {
            raining = shouldRain
            rain.particleBirthRate = shouldRain ? 150 : 0
            if shouldRain {
                if !animated { rain.advanceSimulationTime(2) }
                run(.repeatForever(.sequence([
                    .wait(forDuration: 0.09),
                    .run { [weak self] in
                        guard let self else { return }
                        self.ripple(at: self.randomPondPoint(maxR: 0.95), size: 12, alpha: 0.35, duration: 0.7)
                    },
                ])), withKey: "rainRipples")
            } else {
                removeAction(forKey: "rainRipples")
            }
        }
    }
}
