import Foundation
import ActivityKit

@MainActor
protocol LiveActivityManaging: AnyObject {
    func startOrUpdate(from controller: SessionController, at now: Date)
    func dismissImmediate()
}

@MainActor
final class LiveActivityManager: LiveActivityManaging {
    func startOrUpdate(from controller: SessionController, at now: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard let space = controller.liveActivitySpace() else { return }
        let snapshot = controller.snapshot(for: space.id)
        guard let sessionID = snapshot.sessionID else { return }
        let taskName = space.tasks.first(where: { $0.id == snapshot.currentTaskID })?.name
            ?? controller.activeTask?.name
            ?? "Task"
        let state = LiveActivityPresentation.content(
            spaceName: space.name,
            taskName: taskName,
            phaseRaw: snapshot.phase.rawValue,
            isRunning: snapshot.isRunning,
            elapsed: snapshot.elapsed(at: now),
            now: now
        )
        let content = ActivityContent(state: state, staleDate: nil)
        let attributes = SessionActivityAttributes(sessionID: sessionID)
        Task { @MainActor in
            if let existing = Activity<SessionActivityAttributes>.activities.first(where: { $0.attributes.sessionID == sessionID })
                ?? Activity<SessionActivityAttributes>.activities.first {
                await existing.update(content)
            } else {
                _ = try? Activity.request(attributes: attributes, content: content)
            }
        }
    }

    func dismissImmediate() {
        Task { @MainActor in
            for activity in Activity<SessionActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}

@MainActor
final class NullLiveActivityManager: LiveActivityManaging {
    var started = 0
    var dismissed = 0
    var lastState: SessionActivityAttributes.ContentState?
    var states: [SessionActivityAttributes.ContentState] = []

    func startOrUpdate(from controller: SessionController, at now: Date) {
        started += 1
        guard let space = controller.liveActivitySpace() ?? controller.selectedSpace else { return }
        let snapshot = controller.snapshot(for: space.id)
        let taskName = space.tasks.first(where: { $0.id == snapshot.currentTaskID })?.name ?? "Task"
        let state = LiveActivityPresentation.content(
            spaceName: space.name,
            taskName: taskName,
            phaseRaw: snapshot.phase.rawValue,
            isRunning: snapshot.isRunning,
            elapsed: snapshot.elapsed(at: now),
            now: now
        )
        lastState = state
        states.append(state)
    }

    func dismissImmediate() {
        dismissed += 1
        lastState = nil
    }
}
