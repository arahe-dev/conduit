import SwiftUI
import SwiftData

struct RootView: View {
    let launch: LaunchConfiguration
    @Bindable var controller: SessionController
    @State private var showSettings = false

    var body: some View {
        Group {
            if launch.liveActivityPreview {
                LiveActivityPreviewScreen()
            } else {
                TimerScreen(controller: controller, showSettings: $showSettings)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(controller: controller)
        }
    }
}
