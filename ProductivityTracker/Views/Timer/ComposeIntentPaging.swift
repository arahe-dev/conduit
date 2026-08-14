import SwiftUI

struct ComposeIntentPaging: ScrollTargetBehavior {
    var pageWidth: CGFloat
    var lastSpaceIndex: Int
    var commitFraction: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let width = pageWidth > 1 ? pageWidth : context.containerSize.width
        guard width > 1, lastSpaceIndex >= 0 else { return }
        let lastX = CGFloat(lastSpaceIndex) * width
        let composeX = lastX + width
        let originX = context.originalTarget.rect.minX
        let proposedX = target.rect.minX
        let fromLast = originX > lastX - width * 0.45 && originX < lastX + width * 0.45
        let towardCompose = proposedX > lastX + 8

        if fromLast && towardCompose {
            let pulled = proposedX - lastX
            let flicked = context.velocity.dx > 240
            if pulled < width * commitFraction && !flicked {
                target.rect.origin.x = lastX
            } else {
                target.rect.origin.x = composeX
            }
        } else {
            let maxIndex = CGFloat(lastSpaceIndex + 1)
            let index = min(max(0, (proposedX / width).rounded()), maxIndex)
            target.rect.origin.x = index * width
        }
        target.rect.size = context.containerSize
    }
}
