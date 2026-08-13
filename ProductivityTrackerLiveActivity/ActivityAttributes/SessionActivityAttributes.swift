import Foundation
import ActivityKit

struct SessionActivityAttributes: ActivityAttributes, Sendable {
    var spaceName: String

    struct ContentState: Codable, Hashable, Sendable {
        var taskName: String
        var phaseRaw: String
        var displayStart: Date
        var isRunning: Bool
        var elapsedAtPause: TimeInterval
    }
}
