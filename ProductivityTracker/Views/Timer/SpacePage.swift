import SwiftUI

enum SpacePagerPage: Hashable {
    case space(UUID)
    case compose
}

struct SpacePage: View {
    @Bindable var controller: SessionController
    var space: Space
    var isActivePage: Bool
    var pageIndex: Int
    var pageCount: Int
    var onLongPressLap: () -> Void
    var onRenameTask: (TaskItem) -> Void
    var onEditSpace: () -> Void
    var onSaveTime: () -> Void
    var onOpenSavedTimes: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            StopwatchDisplay(
                controller: controller,
                spaceID: space.id,
                isActivePage: isActivePage
            )
            .padding(.top, 8)
            StopwatchButtons(
                controller: controller,
                space: space,
                isActivePage: isActivePage,
                onLongPressLap: onLongPressLap,
                onSaveTime: onSaveTime,
                onOpenSavedTimes: onOpenSavedTimes
            )
            .padding(.top, 18)
            PageDots(
                count: pageCount,
                current: pageIndex,
                accent: space.tint.color,
                composeAtEnd: true
            )
            .accessibilityIdentifier(isActivePage ? AccessibilityIDs.pageIndicator : "page-indicator-idle")
            .padding(.top, 16)
            .padding(.bottom, 8)

            TaskPanel(
                controller: controller,
                space: space,
                isActivePage: isActivePage,
                onRename: onRenameTask
            )
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, LayoutMetrics.horizontalMargin)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            SpaceCanvas.glow(space.tint.color)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(isActivePage ? AccessibilityIDs.timerCard : "timer-card-idle")
    }

    private var header: some View {
        HStack(spacing: 10) {
            SpaceIconView(icon: space.icon, tint: space.tint.color, pointSize: 24)
            Text(space.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(space.tint.color)
                .lineLimit(1)
                .accessibilityIdentifier(isActivePage ? AccessibilityIDs.spaceName : "space-name-idle")
                .accessibilityLabel(space.name)
            Spacer(minLength: 48)
        }
        .padding(.trailing, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEditSpace)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens Space settings")
    }
}
