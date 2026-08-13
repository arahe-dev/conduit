import SwiftUI

struct StopwatchButtons: View {
    @Bindable var controller: SessionController
    var onLongPressLap: () -> Void
    @State private var ignoreNextLap = false

    var body: some View {
        HStack {
            leftButton
            Spacer()
            rightButton
        }
        .padding(.horizontal, 12)
        .accessibilityIdentifier("stopwatch-buttons")
    }

    @ViewBuilder
    private var leftButton: some View {
        switch controller.snapshot.phase.leftControl {
        case .lapDisabled:
            StopwatchCircleButton(kind: .lap, action: {}, isEnabled: false)
                .accessibilityIdentifier(AccessibilityIDs.lapButton)
        case .lap:
            StopwatchCircleButton(kind: .lap) {
                if ignoreNextLap {
                    ignoreNextLap = false
                    return
                }
                try? controller.lap()
            }
            .onLongPressGesture(minimumDuration: 0.55, pressing: { _ in }, perform: {
                ignoreNextLap = true
                onLongPressLap()
            })
            .accessibilityIdentifier(AccessibilityIDs.lapButton)
            .accessibilityHint("Long press to choose a task")
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
