import SwiftUI

struct SpaceIconView: View {
    var icon: SpaceIcon
    var tint: Color
    var pointSize: CGFloat = 28

    var body: some View {
        Group {
            switch icon.kind {
            case .symbol:
                Image(systemName: icon.value)
                    .font(.system(size: pointSize * 0.62, weight: .semibold))
                    .foregroundStyle(.white)
            case .emoji:
                Text(icon.value)
                    .font(.system(size: pointSize * 0.62))
            case .monogram:
                Text(icon.monogramText)
                    .font(.system(size: max(11, pointSize * 0.36), weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .frame(width: pointSize, height: pointSize)
        .background {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.95), tint.opacity(0.55)],
                        center: .top,
                        startRadius: 0,
                        endRadius: pointSize
                    )
                )
                .shadow(color: tint.opacity(0.55), radius: pointSize * 0.18, y: pointSize * 0.04)
        }
        .accessibilityHidden(true)
    }
}
