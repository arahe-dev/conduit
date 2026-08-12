import Foundation

enum TimerEngineError: Error, Equatable {
    case invalidTransition(from: TimerPhase, to: String)
}

struct TimerEngine: Equatable, Sendable {
    var snapshot: TimerSnapshot

    init(snapshot: TimerSnapshot = .idle) {
        self.snapshot = snapshot
    }

    mutating func start(now: Date, sessionID: UUID, spaceID: UUID, taskID: UUID?) throws {
        switch snapshot.phase {
        case .idle, .stopped:
            snapshot = TimerSnapshot(
                phase: .running,
                sessionID: sessionID,
                spaceID: spaceID,
                activeTaskID: taskID,
                sessionStartedAt: now,
                accumulatedActiveDuration: 0,
                currentSegmentStartedAt: now,
                lastStoppedElapsed: 0
            )
        case .paused:
            snapshot.phase = .running
            snapshot.currentSegmentStartedAt = now
        case .running:
            throw TimerEngineError.invalidTransition(from: .running, to: "start")
        }
    }

    mutating func pause(now: Date) throws {
        guard snapshot.phase == .running else {
            throw TimerEngineError.invalidTransition(from: snapshot.phase, to: "pause")
        }
        if let start = snapshot.currentSegmentStartedAt {
            snapshot.accumulatedActiveDuration += now.timeIntervalSince(start)
        }
        snapshot.currentSegmentStartedAt = nil
        snapshot.phase = .paused
    }

    mutating func resume(now: Date) throws {
        guard snapshot.phase == .paused else {
            throw TimerEngineError.invalidTransition(from: snapshot.phase, to: "resume")
        }
        snapshot.phase = .running
        snapshot.currentSegmentStartedAt = now
    }

    mutating func stop(now: Date) throws {
        guard snapshot.phase == .running || snapshot.phase == .paused else {
            throw TimerEngineError.invalidTransition(from: snapshot.phase, to: "stop")
        }
        let elapsed = snapshot.elapsed(at: now)
        snapshot.phase = .stopped
        snapshot.accumulatedActiveDuration = elapsed
        snapshot.currentSegmentStartedAt = nil
        snapshot.lastStoppedElapsed = elapsed
    }

    mutating func reset() {
        snapshot = .idle
    }

    mutating func lap(now: Date, nextTaskID: UUID) throws {
        guard snapshot.phase == .running else {
            throw TimerEngineError.invalidTransition(from: snapshot.phase, to: "lap")
        }
        snapshot.activeTaskID = nextTaskID
        _ = now
    }

    mutating func selectTask(now: Date, taskID: UUID) throws {
        guard snapshot.phase == .running || snapshot.phase == .paused else {
            throw TimerEngineError.invalidTransition(from: snapshot.phase, to: "selectTask")
        }
        snapshot.activeTaskID = taskID
        _ = now
    }

    mutating func restore(_ snapshot: TimerSnapshot) {
        self.snapshot = snapshot
    }
}
