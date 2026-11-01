import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

extension Rarity {
    var tint: Color {
        switch self {
        case .common: Color(hex: 0x6B8F71)
        case .uncommon: Color(hex: 0x3C7DBF)
        case .rare: Color(hex: 0x8E5BC8)
        case .legendary: Color(hex: 0xD49A1A)
        }
    }
}

struct CoinIcon: View {
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xF4C64E))
            Circle().strokeBorder(Color(hex: 0xC9962A), lineWidth: size * 0.12)
            Circle().fill(Color(hex: 0xFFE08A)).frame(width: size * 0.36, height: size * 0.36)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct CoinAmount: View {
    let amount: Int
    var size: CGFloat = 16

    var body: some View {
        HStack(spacing: 4) {
            CoinIcon(size: size)
            Text("\(amount)")
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(amount) coins")
    }
}

struct RarityPill: View {
    let rarity: Rarity

    var body: some View {
        Text(rarity.label)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(rarity.tint.opacity(0.18), in: Capsule())
            .foregroundStyle(rarity.tint)
    }
}

/// Placeholder fish drawing. If an image named `fish_<id>` exists in the asset catalog it's
/// used instead, so real art can be dropped in later without code changes.
struct FishIllustration: View {
    let species: FishSpecies
    var silhouette = false

    var body: some View {
        if let image = UIImage(named: species.artName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .colorMultiply(silhouette ? .black : .white)
                .opacity(silhouette ? 0.6 : 1)
        } else {
            Canvas { ctx, size in
                let body = silhouette ? Color.black.opacity(0.55) : Color(hex: species.color)
                let accent = silhouette ? Color.black.opacity(0.55) : Color(hex: species.accent)
                switch species.shape {
                case .turtle:
                    Self.drawTurtle(&ctx, size: size, body: body, accent: accent, eye: !silhouette)
                case .fish, .longFish:
                    Self.drawFish(&ctx, size: size, body: body, accent: accent,
                                  long: species.shape == .longFish, eye: !silhouette)
                }
            }
            .aspectRatio(1.6, contentMode: .fit)
        }
    }

    private static func drawFish(_ ctx: inout GraphicsContext, size: CGSize, body: Color, accent: Color, long: Bool, eye: Bool) {
        let w = size.width, h = size.height
        let bodyRect = long
            ? CGRect(x: w * 0.16, y: h * 0.36, width: w * 0.80, height: h * 0.28)
            : CGRect(x: w * 0.24, y: h * 0.22, width: w * 0.70, height: h * 0.56)

        var tail = Path()
        tail.move(to: CGPoint(x: bodyRect.minX + w * 0.04, y: h * 0.5))
        tail.addLine(to: CGPoint(x: w * 0.03, y: h * (long ? 0.28 : 0.2)))
        tail.addLine(to: CGPoint(x: w * 0.03, y: h * (long ? 0.72 : 0.8)))
        tail.closeSubpath()
        ctx.fill(tail, with: .color(accent))

        var fin = Path()
        fin.move(to: CGPoint(x: bodyRect.midX - w * 0.12, y: bodyRect.minY + h * 0.04))
        fin.addQuadCurve(to: CGPoint(x: bodyRect.midX + w * 0.1, y: bodyRect.minY + h * 0.04),
                         control: CGPoint(x: bodyRect.midX - w * 0.04, y: bodyRect.minY - h * 0.16))
        fin.closeSubpath()
        ctx.fill(fin, with: .color(accent))

        ctx.fill(Path(ellipseIn: bodyRect), with: .color(body))

        if eye {
            let r = h * 0.07
            let c = CGPoint(x: bodyRect.maxX - w * 0.1, y: bodyRect.midY - h * 0.05)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(.white))
            let pr = r * 0.6
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - pr + r * 0.2, y: c.y - pr, width: pr * 2, height: pr * 2)),
                     with: .color(Color(white: 0.15)))
        }
    }

    private static func drawTurtle(_ ctx: inout GraphicsContext, size: CGSize, body: Color, accent: Color, eye: Bool) {
        let w = size.width, h = size.height
        for (x, y) in [(0.3, 0.25), (0.62, 0.25), (0.3, 0.75), (0.62, 0.75)] {
            ctx.fill(Path(ellipseIn: CGRect(x: w * x - w * 0.07, y: h * y - h * 0.1, width: w * 0.14, height: h * 0.2)),
                     with: .color(body))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: w * 0.72, y: h * 0.36, width: w * 0.2, height: h * 0.28)), with: .color(body))
        let shell = CGRect(x: w * 0.18, y: h * 0.18, width: w * 0.58, height: h * 0.64)
        ctx.fill(Path(ellipseIn: shell), with: .color(accent))
        ctx.fill(Path(ellipseIn: shell.insetBy(dx: shell.width * 0.25, dy: shell.height * 0.25)),
                 with: .color(body.opacity(0.7)))
        if eye {
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.84, y: h * 0.44, width: w * 0.04, height: w * 0.04)),
                     with: .color(Color(white: 0.15)))
        }
    }
}
