import SwiftUI
import AppIntents

struct LiveActivityElapsedText: View {
    var state: SessionActivityAttributes.ContentState
    var font: Font

    var body: some View {
        Text(
            timerInterval: state.timerRange,
            pauseTime: state.pauseTime,
            countsDown: false,
            showsHours: true
        )
        .font(font)
        .monospacedDigit()
        .foregroundStyle(.white)
        .minimumScaleFactor(0.45)
        .lineLimit(1)
        .contentTransition(.identity)
        .transaction { $0.animation = nil }
        .accessibilityIdentifier("live-activity-elapsed")
    }
}

struct LiveActivityLockScreen: View {
    var state: SessionActivityAttributes.ContentState
    var showsControls: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.spaceName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(state.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(state.taskName.isEmpty ? " " : state.taskName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .accessibilityIdentifier("live-activity-context")
                LiveActivityElapsedText(
                    state: state,
                    font: .system(size: 32, weight: .light, design: .default)
                )
                if showsControls {
                    HStack(spacing: 10) {
                        liveControl
                        closeControl
                    }
                    .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SpaceIconView(icon: state.icon, tint: state.tint, pointSize: 48)
                .accessibilityLabel(state.spaceName)
        }
        .padding(.leading, 18)
        .padding(.trailing, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("live-activity-lock")
        .accessibilityLabel("\(state.spaceName), \(state.taskName), \(ElapsedFormatter.compact(state.elapsedAtPause))")
    }

    private var liveControl: some View {
        Toggle(isOn: state.isRunning, intent: SetStopwatchRunningIntent()) {
            Label(state.isRunning ? "Stop" : "Start", systemImage: state.isRunning ? "stop.fill" : "play.fill")
                .labelStyle(.iconOnly)
        }
        .toggleStyle(LiveActivityRunningToggleStyle())
        .accessibilityIdentifier(state.isRunning ? "live-activity-stop" : "live-activity-start")
        .accessibilityLabel(state.isRunning ? "Stop" : "Start")
    }

    private var closeControl: some View {
        Button(intent: ResetFromLiveActivityIntent()) {
            Image(systemName: "xmark")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.white.opacity(0.14)))
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.22), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("live-activity-close")
        .accessibilityLabel("Reset")
    }
}

struct LiveActivityRunningToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: configuration.isOn ? "stop.fill" : "play.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.white.opacity(0.14)))
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.22), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct DynamicIslandCompactLeading: View {
    var state: SessionActivityAttributes.ContentState

    var body: some View {
            SpaceIconView(icon: state.icon, tint: state.tint, pointSize: 20)
            .accessibilityLabel(state.spaceName)
    }
}

struct DynamicIslandCompactTrailing: View {
    var state: SessionActivityAttributes.ContentState

    var body: some View {
        LiveActivityElapsedText(state: state, font: .caption.weight(.semibold))
            .minimumScaleFactor(0.55)
    }
}

struct DynamicIslandMinimal: View {
    var state: SessionActivityAttributes.ContentState

    var body: some View {
        SpaceIconView(icon: state.icon, tint: state.tint, pointSize: 16)
    }
}

struct DynamicIslandExpandedContent: View {
    var state: SessionActivityAttributes.ContentState
    var showsControls: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            SpaceIconView(icon: state.icon, tint: state.tint, pointSize: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(state.spaceName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(state.tint)
                    .lineLimit(1)
                Text(state.taskName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            LiveActivityElapsedText(state: state, font: .title3.weight(.light))
            if showsControls {
                HStack(spacing: 8) {
                    Toggle(isOn: state.isRunning, intent: SetStopwatchRunningIntent()) {
                        Label(state.isRunning ? "Stop" : "Start", systemImage: state.isRunning ? "stop.fill" : "play.fill")
                            .labelStyle(.iconOnly)
                    }
                    .toggleStyle(LiveActivityRunningToggleStyle())
                    .accessibilityLabel(state.isRunning ? "Stop" : "Start")
                    Button(intent: ResetFromLiveActivityIntent()) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reset")
                }
                .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 4)
        .accessibilityIdentifier("live-activity-island-expanded")
    }
}
