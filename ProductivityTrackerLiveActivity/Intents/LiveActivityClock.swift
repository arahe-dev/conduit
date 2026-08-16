import Foundation
@preconcurrency import ActivityKit

enum StopwatchRunningDecision: Sendable {
    /// `requested` is Toggle's SetValueIntent value (new isOn). If the system leaves it
    /// at the default `false`, treat the tap as a toggle of the Live Activity's current state.
    static func wantRunning(requested: Bool, currentlyRunning: Bool?) -> Bool {
        guard let currentlyRunning else { return requested }
        if requested == currentlyRunning {
            return !currentlyRunning
        }
        return requested
    }
}

/// Pushes stopwatch pause/resume straight into ActivityKit from the current Live Activity
/// content. The digits are a system timer; this only flips `pauseTime` / re-anchors the interval.
enum LiveActivityClock {
    static var currentIsRunning: Bool? {
        Activity<SessionActivityAttributes>.activities.first?.content.state.isRunning
    }

    static func apply(running: Bool, at now: Date = Date()) async {
        if running {
            await resume(at: now)
        } else {
            await pause(at: now)
        }
    }

    static func pause(at now: Date = Date()) async {
        guard let activity = Activity<SessionActivityAttributes>.activities.first else { return }
        let next = activity.content.state.paused(at: now)
        guard next != activity.content.state else { return }
        await activity.update(ActivityContent(state: next, staleDate: nil))
    }

    static func resume(at now: Date = Date()) async {
        guard let activity = Activity<SessionActivityAttributes>.activities.first else { return }
        let next = activity.content.state.resumed(at: now)
        guard next != activity.content.state else { return }
        await activity.update(ActivityContent(state: next, staleDate: nil))
    }

    static func dismiss() async {
        for activity in Activity<SessionActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
