import SwiftUI

struct StopwatchButtons: View {
    @Bindable var controller: SessionController
    var onLongPressLap: () -> Void

    var body: some View {
        HStack {
            leftButton
            Spacer()
            rightButton
        }
        .padding(.horizontal, 28)
    }

    @ViewBuilder
    private var leftButton: some View {
        switch controller.snapshot.phase.leftControl {
        case .lapDisabled:
            StopwatchCircleButton(kind: .lap, action: {})
                .opacity(0.45)
                .disabled(true)
                .accessibilityIdentifier(AccessibilityIDs.lapButton)
        case .lap:
            LapControl(
                onTap: { try? controller.lap() },
                onLongPress: onLongPressLap
            )
        case .reset:
            StopwatchCircleButton(kind: .reset) {
                try? controller.reset()
            }
            .accessibilityIdentifier(AccessibilityIDs.resetButton)
        }
    }

    @ViewBuilder
    private var rightButton: some View {
        switch controller.snapshot.phase.rightControl {
        case .start:
            StopwatchCircleButton(kind: .start) {
                try? controller.start()
            }
            .accessibilityIdentifier(AccessibilityIDs.startStopButton)
        case .stop:
            StopwatchCircleButton(kind: .stop) {
                try? controller.stop()
            }
            .accessibilityIdentifier(AccessibilityIDs.startStopButton)
        }
    }
}

private struct LapControl: View {
    var onTap: () -> Void
    var onLongPress: () -> Void
    @State private var pressStarted: Date?
    private let kind = StopwatchCircleButton.Kind.lap

    var body: some View {
        Text(kind.title)
            .font(.body.weight(.semibold))
            .foregroundStyle(kind.foreground)
            .frame(width: LayoutMetrics.buttonDiameter, height: LayoutMetrics.buttonDiameter)
            .background(Circle().fill(kind.fill))
            .overlay {
                Circle()
                    .strokeBorder(kind.foreground.opacity(0.22), lineWidth: 1)
            }
            .glassEffect(.regular.tint(kind.foreground.opacity(0.18)).interactive(), in: .circle)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if pressStarted == nil {
                            pressStarted = Date()
                        }
                    }
                    .onEnded { _ in
                        let duration = Date().timeIntervalSince(pressStarted ?? Date())
                        pressStarted = nil
                        if duration >= 0.55 {
                            onLongPress()
                        } else {
                            onTap()
                        }
                    }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(kind.title)
            .accessibilityIdentifier(AccessibilityIDs.lapButton)
            .accessibilityHint("Long press to choose a task")
            .frame(minWidth: 44, minHeight: 44)
    }
}
