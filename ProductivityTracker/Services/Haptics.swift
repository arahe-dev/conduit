import Foundation
import UIKit

enum Haptics {
    static func start() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func stop() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func lap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func spaceChange() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func destructive() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
