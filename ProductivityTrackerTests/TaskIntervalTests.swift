import XCTest
import SwiftData
@testable import ProductivityTracker

@MainActor
final class TaskIntervalTests: XCTestCase {
    private func makeController(time: ControllableTimeSource) throws -> SessionController {
        return try SessionController(
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
        ).bootstrapAndReturn()
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

    func testManualTaskSelectionWhileRunning() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        let email = controller.selectedTasks.first { $0.name == "Email" }!
        try controller.selectTask(email)
        XCTAssertEqual(controller.activeTask?.name, "Email")
        let intervals = try controller.allSessions().first?.intervals ?? []
        XCTAssertEqual(intervals.filter(\.isOpen).count, 1)
        XCTAssertEqual(intervals.filter(\.isOpen).first?.task?.name, "Email")
        XCTAssertEqual(intervals.filter { !$0.isOpen }.count, 1)
    }

    func testSameTaskTapDoesNotDuplicateInterval() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        let deep = controller.selectedTasks.first { $0.name == "Deep Work" }!
        try controller.selectTask(deep)
        XCTAssertEqual(try controller.allSessions().first?.intervals.count, 1)
    }

    func testSelectTaskWhileIdleDoesNotStart() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        let email = controller.selectedTasks.first { $0.name == "Email" }!
        try controller.selectTask(email)
        XCTAssertEqual(controller.snapshot.phase, .idle)
        XCTAssertEqual(controller.snapshot.currentTaskID, email.id)
        XCTAssertTrue(try controller.allSessions().isEmpty)
        try controller.start()
        XCTAssertEqual(controller.activeTask?.name, "Email")
    }

    func testSelectTaskWhileStoppedThenResume() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        time.advance(by: 4)
        try controller.stop()
        let email = controller.selectedTasks.first { $0.name == "Email" }!
        try controller.selectTask(email)
        XCTAssertEqual(controller.snapshot.phase, .stopped)
        XCTAssertEqual(controller.displayedElapsed(at: time.now()), 4, accuracy: 0.001)
        try controller.start()
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

    func testStopClosesActiveIntervalWithoutArchiving() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        time.advance(by: 5)
        try controller.stop()
        let intervals = try controller.allSessions().first?.intervals ?? []
        XCTAssertTrue(intervals.allSatisfy { !$0.isOpen })
        XCTAssertEqual(controller.snapshot.phase, .stopped)
        XCTAssertNil(try controller.allSessions().first?.endedAt)
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

    func testDeleteActiveTaskContinuesWithoutFabricating() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        try controller.start()
        let deep = controller.selectedTasks.first { $0.name == "Deep Work" }!
        try controller.deleteTask(deep)
        XCTAssertEqual(controller.activeTask?.name, "Research")
        XCTAssertEqual(try controller.allSessions().first?.intervals.filter(\.isOpen).count, 1)
        for task in controller.selectedTasks {
            try controller.deleteTask(task)
        }
        XCTAssertNil(controller.activeTask)
        XCTAssertEqual(controller.snapshot.phase, .running)
    }

    func testRenameAndReorderTasks() throws {
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 1000))
        let controller = try makeController(time: time)
        let space = controller.selectedSpace!
        let deep = space.allTasksSorted[0]
        try controller.renameTask(deep, to: "Focus")
        XCTAssertEqual(space.allTasksSorted[0].name, "Focus")
        try controller.moveTasks(in: space, from: IndexSet(integer: 0), to: 3)
        XCTAssertEqual(space.allTasksSorted.map(\.name), ["Research", "Email", "Focus"])
        try controller.setTaskEnabled(space.allTasksSorted[0], isEnabled: false)
        XCTAssertEqual(controller.selectedTasks.map(\.name), ["Email", "Focus"])
    }
}

private extension SessionController {
    func bootstrapAndReturn() throws -> SessionController {
        try bootstrap()
        return self
    }
}
