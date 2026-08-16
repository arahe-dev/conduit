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
    var iconKindRaw: String = SpaceIconKind.symbol.rawValue
    var iconValue: String = "square.grid.2x2.fill"

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
        icon: SpaceIcon = .fallback,
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
        self.iconKindRaw = icon.kind.rawValue
        self.iconValue = icon.value
        self.tasks = tasks
        self.sessions = sessions
    }

    var tint: SpaceTint {
        get { SpaceTint(rawValue: tintRaw) ?? .orange }
        set { tintRaw = newValue.rawValue }
    }

    var icon: SpaceIcon {
        get {
            let kind = SpaceIconKind(rawValue: iconKindRaw) ?? .symbol
            let value = iconValue.isEmpty ? SpaceIcon.fallback.value : iconValue
            return SpaceIcon(kind: kind, value: value)
        }
        set {
            iconKindRaw = newValue.kind.rawValue
            iconValue = newValue.value
        }
    }

    var remindersEnabled: Bool { distractionTimeoutSeconds > 0 }

    var enabledTasksSorted: [TaskItem] {
        tasks.filter(\.isEnabled).sorted { $0.displayOrder < $1.displayOrder }
    }

    var timingTasksSorted: [TaskItem] {
        tasks
            .filter { $0.isEnabled && !$0.isCompleted }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    var allTasksSorted: [TaskItem] {
        tasks.sorted { $0.displayOrder < $1.displayOrder }
    }
}
