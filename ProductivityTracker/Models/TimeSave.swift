import Foundation
import SwiftData

@Model
final class TimeSave {
    var id: UUID
    var name: String
    var savedAt: Date
    var elapsed: TimeInterval
    var spaceID: UUID
    var spaceName: String
    var taskName: String?

    init(
        id: UUID = UUID(),
        name: String,
        savedAt: Date,
        elapsed: TimeInterval,
        spaceID: UUID,
        spaceName: String,
        taskName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.savedAt = savedAt
        self.elapsed = elapsed
        self.spaceID = spaceID
        self.spaceName = spaceName
        self.taskName = taskName
    }

    static func makeName(space: String, task: String?, at date: Date) -> String {
        let when = date.formatted(date: .abbreviated, time: .shortened)
        if let task, !task.isEmpty {
            return "\(space) · \(task) · \(when)"
        }
        return "\(space) · \(when)"
    }
}

enum SavedTimeFilter: Hashable {
    case all
    case space(UUID)
}
