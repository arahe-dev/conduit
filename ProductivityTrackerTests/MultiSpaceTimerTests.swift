import XCTest
import SwiftData
@testable import ProductivityTracker

@MainActor
final class MultiSpaceTimerTests: XCTestCase {
    private func makeController(time: ControllableTimeSource) throws -> SessionController {
        let controller = SessionController(
            context: ModelContext(try PersistenceController.makeContainer(inMemory: true)),
            timeSource: time,
            notifications: RecordingNotificationService(),
            liveActivity: NullLiveActivityManager(),
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
        return controller
    }

    func testSwipeDoesNotRelabelRunningSession() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        time.advance(by: 12)
        let workElapsed = controller.displayedElapsed(at: time.now())
        controller.selectSpace(DemoIDs.chores)
        XCTAssertEqual(controller.selectedSpace?.name, "Chores")
        XCTAssertEqual(controller.snapshot.phase, .idle)
        XCTAssertEqual(controller.displayedElapsed(at: time.now()), 0, accuracy: 0.001)
        XCTAssertEqual(controller.snapshot(for: DemoIDs.work).phase, .running)
        XCTAssertEqual(controller.snapshot(for: DemoIDs.work).elapsed(at: time.now()), workElapsed, accuracy: 0.001)
        XCTAssertEqual(controller.runningSpaceID, DemoIDs.work)
    }

    func testStartingAnotherSpaceFreezesTheRunningOne() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        time.advance(by: 9)
        controller.selectSpace(DemoIDs.chores)
        try controller.start()
        XCTAssertEqual(controller.snapshot(for: DemoIDs.work).phase, .stopped)
        XCTAssertEqual(controller.snapshot(for: DemoIDs.work).elapsed(at: time.now()), 9, accuracy: 0.001)
        XCTAssertEqual(controller.snapshot(for: DemoIDs.chores).phase, .running)
        XCTAssertEqual(controller.runningSpaceID, DemoIDs.chores)
        time.advance(by: 4)
        XCTAssertEqual(controller.snapshot(for: DemoIDs.chores).elapsed(at: time.now()), 4, accuracy: 0.001)
        XCTAssertEqual(controller.snapshot(for: DemoIDs.work).elapsed(at: time.now()), 9, accuracy: 0.001)
    }

    func testSpaceCustomization() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        let work = controller.spaces.first { $0.name == "Work" }!
        try controller.renameSpace(work, to: "Studio")
        try controller.recolorSpace(work, tint: .blue)
        try controller.setReminder(for: work, seconds: 0)
        try controller.setFocusKeyword("Work", for: work)
        let email = work.tasks.first { $0.name == "Email" }!
        try controller.setDefaultTask(email, for: work)
        XCTAssertEqual(controller.spaces.first { $0.id == work.id }?.name, "Studio")
        XCTAssertEqual(work.tint, .blue)
        XCTAssertEqual(work.distractionTimeoutSeconds, 0)
        XCTAssertEqual(work.focusKeyword, "Work")
        XCTAssertEqual(work.defaultTaskID, email.id)
        controller.selectSpace(work.id)
        try controller.start()
        XCTAssertEqual(controller.activeTask?.name, "Email")
    }
}
