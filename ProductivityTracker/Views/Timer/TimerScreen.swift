import SwiftUI

struct TimerScreen: View {
    @Bindable var controller: SessionController
    @Binding var showSettings: Bool
    @State private var page: SpacePagerPage? = .space(DemoIDs.work)
    @State private var showTaskPicker = false
    @State private var showSavedTimes = false
    @State private var renamingTask: TaskItem?
    @State private var renameText = ""
    @State private var editingSpace: Space?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                canvasWash.ignoresSafeArea()
                pager(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea(edges: .bottom)

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.78))
                        .frame(width: 44, height: 44)
                }
                .accessibilityIdentifier(AccessibilityIDs.settingsButton)
                .accessibilityLabel("Settings")
                .padding(.trailing, 4)
            }
        }
        .background(canvasWash.ignoresSafeArea())
        .onAppear {
            if let selected = controller.selectedSpaceID {
                page = .space(selected)
            }
        }
        .onChange(of: page) { _, newValue in
            Keyboard.dismiss()
            if case .space(let id) = newValue, id != controller.selectedSpaceID {
                controller.selectSpace(id, haptic: true)
            }
        }
        .sheet(isPresented: $showTaskPicker) {
            TaskPickerSheet(controller: controller, isPresented: $showTaskPicker)
        }
        .sheet(isPresented: $showSavedTimes) {
            NavigationStack {
                SavedTimesView(controller: controller, initialSpaceID: historySpaceID)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSavedTimes = false }
                        }
                    }
            }
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

    private var historySpaceID: UUID? {
        if case .space(let id) = page { return id }
        return controller.selectedSpaceID
    }

    private var canvasWash: Color {
        switch page {
        case .space(let id):
            return controller.spaces.first(where: { $0.id == id })?.tint.color.opacity(0.38) ?? .black
        case .compose:
            return SpaceTint.blue.color.opacity(0.32)
        case .none:
            return controller.selectedSpace?.tint.color.opacity(0.38) ?? .black
        }
    }

    private var pageCount: Int { controller.spaces.count + 1 }

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

    @ViewBuilder
    private func pager(width: CGFloat, height: CGFloat) -> some View {
        let lastSpaceIndex = max(controller.spaces.count - 1, 0)
        let commit = controller.launch.uiTesting ? 0.18 : 0.58
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
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
                        onEditSpace: { editingSpace = space },
                        onSaveTime: { try? controller.saveTime(in: space) },
                        onOpenSavedTimes: { showSavedTimes = true }
                    )
                    .frame(width: width, height: height)
                    .id(SpacePagerPage.space(space.id))
                }
                SpaceComposePage(
                    controller: controller,
                    pageIndex: max(pageCount - 1, 0),
                    pageCount: pageCount,
                    isActive: page == .compose,
                    onCreated: { space in
                        controller.selectSpace(space.id, haptic: true)
                        page = .space(space.id)
                    }
                )
                .frame(width: width, height: height)
                .id(SpacePagerPage.compose)
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(
            ComposeIntentPaging(
                pageWidth: width,
                lastSpaceIndex: lastSpaceIndex,
                commitFraction: commit
            )
        )
        .scrollPosition(id: $page)
        .scrollDismissesKeyboard(.immediately)
        .accessibilityIdentifier(AccessibilityIDs.spacePager)
    }
}
