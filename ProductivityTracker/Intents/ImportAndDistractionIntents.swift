import AppIntents
import SwiftData

struct SelectTaskIntent: AppIntent {
    static var title: LocalizedStringResource { "Select Task" }

    @Parameter(title: "Task")
    var task: TaskEntity

    func perform() async throws -> some IntentResult {
        try await MainActor.run {
            guard let controller = AppRuntime.shared.sessionController else {
                throw IntentFailure.unavailable
            }
            let tasks = controller.selectedSpace?.tasks ?? []
            if let match = tasks.first(where: { $0.id == task.id }) {
                try controller.selectTask(match)
            }
        }
        return .result()
    }
}

struct GetCurrentSessionIntent: AppIntent {
    static var title: LocalizedStringResource { "Get Current Session" }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let summary = await MainActor.run { () -> String in
            guard let controller = AppRuntime.shared.sessionController else {
                return "Unavailable"
            }
            let space = controller.selectedSpace?.name ?? "None"
            let task = controller.activeTask?.name ?? "None"
            let elapsed = ElapsedFormatter.stopwatch(controller.displayedElapsed(at: controller.timeSource.now()))
            return "Space: \(space); Task: \(task); State: \(controller.snapshot.phase.rawValue); Elapsed: \(elapsed)"
        }
        return .result(value: summary)
    }
}

struct CreateSpaceIntent: AppIntent {
    static var title: LocalizedStringResource { "Create Space" }

    @Parameter(title: "Name")
    var name: String

    @Parameter(title: "First task", default: "Task 1")
    var firstTask: String

    func perform() async throws -> some IntentResult {
        try await MainActor.run {
            guard let controller = AppRuntime.shared.sessionController else {
                throw IntentFailure.unavailable
            }
            _ = try controller.createSpace(name: name, tint: .blue, tasks: [firstTask])
        }
        return .result()
    }
}

struct ImportSpaceDefinitionIntent: AppIntent {
    static var title: LocalizedStringResource { "Import Space Definition" }
    static var description: IntentDescription? { IntentDescription("Create a Space from a JSON object with name, color, and tasks.") }

    @Parameter(title: "JSON")
    var json: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        do {
            let payload = try SpaceImportPayload.parse(json: json)
            let createdName = try await MainActor.run { () throws -> String in
                guard let controller = AppRuntime.shared.sessionController else {
                    throw IntentFailure.unavailable
                }
                let space = try controller.importSpace(payload)
                return space.name
            }
            return .result(value: "Created \(createdName)")
        } catch let error as SpaceImportError {
            throw IntentFailure.importFailed(error.errorDescription ?? "Invalid Space definition")
        }
    }
}

struct DistractionStartedIntent: AppIntent {
    static var title: LocalizedStringResource { "Distraction Started" }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppRuntime.shared.sessionController?.distractionStarted()
        }
        return .result()
    }
}

struct DistractionEndedIntent: AppIntent {
    static var title: LocalizedStringResource { "Distraction Ended" }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppRuntime.shared.sessionController?.distractionEnded()
        }
        return .result()
    }
}
