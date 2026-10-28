//
//  NotificationService.swift
//  GroundTruth
//

import Foundation
import UserNotifications

/// Schedules local reminders for a project task's due date. Reminders fire the
/// day before a task is due, since by the time it's actually due it's too late
/// to be useful.
enum NotificationService {
    static let enabledKey = "notificationsEnabled"

    /// Mirrors the default `@AppStorage(enabledKey) var notificationsEnabled = true` in
    /// ProfileView — reads the raw UserDefaults value so non-view code sees the same
    /// "on by default until the user turns it off" behavior.
    static var isEnabled: Bool {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: enabledKey) == nil ? true : defaults.bool(forKey: enabledKey)
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        guard isEnabled else { return false }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        default:
            return false
        }
    }

    static func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Fires a real local notification a few seconds from now, independent of any
    /// task's due date. For demoing that the notification pipeline works end-to-end
    /// without waiting for an actual due date reminder (which fires a day ahead).
    static func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Reminder"
        content.body = "This is what a GroundTruth due-date reminder looks like."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func scheduleDueDateReminder(taskId: String, taskTitle: String, projectName: String, dueDate: Date) {
        let center = UNUserNotificationCenter.current()
        let identifier = identifier(for: taskId)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: dueDate),
              reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Due tomorrow: \(taskTitle)"
        content.body = "\(projectName) — this step is due \(dueDate.formatted(date: .abbreviated, time: .omitted))."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelReminder(taskId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: taskId)])
    }

    private static func identifier(for taskId: String) -> String {
        "task-due-\(taskId)"
    }
}
