import SwiftUI

enum AccessibilityIDs {
    static let timerCard = "timer-card"
    static let taskPanel = "task-panel"
    static let spaceName = "space-name"
    static let stopwatch = "stopwatch-display"
    static let lapButton = "lap-button"
    static let resetButton = "reset-button"
    static let startStopButton = "start-stop-button"
    static let pageIndicator = "page-indicator"
    static let settingsButton = "settings-button"
    static let taskPicker = "task-picker"
    static let glassSurface = "glass-surface"
    static let spaceEditor = "space-editor"
    static let liveActivityPreview = "live-activity-preview"
    static let addSpacePage = "add-space-page"
    static let addTaskInline = "add-task-inline"
    static let createSpaceButton = "create-space-button"
    static let spacePager = "space-pager"
    static let saveTimeButton = "save-time-button"
}

enum LayoutMetrics {
    static let horizontalMargin: CGFloat = 20
    static let stackSpacing: CGFloat = 0
    static let buttonDiameter: CGFloat = 72
    static let stopwatchSize: CGFloat = 84
    static let upperFraction: CGFloat = 0.48
}

enum SpaceCanvas {
    static func glow(_ color: Color) -> some View {
        ZStack {
            Color.black
            LinearGradient(
                stops: [
                    .init(color: color.opacity(0.20), location: 0),
                    .init(color: color.opacity(0.06), location: 0.14),
                    .init(color: Color.clear, location: 0.32)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
