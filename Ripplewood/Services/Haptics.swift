import UIKit

enum Haptics {
    static var enabled = true

    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let notifier = UINotificationFeedbackGenerator()

    static func prepare() {
        light.prepare()
        heavy.prepare()
        notifier.prepare()
    }

    /// Light tap — a fish is nibbling.
    static func nibble() {
        guard enabled else { return }
        light.impactOccurred(intensity: 0.7)
        light.prepare()
    }

    /// Strong tap — the bite!
    static func bite() {
        guard enabled else { return }
        heavy.impactOccurred(intensity: 1.0)
        notifier.prepare()
    }

    /// Success pattern — fish landed / upgrade bought.
    static func success() {
        guard enabled else { return }
        notifier.notificationOccurred(.success)
        heavy.prepare()
    }

    static func tap() {
        guard enabled else { return }
        soft.impactOccurred()
    }
}
