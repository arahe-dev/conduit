import Foundation
@preconcurrency import ActivityKit

@MainActor
protocol LiveActivityManaging: AnyObject {
    func startOrUpdate(from controller: SessionController, at now: Date)
    func startOrUpdateAndWait(from controller: SessionController, at now: Date) async
    func dismissImmediate()
    func dismissAndWait() async
}

@MainActor
final class LiveActivityManager: LiveActivityManaging {
    func startOrUpdate(from controller: SessionController, at now: Date) {
        Task(priority: .userInitiated) {
            await startOrUpdateAndWait(from: controller, at: now)
        }
    }

    func startOrUpdateAndWait(from controller: SessionController, at now: Date) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard let space = controller.liveActivitySpace() else { return }
        let snapshot = controller.snapshot(for: space.id)
        guard let sessionID = snapshot.sessionID else { return }
        let taskName = space.tasks.first(where: { $0.id == snapshot.currentTaskID })?.name
            ?? controller.activeTask?.name
            ?? "Task"
        let elapsed = snapshot.elapsed(at: now)
        let displayStart: Date
        if snapshot.isRunning, let started = snapshot.startedAt {
            displayStart = started.addingTimeInterval(-snapshot.accumulatedBeforeCurrentRun)
        } else {
            displayStart = now.addingTimeInterval(-elapsed)
        }
        let state = LiveActivityPresentation.content(
            spaceName: space.name,
            taskName: taskName,
            phaseRaw: snapshot.phase.rawValue,
            isRunning: snapshot.isRunning,
            elapsed: elapsed,
            now: now,
            tintRaw: space.tintRaw,
            iconKindRaw: space.iconKindRaw,
            iconValue: space.iconValue,
            displayStart: displayStart
        )
        let content = ActivityContent(state: state, staleDate: nil)
        let attributes = SessionActivityAttributes(sessionID: sessionID)
        if let existing = Activity<SessionActivityAttributes>.activities.first {
            await existing.update(content)
        } else {
            _ = try? await Activity.request(attributes: attributes, content: content)
        }
    }

    func dismissImmediate() {
        Task(priority: .userInitiated) {
            await dismissAndWait()
        }
    }

    func dismissAndWait() async {
        for activity in Activity<SessionActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
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
        let elapsed = snapshot.elapsed(at: now)
        lastState = LiveActivityPresentation.content(
            spaceName: space.name,
            taskName: taskName,
            phaseRaw: snapshot.phase.rawValue,
            isRunning: snapshot.isRunning,
            elapsed: elapsed,
            now: now,
            tintRaw: space.tintRaw,
            iconKindRaw: space.iconKindRaw,
            iconValue: space.iconValue
        )
        states.append(lastState!)
    }

    func startOrUpdateAndWait(from controller: SessionController, at now: Date) async {
        startOrUpdate(from: controller, at: now)
    }

    func dismissImmediate() {
        dismissed += 1
        lastState = nil
    }

    func dismissAndWait() async {
        dismissImmediate()
    }
}
