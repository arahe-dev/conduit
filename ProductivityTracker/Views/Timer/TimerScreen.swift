import SwiftUI

struct TimerScreen: View {
    @Bindable var controller: SessionController
    @Binding var showSettings: Bool
    @State private var showTaskPicker = false
    @State private var renamingTask: TaskItem?
    @State private var renameText = ""

    var body: some View {
        GeometryReader { proxy in
            let upper = proxy.size.height * LayoutMetrics.upperFraction
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    spacePager
                        .frame(height: upper)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier(AccessibilityIDs.timerCard)
                    TaskPanel(
                        controller: controller,
                        onRename: { task in
                            renamingTask = task
                            renameText = task.name
                        }
                    )
                    .frame(maxHeight: .infinity)
                }
                .padding(.horizontal, LayoutMetrics.horizontalMargin)
                .padding(.top, 6)
                .padding(.bottom, 8)

                Text(controller.selectedSpace?.name ?? "")
                    .font(.caption)
                    .opacity(0.01)
                    .accessibilityIdentifier(AccessibilityIDs.spaceName)
                    .accessibilityLabel(controller.selectedSpace?.name ?? "")
                    .frame(width: 8, height: 8)
                    .offset(x: -120, y: 20)

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityIdentifier(AccessibilityIDs.settingsButton)
                .accessibilityLabel("Settings")
                .padding(.trailing, 2)
            }
        }
        .sheet(isPresented: $showTaskPicker) {
            TaskPickerSheet(controller: controller, isPresented: $showTaskPicker)
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

    private var spacePager: some View {
        TabView(selection: selectedSpaceBinding) {
            ForEach(controller.spaces, id: \.id) { space in
                StopwatchCard(
                    controller: controller,
                    space: space,
                    showsControls: space.id == controller.selectedSpaceID,
                    onLongPressLap: { showTaskPicker = true }
                )
                .tag(space.id as UUID)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .transaction { $0.animation = nil }
    }

    private var selectedSpaceBinding: Binding<UUID> {
        Binding(
            get: { controller.selectedSpaceID ?? controller.spaces.first?.id ?? DemoIDs.work },
            set: { newValue in
                if newValue != controller.selectedSpaceID {
                    controller.selectSpace(newValue, haptic: true)
                }
            }
        )
    }
}
