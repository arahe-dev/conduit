import SwiftUI

struct SpaceEditorView: View {
    @Bindable var controller: SessionController
    var space: Space
    @State private var name: String
    @State private var newTask = ""

    init(controller: SessionController, space: Space) {
        self.controller = controller
        self.space = space
        _name = State(initialValue: space.name)
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Space name", text: $name)
                    .onSubmit {
                        try? controller.renameSpace(space, to: name)
                    }
            }
            Section("Color") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))]) {
                    ForEach(SpaceTint.allCases) { tint in
                        Circle()
                            .fill(tint.color)
                            .frame(width: 28, height: 28)
                            .overlay {
                                if space.tint == tint {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            .onTapGesture {
                                try? controller.recolorSpace(space, tint: tint)
                            }
                            .accessibilityLabel(tint.displayName)
                    }
                }
            }
            Section("Tasks") {
                ForEach(space.allTasksSorted, id: \.id) { task in
                    HStack {
                        Text(task.name)
                        Spacer()
                        Toggle("Enabled", isOn: enabledBinding(task))
                            .labelsHidden()
                    }
                }
                .onDelete { indexSet in
                    let tasks = space.allTasksSorted
                    for index in indexSet {
                        try? controller.deleteTask(tasks[index])
                    }
                }
                HStack {
                    TextField("New task", text: $newTask)
                    Button("Add") {
                        let value = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !value.isEmpty else { return }
                        try? controller.addTask(to: space, name: value)
                        newTask = ""
                    }
                }
            }
        }
        .navigationTitle(space.name)
        .onDisappear {
            try? controller.renameSpace(space, to: name)
        }
    }

    private func enabledBinding(_ task: TaskItem) -> Binding<Bool> {
        Binding(
            get: { task.isEnabled },
            set: { newValue in
                task.isEnabled = newValue
            }
        )
    }
}
