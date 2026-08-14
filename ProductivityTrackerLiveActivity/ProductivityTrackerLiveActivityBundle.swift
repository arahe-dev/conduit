import SwiftUI
import WidgetKit

@main
struct ProductivityTrackerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            LiveActivityView(context: context)
                .activityBackgroundTint(context.state.tint.opacity(0.38))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    DynamicIslandViews.expanded(context: context)
                }
            } compactLeading: {
                DynamicIslandViews.compactLeading(context: context)
            } compactTrailing: {
                DynamicIslandViews.compactTrailing(context: context)
            } minimal: {
                DynamicIslandViews.minimal(context: context)
            }
        }
    }
}
