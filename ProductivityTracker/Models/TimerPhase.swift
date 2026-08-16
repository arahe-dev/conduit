import Foundation

enum TimerPhase: String, Codable, Sendable, Equatable {
    case idle
    case running
    case stopped

    init(persisted raw: String) {
        switch raw {
        case "running":
            self = .running
        case "stopped", "paused":
            self = .stopped
        default:
            self = .idle
        }
    }

    var leftControl: StopwatchLeftControl {
        switch self {
        case .idle: .lapDisabled
        case .running: .lap
        case .stopped: .reset
        }
    }

    var rightControl: StopwatchRightControl {
        switch self {
        case .idle, .stopped: .start
        case .running: .stop
        }
    }
}

enum StopwatchLeftControl: String, Equatable {
    case lapDisabled
    case lap
    case reset
}

enum StopwatchRightControl: String, Equatable {
    case start
    case stop
}
