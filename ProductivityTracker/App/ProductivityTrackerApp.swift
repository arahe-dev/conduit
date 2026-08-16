import SwiftData
import SwiftUI
import UIKit

@main
struct ProductivityTrackerApp: App {
    private let launch = LaunchConfiguration.from(ProcessInfo.processInfo.arguments, environment: ProcessInfo.processInfo.environment)
    private let container: ModelContainer
    private let controller: SessionController

    init() {
        if launch.uiTesting {
            UIView.setAnimationsEnabled(false)
        }
        do {
            container = try PersistenceController.makeContainer(inMemory: launch.inMemoryStore)
            AppRuntime.shared.container = container
            let controller = SessionController(context: ModelContext(container), launch: launch)
            try controller.bootstrap()
            self.controller = controller
        } catch {
            fatalError("Unable to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(launch: launch, controller: controller)
                .modelContainer(container)
                .preferredColorScheme(.dark)
        }
    }
}
