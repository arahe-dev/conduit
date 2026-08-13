import SwiftUI
import WidgetKit

struct DynamicIslandViews {
    static func compactLeading(context: ActivityViewContext<SessionActivityAttributes>) -> some View {
        DynamicIslandCompactLeading(state: context.state)
    }

    static func compactTrailing(context: ActivityViewContext<SessionActivityAttributes>) -> some View {
        DynamicIslandCompactTrailing(state: context.state)
    }

    static func minimal(context: ActivityViewContext<SessionActivityAttributes>) -> some View {
        DynamicIslandMinimal(state: context.state)
    }

    static func expanded(context: ActivityViewContext<SessionActivityAttributes>) -> some View {
        DynamicIslandExpandedContent(state: context.state)
    }
}
