import Foundation
import ActivityKit

struct SessionActivityAttributes: ActivityAttributes, Sendable {
    var sessionID: UUID

    struct ContentState: Codable, Hashable, Sendable {
        var spaceName: String
        var taskName: String
        var phaseRaw: String
        var displayStart: Date
        var isRunning: Bool
        var elapsedAtPause: TimeInterval
    }
}

enum LiveActivityControl: String, Equatable {
    case stop
    case start
}

enum LiveActivityPresentation {
    /// Ordinary taps on the activity surface must not mutate the timer.
    static let backgroundMutatesTimer = false
    static let backgroundIntentName: String? = nil

    static func exclusiveControl(isRunning: Bool) -> LiveActivityControl {
        isRunning ? .stop : .start
    }

    static func exclusiveControlIntentName(isRunning: Bool) -> String {
        isRunning ? "StopFromLiveActivityIntent" : "ResumeFromLiveActivityIntent"
    }

    static func content(
        spaceName: String,
        taskName: String,
        snapshot: TimerSnapshot,
        now: Date
    ) -> SessionActivityAttributes.ContentState {
        let elapsed = snapshot.elapsed(at: now)
        return SessionActivityAttributes.ContentState(
            spaceName: spaceName,
            taskName: taskName,
            phaseRaw: snapshot.phase.rawValue,
            displayStart: now.addingTimeInterval(-elapsed),
            isRunning: snapshot.isRunning,
            elapsedAtPause: elapsed
        )
    }
}
