import SwiftUI

struct StopwatchDisplay: View {
    @Bindable var controller: SessionController

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.07)) { timeline in
            let elapsed = controller.displayedElapsed(at: timeline.date)
            Text(ElapsedFormatter.stopwatch(elapsed))
                .font(.system(size: LayoutMetrics.stopwatchSize, weight: .thin, design: .default))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .accessibilityIdentifier(AccessibilityIDs.stopwatch)
                .accessibilityLabel(ElapsedFormatter.stopwatch(elapsed))
                .accessibilityValue(controller.snapshot.phase.rawValue)
        }
    }
}
