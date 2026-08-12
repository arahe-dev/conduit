import SwiftUI

struct TaskRow: View {
    var task: TaskItem
    var isActive: Bool
    var elapsed: TimeInterval

    var body: some View {
        HStack {
            if isActive {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 6, height: 6)
                    .padding(.trailing, 4)
            }
            Text(task.name)
                .font(.body)
                .foregroundStyle(isActive ? .primary : .secondary)
                .lineLimit(1)
            Spacer()
            Text(ElapsedFormatter.stopwatch(elapsed))
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .frame(minHeight: 48)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.name), \(ElapsedFormatter.stopwatch(elapsed))")
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityIdentifier("task-row-\(task.name)")
    }
}
