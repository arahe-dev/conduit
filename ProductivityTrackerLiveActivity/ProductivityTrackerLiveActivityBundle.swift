import SwiftUI
import WidgetKit

@main
struct ProductivityTrackerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            LiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.35))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.bottom) {
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
