import XCTest
import SwiftData
@testable import ProductivityTracker

final class NotificationAndImportTests: XCTestCase {
    func testDistractionSchedulesOnlyWhenRunning() {
        var monitor = DistractionMonitor(activeSessionID: nil, threshold: 300)
        var scheduled: UUID?
        monitor.distractionStarted(isSessionActive: false, sessionID: UUID()) { scheduled = $0 }
        XCTAssertNil(scheduled)

        let session = UUID()
        monitor.distractionStarted(isSessionActive: true, sessionID: session) { scheduled = $0 }
        XCTAssertEqual(scheduled, session)
        XCTAssertEqual(NotificationIdentifiers.distraction(sessionID: session), "distraction.session.\(session.uuidString)")
    }

    func testDistractionCancellation() {
        var monitor = DistractionMonitor(activeSessionID: nil, threshold: 300)
        let session = UUID()
        monitor.distractionStarted(isSessionActive: true, sessionID: session) { _ in }
        var cancelled: UUID?
        monitor.distractionEnded { cancelled = $0 }
        XCTAssertEqual(cancelled, session)
        XCTAssertNil(monitor.activeSessionID)
    }

    @MainActor
    func testNotificationServiceRecordsActiveTimerOnly() throws {
        let notifications = RecordingNotificationService()
        let container = try PersistenceController.makeContainer(inMemory: true)
        let controller = SessionController(
            context: ModelContext(container),
            timeSource: ControllableTimeSource(now: Date(timeIntervalSince1970: 1)),
            notifications: notifications,
            liveActivity: NullLiveActivityManager(),
            settings: SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!),
            launch: LaunchConfiguration(uiTesting: true, resetStore: true, screenshotMode: false, startRunning: false, frozenElapsed: nil, inMemoryStore: true)
        )
        try controller.bootstrap()
        controller.distractionStarted()
        XCTAssertTrue(notifications.scheduled.isEmpty)
        try controller.start()
        controller.distractionStarted()
        XCTAssertEqual(notifications.scheduled.count, 1)
        XCTAssertEqual(notifications.scheduled.first?.after, 300)
        controller.distractionEnded()
        XCTAssertTrue(notifications.scheduled.isEmpty)
    }

    func testValidSpaceJSON() throws {
        let json = """
        {"name":"Thermodynamics","color":"blue","tasks":["Review lecture","Practice problems","Formula review","Assignment"]}
        """
        let payload = try SpaceImportPayload.parse(json: json)
        XCTAssertEqual(payload.name, "Thermodynamics")
        XCTAssertEqual(payload.color, .blue)
        XCTAssertEqual(payload.tasks.count, 4)
    }

    func testMalformedJSON() {
        XCTAssertThrowsError(try SpaceImportPayload.parse(json: "{not json")) { error in
            XCTAssertEqual(error as? SpaceImportError, .malformedJSON)
        }
    }

    func testMissingName() {
        XCTAssertThrowsError(try SpaceImportPayload.parse(json: #"{"color":"blue","tasks":["A"]}"#)) { error in
            XCTAssertEqual(error as? SpaceImportError, .missingName)
        }
    }

    func testEmptyTasks() {
        XCTAssertThrowsError(try SpaceImportPayload.parse(json: #"{"name":"Work","tasks":[]}"#)) { error in
            XCTAssertEqual(error as? SpaceImportError, .emptyTasks)
        }
    }

    func testExcessiveTaskCount() {
        let tasks = (1...41).map { "\"T\($0)\"" }.joined(separator: ",")
        XCTAssertThrowsError(try SpaceImportPayload.parse(json: "{\"name\":\"X\",\"tasks\":[\(tasks)]}")) { error in
            XCTAssertEqual(error as? SpaceImportError, .excessiveTaskCount)
        }
    }

    func testDuplicateTaskHandling() throws {
        let payload = try SpaceImportPayload.parse(json: #"{"name":"Work","color":"orange","tasks":["Deep Work","deep work","Email"]}"#)
        XCTAssertEqual(payload.tasks, ["Deep Work", "Email"])
    }

    func testInvalidColor() {
        XCTAssertThrowsError(try SpaceImportPayload.parse(json: #"{"name":"Work","color":"neon","tasks":["A"]}"#)) { error in
            XCTAssertEqual(error as? SpaceImportError, .invalidColor("neon"))
        }
    }

    func testLaunchConfigurationScreenshot() {
        let config = LaunchConfiguration.from(["-ScreenshotMode"])
        XCTAssertEqual(config.frozenElapsed, 31.42)
        XCTAssertTrue(config.startRunning)
    }
}
