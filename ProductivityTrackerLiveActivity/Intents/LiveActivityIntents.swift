import AppIntents

struct StopFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Stop Session" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            try? AppRuntime.shared.sessionController?.stop()
        }
        return .result()
    }
}

struct LapFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Next Task" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            try? AppRuntime.shared.sessionController?.lap()
        }
        return .result()
    }
}

struct PauseFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Pause Session" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            try? AppRuntime.shared.sessionController?.pause()
        }
        return .result()
    }
}

struct ResumeFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Resume Session" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            try? AppRuntime.shared.sessionController?.resume()
        }
        return .result()
    }
}
