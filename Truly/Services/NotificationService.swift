import Foundation
import UserNotifications

final class NotificationService {

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleDailyNudges(hours: [Int]) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(withIdentifiers: hours.map { "truly.nudge.\($0)" })

        for hour in hours {
            var date = DateComponents()
            date.hour = hour
            date.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "Truly"
            content.body = "Маленький момент для тебя — прямо сейчас."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            let request = UNNotificationRequest(identifier: "truly.nudge.\(hour)", content: content, trigger: trigger)

            do { try await center.add(request) } catch {}
        }
    }
}
