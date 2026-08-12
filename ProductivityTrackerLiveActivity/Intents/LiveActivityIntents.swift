import AppIntents

struct StopFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Stop Session" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        #if APP_TARGET
        await MainActor.run {
            try? AppRuntime.shared.sessionController?.stop()
        }
        #endif
        return .result()
    }
}

struct LapFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Next Task" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        #if APP_TARGET
        await MainActor.run {
            try? AppRuntime.shared.sessionController?.lap()
        }
        #endif
        return .result()
    }
}

struct PauseFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Pause Session" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        #if APP_TARGET
        await MainActor.run {
            try? AppRuntime.shared.sessionController?.pause()
        }
        #endif
        return .result()
    }
}

struct ResumeFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Resume Session" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        #if APP_TARGET
        await MainActor.run {
            try? AppRuntime.shared.sessionController?.resume()
        }
        #endif
        return .result()
    }
}
