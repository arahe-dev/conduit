import Foundation

enum TimerPhase: String, Codable, Sendable, Equatable {
    case idle
    case running
    case paused
    case stopped
}
