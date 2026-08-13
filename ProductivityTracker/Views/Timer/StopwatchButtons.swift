import SwiftUI

struct StopwatchButtons: View {
    @Bindable var controller: SessionController
    var onLongPressLap: () -> Void
    @State private var ignoreNextLap = false

    var body: some View {
        HStack {
            left
            Spacer()
            right
        }
        .padding(.horizontal, 12)
        .accessibilityIdentifier("stopwatch-buttons")
    }

    @ViewBuilder
    private var left: some View {
        switch controller.snapshot.phase.leftControl {
        case .lapDisabled:
            circle(title: "Lap", fill: Color(white: 0.18), foreground: Color(white: 0.92).opacity(0.45), identifier: AccessibilityIDs.lapButton, enabled: false, action: {})
        case .lap:
            circle(title: "Lap", fill: Color(white: 0.18), foreground: Color(white: 0.92), identifier: AccessibilityIDs.lapButton, enabled: true) {
                if ignoreNextLap {
                    ignoreNextLap = false
                    return
                }
                try? controller.lap()
            }
            .onLongPressGesture(minimumDuration: 0.55) {
                ignoreNextLap = true
                onLongPressLap()
            }
        case .reset:
            circle(title: "Reset", fill: Color(white: 0.18), foreground: Color(white: 0.92), identifier: AccessibilityIDs.resetButton, enabled: true) {
                try? controller.reset()
            }
        }
    }

    @ViewBuilder
    private var right: some View {
        switch controller.snapshot.phase.rightControl {
        case .start:
            circle(
                title: "Start",
                fill: Color.green.opacity(0.22),
                foreground: Color(red: 0.22, green: 0.84, blue: 0.40),
                identifier: AccessibilityIDs.startStopButton,
                enabled: true
            ) {
                try? controller.start()
            }
        case .stop:
            circle(
                title: "Stop",
                fill: Color.red.opacity(0.22),
                foreground: Color(red: 0.92, green: 0.28, blue: 0.27),
                identifier: AccessibilityIDs.startStopButton,
                enabled: true
            ) {
                try? controller.stop()
            }
        }
    }

    private func circle(
        title: String,
        fill: Color,
        foreground: Color,
        identifier: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(foreground)
                .frame(width: LayoutMetrics.buttonDiameter, height: LayoutMetrics.buttonDiameter)
                .background(Circle().fill(fill))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(identifier)
        .disabled(!enabled)
        .frame(minWidth: 44, minHeight: 44)
    }
}
