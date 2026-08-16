import SwiftUI
import WidgetKit

struct LiveActivityView: View {
    let context: ActivityViewContext<SessionActivityAttributes>

    var body: some View {
        LiveActivityLockScreen(state: context.state)
    }
}
