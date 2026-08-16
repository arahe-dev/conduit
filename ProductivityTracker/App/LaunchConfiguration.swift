import Foundation

enum ScreenshotTimerState: String, Equatable, Sendable {
    case idle
    case running
    case stopped
}

struct LaunchConfiguration: Equatable, Sendable {
    var uiTesting: Bool
    var resetStore: Bool
    var screenshotMode: Bool
    var startRunning: Bool
    var frozenElapsed: TimeInterval?
    var inMemoryStore: Bool
    var timerState: ScreenshotTimerState?
    var liveActivityPreview: Bool

    init(
        uiTesting: Bool = false,
        resetStore: Bool = false,
        screenshotMode: Bool = false,
        startRunning: Bool = false,
        frozenElapsed: TimeInterval? = nil,
        inMemoryStore: Bool = false,
        timerState: ScreenshotTimerState? = nil,
        liveActivityPreview: Bool = false
    ) {
        self.uiTesting = uiTesting
        self.resetStore = resetStore
        self.screenshotMode = screenshotMode
        self.startRunning = startRunning
        self.frozenElapsed = frozenElapsed
        self.inMemoryStore = inMemoryStore
        self.timerState = timerState
        self.liveActivityPreview = liveActivityPreview
    }

    static let `default` = LaunchConfiguration()

    static func from(_ arguments: [String], environment: [String: String] = [:]) -> LaunchConfiguration {
        var config = LaunchConfiguration.default
        config.uiTesting = arguments.contains("-UITests") || arguments.contains("--uitesting")
        config.resetStore = arguments.contains("-ResetStore")
        config.screenshotMode = arguments.contains("-ScreenshotMode")
        config.startRunning = arguments.contains("-StartRunning")
        config.liveActivityPreview = arguments.contains("-LiveActivityPreview")
        let persist = arguments.contains("-PersistStore")
        config.inMemoryStore = (arguments.contains("-InMemoryStore") || config.uiTesting) && !persist
        if let value = environment["UITEST_ELAPSED"] ?? argumentValue("-FrozenElapsed", in: arguments) {
            config.frozenElapsed = TimeInterval(value)
        }
        if let raw = environment["UITEST_TIMER_STATE"] ?? argumentValue("-TimerState", in: arguments) {
            config.timerState = ScreenshotTimerState(rawValue: raw)
        }
        if config.screenshotMode && config.timerState == nil {
            config.timerState = .running
        }
        if config.timerState == .running {
            config.startRunning = true
        }
        if config.screenshotMode && config.frozenElapsed == nil {
            config.frozenElapsed = config.timerState == .idle ? 0 : 31.42
        }
        if config.timerState == .idle {
            config.startRunning = false
            if config.frozenElapsed == nil {
                config.frozenElapsed = 0
            }
        }
        return config
    }

    private static func argumentValue(_ flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }
}
