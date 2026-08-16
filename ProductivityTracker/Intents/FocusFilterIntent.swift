import AppIntents

struct ProductivityFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource { "Select a Space" }
    static var description: IntentDescription? {
        IntentDescription(
            "When this Focus is active, ProductivityTracker can select the matching Space. The app cannot turn Focus on by itself."
        )
    }

    @Parameter(title: "Space")
    var space: SpaceEntity?

    var displayRepresentation: DisplayRepresentation {
        if let space {
            return DisplayRepresentation(title: "Space: \(space.name)")
        }
        return DisplayRepresentation(title: "Select a Space")
    }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            if let space {
                AppRuntime.shared.sessionController?.selectSpace(space.id)
            }
        }
        return .result()
    }
}
