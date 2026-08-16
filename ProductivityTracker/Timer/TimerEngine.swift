import Foundation

/// Timestamp-based stopwatch. Stop freezes; Start resumes; Reset returns to idle.
@MainActor
final class TimerEngine {
    private(set) var snapshot: TimerSnapshot

    init(spaceID: UUID = UUID(), currentTaskID: UUID? = nil) {
        self.snapshot = .idle(spaceID: spaceID, currentTaskID: currentTaskID)
    }

    init(snapshot: TimerSnapshot) {
        self.snapshot = snapshot
    }

    func restore(_ snapshot: TimerSnapshot) {
        self.snapshot = snapshot
    }

    func bindSpace(_ spaceID: UUID) {
        snapshot.spaceID = spaceID
    }

    func selectTask(_ taskID: UUID?) {
        snapshot.currentTaskID = taskID
    }

    func start(now: Date, sessionID: UUID) {
        switch snapshot.phase {
        case .idle:
            snapshot.sessionID = sessionID
            snapshot.startedAt = now
            snapshot.accumulatedBeforeCurrentRun = 0
            snapshot.phase = .running
            snapshot.lastTick = now
        case .stopped:
            snapshot.startedAt = now
            snapshot.phase = .running
            snapshot.lastTick = now
        case .running:
            break
        }
    }

    func stop(now: Date) {
        guard snapshot.phase == .running else { return }
        snapshot.accumulatedBeforeCurrentRun = snapshot.elapsed(at: now)
        snapshot.startedAt = nil
        snapshot.phase = .stopped
        snapshot.lastTick = now
    }

    func resetDisplay() {
        snapshot.phase = .idle
        snapshot.sessionID = nil
        snapshot.startedAt = nil
        snapshot.accumulatedBeforeCurrentRun = 0
        snapshot.liveActivityID = nil
        snapshot.lastTick = Date(timeIntervalSince1970: 0)
    }

    func attachLiveActivity(_ id: String) {
        snapshot.liveActivityID = id
    }

    func detachLiveActivity() {
        snapshot.liveActivityID = nil
    }
}
