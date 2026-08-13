import Foundation

struct TimerSnapshot: Equatable, Sendable {
    var phase: TimerPhase
    var spaceID: UUID
    var sessionID: UUID?
    var currentTaskID: UUID?
    var startedAt: Date?
    var accumulatedBeforeCurrentRun: TimeInterval
    var lastTick: Date
    var liveActivityID: String?

    static func idle(spaceID: UUID, currentTaskID: UUID? = nil) -> TimerSnapshot {
        TimerSnapshot(
            phase: .idle,
            spaceID: spaceID,
            sessionID: nil,
            currentTaskID: currentTaskID,
            startedAt: nil,
            accumulatedBeforeCurrentRun: 0,
            lastTick: Date(timeIntervalSince1970: 0),
            liveActivityID: nil
        )
    }

    func elapsed(at now: Date) -> TimeInterval {
        switch phase {
        case .idle:
            return 0
        case .stopped:
            return accumulatedBeforeCurrentRun
        case .running:
            guard let startedAt else { return accumulatedBeforeCurrentRun }
            return accumulatedBeforeCurrentRun + now.timeIntervalSince(startedAt)
        }
    }

    var isRunning: Bool { phase == .running }
    var isStopped: Bool { phase == .stopped }
    var isIdle: Bool { phase == .idle }
    var hasLiveActivity: Bool { liveActivityID != nil }
}
