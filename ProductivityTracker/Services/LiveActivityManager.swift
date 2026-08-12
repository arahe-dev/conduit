import Foundation
import ActivityKit

protocol LiveActivityManaging: AnyObject {
    func startOrUpdate(from controller: SessionController, at now: Date)
    func end(at now: Date, elapsed: TimeInterval)
    func dismiss()
}

@MainActor
final class LiveActivityManager: LiveActivityManaging {
    func startOrUpdate(from controller: SessionController, at now: Date) {
        #if !targetEnvironment(simulator) || true
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let snapshot = controller.snapshot
        guard snapshot.sessionID != nil else { return }
        let attributes = SessionActivityAttributes(spaceName: controller.selectedSpace?.name ?? "Space")
        let elapsed = controller.displayedElapsed(at: now)
        let state = SessionActivityAttributes.ContentState(
            taskName: controller.activeTask?.name ?? "Task",
            phaseRaw: snapshot.phase.rawValue,
            displayStart: now.addingTimeInterval(-elapsed),
            isRunning: snapshot.phase == .running,
            elapsedAtPause: elapsed
        )
        let content = ActivityContent(state: state, staleDate: nil)
        if let existing = Activity<SessionActivityAttributes>.activities.first {
            Task { await existing.update(content) }
        } else {
            do {
                _ = try Activity.request(attributes: attributes, content: content)
            } catch {
                // Live Activities are optional; the timer remains authoritative in-app.
            }
        }
        #endif
    }

    func end(at now: Date, elapsed: TimeInterval) {
        let state = SessionActivityAttributes.ContentState(
            taskName: "Stopped",
            phaseRaw: TimerPhase.stopped.rawValue,
            displayStart: now.addingTimeInterval(-elapsed),
            isRunning: false,
            elapsedAtPause: elapsed
        )
        let content = ActivityContent(state: state, staleDate: now)
        for activity in Activity<SessionActivityAttributes>.activities {
            Task { await activity.end(content, dismissalPolicy: .after(.now + 8)) }
        }
    }

    func dismiss() {
        for activity in Activity<SessionActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}

final class NullLiveActivityManager: LiveActivityManaging {
    var started = 0
    var ended = 0
    func startOrUpdate(from controller: SessionController, at now: Date) {
        started += 1
        _ = controller
        _ = now
    }
    func end(at now: Date, elapsed: TimeInterval) {
        ended += 1
        _ = now
        _ = elapsed
    }
    func dismiss() {}
}
