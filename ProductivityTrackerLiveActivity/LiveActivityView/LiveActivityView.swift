import SwiftUI
import WidgetKit

struct LiveActivityView: View {
    let context: ActivityViewContext<SessionActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            controlCluster
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(context.attributes.spaceName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(context.state.taskName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                elapsedText
                    .font(.system(size: 28, weight: .thin, design: .default).monospacedDigit())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var elapsedText: some View {
        if context.state.isRunning {
            Text(
                timerInterval: context.state.displayStart...context.state.displayStart.addingTimeInterval(60 * 60 * 24 * 14),
                pauseTime: nil,
                countsDown: false,
                showsHours: true
            )
        } else {
            Text(ElapsedFormatter.stopwatch(context.state.elapsedAtPause))
        }
    }

    private var controlCluster: some View {
        HStack(spacing: 10) {
            if context.state.isRunning {
                Button(intent: PauseFromLiveActivityIntent()) {
                    Image(systemName: "pause.fill")
                }
                Button(intent: StopFromLiveActivityIntent()) {
                    Image(systemName: "xmark")
                }
            } else {
                Button(intent: ResumeFromLiveActivityIntent()) {
                    Image(systemName: "play.fill")
                }
                Button(intent: StopFromLiveActivityIntent()) {
                    Image(systemName: "xmark")
                }
            }
        }
        .buttonStyle(.plain)
        .font(.body.weight(.semibold))
        .foregroundStyle(.primary)
    }
}
