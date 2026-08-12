import AppIntents

struct SelectSpaceIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Space"
    static var description = IntentDescription("Select a ProductivityTracker Space without starting the timer.")

    @Parameter(title: "Space")
    var space: SpaceEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Select \(\.$space)")
    }

    func perform() async throws -> some IntentResult {
        try await MainActor.run {
            guard let controller = AppRuntime.shared.sessionController else {
                throw IntentFailure.unavailable
            }
            controller.selectSpace(space.id)
        }
        return .result()
    }
}

struct StartSpaceIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Space"
    static var description = IntentDescription("Select a Space and start its timer.")

    @Parameter(title: "Space")
    var space: SpaceEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$space) in ProductivityTracker")
    }

    func perform() async throws -> some IntentResult {
        try await MainActor.run {
            guard let controller = AppRuntime.shared.sessionController else {
                throw IntentFailure.unavailable
            }
            controller.selectSpace(space.id)
            try controller.start()
        }
        return .result()
    }
}

struct StartCurrentSpaceIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Session"
    static var description = IntentDescription("Start the timer for the current or default Space.")

    func perform() async throws -> some IntentResult {
        try await MainActor.run {
            guard let controller = AppRuntime.shared.sessionController else {
                throw IntentFailure.unavailable
            }
            try controller.start()
        }
        return .result()
    }
}

struct StopSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Session"

    func perform() async throws -> some IntentResult {
        try await MainActor.run {
            try AppRuntime.shared.sessionController?.stop()
        }
        return .result()
    }
}

struct PauseSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Session"

    func perform() async throws -> some IntentResult {
        try await MainActor.run {
            try AppRuntime.shared.sessionController?.pause()
        }
        return .result()
    }
}

struct ResumeSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Session"

    func perform() async throws -> some IntentResult {
        try await MainActor.run {
            try AppRuntime.shared.sessionController?.resume()
        }
        return .result()
    }
}

struct LapIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Task"
    static var description = IntentDescription("Finish the current task interval and start the next enabled task.")

    func perform() async throws -> some IntentResult {
        try await MainActor.run {
            try AppRuntime.shared.sessionController?.lap()
        }
        return .result()
    }
}

enum IntentFailure: Error, CustomLocalizedStringResourceConvertible {
    case unavailable
    case importFailed(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .unavailable:
            return "ProductivityTracker is not ready."
        case .importFailed(let message):
            return "\(message)"
        }
    }
}
