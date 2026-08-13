import SwiftUI

struct SpaceListView: View {
    @Bindable var controller: SessionController
    @State private var newName = ""
    @State private var pendingDelete: Space?
    @State private var confirmHistory = false

    var body: some View {
        List {
            ForEach(controller.spaces, id: \.id) { space in
                NavigationLink {
                    SpaceEditorView(controller: controller, space: space)
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(space.tint.color)
                            .frame(width: 10, height: 10)
                        Text(space.name)
                    }
                }
                .accessibilityIdentifier("space-row-\(space.name)")
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
            Section {
                TextField("Name", text: $newName)
                Button("Add") {
                    let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    _ = try? controller.createSpace(name: name, tint: .blue, tasks: ["Task"])
                    newName = ""
                }
            } header: {
                Text("New Space")
            }
        }
        .navigationTitle("Spaces")
        .toolbar { EditButton() }
        .alert("Delete Space?", isPresented: $confirmHistory) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let space = pendingDelete {
                    try? controller.deleteSpace(space, confirmHistory: true)
                }
                pendingDelete = nil
            }
        } message: {
            Text("Session history for this Space will be removed.")
        }
    }
}
