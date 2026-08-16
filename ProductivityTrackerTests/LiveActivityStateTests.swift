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
        let runningAnchor = live.lastState?.displayStart

        time.advance(by: 10)
        try controller.stop()
        XCTAssertEqual(live.lastState?.isRunning, false)
        XCTAssertEqual(live.lastState?.elapsedAtPause ?? 0, 10, accuracy: 0.01)
        XCTAssertNotNil(live.lastState?.pauseTime)
        XCTAssertEqual(live.lastState?.displayStart, runningAnchor)
        XCTAssertEqual(live.lastState?.tintRaw, SpaceTint.orange.rawValue)
        XCTAssertEqual(live.lastState?.iconValue, SpaceIcon.work.value)
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
        XCTAssertEqual(String(describing: StopFromLiveActivityIntent.self), "StopFromLiveActivityIntent")
        XCTAssertEqual(String(describing: ResumeFromLiveActivityIntent.self), "ResumeFromLiveActivityIntent")
    }

    func testElapsedClockIdentityChangesOnPauseAndResume() {
        let start = Date(timeIntervalSince1970: 4000)
        let running = LiveActivityPresentation.content(
            spaceName: "Work",
            taskName: "Deep Work",
            phaseRaw: TimerPhase.running.rawValue,
            isRunning: true,
            elapsed: 12,
            now: start.addingTimeInterval(12),
            displayStart: start
        )
        let paused = running.paused(at: start.addingTimeInterval(12.5))
        let resumed = paused.resumed(at: start.addingTimeInterval(42.5))
        XCTAssertNotEqual(running.elapsedClockID, paused.elapsedClockID)
        XCTAssertNotEqual(paused.elapsedClockID, resumed.elapsedClockID)
        XCTAssertTrue(running.elapsedClockID.hasPrefix("run-"))
        XCTAssertTrue(paused.elapsedClockID.hasPrefix("stop-"))
        XCTAssertTrue(resumed.elapsedClockID.hasPrefix("run-"))
        XCTAssertNotEqual(running.displayStart, resumed.displayStart)
    }

    func testLiveActivityContentIncludesTintAndIconFields() throws {
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
        XCTAssertEqual(live.lastState?.tintRaw, SpaceTint.orange.rawValue)
        XCTAssertEqual(live.lastState?.iconKindRaw, SpaceIconKind.symbol.rawValue)
        XCTAssertEqual(live.lastState?.iconValue, SpaceIcon.work.value)
        XCTAssertEqual(live.lastState?.icon, .work)
    }

    func testLiveActivityRunningAndStoppedShareTimerIntervalModel() {
        let now = Date(timeIntervalSince1970: 3000)
        let running = LiveActivityPresentation.content(
            spaceName: "Work",
            taskName: "Deep Work",
            phaseRaw: TimerPhase.running.rawValue,
            isRunning: true,
            elapsed: 42,
            now: now,
            tintRaw: SpaceTint.orange.rawValue,
            iconKindRaw: SpaceIconKind.symbol.rawValue,
            iconValue: SpaceIcon.work.value
        )
        XCTAssertTrue(running.isRunning)
        XCTAssertEqual(running.elapsedAtPause, 42, accuracy: 0.001)
        XCTAssertNil(running.pauseTime)
        XCTAssertEqual(
            running.timerRange.lowerBound.timeIntervalSince1970,
            now.addingTimeInterval(-42).timeIntervalSince1970,
            accuracy: 0.001
        )

        let stopped = LiveActivityPresentation.content(
            spaceName: "Work",
            taskName: "Deep Work",
            phaseRaw: TimerPhase.stopped.rawValue,
            isRunning: false,
            elapsed: 42,
            now: now,
            tintRaw: SpaceTint.orange.rawValue,
            iconKindRaw: SpaceIconKind.symbol.rawValue,
            iconValue: SpaceIcon.work.value
        )
        XCTAssertFalse(stopped.isRunning)
        XCTAssertEqual(stopped.elapsedAtPause, 42, accuracy: 0.001)
        XCTAssertNotNil(stopped.pauseTime)
        XCTAssertEqual(
            stopped.pauseTime!.timeIntervalSince1970,
            stopped.displayStart.addingTimeInterval(stopped.elapsedAtPause).timeIntervalSince1970,
            accuracy: 0.001
        )
        XCTAssertEqual(
            stopped.timerRange.lowerBound.timeIntervalSince1970,
            running.timerRange.lowerBound.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testPauseKeepsClockAnchorAndResumeReanchorsElapsed() {
        let start = Date(timeIntervalSince1970: 4000)
        let running = LiveActivityPresentation.content(
            spaceName: "Work",
            taskName: "Deep Work",
            phaseRaw: TimerPhase.running.rawValue,
            isRunning: true,
            elapsed: 12,
            now: start.addingTimeInterval(12),
            displayStart: start
        )
        let pausedAt = start.addingTimeInterval(12.5)
        let paused = running.paused(at: pausedAt)
        XCTAssertFalse(paused.isRunning)
        XCTAssertEqual(paused.displayStart, start)
        XCTAssertEqual(paused.elapsedAtPause, 12.5, accuracy: 0.0001)
        XCTAssertNotNil(paused.pauseTime)
        XCTAssertEqual(paused.pauseTime!.timeIntervalSince1970, pausedAt.timeIntervalSince1970, accuracy: 0.0001)

        let resumeAt = pausedAt.addingTimeInterval(30)
        let resumed = paused.resumed(at: resumeAt)
        XCTAssertTrue(resumed.isRunning)
        XCTAssertNil(resumed.pauseTime)
        XCTAssertEqual(resumed.elapsedAtPause, 12.5, accuracy: 0.0001)
        XCTAssertEqual(
            resumeAt.timeIntervalSince(resumed.displayStart),
            12.5,
            accuracy: 0.0001
        )
        XCTAssertNotEqual(paused.elapsedClockID, resumed.elapsedClockID)
    }

    func testLockScreenStopThenStartRepublishesRunningClock() async throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 5000))
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
        time.advance(by: 10)
        let runningAnchor = live.lastState?.displayStart
        await controller.stopFromLiveActivity(at: time.now())
        XCTAssertEqual(controller.snapshot.phase, .stopped)
        XCTAssertEqual(live.lastState?.isRunning, false)
        XCTAssertEqual(live.lastState?.displayStart, runningAnchor)
        XCTAssertNotNil(live.lastState?.pauseTime)
        let pausedID = live.lastState?.elapsedClockID

        time.advance(by: 20)
        await controller.startFromLiveActivity(at: time.now())
        XCTAssertEqual(controller.snapshot.phase, .running)
        XCTAssertEqual(live.lastState?.isRunning, true)
        XCTAssertNil(live.lastState?.pauseTime)
        XCTAssertNotEqual(live.lastState?.displayStart, runningAnchor)
        XCTAssertNotEqual(live.lastState?.elapsedClockID, pausedID)
        XCTAssertEqual(
            time.now().timeIntervalSince(live.lastState!.displayStart),
            10,
            accuracy: 0.01
        )
        time.advance(by: 5)
        XCTAssertEqual(controller.displayedElapsed(at: time.now()), 15, accuracy: 0.01)
    }

    func testLockScreenResumeUsesLiveActivityOwnerNotSelectedSpace() async throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 6000))
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
        time.advance(by: 8)
        await controller.stopFromLiveActivity(at: time.now())
        controller.selectSpace(DemoIDs.chores)
        await controller.startFromLiveActivity(at: time.now())
        XCTAssertEqual(controller.snapshot(for: DemoIDs.work).phase, .running)
        XCTAssertEqual(controller.snapshot(for: DemoIDs.chores).phase, .idle)
        XCTAssertEqual(live.lastState?.spaceName, "Work")
        XCTAssertEqual(live.lastState?.isRunning, true)
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
        let publishes = live.started
        controller.selectSpace(DemoIDs.chores)
        XCTAssertEqual(live.started, publishes)
        live.startOrUpdate(from: controller, at: time.now())
        XCTAssertEqual(live.lastState?.spaceName, "Work")
        XCTAssertEqual(controller.liveActivitySpace()?.name, "Work")
    }
}
