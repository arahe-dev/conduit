import AppIntents

struct StopFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Stop" }
    static var openAppWhenRun: Bool { false }

    func perform() async throws -> some IntentResult {
        #if APP_TARGET
        await MainActor.run {
            try? AppRuntime.shared.sessionController?.stop()
        }
        #endif
        return .result()
    }
}

struct ResumeFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Start" }
    static var openAppWhenRun: Bool { false }

    func perform() async throws -> some IntentResult {
        #if APP_TARGET
        await MainActor.run {
            try? AppRuntime.shared.sessionController?.start()
        }
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
            try? AppRuntime.shared.sessionController?.lap()
        }
        #endif
        return .result()
    }
}
