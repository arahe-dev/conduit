import SwiftUI

struct SettingsView: View {
    @Bindable var controller: SessionController
    @State private var timeout: Double
    @Environment(\.dismiss) private var dismiss

    init(controller: SessionController) {
        self.controller = controller
        _timeout = State(initialValue: controller.settings.distractionTimeoutSeconds)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Spaces") {
                    NavigationLink("Manage Spaces") {
                        SpaceListView(controller: controller)
                    }
                }
                Section("History") {
                    NavigationLink("Session History") {
                        HistoryView(controller: controller)
                    }
                }
                Section("Distraction reminder") {
                    Stepper(
                        value: $timeout,
                        in: 60...1800,
                        step: 60
                    ) {
                        Text("Threshold \(Int(timeout / 60)) min")
                    }
                    .onChange(of: timeout) { _, newValue in
                        controller.settings.distractionTimeoutSeconds = newValue
                    }
                    Text("Used by the Shortcuts Distraction Started intent. This is not Screen Time measurement.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Integrations") {
                    NavigationLink("Shortcuts and Focus") {
                        IntegrationHelpView()
                    }
                }
                Section("About") {
                    LabeledContent("App", value: "ProductivityTracker")
                    LabeledContent("Version", value: "0.1.0")
                    Text("Local timer. No account, no network, no analytics.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("settings-screen")
    }
}

struct IntegrationHelpView: View {
    var body: some View {
        List {
            Section("Start Work shortcut") {
                Text("1. Set Focus → Work\n2. ProductivityTracker → Select Space → Work\n3. ProductivityTracker → Start Session")
            }
            Section("AI Space import") {
                Text("Ask Shortcuts’ Use Model action to emit JSON matching the Space schema, then run Import Space Definition.")
            }
            Section("Distraction approximation") {
                Text("When a distracting app opens, run Distraction Started. When it closes, run Distraction Ended. If a session is running, a local reminder is scheduled after the threshold.")
            }
            Section("Focus") {
                Text("The app cannot force system Focus on. Add a ProductivityTracker Focus Filter in Settings → Focus to select a Space when that Focus activates.")
            }
        }
        .navigationTitle("Integrations")
    }
}
