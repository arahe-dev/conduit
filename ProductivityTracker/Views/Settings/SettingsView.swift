import SwiftUI

struct SettingsView: View {
    @Bindable var controller: SessionController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Spaces") {
                    NavigationLink("Manage Spaces") {
                        SpaceListView(controller: controller)
                    }
                    .accessibilityIdentifier("manage-spaces")
                }
                Section("History") {
                    NavigationLink("Saved Times") {
                        SavedTimesView(controller: controller, initialSpaceID: controller.selectedSpaceID)
                    }
                    NavigationLink("Session History") {
                        HistoryView(controller: controller)
                    }
                }
                Section("Integrations") {
                    NavigationLink("Shortcuts and Focus") {
                        IntegrationHelpView()
                    }
                }
                Section("About") {
                    LabeledContent("App", value: "Conduit")
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
            Section("Focus") {
                Text("The app cannot force system Focus on. Add a ProductivityTracker Focus Filter in Settings → Focus to select a Space when that Focus activates.")
            }
        }
        .navigationTitle("Integrations")
    }
}
