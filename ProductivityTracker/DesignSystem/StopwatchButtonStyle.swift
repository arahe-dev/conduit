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
            case .lap, .reset: Color.gray.opacity(0.28)
            case .start: Color.green.opacity(0.28)
            case .stop: Color.red.opacity(0.28)
            }
        }

        var foreground: Color {
            switch self {
            case .lap, .reset: .white
            case .start: .green
            case .stop: .red
            }
        }
    }

    var kind: Kind
    var action: () -> Void
    var diameter: CGFloat = LayoutMetrics.buttonDiameter

    var body: some View {
        Button(action: action) {
            Text(kind.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(kind.foreground)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(kind.fill))
                .overlay {
                    Circle()
                        .strokeBorder(kind.foreground.opacity(0.22), lineWidth: 1)
                }
                .glassEffect(.regular.tint(kind.foreground.opacity(0.18)).interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(kind.title)
        .frame(minWidth: 44, minHeight: 44)
    }
}
