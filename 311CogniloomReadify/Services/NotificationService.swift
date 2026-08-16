import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    private let reminderId = "cr_daily_goal_reminder"

    private init() {}

    func requestAuthorizationIfNeeded(completion: ((Bool) -> Void)? = nil) {
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async { completion?(granted) }
                }
            case .authorized, .provisional:
                DispatchQueue.main.async { completion?(true) }
            default:
                DispatchQueue.main.async { completion?(false) }
            }
        }
    }

    func syncReminder(enabled: Bool, hour: Int, minute: Int, goal: Int) {
        center.removePendingNotificationRequests(withIdentifiers: [reminderId])
        guard enabled else { return }

        requestAuthorizationIfNeeded { granted in
            guard granted else { return }
            var date = DateComponents()
            date.hour = hour
            date.minute = minute
            let content = UNMutableNotificationContent()
            content.title = "Cogniloom"
            content.body = "Lift \(goal) quote\(goal == 1 ? "" : "s") from the page you are reading."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            let request = UNNotificationRequest(identifier: self.reminderId, content: content, trigger: trigger)
            self.center.add(request)
        }
    }
}
