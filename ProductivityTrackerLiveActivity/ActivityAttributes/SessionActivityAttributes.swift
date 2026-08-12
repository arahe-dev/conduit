import Foundation
import ActivityKit

struct SessionActivityAttributes: ActivityAttributes {
    var spaceName: String

    struct ContentState: Codable, Hashable {
        var taskName: String
        var phaseRaw: String
        var displayStart: Date
        var isRunning: Bool
        var elapsedAtPause: TimeInterval
    }
}
