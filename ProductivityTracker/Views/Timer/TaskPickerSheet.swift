import SwiftUI

struct TaskPickerSheet: View {
    @Bindable var controller: SessionController
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List(controller.selectedTasks, id: \.id) { task in
                Button {
                    try? controller.selectTask(task)
                    isPresented = false
                } label: {
                    HStack {
                        Text(task.name)
                        Spacer()
                        if task.id == controller.snapshot.activeTaskID {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityIdentifier("task-choice-\(task.name)")
            }
            .navigationTitle("Choose Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium])
        .accessibilityIdentifier(AccessibilityIDs.taskPicker)
    }
}
