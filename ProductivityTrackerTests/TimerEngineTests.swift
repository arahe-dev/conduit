import XCTest
@testable import ProductivityTracker

final class TimerEngineTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    func testStartFromIdle() throws {
        var engine = TimerEngine()
        try engine.start(now: t0, sessionID: UUID(), spaceID: UUID(), taskID: UUID())
        XCTAssertEqual(engine.snapshot.phase, .running)
        XCTAssertEqual(engine.snapshot.elapsed(at: t0.addingTimeInterval(12.5)), 12.5, accuracy: 0.0001)
    }

    func testStopFromRunning() throws {
        var engine = TimerEngine()
        try engine.start(now: t0, sessionID: UUID(), spaceID: UUID(), taskID: nil)
        try engine.stop(now: t0.addingTimeInterval(31.42))
        XCTAssertEqual(engine.snapshot.phase, .stopped)
        XCTAssertEqual(engine.snapshot.elapsed(at: t0.addingTimeInterval(100)), 31.42, accuracy: 0.0001)
    }

    func testPauseResume() throws {
        var engine = TimerEngine()
        try engine.start(now: t0, sessionID: UUID(), spaceID: UUID(), taskID: nil)
        try engine.pause(now: t0.addingTimeInterval(10))
        XCTAssertEqual(engine.snapshot.phase, .paused)
        XCTAssertEqual(engine.snapshot.elapsed(at: t0.addingTimeInterval(50)), 10, accuracy: 0.0001)
        try engine.resume(now: t0.addingTimeInterval(50))
        XCTAssertEqual(engine.snapshot.elapsed(at: t0.addingTimeInterval(55)), 15, accuracy: 0.0001)
    }

    func testInvalidStartWhileRunning() throws {
        var engine = TimerEngine()
        try engine.start(now: t0, sessionID: UUID(), spaceID: UUID(), taskID: nil)
        XCTAssertThrowsError(try engine.start(now: t0, sessionID: UUID(), spaceID: UUID(), taskID: nil))
    }

    func testBackgroundElapsedUsesTimestamps() throws {
        var engine = TimerEngine()
        try engine.start(now: t0, sessionID: UUID(), spaceID: UUID(), taskID: nil)
        let later = t0.addingTimeInterval(3600)
        XCTAssertEqual(engine.snapshot.elapsed(at: later), 3600, accuracy: 0.001)
    }

    func testRestoration() {
        var engine = TimerEngine()
        let session = UUID()
        engine.restore(
            TimerSnapshot(
                phase: .running,
                sessionID: session,
                spaceID: UUID(),
                activeTaskID: nil,
                sessionStartedAt: t0,
                accumulatedActiveDuration: 20,
                currentSegmentStartedAt: t0.addingTimeInterval(20),
                lastStoppedElapsed: 0
            )
        )
        XCTAssertEqual(engine.snapshot.elapsed(at: t0.addingTimeInterval(30)), 30, accuracy: 0.0001)
    }

    func testStopFinalizesElapsed() throws {
        var engine = TimerEngine()
        try engine.start(now: t0, sessionID: UUID(), spaceID: UUID(), taskID: nil)
        try engine.pause(now: t0.addingTimeInterval(8))
        try engine.stop(now: t0.addingTimeInterval(40))
        XCTAssertEqual(engine.snapshot.lastStoppedElapsed, 8, accuracy: 0.0001)
    }

    func testFormatter() {
        XCTAssertEqual(ElapsedFormatter.stopwatch(31.42), "00:31.42")
        XCTAssertEqual(ElapsedFormatter.stopwatch(0), "00:00.00")
        XCTAssertEqual(ElapsedFormatter.stopwatch(3661.07), "1:01:01.07")
    }
}
