import Foundation

struct DistractionMonitor {
    var activeSessionID: UUID?
    var threshold: TimeInterval

    mutating func distractionStarted(
        isSessionActive: Bool,
        sessionID: UUID?,
        schedule: (UUID) -> Void
    ) {
        guard isSessionActive, let sessionID else { return }
        activeSessionID = sessionID
        schedule(sessionID)
    }

    mutating func distractionEnded(cancel: (UUID) -> Void) {
        if let sessionID = activeSessionID {
            cancel(sessionID)
        }
        activeSessionID = nil
    }
}
