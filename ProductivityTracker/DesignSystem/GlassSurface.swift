import SwiftUI

struct GlassSurface<Content: View>: View {
    var tint: Color
    var cornerRadius: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.black.opacity(0.18))
            }
            .glassEffect(.regular.tint(tint.opacity(0.22)), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
