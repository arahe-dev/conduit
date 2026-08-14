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
        List {
            if tasks.isEmpty {
                Text("No Tasks")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            ForEach(tasks, id: \.id) { task in
                let snap = controller.snapshot(for: space.id)
                let isSelected = task.id == snap.currentTaskID && !task.isCompleted
                let parts = controller.taskElapsedParts(for: task)
                Button {
                    try? controller.selectTask(task)
                } label: {
                    TaskRow(
                        task: task,
                        isActive: isSelected,
                        accent: space.tint.color,
                        isLive: isActivePage && isSelected && snap.isRunning,
                        closedElapsed: parts.closed,
                        openStartedAt: parts.openStartedAt
                    )
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                .listRowBackground(Color.clear)
                .simultaneousGesture(
                    TapGesture(count: 2).onEnded {
                        try? controller.setTaskCompleted(task, isCompleted: !task.isCompleted)
                    }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(task.isCompleted ? "Undo" : "Done") {
                        try? controller.setTaskCompleted(task, isCompleted: !task.isCompleted)
                    }
                    .tint(space.tint.color)
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
            }
            addRow
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
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
        .padding(.vertical, 8)
    }
}
