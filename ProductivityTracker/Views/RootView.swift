import SwiftUI
import SwiftData

struct RootView: View {
    let launch: LaunchConfiguration
    @Environment(\.modelContext) private var modelContext
    @State private var controller: SessionController?
    @State private var showSettings = false

    var body: some View {
        Group {
            if let controller {
                TimerScreen(controller: controller, showSettings: $showSettings)
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear {
            if controller == nil {
                let created = SessionController(context: modelContext, launch: launch)
                try? created.bootstrap()
                controller = created
            }
        }
        .sheet(isPresented: $showSettings) {
            if let controller {
                SettingsView(controller: controller)
            }
        }
    }
}
