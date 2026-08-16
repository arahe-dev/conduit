import Foundation
import ActivityKit
import SwiftUI

struct SessionActivityAttributes: ActivityAttributes, Sendable {
    var sessionID: UUID

    struct ContentState: Codable, Hashable, Sendable {
        var spaceName: String
        var taskName: String
        var phaseRaw: String
        var displayStart: Date
        var isRunning: Bool
        var elapsedAtPause: TimeInterval
        var tintRaw: String
        var iconKindRaw: String
        var iconValue: String
    }
}

enum LiveActivityControl: String, Equatable {
    case stop
    case start
}

enum LiveActivityPresentation {
    /// Ordinary taps on the activity surface must not mutate the timer.
    static let backgroundMutatesTimer = false
    static let backgroundIntentName: String? = nil

    static func exclusiveControl(isRunning: Bool) -> LiveActivityControl {
        isRunning ? .stop : .start
    }

    static func exclusiveControlIntentName(isRunning: Bool) -> String {
        isRunning ? "StopFromLiveActivityIntent" : "ResumeFromLiveActivityIntent"
    }

    static func content(
        spaceName: String,
        taskName: String,
        phaseRaw: String,
        isRunning: Bool,
        elapsed: TimeInterval,
        now: Date,
        tintRaw: String = SpaceTint.orange.rawValue,
        iconKindRaw: String = SpaceIconKind.symbol.rawValue,
        iconValue: String = SpaceIcon.work.value,
        displayStart: Date? = nil
    ) -> SessionActivityAttributes.ContentState {
        SessionActivityAttributes.ContentState(
            spaceName: spaceName,
            taskName: taskName,
            phaseRaw: phaseRaw,
            displayStart: displayStart ?? now.addingTimeInterval(-elapsed),
            isRunning: isRunning,
            elapsedAtPause: elapsed,
            tintRaw: tintRaw,
            iconKindRaw: iconKindRaw,
            iconValue: iconValue
        )
    }
}

extension SessionActivityAttributes.ContentState {
    var tint: Color {
        (SpaceTint.parse(tintRaw) ?? .orange).color
    }

    var icon: SpaceIcon {
        SpaceIcon(kind: SpaceIconKind(rawValue: iconKindRaw) ?? .symbol, value: iconValue)
    }

    var pauseTime: Date? {
        isRunning ? nil : displayStart.addingTimeInterval(elapsedAtPause)
    }

    var timerRange: ClosedRange<Date> {
        displayStart...displayStart.addingTimeInterval(60 * 60 * 24 * 14)
    }

    /// Freeze the system timer in place. Keeps `displayStart` so the digits do not rebuild.
    func paused(at now: Date) -> SessionActivityAttributes.ContentState {
        guard isRunning else { return self }
        var next = self
        next.isRunning = false
        next.elapsedAtPause = now.timeIntervalSince(displayStart)
        next.phaseRaw = "stopped"
        return next
    }

    /// Continue from the frozen elapsed time. Re-anchors `displayStart` to `now - elapsed`.
    func resumed(at now: Date) -> SessionActivityAttributes.ContentState {
        guard !isRunning else { return self }
        var next = self
        next.displayStart = now.addingTimeInterval(-elapsedAtPause)
        next.isRunning = true
        next.phaseRaw = "running"
        return next
    }
}
