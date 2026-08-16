import SwiftUI

enum ComposePull {
    static func resist(_ translation: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let x = max(0, translation)
        let width = max(pageWidth, 1)
        return width * (1 - exp(-x / (width * 1.15)))
    }

    static func shouldCommit(
        translation: CGFloat,
        predicted: CGFloat,
        pageWidth: CGFloat,
        relaxed: Bool
    ) -> Bool {
        let threshold = pageWidth * (relaxed ? 0.12 : 0.34)
        return translation > threshold || predicted > pageWidth * (relaxed ? 0.18 : 0.48)
    }

    static func shouldDismiss(translation: CGFloat, predicted: CGFloat, pageWidth: CGFloat) -> Bool {
        translation > pageWidth * 0.18 || predicted > pageWidth * 0.28
    }
}
