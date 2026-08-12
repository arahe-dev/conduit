import Foundation

protocol TimeSource: Sendable {
    func now() -> Date
}

struct SystemTimeSource: TimeSource {
    func now() -> Date { Date() }
}

final class ControllableTimeSource: TimeSource, @unchecked Sendable {
    private let lock = NSLock()
    private var _now: Date

    init(now: Date) {
        self._now = now
    }

    func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return _now
    }

    func set(_ date: Date) {
        lock.lock()
        _now = date
        lock.unlock()
    }

    func advance(by interval: TimeInterval) {
        lock.lock()
        _now = _now.addingTimeInterval(interval)
        lock.unlock()
    }
}
