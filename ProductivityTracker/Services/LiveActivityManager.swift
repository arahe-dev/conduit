import Foundation
@preconcurrency import ActivityKit

@MainActor
protocol LiveActivityManaging: AnyObject {
    func startOrUpdate(from controller: SessionController, at now: Date)
    func startOrUpdateAndWait(from controller: SessionController, at now: Date) async
    func dismissImmediate()
    func dismissAndWait() async
}

private struct LiveActivityPayload: Sendable {
    var sessionID: UUID
    var state: SessionActivityAttributes.ContentState
}

@MainActor
final class LiveActivityManager: LiveActivityManaging {
    private var clockAnchorBySession: [UUID: Date] = [:]

    func startOrUpdate(from controller: SessionController, at now: Date) {
        guard let payload = prepare(from: controller, at: now) else { return }
        Task.detached(priority: .userInitiated) {
            await LiveActivityManager.publish(payload)
        }
    }

    func startOrUpdateAndWait(from controller: SessionController, at now: Date) async {
        guard let payload = prepare(from: controller, at: now) else { return }
        await LiveActivityManager.publish(payload)
    }

    func dismissImmediate() {
        clockAnchorBySession.removeAll()
        let activities = Array(Activity<SessionActivityAttributes>.activities)
        Task.detached(priority: .userInitiated) {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    func dismissAndWait() async {
        clockAnchorBySession.removeAll()
        for activity in Activity<SessionActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func prepare(from controller: SessionController, at now: Date) -> LiveActivityPayload? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }
        guard let space = controller.liveActivitySpace() else { return nil }
        let snapshot = controller.snapshot(for: space.id)
        guard let sessionID = snapshot.sessionID else { return nil }
        let taskName = space.tasks.first(where: { $0.id == snapshot.currentTaskID })?.name
            ?? controller.activeTask?.name
            ?? "Task"
        let elapsed = snapshot.elapsed(at: now)
        let displayStart = clockAnchor(for: snapshot, elapsed: elapsed, now: now)
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
        return LiveActivityPayload(sessionID: sessionID, state: state)
    }

    nonisolated private static func publish(_ payload: LiveActivityPayload) async {
        let content = ActivityContent(state: payload.state, staleDate: nil)
        if let existing = Activity<SessionActivityAttributes>.activities.first {
            await existing.update(content)
        } else {
            let attributes = SessionActivityAttributes(sessionID: payload.sessionID)
            _ = try? await Activity.request(attributes: attributes, content: content)
        }
    }

    private func clockAnchor(for snapshot: TimerSnapshot, elapsed: TimeInterval, now: Date) -> Date {
        if snapshot.isRunning, let started = snapshot.startedAt {
            let anchor = started.addingTimeInterval(-snapshot.accumulatedBeforeCurrentRun)
            if let sessionID = snapshot.sessionID {
                clockAnchorBySession[sessionID] = anchor
            }
            return anchor
        }
        if let sessionID = snapshot.sessionID, let anchor = clockAnchorBySession[sessionID] {
            return anchor
        }
        let anchor = now.addingTimeInterval(-elapsed)
        if let sessionID = snapshot.sessionID {
            clockAnchorBySession[sessionID] = anchor
        }
        return anchor
    }
}

@MainActor
final class NullLiveActivityManager: LiveActivityManaging {
    var started = 0
    var dismissed = 0
    var lastState: SessionActivityAttributes.ContentState?
    var states: [SessionActivityAttributes.ContentState] = []
    private var clockAnchorBySession: [UUID: Date] = [:]

    func startOrUpdate(from controller: SessionController, at now: Date) {
        started += 1
        guard let space = controller.liveActivitySpace() ?? controller.selectedSpace else { return }
        let snapshot = controller.snapshot(for: space.id)
        let taskName = space.tasks.first(where: { $0.id == snapshot.currentTaskID })?.name ?? "Task"
        let elapsed = snapshot.elapsed(at: now)
        let displayStart = clockAnchor(for: snapshot, elapsed: elapsed, now: now)
        lastState = LiveActivityPresentation.content(
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
        states.append(lastState!)
    }

    func startOrUpdateAndWait(from controller: SessionController, at now: Date) async {
        startOrUpdate(from: controller, at: now)
    }

    func dismissImmediate() {
        dismissed += 1
        lastState = nil
        clockAnchorBySession.removeAll()
    }

    func dismissAndWait() async {
        dismissImmediate()
    }

    private func clockAnchor(for snapshot: TimerSnapshot, elapsed: TimeInterval, now: Date) -> Date {
        if snapshot.isRunning, let started = snapshot.startedAt {
            let anchor = started.addingTimeInterval(-snapshot.accumulatedBeforeCurrentRun)
            if let sessionID = snapshot.sessionID {
                clockAnchorBySession[sessionID] = anchor
            }
            return anchor
        }
        if let sessionID = snapshot.sessionID, let anchor = clockAnchorBySession[sessionID] {
            return anchor
        }
        let anchor = now.addingTimeInterval(-elapsed)
        if let sessionID = snapshot.sessionID {
            clockAnchorBySession[sessionID] = anchor
        }
        return anchor
    }
}
