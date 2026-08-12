import SwiftUI

struct TaskPanel: View {
    @Bindable var controller: SessionController

    var body: some View {
        GlassSurface(tint: controller.selectedSpace?.tint.color ?? .gray, cornerRadius: LayoutMetrics.panelCorner) {
            VStack(spacing: 0) {
                if controller.selectedTasks.isEmpty {
                    Text("No tasks")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(controller.selectedTasks.enumerated()), id: \.element.id) { index, task in
                                TaskRow(
                                    task: task,
                                    isActive: task.id == controller.activeTask?.id && controller.snapshot.isActiveSession,
                                    elapsed: controller.accumulatedDuration(for: task, at: controller.timeSource.now())
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if controller.snapshot.isRunning {
                                        try? controller.selectTask(task)
                                    }
                                }
                                if index < controller.selectedTasks.count - 1 {
                                    Divider().opacity(0.18).padding(.leading, 18)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .accessibilityIdentifier(AccessibilityIDs.taskPanel)
    }
}
