import SwiftUI

struct StopwatchDisplay: View {
    var snapshot: TimerSnapshot
    var overrideElapsed: TimeInterval?
    var isActivePage: Bool

    var body: some View {
        let running = snapshot.isRunning && isActivePage && overrideElapsed == nil
        Group {
            if running {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                    digits(snapshot.elapsed(at: timeline.date))
                }
            } else {
                digits(overrideElapsed ?? snapshot.elapsed(at: Date()))
            }
        }
    }

    private func digits(_ elapsed: TimeInterval) -> some View {
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
            .accessibilityValue(snapshot.phase.rawValue)
    }
}
