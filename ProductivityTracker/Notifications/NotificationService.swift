import Foundation
import UserNotifications

struct NotificationIdentifiers {
    static let distractionCategory = "DISTRACTION_REMINDER"
    static let continueAction = "CONTINUE"
    static let stopAction = "STOP"
    static let pauseAction = "PAUSE"

    static func distraction(sessionID: UUID) -> String {
        "distraction.session.\(sessionID.uuidString)"
    }
}

protocol NotificationScheduling: AnyObject {
    func requestAuthorizationIfNeeded()
    func scheduleDistractionReminder(sessionID: UUID, spaceName: String, elapsed: TimeInterval, after seconds: TimeInterval)
    func cancelDistractionReminder(sessionID: UUID)
    func cancelAllDistractionReminders()
}

final class NotificationService: NSObject, NotificationScheduling, UNUserNotificationCenterDelegate {
    private let center: UNUserNotificationCenter
    var onContinue: (@MainActor () -> Void)?
    var onStop: (@MainActor () -> Void)?
    var onPause: (@MainActor () -> Void)?

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
    }

    func configure() {
        center.delegate = self
        let continueAction = UNNotificationAction(
            identifier: NotificationIdentifiers.continueAction,
            title: "Continue"
        )
        let pauseAction = UNNotificationAction(
            identifier: NotificationIdentifiers.pauseAction,
            title: "Pause"
        )
        let stopAction = UNNotificationAction(
            identifier: NotificationIdentifiers.stopAction,
            title: "Stop",
            options: .destructive
        )
        let category = UNNotificationCategory(
            identifier: NotificationIdentifiers.distractionCategory,
            actions: [continueAction, pauseAction, stopAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            self.center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    func scheduleDistractionReminder(sessionID: UUID, spaceName: String, elapsed: TimeInterval, after seconds: TimeInterval) {
        cancelDistractionReminder(sessionID: sessionID)
        let content = UNMutableNotificationContent()
        content.title = "\(spaceName) timer: \(ElapsedFormatter.compact(elapsed))"
        content.body = "Still working?"
        content.categoryIdentifier = NotificationIdentifiers.distractionCategory
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationIdentifiers.distraction(sessionID: sessionID),
            content: content,
            trigger: trigger
        )
        center.add(request, withCompletionHandler: { _ in })
    }

    func cancelDistractionReminder(sessionID: UUID) {
        center.removePendingNotificationRequests(
            withIdentifiers: [NotificationIdentifiers.distraction(sessionID: sessionID)]
        )
    }

    func cancelAllDistractionReminders() {
        center.removeAllPendingNotificationRequests()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            switch response.actionIdentifier {
            case NotificationIdentifiers.stopAction:
                onStop?()
            case NotificationIdentifiers.pauseAction:
                onPause?()
            default:
                onContinue?()
            }
            completionHandler()
        }
    }
}

final class RecordingNotificationService: NotificationScheduling {
    struct Request: Equatable {
        var sessionID: UUID
        var spaceName: String
        var elapsed: TimeInterval
        var after: TimeInterval
    }

    var scheduled: [Request] = []
    var cancelled: [UUID] = []
    var cancelledAll = false
    var authorizationRequested = false

    func requestAuthorizationIfNeeded() {
        authorizationRequested = true
    }

    func scheduleDistractionReminder(sessionID: UUID, spaceName: String, elapsed: TimeInterval, after seconds: TimeInterval) {
        scheduled.removeAll { $0.sessionID == sessionID }
        scheduled.append(Request(sessionID: sessionID, spaceName: spaceName, elapsed: elapsed, after: seconds))
    }

    func cancelDistractionReminder(sessionID: UUID) {
        scheduled.removeAll { $0.sessionID == sessionID }
        cancelled.append(sessionID)
    }

    func cancelAllDistractionReminders() {
        scheduled.removeAll()
        cancelledAll = true
    }
}
