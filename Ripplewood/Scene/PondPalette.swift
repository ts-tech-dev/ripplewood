import UIKit

/// Colors for the pond scene, derived from time of day and weather.
struct PondPalette {
    var skyTop = UIColor(r: 0.53, g: 0.78, b: 0.95)
    var skyBottom = UIColor(r: 0.86, g: 0.93, b: 0.96)
    var hill = UIColor(r: 0.52, g: 0.73, b: 0.44)
    var ground = UIColor(r: 0.60, g: 0.79, b: 0.49)
    var rim = UIColor(r: 0.58, g: 0.52, b: 0.38)
    var waterClean = UIColor(r: 0.45, g: 0.74, b: 0.84)
    var waterMurky = UIColor(r: 0.45, g: 0.48, b: 0.32)
    var cloud = UIColor.white
    var cloudAlpha: CGFloat = 0.45
    var starAlpha: CGFloat = 0
    var sunAlpha: CGFloat = 1
    var sunPosition = CGPoint(x: 300, y: 770)
    var sunColor = UIColor(r: 1.0, g: 0.93, b: 0.66)
    var moonAlpha: CGFloat = 0
    var overlay = UIColor(r: 0.2, g: 0.25, b: 0.35)
    var overlayAlpha: CGFloat = 0
    var glowAlpha: CGFloat = 0.15
    var fireflyAlpha: CGFloat = 0.25

    func water(clean: Bool) -> UIColor { clean ? waterClean : waterMurky }

    static func make(_ c: PondConditions) -> PondPalette {
        var p = PondPalette()
        switch c.time {
        case .day:
            break
        case .dusk:
            p.skyTop = UIColor(r: 0.42, g: 0.40, b: 0.70)
            p.skyBottom = UIColor(r: 0.98, g: 0.67, b: 0.52)
            p.hill = UIColor(r: 0.46, g: 0.57, b: 0.42)
            p.ground = UIColor(r: 0.54, g: 0.65, b: 0.45)
            p.rim = UIColor(r: 0.52, g: 0.44, b: 0.36)
            p.waterClean = UIColor(r: 0.52, g: 0.58, b: 0.76)
            p.waterMurky = UIColor(r: 0.43, g: 0.41, b: 0.33)
            p.cloud = UIColor(r: 0.98, g: 0.82, b: 0.80)
            p.starAlpha = 0.3
            p.sunPosition = CGPoint(x: 70, y: 650)
            p.sunColor = UIColor(r: 1.0, g: 0.62, b: 0.40)
            p.overlay = UIColor(r: 0.55, g: 0.25, b: 0.40)
            p.overlayAlpha = 0.12
            p.glowAlpha = 0.6
            p.fireflyAlpha = 0.7
        case .night:
            p.skyTop = UIColor(r: 0.06, g: 0.08, b: 0.20)
            p.skyBottom = UIColor(r: 0.19, g: 0.23, b: 0.40)
            p.hill = UIColor(r: 0.20, g: 0.30, b: 0.30)
            p.ground = UIColor(r: 0.24, g: 0.35, b: 0.32)
            p.rim = UIColor(r: 0.26, g: 0.26, b: 0.26)
            p.waterClean = UIColor(r: 0.17, g: 0.28, b: 0.44)
            p.waterMurky = UIColor(r: 0.20, g: 0.22, b: 0.18)
            p.cloud = UIColor(r: 0.32, g: 0.35, b: 0.45)
            p.starAlpha = 1
            p.sunAlpha = 0
            p.sunPosition = CGPoint(x: 40, y: 600)
            p.moonAlpha = 1
            p.overlay = UIColor(r: 0.04, g: 0.06, b: 0.18)
            p.overlayAlpha = 0.30
            p.glowAlpha = 1
            p.fireflyAlpha = 1
        }

        let night = c.time == .night
        let greyTone = night ? UIColor(r: 0.22, g: 0.24, b: 0.30) : UIColor(r: 0.62, g: 0.65, b: 0.68)
        func grey(_ color: UIColor, _ amount: CGFloat) -> UIColor { color.mixed(with: greyTone, amount: amount) }

        switch c.weather {
        case .clear:
            break
        case .cloudy:
            p.skyTop = grey(p.skyTop, 0.40)
            p.skyBottom = grey(p.skyBottom, 0.35)
            p.hill = grey(p.hill, 0.15)
            p.ground = grey(p.ground, 0.15)
            p.waterClean = grey(p.waterClean, 0.2)
            p.waterMurky = grey(p.waterMurky, 0.2)
            p.cloud = grey(p.cloud, 0.2)
            p.cloudAlpha = 0.95
            p.starAlpha *= 0.35
            p.sunAlpha *= 0.35
            p.moonAlpha *= 0.4
        case .rain:
            p.skyTop = grey(p.skyTop, 0.55)
            p.skyBottom = grey(p.skyBottom, 0.5)
            p.hill = grey(p.hill, 0.25)
            p.ground = grey(p.ground, 0.25)
            p.waterClean = grey(p.waterClean, 0.3)
            p.waterMurky = grey(p.waterMurky, 0.3)
            p.cloud = grey(p.cloud, 0.45)
            p.cloudAlpha = 1
            p.starAlpha = 0
            p.sunAlpha = 0
            p.moonAlpha *= 0.2
            if c.time == .day { p.overlay = UIColor(r: 0.2, g: 0.25, b: 0.35) }
            p.overlayAlpha += 0.10
        }
        return p
    }
}
