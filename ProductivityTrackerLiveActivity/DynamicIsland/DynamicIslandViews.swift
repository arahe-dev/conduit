import SwiftUI
import WidgetKit

struct DynamicIslandViews {
    static func compactLeading(context: ActivityViewContext<SessionActivityAttributes>) -> some View {
        Image(systemName: "timer")
            .font(.caption.weight(.semibold))
    }

    static func compactTrailing(context: ActivityViewContext<SessionActivityAttributes>) -> some View {
        Group {
            if context.state.isRunning {
                Text(
                    timerInterval: context.state.displayStart...context.state.displayStart.addingTimeInterval(60 * 60 * 24 * 14),
                    countsDown: false,
                    showsHours: false
                )
            } else {
                Text(ElapsedFormatter.compact(context.state.elapsedAtPause))
            }
        }
        .font(.caption.monospacedDigit())
        .minimumScaleFactor(0.7)
    }

    static func minimal(context: ActivityViewContext<SessionActivityAttributes>) -> some View {
        Image(systemName: context.state.isRunning ? "timer" : "pause.fill")
    }

    static func expanded(context: ActivityViewContext<SessionActivityAttributes>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.spaceName)
                    .font(.caption.weight(.semibold))
                Text(context.state.taskName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if context.state.isRunning {
                Text(
                    timerInterval: context.state.displayStart...context.state.displayStart.addingTimeInterval(60 * 60 * 24 * 14),
                    countsDown: false,
                    showsHours: true
                )
                .font(.title2.weight(.thin).monospacedDigit())
            } else {
                Text(ElapsedFormatter.stopwatch(context.state.elapsedAtPause))
                    .font(.title2.weight(.thin).monospacedDigit())
            }
        }
        .padding(.horizontal, 8)
    }
}
