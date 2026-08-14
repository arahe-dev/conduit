import SwiftUI

struct SpaceComposePage: View {
    @Bindable var controller: SessionController
    var pageIndex: Int
    var pageCount: Int
    var isActive: Bool
    var onCreated: (Space) -> Void

    @State private var name = ""
    @State private var tint: SpaceTint = .blue
    @State private var icon = SpaceIcon.fallback
    @State private var taskDraft = ""
    @State private var tasks: [String] = ["Task"]
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case name
        case task
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("New Space")
                        .font(.title3.weight(.semibold))
                    Spacer(minLength: 48)
                }
                .padding(.top, 8)

                TextField("Name", text: $name)
                    .font(.title2.weight(.semibold))
                    .textInputAutocapitalization(.words)
                    .focused($focus, equals: .name)
                    .accessibilityIdentifier("new-space-name")

                SpaceIconPicker(icon: $icon, name: name, tint: tint.color)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Color")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))], spacing: 10) {
                        ForEach(SpaceTint.allCases) { option in
                            Circle()
                                .fill(option.color)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if tint == option {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { tint = option }
                                .accessibilityLabel(option.displayName)
                                .accessibilityAddTraits(tint == option ? .isSelected : [])
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tasks")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(Array(tasks.enumerated()), id: \.offset) { index, task in
                        HStack {
                            Text(task)
                            Spacer()
                            Button {
                                tasks.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityLabel("Remove \(task)")
                        }
                        .font(.body)
                    }
                    HStack {
                        TextField("Add a task", text: $taskDraft)
                            .focused($focus, equals: .task)
                            .accessibilityIdentifier("compose-task-field")
                        Button("Add") {
                            let value = taskDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !value.isEmpty else { return }
                            tasks.append(value)
                            taskDraft = ""
                        }
                        .accessibilityIdentifier("compose-add-task")
                    }
                }

                Button {
                    create()
                } label: {
                    Text("Create Space")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(tint.color)
                .disabled(!canCreate)
                .accessibilityIdentifier(AccessibilityIDs.createSpaceButton)

                PageDots(
                    count: pageCount,
                    current: pageIndex,
                    accent: tint.color,
                    composeAtEnd: true
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding(.horizontal, LayoutMetrics.horizontalMargin)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(
                colors: [tint.color.opacity(0.55), tint.color.opacity(0.16), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .onChange(of: isActive) { _, active in
            if !active {
                focus = nil
                Keyboard.dismiss()
            }
        }
        .onDisappear {
            focus = nil
            Keyboard.dismiss()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIDs.addSpacePage)
    }

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !tasks.isEmpty
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let taskNames = tasks.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard let space = try? controller.createSpace(
            name: trimmed,
            tint: tint,
            tasks: taskNames.isEmpty ? ["Task"] : taskNames,
            icon: icon
        ) else { return }
        onCreated(space)
        name = ""
        taskDraft = ""
        tasks = ["Task"]
        icon = .fallback
        tint = .blue
    }
}
