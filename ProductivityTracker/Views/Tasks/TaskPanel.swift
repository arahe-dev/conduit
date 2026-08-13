import SwiftUI

struct TaskPanel: View {
    @Bindable var controller: SessionController
    var onRename: (TaskItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if controller.selectedTasks.isEmpty {
                HStack {
                    Text("No Tasks")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Add") {
                        if let space = controller.selectedSpace {
                            try? controller.addTask(to: space, name: "Task")
                        }
                    }
                    .accessibilityIdentifier("add-task-empty")
                }
                .padding(.horizontal, 4)
                .padding(.top, 16)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(controller.selectedTasks, id: \.id) { task in
                            let isSelected = task.id == controller.snapshot.currentTaskID
                            let parts = controller.taskElapsedParts(for: task)
                            TaskRow(
                                task: task,
                                isActive: isSelected,
                                accent: controller.selectedSpace?.tint.color ?? .white,
                                isLive: isSelected && controller.snapshot.isRunning,
                                closedElapsed: parts.closed,
                                openStartedAt: parts.openStartedAt
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                try? controller.selectTask(task)
                            }
                            .contextMenu {
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
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .accessibilityIdentifier(AccessibilityIDs.taskPanel)
    }
}
