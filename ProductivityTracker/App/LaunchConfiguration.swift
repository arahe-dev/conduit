import Foundation

struct LaunchConfiguration: Equatable, Sendable {
    var uiTesting: Bool
    var resetStore: Bool
    var screenshotMode: Bool
    var startRunning: Bool
    var frozenElapsed: TimeInterval?
    var inMemoryStore: Bool

    static let `default` = LaunchConfiguration(
        uiTesting: false,
        resetStore: false,
        screenshotMode: false,
        startRunning: false,
        frozenElapsed: nil,
        inMemoryStore: false
    )

    static func from(_ arguments: [String], environment: [String: String] = [:]) -> LaunchConfiguration {
        var config = LaunchConfiguration.default
        config.uiTesting = arguments.contains("-UITests") || arguments.contains("--uitesting")
        config.resetStore = arguments.contains("-ResetStore")
        config.screenshotMode = arguments.contains("-ScreenshotMode")
        config.startRunning = arguments.contains("-StartRunning")
        let persist = arguments.contains("-PersistStore")
        config.inMemoryStore = (arguments.contains("-InMemoryStore") || config.uiTesting) && !persist
        if let value = environment["UITEST_ELAPSED"] ?? argumentValue("-FrozenElapsed", in: arguments) {
            config.frozenElapsed = TimeInterval(value)
        }
        if config.screenshotMode && config.frozenElapsed == nil {
            config.frozenElapsed = 31.42
            config.startRunning = true
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
