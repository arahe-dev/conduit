import SwiftUI

struct SavedTimesView: View {
    @Bindable var controller: SessionController
    var initialSpaceID: UUID?
    @State private var filter: SavedTimeFilter
    @State private var records: [TimeSave] = []

    init(controller: SessionController, initialSpaceID: UUID?) {
        self.controller = controller
        self.initialSpaceID = initialSpaceID
        if let initialSpaceID {
            _filter = State(initialValue: .space(initialSpaceID))
        } else {
            _filter = State(initialValue: .all)
        }
    }

    var body: some View {
        List {
            if records.isEmpty {
                Text("No saved times")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(records, id: \.id) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(record.name)
                                .font(.body.weight(.medium))
                            Spacer()
                            Text(ElapsedFormatter.stopwatch(record.elapsed))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Text(record.savedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .accessibilityIdentifier("saved-time-\(record.id.uuidString)")
                }
                .onDelete { offsets in
                    for index in offsets {
                        try? controller.deleteSavedTime(records[index])
                    }
                    reload()
                }
            }
        }
        .navigationTitle("Saved Times")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Filter", selection: $filter) {
                    Text("All Spaces").tag(SavedTimeFilter.all)
                    ForEach(controller.spaces, id: \.id) { space in
                        Text(space.name).tag(SavedTimeFilter.space(space.id))
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("saved-times-filter")
            }
        }
        .accessibilityIdentifier("saved-times-screen")
        .onAppear(perform: reload)
        .onChange(of: filter) { _, _ in reload() }
    }

    private func reload() {
        records = (try? controller.savedTimes(filter: filter)) ?? []
    }
}
