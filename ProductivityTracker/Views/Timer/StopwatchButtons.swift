import SwiftUI

struct StopwatchButtons: View {
    @Bindable var controller: SessionController
    var onLongPressLap: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 80) {
            HStack {
                leftButton
                Spacer()
                rightButton
            }
            .padding(.horizontal, 28)
        }
    }

    @ViewBuilder
    private var leftButton: some View {
        switch controller.snapshot.phase {
        case .idle, .stopped:
            StopwatchCircleButton(kind: .lap, action: {})
                .opacity(0.45)
                .disabled(true)
                .accessibilityIdentifier(AccessibilityIDs.lapButton)
        case .running, .paused:
            StopwatchCircleButton(kind: .lap) {
                try? controller.lap()
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.55).onEnded { _ in
                    onLongPressLap()
                }
            )
            .accessibilityIdentifier(AccessibilityIDs.lapButton)
            .accessibilityHint("Long press to choose a task")
        }
    }

    @ViewBuilder
    private var rightButton: some View {
        switch controller.snapshot.phase {
        case .idle, .paused:
            StopwatchCircleButton(kind: .start) {
                try? controller.start()
            }
            .accessibilityIdentifier(AccessibilityIDs.startStopButton)
        case .stopped:
            StopwatchCircleButton(kind: .start) {
                controller.resetStoppedDisplay()
                try? controller.start()
            }
            .accessibilityIdentifier(AccessibilityIDs.startStopButton)
        case .running:
            StopwatchCircleButton(kind: .stop) {
                try? controller.stop()
            }
            .accessibilityIdentifier(AccessibilityIDs.startStopButton)
        }
    }
}
