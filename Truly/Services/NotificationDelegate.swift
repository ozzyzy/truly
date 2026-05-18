import Foundation
import UserNotifications

/// Handles UNUserNotificationCenter callbacks.
/// When the user taps a Truly nudge, posts `.trulyOpenSuggestion`
/// so HomeView can navigate straight to a suggestion card.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    // Called when the user taps the notification (app in background / closed)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationCenter.default.post(name: .trulyOpenSuggestion, object: nil)
        completionHandler()
    }

    // Called when notification arrives while app is in foreground — still show banner
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

extension Notification.Name {
    static let trulyOpenSuggestion = Notification.Name("trulyOpenSuggestion")
}
