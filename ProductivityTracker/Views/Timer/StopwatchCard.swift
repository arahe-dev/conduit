import SwiftUI

struct StopwatchCard: View {
    @Bindable var controller: SessionController
    var space: Space
    var showsControls: Bool
    var onLongPressLap: () -> Void

    var body: some View {
        let snap = controller.snapshot(for: space.id)
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(space.tint.color)
                    .frame(width: 7, height: 7)
                    .accessibilityHidden(true)
                Text(space.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier(showsControls ? "space-name-card" : "space-name-idle")
                    .accessibilityLabel(space.name)
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 12)

            Spacer(minLength: 4)

            StopwatchDisplay(
                snapshot: snap,
                overrideElapsed: controller.displayOverrideElapsed(for: space.id),
                isActivePage: showsControls
            )

            Spacer(minLength: 18)

            if showsControls {
                StopwatchButtons(controller: controller, onLongPressLap: onLongPressLap)
            } else {
                Color.clear.frame(height: LayoutMetrics.buttonDiameter)
            }

            PageDots(
                count: controller.spaces.count,
                current: currentIndex,
                accent: space.tint.color
            )
            .accessibilityIdentifier(AccessibilityIDs.pageIndicator)
            .padding(.top, 18)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
    }

    private var currentIndex: Int {
        controller.spaces.firstIndex(where: { $0.id == controller.selectedSpaceID }) ?? 0
    }
}
