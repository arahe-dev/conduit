import SwiftUI

struct StopwatchCard: View {
    @Bindable var controller: SessionController
    var space: Space
    var showsControls: Bool
    var onLongPressLap: () -> Void

    var body: some View {
        GlassSurface(tint: space.tint.color, cornerRadius: LayoutMetrics.cardCorner) {
            VStack(spacing: 0) {
                HStack {
                    Text(space.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier(showsControls ? "space-name-card" : "space-name-idle")
                        .accessibilityLabel(space.name)
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)

                Spacer(minLength: 8)

                StopwatchDisplay(controller: controller)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 8)

                if showsControls {
                    StopwatchButtons(controller: controller, onLongPressLap: onLongPressLap)
                        .padding(.bottom, 10)
                } else {
                    Color.clear.frame(height: LayoutMetrics.buttonDiameter + 10)
                }

                PageDots(count: controller.spaces.count, current: currentIndex)
                    .accessibilityIdentifier(AccessibilityIDs.pageIndicator)
                    .padding(.bottom, 16)
            }
        }
    }

    private var currentIndex: Int {
        controller.spaces.firstIndex(where: { $0.id == space.id }) ?? 0
    }
}
