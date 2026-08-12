import XCTest
import SwiftData
@testable import ProductivityTracker

@MainActor
final class SpacePersistenceTests: XCTestCase {
    private func makeController() throws -> SessionController {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let controller = SessionController(
            context: context,
            timeSource: ControllableTimeSource(now: Date(timeIntervalSince1970: 50)),
            notifications: RecordingNotificationService(),
            liveActivity: NullLiveActivityManager(),
            settings: SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!),
            launch: LaunchConfiguration(uiTesting: true, resetStore: true, screenshotMode: false, startRunning: false, frozenElapsed: nil, inMemoryStore: true)
        )
        try controller.bootstrap()
        return controller
    }

    func testDefaultSpacesAndSelection() throws {
        let controller = try makeController()
        XCTAssertEqual(controller.spaces.map(\.name), ["Work", "Chores", "Personal"])
        XCTAssertEqual(controller.selectedSpace?.name, "Work")
        controller.selectSpace(DemoIDs.chores)
        XCTAssertEqual(controller.selectedSpace?.name, "Chores")
    }

    func testOrdering() throws {
        let controller = try makeController()
        try controller.moveSpaces(from: IndexSet(integer: 0), to: 3)
        XCTAssertEqual(controller.spaces.map(\.name), ["Chores", "Personal", "Work"])
    }

    func testDeletionSafeguard() throws {
        let controller = try makeController()
        try controller.start()
        try controller.stop()
        let work = controller.spaces.first { $0.name == "Work" }!
        XCTAssertThrowsError(try controller.deleteSpace(work, confirmHistory: false))
        try controller.deleteSpace(work, confirmHistory: true)
        XCTAssertFalse(controller.spaces.contains(where: { $0.name == "Work" }))
    }

    func testTintPersistence() throws {
        let controller = try makeController()
        let work = controller.spaces.first { $0.name == "Work" }!
        try controller.recolorSpace(work, tint: .blue)
        XCTAssertEqual(controller.spaces.first { $0.name == "Work" }?.tint, .blue)
    }

    func testCreateLoadUpdate() throws {
        let controller = try makeController()
        let space = try controller.createSpace(name: "Thermodynamics", tint: .indigo, tasks: ["Review", "Problems"])
        XCTAssertEqual(space.tasks.count, 2)
        try controller.renameSpace(space, to: "Math")
        XCTAssertTrue(controller.spaces.contains(where: { $0.name == "Math" }))
    }

    func testActiveSessionRecovery() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let time = ControllableTimeSource(now: Date(timeIntervalSince1970: 10))
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let first = SessionController(
            context: context,
            timeSource: time,
            notifications: RecordingNotificationService(),
            liveActivity: NullLiveActivityManager(),
            settings: SettingsStore(defaults: defaults),
            launch: LaunchConfiguration(uiTesting: true, resetStore: true, screenshotMode: false, startRunning: false, frozenElapsed: nil, inMemoryStore: true)
        )
        try first.bootstrap()
        try first.start()
        time.advance(by: 12)

        let restored = SessionController(
            context: context,
            timeSource: time,
            notifications: RecordingNotificationService(),
            liveActivity: NullLiveActivityManager(),
            settings: SettingsStore(defaults: defaults),
            launch: LaunchConfiguration(uiTesting: true, resetStore: false, screenshotMode: false, startRunning: false, frozenElapsed: nil, inMemoryStore: true)
        )
        try restored.bootstrap()
        XCTAssertEqual(restored.snapshot.phase, .running)
        XCTAssertGreaterThan(restored.snapshot.elapsed(at: time.now()), 0)
    }
}
