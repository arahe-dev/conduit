import Foundation
import SwiftData

@Model
final class TaskInterval {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var session: Session?
    var task: TaskItem?

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date? = nil,
        session: Session? = nil,
        task: TaskItem? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.session = session
        self.task = task
    }

    func duration(at now: Date) -> TimeInterval {
        let end = endedAt ?? now
        return max(0, end.timeIntervalSince(startedAt))
    }

    var isOpen: Bool { endedAt == nil }
}
