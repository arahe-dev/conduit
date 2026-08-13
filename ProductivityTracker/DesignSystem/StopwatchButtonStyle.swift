import SwiftUI

struct StopwatchCircleButton: View {
    enum Kind {
        case lap
        case start
        case stop
        case reset

        var title: String {
            switch self {
            case .lap: "Lap"
            case .start: "Start"
            case .stop: "Stop"
            case .reset: "Reset"
            }
        }

        var fill: Color {
            switch self {
            case .lap, .reset: Color(white: 0.18)
            case .start: Color.green.opacity(0.22)
            case .stop: Color.red.opacity(0.22)
            }
        }

        var foreground: Color {
            switch self {
            case .lap, .reset: Color(white: 0.92)
            case .start: Color(red: 0.22, green: 0.84, blue: 0.40)
            case .stop: Color(red: 0.92, green: 0.28, blue: 0.27)
            }
        }
    }

    var kind: Kind
    var action: () -> Void
    var isEnabled: Bool = true
    var identifier: String? = nil
    var diameter: CGFloat = LayoutMetrics.buttonDiameter

    var body: some View {
        Button(action: action) {
            Text(kind.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(kind.foreground.opacity(isEnabled ? 1 : 0.45))
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(kind.fill.opacity(isEnabled ? 1 : 0.55)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(kind.title)
        .accessibilityIdentifier(identifier ?? kind.title.lowercased())
        .disabled(!isEnabled)
        .frame(minWidth: 44, minHeight: 44)
    }
}
