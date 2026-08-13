import Foundation
import SwiftData

@Model
final class Space {
    var id: UUID
    var name: String
    var tintRaw: String
    var displayOrder: Int
    var createdAt: Date
    var distractionTimeoutSeconds: Double
    var focusKeyword: String?
    var defaultTaskID: UUID?

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.space)
    var tasks: [TaskItem]

    @Relationship(deleteRule: .cascade, inverse: \Session.space)
    var sessions: [Session]

    init(
        id: UUID = UUID(),
        name: String,
        tint: SpaceTint,
        displayOrder: Int,
        createdAt: Date = Date(),
        distractionTimeoutSeconds: Double = 300,
        focusKeyword: String? = nil,
        defaultTaskID: UUID? = nil,
        tasks: [TaskItem] = [],
        sessions: [Session] = []
    ) {
        self.id = id
        self.name = name
        self.tintRaw = tint.rawValue
        self.displayOrder = displayOrder
        self.createdAt = createdAt
        self.distractionTimeoutSeconds = distractionTimeoutSeconds
        self.focusKeyword = focusKeyword
        self.defaultTaskID = defaultTaskID
        self.tasks = tasks
        self.sessions = sessions
    }

    var tint: SpaceTint {
        get { SpaceTint(rawValue: tintRaw) ?? .orange }
        set { tintRaw = newValue.rawValue }
    }

    var remindersEnabled: Bool { distractionTimeoutSeconds > 0 }

    var enabledTasksSorted: [TaskItem] {
        tasks.filter(\.isEnabled).sorted { $0.displayOrder < $1.displayOrder }
    }

    var allTasksSorted: [TaskItem] {
        tasks.sorted { $0.displayOrder < $1.displayOrder }
    }
}
