import SwiftUI
import AppIntents

struct LiveActivityLockScreen: View {
    var state: SessionActivityAttributes.ContentState
    var showsControls: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                elapsedText
                    .font(.system(size: 34, weight: .thin).monospacedDigit())
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .accessibilityIdentifier("live-activity-elapsed")
                Text(secondaryLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .accessibilityIdentifier("live-activity-context")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if showsControls {
                control
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("live-activity-lock")
        .accessibilityLabel("\(secondaryLabel), \(ElapsedFormatter.stopwatch(state.elapsedAtPause))")
    }

    private var secondaryLabel: String {
        if state.taskName.isEmpty {
            return state.spaceName
        }
        return "\(state.spaceName) · \(state.taskName)"
    }

    @ViewBuilder
    private var elapsedText: some View {
        if state.isRunning {
            Text(
                timerInterval: state.displayStart...state.displayStart.addingTimeInterval(60 * 60 * 24 * 14),
                pauseTime: nil,
                countsDown: false,
                showsHours: true
            )
        } else {
            Text(ElapsedFormatter.stopwatch(state.elapsedAtPause))
        }
    }

    @ViewBuilder
    private var control: some View {
        if state.isRunning {
            Button(intent: StopFromLiveActivityIntent()) {
                Image(systemName: "stop.fill")
                    .font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("live-activity-stop")
            .accessibilityLabel("Stop")
        } else {
            Button(intent: ResumeFromLiveActivityIntent()) {
                Image(systemName: "play.fill")
                    .font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("live-activity-start")
            .accessibilityLabel("Start")
        }
    }
}

struct DynamicIslandCompactLeading: View {
    var state: SessionActivityAttributes.ContentState

    var body: some View {
        Circle()
            .fill(Color.primary)
            .frame(width: 8, height: 8)
            .accessibilityLabel(state.spaceName)
    }
}

struct DynamicIslandCompactTrailing: View {
    var state: SessionActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.isRunning {
                Text(
                    timerInterval: state.displayStart...state.displayStart.addingTimeInterval(60 * 60 * 24 * 14),
                    countsDown: false,
                    showsHours: false
                )
            } else {
                Text(ElapsedFormatter.compact(state.elapsedAtPause))
            }
        }
        .font(.caption.monospacedDigit())
        .minimumScaleFactor(0.7)
    }
}

struct DynamicIslandMinimal: View {
    var state: SessionActivityAttributes.ContentState

    var body: some View {
        Image(systemName: "timer")
            .font(.caption2.weight(.semibold))
    }
}

struct DynamicIslandExpandedContent: View {
    var state: SessionActivityAttributes.ContentState
    var showsControls: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(state.spaceName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(state.taskName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Group {
                if state.isRunning {
                    Text(
                        timerInterval: state.displayStart...state.displayStart.addingTimeInterval(60 * 60 * 24 * 14),
                        countsDown: false,
                        showsHours: true
                    )
                } else {
                    Text(ElapsedFormatter.stopwatch(state.elapsedAtPause))
                }
            }
            .font(.title3.weight(.thin).monospacedDigit())
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            if showsControls {
                if state.isRunning {
                    Button(intent: StopFromLiveActivityIntent()) {
                        Image(systemName: "stop.fill")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Stop")
                } else {
                    Button(intent: ResumeFromLiveActivityIntent()) {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Start")
                }
            }
        }
        .padding(.horizontal, 4)
        .accessibilityIdentifier("live-activity-island-expanded")
    }
}
