import AppIntents

/// WidgetKit pre-renders on/off for `Toggle`. `value` is the new running flag after the tap.
struct SetStopwatchRunningIntent: SetValueIntent, LiveActivityIntent {
    static var title: LocalizedStringResource { "Stopwatch Running" }
    static var openAppWhenRun: Bool { false }
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }

    @Parameter(title: "Running")
    var value: Bool

    init() {}

    init(value: Bool) {
        self.value = value
    }

    func perform() async throws -> some IntentResult {
        let now = Date()
        if value {
            await LiveActivityClock.resume(at: now)
        } else {
            await LiveActivityClock.pause(at: now)
        }
        #if APP_TARGET
        let running = value
        Task(priority: .userInitiated) { @MainActor in
            if running {
                await AppRuntime.shared.sessionController?.startFromLiveActivity(at: now)
            } else {
                await AppRuntime.shared.sessionController?.stopFromLiveActivity(at: now)
            }
        }
        #endif
        return .result()
    }
}

struct StopFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Stop" }
    static var openAppWhenRun: Bool { false }
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }

    func perform() async throws -> some IntentResult {
        try await SetStopwatchRunningIntent(value: false).perform()
    }
}

struct ResumeFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Start" }
    static var openAppWhenRun: Bool { false }
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }

    func perform() async throws -> some IntentResult {
        try await SetStopwatchRunningIntent(value: true).perform()
    }
}

struct LapFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Next Task" }
    static var openAppWhenRun: Bool { false }
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }

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
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }

    func perform() async throws -> some IntentResult {
        await LiveActivityClock.dismiss()
        #if APP_TARGET
        Task(priority: .userInitiated) { @MainActor in
            await AppRuntime.shared.sessionController?.resetFromLiveActivity()
        }
        #endif
        return .result()
    }
}
