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
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(state.spaceName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(state.tint)
                    .shadow(color: state.tint.opacity(0.55), radius: 8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(state.taskName.isEmpty ? " " : state.taskName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .accessibilityIdentifier("live-activity-context")
                LiveActivityElapsedText(
                    state: state,
                    font: .system(size: 42, weight: .light, design: .default)
                )
                if showsControls {
                    HStack(spacing: 12) {
                        liveControl
                        closeControl
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SpaceIconView(icon: state.icon, tint: state.tint, pointSize: 92)
                .accessibilityLabel(state.spaceName)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("live-activity-lock")
        .accessibilityLabel("\(state.spaceName), \(state.taskName), \(ElapsedFormatter.compact(state.elapsedAtPause))")
    }

    @ViewBuilder
    private var liveControl: some View {
        if state.isRunning {
            Button(intent: StopFromLiveActivityIntent()) {
                controlGlyph("stop.fill")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("live-activity-stop")
            .accessibilityLabel("Stop")
        } else {
            Button(intent: ResumeFromLiveActivityIntent()) {
                controlGlyph("play.fill")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("live-activity-start")
            .accessibilityLabel("Start")
        }
    }

    private var closeControl: some View {
        Button(intent: ResetFromLiveActivityIntent()) {
            controlGlyph("xmark")
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("live-activity-close")
        .accessibilityLabel("Reset")
    }

    private func controlGlyph(_ name: String) -> some View {
        Image(systemName: name)
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Circle().fill(.white.opacity(0.14)))
            .overlay {
                Circle().strokeBorder(.white.opacity(0.22), lineWidth: 1)
            }
    }
}

struct DynamicIslandCompactLeading: View {
    var state: SessionActivityAttributes.ContentState

    var body: some View {
        SpaceIconView(icon: state.icon, tint: state.tint, pointSize: 22)
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
        SpaceIconView(icon: state.icon, tint: state.tint, pointSize: 18)
    }
}

struct DynamicIslandExpandedContent: View {
    var state: SessionActivityAttributes.ContentState
    var showsControls: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            SpaceIconView(icon: state.icon, tint: state.tint, pointSize: 36)
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
