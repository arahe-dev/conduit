import XCTest
@testable import ProductivityTracker

@MainActor
final class TimerEngineTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    func testStartFromIdle() {
        let engine = TimerEngine()
        engine.start(now: t0, sessionID: UUID())
        XCTAssertEqual(engine.snapshot.phase, .running)
        XCTAssertEqual(engine.snapshot.elapsed(at: t0.addingTimeInterval(12.5)), 12.5, accuracy: 0.0001)
    }

    func testStopFreezesElapsed() {
        let engine = TimerEngine()
        engine.start(now: t0, sessionID: UUID())
        engine.stop(now: t0.addingTimeInterval(31.42))
        XCTAssertEqual(engine.snapshot.phase, .stopped)
        XCTAssertEqual(engine.snapshot.elapsed(at: t0.addingTimeInterval(100)), 31.42, accuracy: 0.0001)
    }

    func testStartAfterStopResumesSameSession() {
        let engine = TimerEngine()
        let session = UUID()
        engine.start(now: t0, sessionID: session)
        engine.stop(now: t0.addingTimeInterval(10))
        engine.start(now: t0.addingTimeInterval(30), sessionID: UUID())
        XCTAssertEqual(engine.snapshot.sessionID, session)
        XCTAssertEqual(engine.snapshot.elapsed(at: t0.addingTimeInterval(35)), 15, accuracy: 0.0001)
    }

    func testResetClearsDisplay() {
        let engine = TimerEngine()
        engine.start(now: t0, sessionID: UUID())
        engine.stop(now: t0.addingTimeInterval(8))
        engine.resetDisplay()
        XCTAssertEqual(engine.snapshot.phase, .idle)
        XCTAssertEqual(engine.snapshot.elapsed(at: t0.addingTimeInterval(40)), 0, accuracy: 0.0001)
        XCTAssertNil(engine.snapshot.sessionID)
    }

    func testStartWhileRunningIsNoOp() {
        let engine = TimerEngine()
        let session = UUID()
        engine.start(now: t0, sessionID: session)
        engine.start(now: t0.addingTimeInterval(1), sessionID: UUID())
        XCTAssertEqual(engine.snapshot.sessionID, session)
        XCTAssertEqual(engine.snapshot.elapsed(at: t0.addingTimeInterval(5)), 5, accuracy: 0.0001)
    }

    func testBackgroundElapsedUsesTimestamps() {
        let engine = TimerEngine()
        engine.start(now: t0, sessionID: UUID())
        XCTAssertEqual(engine.snapshot.elapsed(at: t0.addingTimeInterval(3600)), 3600, accuracy: 0.001)
    }

    func testRestoration() {
        let engine = TimerEngine()
        let session = UUID()
        engine.restore(
            TimerSnapshot(
                phase: .running,
                spaceID: UUID(),
                sessionID: session,
                currentTaskID: nil,
                startedAt: t0.addingTimeInterval(20),
                accumulatedBeforeCurrentRun: 20,
                lastTick: t0,
                liveActivityID: nil
            )
        )
        XCTAssertEqual(engine.snapshot.elapsed(at: t0.addingTimeInterval(30)), 30, accuracy: 0.0001)
    }

    func testPausedPersistenceMapsToStopped() {
        XCTAssertEqual(TimerPhase(persisted: "paused"), .stopped)
        XCTAssertEqual(TimerPhase(persisted: "stopped"), .stopped)
    }

    func testFormatter() {
        XCTAssertEqual(ElapsedFormatter.stopwatch(31.42), "00:31.42")
        XCTAssertEqual(ElapsedFormatter.stopwatch(0), "00:00.00")
        XCTAssertEqual(ElapsedFormatter.stopwatch(3661.07), "1:01:01.07")
    }
}
