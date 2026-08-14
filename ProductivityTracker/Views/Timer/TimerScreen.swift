import SwiftUI

struct TimerScreen: View {
    @Bindable var controller: SessionController
    @Binding var showSettings: Bool
    @State private var page: SpacePagerPage = .space(DemoIDs.work)
    @State private var showTaskPicker = false
    @State private var renamingTask: TaskItem?
    @State private var renameText = ""
    @State private var editingSpace: Space?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            TabView(selection: pageBinding) {
                ForEach(controller.spaces, id: \.id) { space in
                    SpacePage(
                        controller: controller,
                        space: space,
                        isActivePage: isActive(space.id),
                        pageIndex: pageIndex(for: .space(space.id)),
                        pageCount: pageCount,
                        onLongPressLap: { showTaskPicker = true },
                        onRenameTask: { task in
                            renamingTask = task
                            renameText = task.name
                        },
                        onEditSpace: { editingSpace = space }
                    )
                    .tag(SpacePagerPage.space(space.id))
                }
                SpaceComposePage(
                    controller: controller,
                    pageIndex: max(pageCount - 1, 0),
                    pageCount: pageCount,
                    onCreated: { space in
                        controller.selectSpace(space.id, haptic: true)
                        page = .space(space.id)
                    }
                )
                .tag(SpacePagerPage.compose)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .accessibilityIdentifier(AccessibilityIDs.spacePager)

            Button {
                showSettings = true
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.black.opacity(0.18)))
            }
            .accessibilityIdentifier(AccessibilityIDs.settingsButton)
            .accessibilityLabel("Settings")
            .padding(.trailing, 4)
            .padding(.top, 2)
        }
        .onAppear {
            if case .space = page, let selected = controller.selectedSpaceID {
                page = .space(selected)
            }
        }
        .sheet(isPresented: $showTaskPicker) {
            TaskPickerSheet(controller: controller, isPresented: $showTaskPicker)
        }
        .sheet(isPresented: Binding(
            get: { editingSpace != nil },
            set: { if !$0 { editingSpace = nil } }
        )) {
            if let space = editingSpace {
                NavigationStack {
                    SpaceEditorView(controller: controller, space: space)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { editingSpace = nil }
                            }
                        }
                }
            }
        }
        .alert("Rename", isPresented: Binding(
            get: { renamingTask != nil },
            set: { if !$0 { renamingTask = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { renamingTask = nil }
            Button("Save") {
                if let task = renamingTask {
                    try? controller.renameTask(task, to: renameText)
                }
                renamingTask = nil
            }
        }
    }

    private var pageCount: Int {
        controller.spaces.count + 1
    }

    private func isActive(_ id: UUID) -> Bool {
        page == .space(id)
    }

    private func pageIndex(for value: SpacePagerPage) -> Int {
        switch value {
        case .space(let id):
            return controller.spaces.firstIndex(where: { $0.id == id }) ?? 0
        case .compose:
            return controller.spaces.count
        }
    }

    private var pageBinding: Binding<SpacePagerPage> {
        Binding(
            get: { page },
            set: { newValue in
                page = newValue
                if case .space(let id) = newValue, id != controller.selectedSpaceID {
                    controller.selectSpace(id, haptic: true)
                }
            }
        )
    }
}
