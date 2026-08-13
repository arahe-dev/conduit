import SwiftUI

struct TaskRow: View {
    var task: TaskItem
    var isActive: Bool
    var accent: Color
    var isLive: Bool
    var closedElapsed: TimeInterval
    var openStartedAt: Date?

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isActive ? accent : Color.clear)
                .frame(width: 6, height: 6)
            Text(task.name)
                .font(.body)
                .foregroundStyle(isActive ? .primary : .secondary)
                .lineLimit(1)
            Spacer()
            elapsedLabel
        }
        .padding(.horizontal, 4)
        .frame(minHeight: 48)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.name), \(ElapsedFormatter.stopwatch(elapsed(at: Date())))")
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityIdentifier("task-row-\(task.name)")
    }

    @ViewBuilder
    private var elapsedLabel: some View {
        if isLive {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                timeText(elapsed(at: timeline.date))
            }
        } else {
            timeText(closedElapsed)
        }
    }

    private func elapsed(at now: Date) -> TimeInterval {
        var total = closedElapsed
        if let start = openStartedAt {
            total += now.timeIntervalSince(start)
        }
        return total
    }

    private func timeText(_ elapsed: TimeInterval) -> some View {
        Text(ElapsedFormatter.stopwatch(elapsed))
            .font(.body.monospacedDigit())
            .foregroundStyle(.secondary)
    }
}
