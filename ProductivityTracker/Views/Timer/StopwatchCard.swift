import SwiftUI

struct StopwatchCard: View {
    @Bindable var controller: SessionController
    var space: Space

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
                    .accessibilityIdentifier("space-name-card")
                    .accessibilityLabel(space.name)
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 12)

            Spacer(minLength: 4)

            StopwatchDisplay(
                snapshot: snap,
                overrideElapsed: controller.displayOverrideElapsed(for: space.id),
                isActivePage: space.id == controller.selectedSpaceID
            )

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
    }
}
