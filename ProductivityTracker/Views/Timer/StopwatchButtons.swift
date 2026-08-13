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
            StopwatchCircleButton(
                kind: .lap,
                action: {},
                isEnabled: false,
                identifier: AccessibilityIDs.lapButton
            )
        case .lap:
            StopwatchCircleButton(
                kind: .lap,
                action: {
                    if ignoreNextLap {
                        ignoreNextLap = false
                        return
                    }
                    try? controller.lap()
                },
                identifier: AccessibilityIDs.lapButton
            )
            .onLongPressGesture(minimumDuration: 0.55, pressing: { _ in }, perform: {
                ignoreNextLap = true
                onLongPressLap()
            })
            .accessibilityHint("Long press to choose a task")
        case .reset:
            StopwatchCircleButton(
                kind: .reset,
                action: { try? controller.reset() },
                identifier: AccessibilityIDs.resetButton
            )
        }
    }

    @ViewBuilder
    private var rightButton: some View {
        switch controller.snapshot.phase.rightControl {
        case .start:
            StopwatchCircleButton(
                kind: .start,
                action: { try? controller.start() },
                identifier: AccessibilityIDs.startStopButton
            )
        case .stop:
            StopwatchCircleButton(
                kind: .stop,
                action: { try? controller.stop() },
                identifier: AccessibilityIDs.startStopButton
            )
        }
    }
}
