import Foundation

struct TimerSnapshot: Equatable, Sendable {
    var phase: TimerPhase
    var sessionID: UUID?
    var spaceID: UUID?
    var activeTaskID: UUID?
    var sessionStartedAt: Date?
    var accumulatedActiveDuration: TimeInterval
    var currentSegmentStartedAt: Date?
    var lastStoppedElapsed: TimeInterval

    static let idle = TimerSnapshot(
        phase: .idle,
        sessionID: nil,
        spaceID: nil,
        activeTaskID: nil,
        sessionStartedAt: nil,
        accumulatedActiveDuration: 0,
        currentSegmentStartedAt: nil,
        lastStoppedElapsed: 0
    )

    func elapsed(at now: Date) -> TimeInterval {
        switch phase {
        case .idle:
            return 0
        case .stopped:
            return lastStoppedElapsed
        case .paused:
            return accumulatedActiveDuration
        case .running:
            let extra = currentSegmentStartedAt.map { now.timeIntervalSince($0) } ?? 0
            return max(0, accumulatedActiveDuration + extra)
        }
    }

    var isRunning: Bool { phase == .running }
    var isActiveSession: Bool { phase == .running || phase == .paused }
}
