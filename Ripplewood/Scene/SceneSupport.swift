import SpriteKit
import UIKit

/// Global draw order. Child z-positions are relative to their parents, so nodes that must
/// glow above the night overlay offset themselves (see `PondScene.makeGlow`).
enum Z {
    static let sky: CGFloat = 0
    static let stars: CGFloat = 1
    static let celestial: CGFloat = 1.5
    static let clouds: CGFloat = 2
    static let ground: CGFloat = 3
    static let hill: CGFloat = 4
    static let backDecor: CGFloat = 5
    static let rim: CGFloat = 5.8
    static let pond: CGFloat = 6
    static let shadow: CGFloat = 6.4
    static let water: CGFloat = 7
    static let ripple: CGFloat = 7.6
    static let dock: CGFloat = 8
    static let bobber: CGFloat = 9
    static let line: CGFloat = 9.5
    static let front: CGFloat = 10
    static let rod: CGFloat = 11
    static let petal: CGFloat = 11.5
    static let rain: CGFloat = 12
    static let overlay: CGFloat = 13
    static let glow: CGFloat = 14
    static let leap: CGFloat = 15
    static let sparkle: CGFloat = 16
    static let label: CGFloat = 20
}

extension CGPoint {
    static func + (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x - b.x, y: a.y - b.y) }

    static func quad(_ p0: CGPoint, _ c: CGPoint, _ p1: CGPoint, _ t: CGFloat) -> CGPoint {
        let u = 1 - t
        return CGPoint(x: u * u * p0.x + 2 * u * t * c.x + t * t * p1.x,
                       y: u * u * p0.y + 2 * u * t * c.y + t * t * p1.y)
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }

    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    func mixed(with other: UIColor, amount: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = min(max(amount, 0), 1)
        return UIColor(red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t,
                       blue: b1 + (b2 - b1) * t, alpha: a1 + (a2 - a1) * t)
    }
}

/// Procedural textures so the game is fully playable before any real art exists.
enum SceneTextures {
    static let glow: SKTexture = {
        let size = CGSize(width: 64, height: 64)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
            let c = CGPoint(x: 32, y: 32)
            ctx.cgContext.drawRadialGradient(gradient, startCenter: c, startRadius: 0, endCenter: c, endRadius: 32, options: [])
        }
        return SKTexture(image: image)
    }()

    static let dot: SKTexture = {
        let size = CGSize(width: 16, height: 16)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        }
        return SKTexture(image: image)
    }()

    static let raindrop: SKTexture = {
        let size = CGSize(width: 2, height: 16)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 1).fill()
        }
        return SKTexture(image: image)
    }()

    static func gradient(top: UIColor, bottom: UIColor) -> SKTexture {
        let size = CGSize(width: 4, height: 256)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        }
        return SKTexture(image: image)
    }
}

/// Optional real art: drop an image with this name into Assets.xcassets/Art and it replaces
/// the placeholder shape automatically.
enum Art {
    static func sprite(named name: String, height: CGFloat) -> SKSpriteNode? {
        guard let image = UIImage(named: name) else { return nil }
        let texture = SKTexture(image: image)
        let aspect = image.size.width / max(image.size.height, 1)
        let sprite = SKSpriteNode(texture: texture, size: CGSize(width: height * aspect, height: height))
        return sprite
    }
}

/// A placeholder fish/turtle built from shapes, used for the catch leap.
enum FishSprite {
    static func make(_ species: FishSpecies) -> SKNode {
        let node = SKNode()
        if species.rarity >= .rare {
            let glow = SKSpriteNode(texture: SceneTextures.glow)
            glow.size = CGSize(width: 110, height: 110)
            glow.color = UIColor(hex: species.color)
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.8
            glow.zPosition = -1
            node.addChild(glow)
        }
        if let art = Art.sprite(named: species.artName, height: 34) {
            node.addChild(art)
            return node
        }
        let body = UIColor(hex: species.color)
        let accent = UIColor(hex: species.accent)

        switch species.shape {
        case .turtle:
            for (x, y) in [(-11.0, -9.0), (11.0, -9.0), (-11.0, 9.0), (11.0, 9.0)] {
                let leg = SKShapeNode(ellipseOf: CGSize(width: 9, height: 7))
                leg.fillColor = body; leg.strokeColor = .clear
                leg.position = CGPoint(x: x, y: y)
                node.addChild(leg)
            }
            let head = SKShapeNode(circleOfRadius: 6)
            head.fillColor = body; head.strokeColor = .clear
            head.position = CGPoint(x: 20, y: 0)
            node.addChild(head)
            let shell = SKShapeNode(ellipseOf: CGSize(width: 34, height: 24))
            shell.fillColor = accent; shell.strokeColor = body; shell.lineWidth = 2
            node.addChild(shell)
            let pattern = SKShapeNode(ellipseOf: CGSize(width: 16, height: 11))
            pattern.fillColor = body.withAlphaComponent(0.7); pattern.strokeColor = .clear
            node.addChild(pattern)
        case .fish, .longFish:
            let long = species.shape == .longFish
            let bw: CGFloat = long ? 60 : 40
            let bh: CGFloat = long ? 13 : 20
            let tail = CGMutablePath()
            tail.move(to: CGPoint(x: -bw / 2 + 4, y: 0))
            tail.addLine(to: CGPoint(x: -bw / 2 - 12, y: 9))
            tail.addLine(to: CGPoint(x: -bw / 2 - 12, y: -9))
            tail.closeSubpath()
            let tailNode = SKShapeNode(path: tail)
            tailNode.fillColor = accent; tailNode.strokeColor = .clear
            node.addChild(tailNode)
            let fin = CGMutablePath()
            fin.move(to: CGPoint(x: -6, y: bh / 2 - 2))
            fin.addQuadCurve(to: CGPoint(x: 8, y: bh / 2 - 1), control: CGPoint(x: -2, y: bh / 2 + 9))
            fin.closeSubpath()
            let finNode = SKShapeNode(path: fin)
            finNode.fillColor = accent; finNode.strokeColor = .clear
            node.addChild(finNode)
            let bodyNode = SKShapeNode(ellipseOf: CGSize(width: bw, height: bh))
            bodyNode.fillColor = body; bodyNode.strokeColor = accent.withAlphaComponent(0.6); bodyNode.lineWidth = 1
            node.addChild(bodyNode)
            let eye = SKShapeNode(circleOfRadius: 2.2)
            eye.fillColor = UIColor(white: 0.15, alpha: 1); eye.strokeColor = .white; eye.lineWidth = 1
            eye.position = CGPoint(x: bw / 2 - 7, y: 2)
            node.addChild(eye)
        }
        return node
    }
}
