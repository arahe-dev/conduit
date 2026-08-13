import SwiftUI

struct LiveActivityPreviewScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                previewCard(title: "Lock Running", identifier: "la-lock-running") {
                    LiveActivityLockScreen(state: .runningPreview)
                }
                previewCard(title: "Lock Stopped", identifier: "la-lock-stopped") {
                    LiveActivityLockScreen(state: .stoppedPreview)
                }
                previewCard(title: "Island Compact", identifier: "la-island-compact") {
                    HStack {
                        DynamicIslandCompactLeading(state: .runningPreview)
                        Spacer()
                        DynamicIslandCompactTrailing(state: .runningPreview)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black))
                }
                previewCard(title: "Island Expanded", identifier: "la-island-expanded") {
                    DynamicIslandExpandedContent(state: .runningPreview)
                }
            }
            .padding(16)
        }
        .background(Color.black.ignoresSafeArea())
        .accessibilityIdentifier(AccessibilityIDs.liveActivityPreview)
    }

    private func previewCard<Content: View>(title: String, identifier: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(white: 0.12)))
                .accessibilityIdentifier(identifier)
        }
    }
}

private extension SessionActivityAttributes.ContentState {
    static let runningPreview = SessionActivityAttributes.ContentState(
        spaceName: "Work",
        taskName: "Deep Work",
        phaseRaw: TimerPhase.running.rawValue,
        displayStart: Date().addingTimeInterval(-31.42),
        isRunning: true,
        elapsedAtPause: 31.42
    )

    static let stoppedPreview = SessionActivityAttributes.ContentState(
        spaceName: "Work",
        taskName: "Deep Work",
        phaseRaw: TimerPhase.stopped.rawValue,
        displayStart: Date().addingTimeInterval(-31.42),
        isRunning: false,
        elapsedAtPause: 31.42
    )
}
