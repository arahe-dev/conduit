import SwiftUI

struct SpaceEditorView: View {
    @Bindable var controller: SessionController
    var space: Space
    @State private var name: String
    @State private var newTask = ""
    @State private var focusKeyword: String
    @State private var reminderSeconds: Double

    init(controller: SessionController, space: Space) {
        self.controller = controller
        self.space = space
        _name = State(initialValue: space.name)
        _focusKeyword = State(initialValue: space.focusKeyword ?? "")
        _reminderSeconds = State(initialValue: space.distractionTimeoutSeconds)
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Space", text: $name)
                    .onSubmit { try? controller.renameSpace(space, to: name) }
            }
            Section("Accent") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))]) {
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
                            .accessibilityAddTraits(space.tint == tint ? .isSelected : [])
                    }
                }
                .padding(.vertical, 4)
            }
            Section("Default Task") {
                Picker("Default Task", selection: defaultTaskBinding) {
                    Text("None").tag(UUID?.none)
                    ForEach(space.enabledTasksSorted, id: \.id) { task in
                        Text(task.name).tag(Optional(task.id))
                    }
                }
            }
            Section("Reminder") {
                Picker("Reminder", selection: $reminderSeconds) {
                    Text("Off").tag(0.0)
                    Text("1 min").tag(60.0)
                    Text("5 min").tag(300.0)
                    Text("10 min").tag(600.0)
                    Text("15 min").tag(900.0)
                    Text("30 min").tag(1800.0)
                }
                .onChange(of: reminderSeconds) { _, newValue in
                    try? controller.setReminder(for: space, seconds: newValue)
                }
            }
            Section("Focus") {
                TextField("Focus keyword", text: $focusKeyword)
                    .onSubmit {
                        try? controller.setFocusKeyword(focusKeyword, for: space)
                    }
            }
            Section("Tasks") {
                ForEach(space.allTasksSorted, id: \.id) { task in
                    TaskEditorRow(controller: controller, task: task)
                }
                .onMove { source, destination in
                    try? controller.moveTasks(in: space, from: source, to: destination)
                }
                .onDelete { indexSet in
                    let tasks = space.allTasksSorted
                    for index in indexSet {
                        try? controller.deleteTask(tasks[index])
                    }
                }
                HStack {
                    TextField("New task", text: $newTask)
                        .accessibilityIdentifier("new-task-field")
                    Button("Add") {
                        let value = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !value.isEmpty else { return }
                        try? controller.addTask(to: space, name: value)
                        newTask = ""
                    }
                    .accessibilityIdentifier("add-task-button")
                }
            }
        }
        .navigationTitle("Space")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
        .accessibilityIdentifier(AccessibilityIDs.spaceEditor)
        .onDisappear {
            try? controller.renameSpace(space, to: name)
            try? controller.setFocusKeyword(focusKeyword, for: space)
        }
    }

    private var defaultTaskBinding: Binding<UUID?> {
        Binding(
            get: { space.defaultTaskID },
            set: { newValue in
                let task = space.tasks.first { $0.id == newValue }
                try? controller.setDefaultTask(task, for: space)
            }
        )
    }
}

private struct TaskEditorRow: View {
    @Bindable var controller: SessionController
    var task: TaskItem
    @State private var name: String

    init(controller: SessionController, task: TaskItem) {
        self.controller = controller
        self.task = task
        _name = State(initialValue: task.name)
    }

    var body: some View {
        HStack {
            TextField("Task", text: $name)
                .onSubmit {
                    try? controller.renameTask(task, to: name)
                }
                .accessibilityIdentifier("rename-task-\(task.id.uuidString)")
            Toggle("Enabled", isOn: enabledBinding)
                .labelsHidden()
                .accessibilityIdentifier("enable-task-\(task.name)")
        }
        .onChange(of: name) { _, newValue in
            if newValue != task.name && !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try? controller.renameTask(task, to: newValue)
            }
        }
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { task.isEnabled },
            set: { try? controller.setTaskEnabled(task, isEnabled: $0) }
        )
    }
}
