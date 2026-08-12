import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var name: String
    var displayOrder: Int
    var isEnabled: Bool
    var createdAt: Date
    var space: Space?

    @Relationship(deleteRule: .cascade, inverse: \TaskInterval.task)
    var intervals: [TaskInterval]

    init(
        id: UUID = UUID(),
        name: String,
        displayOrder: Int,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        space: Space? = nil,
        intervals: [TaskInterval] = []
    ) {
        self.id = id
        self.name = name
        self.displayOrder = displayOrder
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.space = space
        self.intervals = intervals
    }
}
