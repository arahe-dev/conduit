import AppIntents
import SwiftData

struct SpaceEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Space" }
    static var defaultQuery: SpaceEntityQuery { SpaceEntityQuery() }

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct SpaceEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [SpaceEntity] {
        try await all().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [SpaceEntity] {
        try await all()
    }

    func all() async throws -> [SpaceEntity] {
        try await MainActor.run {
            guard let container = AppRuntime.shared.container else { return [] }
            let context = ModelContext(container)
            let spaces = try context.fetch(FetchDescriptor<Space>(sortBy: [SortDescriptor(\.displayOrder)]))
            return spaces.map { SpaceEntity(id: $0.id, name: $0.name) }
        }
    }
}

struct TaskEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Task" }
    static var defaultQuery: TaskEntityQuery { TaskEntityQuery() }

    var id: UUID
    var name: String
    var spaceID: UUID

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct TaskEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [TaskEntity] {
        try await all().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [TaskEntity] {
        try await all()
    }

    func all() async throws -> [TaskEntity] {
        try await MainActor.run {
            guard let container = AppRuntime.shared.container else { return [] }
            let context = ModelContext(container)
            let tasks = try context.fetch(FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.displayOrder)]))
            return tasks.compactMap { task in
                guard let spaceID = task.space?.id else { return nil }
                return TaskEntity(id: task.id, name: task.name, spaceID: spaceID)
            }
        }
    }
}
