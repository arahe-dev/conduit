import SwiftUI

struct SpaceListView: View {
    @Bindable var controller: SessionController
    @State private var newName = ""
    @State private var pendingDelete: Space?
    @State private var confirmHistory = false

    var body: some View {
        List {
            ForEach(controller.spaces, id: \.id) { space in
                NavigationLink(space.name) {
                    SpaceEditorView(controller: controller, space: space)
                }
            }
            .onMove { source, destination in
                try? controller.moveSpaces(from: source, to: destination)
            }
            .onDelete { indexSet in
                if let index = indexSet.first {
                    pendingDelete = controller.spaces[index]
                    confirmHistory = true
                }
            }
            Section("New Space") {
                TextField("Name", text: $newName)
                Button("Create") {
                    let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    _ = try? controller.createSpace(name: name, tint: .blue, tasks: ["Task 1"])
                    newName = ""
                }
            }
        }
        .navigationTitle("Spaces")
        .environment(\.editMode, .constant(.active))
        .alert("Delete Space?", isPresented: $confirmHistory) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let space = pendingDelete {
                    try? controller.deleteSpace(space, confirmHistory: true)
                }
                pendingDelete = nil
            }
        } message: {
            Text("This Space may contain session history. Deleting it removes that history from this device.")
        }
    }
}
