import XCTest
import SwiftData
@testable import ProductivityTracker

@MainActor
final class LiveActivityStateTests: XCTestCase {
    func testLiveActivityFollowsStopResumeResetAndTaskSwitch() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 2000))
        let live = NullLiveActivityManager()
        let controller = SessionController(
            context: ModelContext(try PersistenceController.makeContainer(inMemory: true)),
            timeSource: time,
            notifications: RecordingNotificationService(),
            liveActivity: live,
            settings: SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!),
            launch: LaunchConfiguration(
                uiTesting: true,
                resetStore: true,
                screenshotMode: false,
                startRunning: false,
                frozenElapsed: nil,
                inMemoryStore: true,
                timerState: nil,
                liveActivityPreview: false
            )
        )
        try controller.bootstrap()
        try controller.start()
        XCTAssertEqual(live.lastState?.isRunning, true)
        XCTAssertEqual(live.lastState?.spaceName, "Work")
        XCTAssertEqual(live.lastState?.taskName, "Deep Work")
        XCTAssertEqual(live.dismissed, 0)

        time.advance(by: 10)
        try controller.stop()
        XCTAssertEqual(live.lastState?.isRunning, false)
        XCTAssertEqual(live.lastState?.elapsedAtPause ?? 0, 10, accuracy: 0.01)
        XCTAssertEqual(live.dismissed, 0)
        time.advance(by: 20)
        try controller.start()
        XCTAssertEqual(live.lastState?.isRunning, true)
        XCTAssertEqual(live.dismissed, 0)

        let email = controller.selectedTasks.first { $0.name == "Email" }!
        try controller.selectTask(email)
        XCTAssertEqual(live.lastState?.taskName, "Email")
        XCTAssertEqual(live.lastState?.spaceName, "Work")

        try controller.stop()
        try controller.reset()
        XCTAssertEqual(live.dismissed, 1)
        XCTAssertNil(live.lastState)
    }

    func testSurfaceTapDoesNotCarryPauseOrResumeIntent() {
        XCTAssertFalse(LiveActivityPresentation.backgroundMutatesTimer)
        XCTAssertNil(LiveActivityPresentation.backgroundIntentName)
        XCTAssertEqual(LiveActivityPresentation.exclusiveControlIntentName(isRunning: true), "StopFromLiveActivityIntent")
        XCTAssertEqual(LiveActivityPresentation.exclusiveControlIntentName(isRunning: false), "ResumeFromLiveActivityIntent")
        XCTAssertEqual(LiveActivityPresentation.exclusiveControl(isRunning: true), .stop)
        XCTAssertEqual(LiveActivityPresentation.exclusiveControl(isRunning: false), .start)
    }

    func testSpaceOwnershipStaysWithRunningSpace() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 2000))
        let live = NullLiveActivityManager()
        let controller = SessionController(
            context: ModelContext(try PersistenceController.makeContainer(inMemory: true)),
            timeSource: time,
            notifications: RecordingNotificationService(),
            liveActivity: live,
            settings: SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!),
            launch: LaunchConfiguration(
                uiTesting: true,
                resetStore: true,
                screenshotMode: false,
                startRunning: false,
                frozenElapsed: nil,
                inMemoryStore: true,
                timerState: nil,
                liveActivityPreview: false
            )
        )
        try controller.bootstrap()
        try controller.start()
        controller.selectSpace(DemoIDs.chores)
        live.startOrUpdate(from: controller, at: time.now())
        XCTAssertEqual(live.lastState?.spaceName, "Work")
        XCTAssertEqual(controller.liveActivitySpace()?.name, "Work")
    }
}
