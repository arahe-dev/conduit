import AppIntents

struct StopFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Stop" }
    static var openAppWhenRun: Bool { false }

    func perform() async throws -> some IntentResult {
        #if APP_TARGET
        await AppRuntime.shared.sessionController?.stopFromLiveActivity()
        #endif
        return .result()
    }
}

struct ResumeFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Start" }
    static var openAppWhenRun: Bool { false }

    func perform() async throws -> some IntentResult {
        #if APP_TARGET
        await AppRuntime.shared.sessionController?.startFromLiveActivity()
        #endif
        return .result()
    }
}

struct LapFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Next Task" }
    static var openAppWhenRun: Bool { false }

    func perform() async throws -> some IntentResult {
        #if APP_TARGET
        await MainActor.run {
            try? AppRuntime.shared.sessionController?.lapFromLiveActivity()
        }
        #endif
        return .result()
    }
}

struct ResetFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Reset" }
    static var openAppWhenRun: Bool { false }

    func perform() async throws -> some IntentResult {
        #if APP_TARGET
        await AppRuntime.shared.sessionController?.resetFromLiveActivity()
        #endif
        return .result()
    }
}
