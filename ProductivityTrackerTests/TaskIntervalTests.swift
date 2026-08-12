import XCTest
import SwiftData
@testable import ProductivityTracker

@MainActor
final class TaskIntervalTests: XCTestCase {
    private func makeController(time: ControllableTimeSource) throws -> SessionController {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let controller = SessionController(
            context: context,
            timeSource: time,
            notifications: RecordingNotificationService(),
            liveActivity: NullLiveActivityManager(),
            settings: SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!),
            launch: LaunchConfiguration(uiTesting: true, resetStore: true, screenshotMode: false, startRunning: false, frozenElapsed: nil, inMemoryStore: true)
        )
        try controller.bootstrap()
        return controller
    }

    func testFirstTaskStarts() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        XCTAssertEqual(controller.activeTask?.name, "Deep Work")
        XCTAssertEqual(controller.snapshot.phase, .running)
    }

    func testLapClosesOldAndStartsNext() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        time.advance(by: 10)
        try controller.lap()
        XCTAssertEqual(controller.activeTask?.name, "Research")
        let session = try controller.allSessions().first
        let closed = session?.intervals.filter { $0.endedAt != nil } ?? []
        let open = session?.intervals.filter { $0.isOpen } ?? []
        XCTAssertEqual(closed.count, 1)
        XCTAssertEqual(open.count, 1)
        XCTAssertEqual(closed.first?.task?.name, "Deep Work")
        XCTAssertEqual(open.first?.task?.name, "Research")
        XCTAssertEqual(controller.snapshot.elapsed(at: time.now()), 10, accuracy: 0.001)
    }

    func testManualTaskSelection() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        let email = controller.selectedTasks.first { $0.name == "Email" }!
        try controller.selectTask(email)
        XCTAssertEqual(controller.activeTask?.name, "Email")
        let open = try controller.allSessions().first?.intervals.filter(\.isOpen) ?? []
        XCTAssertEqual(open.count, 1)
        XCTAssertEqual(open.first?.task?.name, "Email")
    }

    func testNoOverlappingActiveIntervals() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        try controller.lap()
        try controller.lap()
        let open = try controller.allSessions().first?.intervals.filter(\.isOpen) ?? []
        XCTAssertEqual(open.count, 1)
    }

    func testStopClosesActiveInterval() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        time.advance(by: 5)
        try controller.stop()
        let intervals = try controller.allSessions().first?.intervals ?? []
        XCTAssertTrue(intervals.allSatisfy { !$0.isOpen })
        XCTAssertEqual(controller.snapshot.phase, .stopped)
    }

    func testLapWrapsToFirstTask() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        try controller.lap()
        try controller.lap()
        try controller.lap()
        XCTAssertEqual(controller.activeTask?.name, "Deep Work")
    }
}
