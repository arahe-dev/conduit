import XCTest
import SwiftData
@testable import ProductivityTracker

@MainActor
final class StopwatchSemanticsTests: XCTestCase {
    private func makeController(time: ControllableTimeSource) throws -> SessionController {
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
        return controller
    }

    func testRequiredStopResumeResetSequence() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        XCTAssertEqual(controller.snapshot.phase, .running)
        time.advance(by: 10)
        XCTAssertEqual(controller.displayedElapsed(at: time.now()), 10, accuracy: 0.001)
        try controller.stop()
        XCTAssertEqual(controller.snapshot.phase, .stopped)
        XCTAssertEqual(controller.displayedElapsed(at: time.now()), 10, accuracy: 0.001)
        time.advance(by: 20)
        XCTAssertEqual(controller.displayedElapsed(at: time.now()), 10, accuracy: 0.001)
        try controller.start()
        time.advance(by: 5)
        XCTAssertEqual(controller.displayedElapsed(at: time.now()), 15, accuracy: 0.001)
        try controller.stop()
        XCTAssertEqual(controller.displayedElapsed(at: time.now()), 15, accuracy: 0.001)
        try controller.reset()
        XCTAssertEqual(controller.snapshot.phase, .idle)
        XCTAssertEqual(controller.displayedElapsed(at: time.now()), 0, accuracy: 0.001)
        let historical = try controller.historicalSessions()
        XCTAssertEqual(historical.count, 1)
        XCTAssertEqual(historical[0].elapsed(at: historical[0].endedAt ?? time.now()), 15, accuracy: 0.05)
        XCTAssertEqual(try controller.allSessions().count, 1)
    }

    func testStopDoesNotCreateHistory() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        time.advance(by: 8)
        try controller.stop()
        XCTAssertTrue(try controller.historicalSessions().isEmpty)
        XCTAssertEqual(try controller.allSessions().count, 1)
        XCTAssertNil(try controller.allSessions().first?.endedAt)
    }

    func testResumeDoesNotCreateSecondSession() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        let sessionID = controller.snapshot.sessionID
        try controller.stop()
        try controller.start()
        XCTAssertEqual(controller.snapshot.sessionID, sessionID)
        XCTAssertEqual(try controller.allSessions().count, 1)
    }

    func testButtonSemantics() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        XCTAssertEqual(controller.snapshot.phase.leftControl, .lapDisabled)
        XCTAssertEqual(controller.snapshot.phase.rightControl, .start)
        try controller.start()
        XCTAssertEqual(controller.snapshot.phase.leftControl, .lap)
        XCTAssertEqual(controller.snapshot.phase.rightControl, .stop)
        try controller.stop()
        XCTAssertEqual(controller.snapshot.phase.leftControl, .reset)
        XCTAssertEqual(controller.snapshot.phase.rightControl, .start)
    }
}
