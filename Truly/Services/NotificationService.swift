import Foundation
import UserNotifications

final class NotificationService {

    // MARK: – Permission

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: – Schedule

    /// Планирует случайные пуши на 7 дней вперёд.
    /// Если `lastSessionAt` указан — пропускает слоты ближайших 3 часов после сессии.
    func scheduleDailyNudges(windows: [NudgeWindow],
                              lastSessionAt: Date? = nil) async {
        let center   = UNUserNotificationCenter.current()
        await center.removeAllPendingNotificationRequests()

        guard !windows.isEmpty else { return }

        let calendar = Calendar.current
        let now      = Date()
        let catalog  = NudgeTextCatalog.shared

        for dayOffset in 0..<7 {
            guard let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            for window in windows {
                guard let fireDate = window.randomDateWithin(referenceDate: baseDate,
                                                             calendar: calendar) else { continue }

                // Не планировать в прошлом
                guard fireDate > now else { continue }

                // Не беспокоить, если последняя сессия была менее 3 часов назад
                if let last = lastSessionAt,
                   fireDate < last.addingTimeInterval(3 * 3600) { continue }

                let text = catalog.randomText(for: window.timeOfDay)

                let content       = UNMutableNotificationContent()
                content.title     = text.title
                if let body = text.body { content.body = body }
                content.sound     = .default

                let components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: fireDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let id      = "truly.nudge.\(window.timeOfDay.rawValue).\(dayOffset)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

                do    { try await center.add(request) }
                catch { print("Truly: failed to schedule nudge – \(error)") }
            }
        }
    }
}
