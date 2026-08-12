import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var phaseRaw: String
    var accumulatedActiveDuration: Double
    var currentSegmentStartedAt: Date?
    var activeTaskID: UUID?
    var space: Space?

    @Relationship(deleteRule: .cascade, inverse: \TaskInterval.session)
    var intervals: [TaskInterval]

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date? = nil,
        phase: TimerPhase = .running,
        accumulatedActiveDuration: Double = 0,
        currentSegmentStartedAt: Date? = nil,
        activeTaskID: UUID? = nil,
        space: Space? = nil,
        intervals: [TaskInterval] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.phaseRaw = phase.rawValue
        self.accumulatedActiveDuration = accumulatedActiveDuration
        self.currentSegmentStartedAt = currentSegmentStartedAt
        self.activeTaskID = activeTaskID
        self.space = space
        self.intervals = intervals
    }

    var phase: TimerPhase {
        get { TimerPhase(rawValue: phaseRaw) ?? .idle }
        set { phaseRaw = newValue.rawValue }
    }

    func elapsed(at now: Date) -> TimeInterval {
        var total = accumulatedActiveDuration
        if phase == .running, let start = currentSegmentStartedAt {
            total += now.timeIntervalSince(start)
        }
        return max(0, total)
    }
}
