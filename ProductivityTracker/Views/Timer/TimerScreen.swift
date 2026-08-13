import SwiftUI

struct TimerScreen: View {
    @Bindable var controller: SessionController
    @Binding var showSettings: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showTaskPicker = false

    var body: some View {
        GeometryReader { proxy in
            let usable = proxy.size.height
            let upper = usable * LayoutMetrics.upperFraction
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                VStack(spacing: LayoutMetrics.stackSpacing) {
                    spacePager
                        .frame(height: upper)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier(AccessibilityIDs.timerCard)
                    TaskPanel(controller: controller)
                        .frame(maxHeight: .infinity)
                }
                .padding(.horizontal, LayoutMetrics.horizontalMargin)
                .padding(.top, 4)
                .padding(.bottom, 10)

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
                .padding(.trailing, 6)
            }
        }
        .sheet(isPresented: $showTaskPicker) {
            TaskPickerSheet(controller: controller, isPresented: $showTaskPicker)
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
        .animation(reduceMotion ? nil : .interactiveSpring, value: controller.selectedSpaceID)
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
