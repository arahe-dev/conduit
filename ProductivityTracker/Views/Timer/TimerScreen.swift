import SwiftUI

struct TimerScreen: View {
    @Bindable var controller: SessionController
    @Binding var showSettings: Bool
    @State private var page: SpacePagerPage? = .space(DemoIDs.work)
    @State private var composeOpen = false
    @State private var peekRaw: CGFloat = 0
    @State private var dismissDrag: CGFloat = 0
    @State private var showTaskPicker = false
    @State private var showSavedTimes = false
    @State private var renamingTask: TaskItem?
    @State private var renameText = ""
    @State private var editingSpace: Space?

    var body: some View {
        GeometryReader { geo in
            let pageWidth = geo.size.width
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                pager(width: pageWidth, height: geo.size.height)
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
                .zIndex(2)
            }
        }
        .background(Color.black.ignoresSafeArea())
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
            if newValue == .compose {
                composeOpen = true
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

    private var pageCount: Int { controller.spaces.count + 1 }

    private var currentSpaceID: UUID? {
        if case .space(let id) = page { return id }
        return controller.spaces.last?.id
    }

    private var isOnLastSpace: Bool {
        !composeOpen && currentSpaceID == controller.spaces.last?.id
    }

    private func pageIndex(for id: UUID) -> Int {
        controller.spaces.firstIndex(where: { $0.id == id }) ?? 0
    }

    @ViewBuilder
    private func pager(width: CGFloat, height: CGFloat) -> some View {
        let reveal = composeReveal(pageWidth: width)
        ZStack(alignment: .topLeading) {
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(controller.spaces, id: \.id) { space in
                        SpacePage(
                            controller: controller,
                            space: space,
                            isActivePage: currentSpaceID == space.id && !composeOpen,
                            pageIndex: pageIndex(for: space.id),
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
                    if controller.launch.uiTesting {
                        composePage(width: width, height: height)
                            .id(SpacePagerPage.compose)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $page)
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(
                peekGesture(pageWidth: width),
                including: (isOnLastSpace && !controller.launch.uiTesting) ? .all : .none
            )

            if !controller.launch.uiTesting, reveal > 0.5 {
                composePage(width: width, height: height)
                    .offset(x: width - reveal)
                    .allowsHitTesting(composeOpen)
                    .gesture(composeDismissGesture(pageWidth: width))
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .accessibilityIdentifier(AccessibilityIDs.spacePager)
    }

    private func composePage(width: CGFloat, height: CGFloat) -> some View {
        SpaceComposePage(
            controller: controller,
            pageIndex: max(pageCount - 1, 0),
            pageCount: pageCount,
            isActive: composeOpen || page == .compose,
            onCreated: { space in
                closeCompose(animated: false)
                controller.selectSpace(space.id, haptic: true)
                page = .space(space.id)
            }
        )
        .frame(width: width, height: height)
    }

    private func peekGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard isOnLastSpace, value.translation.width < 0 else { return }
                peekRaw = -value.translation.width
            }
            .onEnded { value in
                guard isOnLastSpace else {
                    peekRaw = 0
                    return
                }
                finishPeek(
                    translation: max(0, -value.translation.width),
                    predicted: max(0, -value.predictedEndTranslation.width),
                    pageWidth: pageWidth
                )
            }
    }

    private func composeReveal(pageWidth: CGFloat) -> CGFloat {
        if composeOpen {
            return max(0, pageWidth - dismissDrag)
        }
        return ComposePull.resist(peekRaw, pageWidth: pageWidth)
    }

    private func finishPeek(translation: CGFloat, predicted: CGFloat, pageWidth: CGFloat) {
        if ComposePull.shouldCommit(
            translation: translation,
            predicted: predicted,
            pageWidth: pageWidth,
            relaxed: controller.launch.uiTesting
        ) {
            Keyboard.dismiss()
            withAnimation(.interactiveSpring(response: 0.34, dampingFraction: 0.9)) {
                composeOpen = true
                peekRaw = 0
                dismissDrag = 0
                page = .compose
            }
        } else {
            withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.86)) {
                peekRaw = 0
            }
        }
    }

    private func composeDismissGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                dismissDrag = max(0, value.translation.width)
            }
            .onEnded { value in
                let predicted = max(0, value.predictedEndTranslation.width)
                finishDismiss(translation: max(0, value.translation.width), predicted: predicted, pageWidth: pageWidth)
            }
    }

    private func finishDismiss(translation: CGFloat, predicted: CGFloat, pageWidth: CGFloat) {
        if ComposePull.shouldDismiss(translation: translation, predicted: predicted, pageWidth: pageWidth) {
            Keyboard.dismiss()
            withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.92)) {
                composeOpen = false
                peekRaw = 0
                dismissDrag = 0
                if let last = controller.spaces.last?.id {
                    page = .space(last)
                }
            }
        } else {
            withAnimation(.interactiveSpring(response: 0.24, dampingFraction: 0.9)) {
                dismissDrag = 0
            }
        }
    }

    private func closeCompose(animated: Bool) {
        let apply = {
            composeOpen = false
            peekRaw = 0
            dismissDrag = 0
            if case .compose = page, let last = controller.spaces.last?.id {
                page = .space(last)
            }
        }
        if animated {
            withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.94), apply)
        } else {
            apply()
        }
    }
}
