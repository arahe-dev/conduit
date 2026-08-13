import SwiftUI

struct StopwatchDisplay: View {
    @Bindable var controller: SessionController
    var spaceID: UUID
    var isActivePage: Bool

    var body: some View {
        let snap = controller.snapshot(for: spaceID)
        let overrideElapsed = controller.displayOverrideElapsed(for: spaceID)
        let running = snap.isRunning && isActivePage && overrideElapsed == nil
        Group {
            if running {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                    digits(snap.elapsed(at: timeline.date), phase: snap.phase.rawValue)
                }
            } else {
                digits(overrideElapsed ?? snap.elapsed(at: Date()), phase: snap.phase.rawValue)
            }
        }
    }

    private func digits(_ elapsed: TimeInterval, phase: String) -> some View {
        Text(ElapsedFormatter.stopwatch(elapsed))
            .font(.system(size: LayoutMetrics.stopwatchSize, weight: .thin, design: .default))
            .monospacedDigit()
            .foregroundStyle(.white)
            .minimumScaleFactor(0.45)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .accessibilityIdentifier(isActivePage ? AccessibilityIDs.stopwatch : "stopwatch-display-idle")
            .accessibilityLabel(ElapsedFormatter.stopwatch(elapsed))
            .accessibilityValue(phase)
    }
}
