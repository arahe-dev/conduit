import SwiftUI

struct TaskPanel: View {
    @Bindable var controller: SessionController
    var space: Space
    var isActivePage: Bool
    var onRename: (TaskItem) -> Void
    @State private var draft = ""

    private var tasks: [TaskItem] {
        _ = controller.mutation
        return space.enabledTasksSorted
    }

    var body: some View {
        VStack(spacing: 0) {
            if tasks.isEmpty {
                HStack {
                    Text("No Tasks")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.top, 16)
            }
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(tasks, id: \.id) { task in
                        let snap = controller.snapshot(for: space.id)
                        let isSelected = task.id == snap.currentTaskID && !task.isCompleted
                        let parts = controller.taskElapsedParts(for: task)
                        TaskRow(
                            task: task,
                            isActive: isSelected,
                            accent: space.tint.color,
                            isLive: isActivePage && isSelected && snap.isRunning,
                            closedElapsed: parts.closed,
                            openStartedAt: parts.openStartedAt
                        )
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            try? controller.setTaskCompleted(task, isCompleted: !task.isCompleted)
                        }
                        .onTapGesture {
                            try? controller.selectTask(task)
                        }
                        .contextMenu {
                            Button(task.isCompleted ? "Mark Incomplete" : "Complete") {
                                try? controller.setTaskCompleted(task, isCompleted: !task.isCompleted)
                            }
                            Button("Rename") { onRename(task) }
                            Button(task.isEnabled ? "Disable" : "Enable") {
                                try? controller.setTaskEnabled(task, isEnabled: !task.isEnabled)
                            }
                            Button("Delete", role: .destructive) {
                                try? controller.deleteTask(task)
                            }
                        }
                        Divider().opacity(0.22)
                    }
                    addRow
                }
            }
            .scrollIndicators(.hidden)
        }
        .accessibilityIdentifier(isActivePage ? AccessibilityIDs.taskPanel : "task-panel-idle")
    }

    private var addRow: some View {
        HStack {
            TextField("Add a task", text: $draft)
                .accessibilityIdentifier(isActivePage ? AccessibilityIDs.addTaskInline : "add-task-inline-idle")
            Button("Add") {
                let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { return }
                try? controller.addTask(to: space, name: value)
                draft = ""
            }
            .accessibilityIdentifier(isActivePage ? "add-task-empty" : "add-task-empty-idle")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 12)
    }
}
