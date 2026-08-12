import AppIntents

struct ProductivityTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartCurrentSpaceIntent(),
            phrases: [
                "Start a session in \(.applicationName)",
                "Start Work in \(.applicationName)"
            ],
            shortTitle: "Start Session",
            systemImageName: "play.circle"
        )
        AppShortcut(
            intent: StopSessionIntent(),
            phrases: [
                "Stop the timer in \(.applicationName)"
            ],
            shortTitle: "Stop Session",
            systemImageName: "stop.circle"
        )
        AppShortcut(
            intent: LapIntent(),
            phrases: [
                "Next task in \(.applicationName)"
            ],
            shortTitle: "Next Task",
            systemImageName: "forward.end"
        )
        AppShortcut(
            intent: ImportSpaceDefinitionIntent(),
            phrases: [
                "Import a space in \(.applicationName)"
            ],
            shortTitle: "Import Space",
            systemImageName: "square.and.arrow.down"
        )
    }
}
