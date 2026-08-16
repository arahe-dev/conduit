import Foundation
@preconcurrency import ActivityKit

/// Pushes stopwatch pause/resume straight into ActivityKit from the current Live Activity
/// content. This is the Clock-app path: the lock-screen digits are a system timer, so the only
/// work on tap is flipping `pauseTime` / re-anchoring the interval — no SwiftData, no UI.
enum LiveActivityClock {
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
