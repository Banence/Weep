import UserNotifications
import UIKit

struct NotificationManager {

    // MARK: - Public API

    /// Request notification permission from the user.
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("[NotificationManager] Permission error: \(error)")
            return false
        }
    }

    /// Reschedule all expiry notifications based on current kitchen items.
    /// Call this whenever items change (add, remove, update).
    static func rescheduleAll(items: [FoodItem]) {
        let center = UNUserNotificationCenter.current()

        // Clear all existing expiry notifications
        center.removeAllPendingNotificationRequests()

        // Schedule per-item notifications
        var scheduledCount = 0
        for item in items {
            guard let expiryDate = item.expiryDate else { continue }
            let days = daysUntil(expiryDate)

            // Only schedule for items that haven't expired yet
            guard days >= 0 else { continue }

            // 3 days before — gentle nudge
            if days >= 3 {
                scheduleItemNotification(
                    item: item,
                    expiryDate: expiryDate,
                    daysBefore: 3,
                    title: "Use \(item.name) soon",
                    body: "\(item.name) expires in 3 days. Time to plan a meal!",
                    priority: .normal
                )
            }

            // 1 day before — urgent
            scheduleItemNotification(
                item: item,
                expiryDate: expiryDate,
                daysBefore: 1,
                title: "\(item.name) expires tomorrow",
                body: "Don't let \(item.name) go to waste — use it today or freeze it.",
                priority: .urgent
            )

            // Day of — final alert
            scheduleItemNotification(
                item: item,
                expiryDate: expiryDate,
                daysBefore: 0,
                title: "\(item.name) expires today!",
                body: "Last chance to use \(item.name) before it goes bad.",
                priority: .critical
            )

            scheduledCount += 1
        }

        // Schedule daily morning summary
        scheduleDailySummary(items: items)

        print("[NotificationManager] Scheduled notifications for \(scheduledCount) items")
    }

    // MARK: - Per-Item Notifications

    private enum Priority {
        case normal, urgent, critical
    }

    private static func scheduleItemNotification(
        item: FoodItem,
        expiryDate: Date,
        daysBefore: Int,
        title: String,
        body: String,
        priority: Priority
    ) {
        let calendar = Calendar.current
        guard let triggerDate = calendar.date(byAdding: .day, value: -daysBefore, to: expiryDate) else { return }

        // Set notification time to 9:00 AM
        var components = calendar.dateComponents([.year, .month, .day], from: triggerDate)
        components.hour = 9
        components.minute = 0

        // Don't schedule if the trigger date is in the past
        guard let fireDate = calendar.date(from: components), fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = "EXPIRY_REMINDER"
        content.userInfo = ["itemId": item.id.uuidString, "daysBefore": daysBefore]
        content.threadIdentifier = "expiry-\(item.id.uuidString)"

        switch priority {
        case .normal:
            content.interruptionLevel = .passive
            content.sound = .default
        case .urgent:
            content.interruptionLevel = .timeSensitive
            content.sound = .default
        case .critical:
            content.interruptionLevel = .timeSensitive
            content.sound = UNNotificationSound.defaultCritical
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let id = "expiry-\(item.id.uuidString)-\(daysBefore)d"

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationManager] Failed to schedule \(id): \(error)")
            }
        }
    }

    // MARK: - Daily Summary

    private static func scheduleDailySummary(items: [FoodItem]) {
        // Schedule a repeating daily summary at 8:30 AM
        let expiringItems = items.filter { item in
            guard let days = item.daysUntilExpiry else { return false }
            return days >= 0 && days <= 3
        }

        // Only schedule if there are items expiring soon
        guard !expiringItems.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "DAILY_SUMMARY"
        content.threadIdentifier = "daily-summary"
        content.interruptionLevel = .active
        content.sound = .default

        let count = expiringItems.count
        if count == 1, let item = expiringItems.first {
            let daysText = dayLabel(item.daysUntilExpiry ?? 0)
            content.title = "Kitchen check-in"
            content.body = "\(item.name) \(daysText). Open Weep to see details."
        } else {
            let expiresToday = expiringItems.filter { ($0.daysUntilExpiry ?? 99) == 0 }.count
            let expiresTomorrow = expiringItems.filter { ($0.daysUntilExpiry ?? 99) == 1 }.count
            let expiresSoon = count - expiresToday - expiresTomorrow

            content.title = "\(count) items need attention"

            var parts: [String] = []
            if expiresToday > 0 { parts.append("\(expiresToday) expiring today") }
            if expiresTomorrow > 0 { parts.append("\(expiresTomorrow) expiring tomorrow") }
            if expiresSoon > 0 { parts.append("\(expiresSoon) expiring within 3 days") }
            content.body = parts.joined(separator: ", ") + "."
        }

        // Fire daily at 8:30 AM
        var components = DateComponents()
        components.hour = 8
        components.minute = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-summary", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationManager] Failed to schedule daily summary: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private static func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    private static func dayLabel(_ days: Int) -> String {
        switch days {
        case 0: return "expires today"
        case 1: return "expires tomorrow"
        default: return "expires in \(days) days"
        }
    }

    // MARK: - Notification Actions

    static func registerCategories() {
        let markUsedAction = UNNotificationAction(
            identifier: "MARK_USED",
            title: "Mark as Used",
            options: []
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_1D",
            title: "Remind Tomorrow",
            options: []
        )

        let expiryCategory = UNNotificationCategory(
            identifier: "EXPIRY_REMINDER",
            actions: [markUsedAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let summaryCategory = UNNotificationCategory(
            identifier: "DAILY_SUMMARY",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([expiryCategory, summaryCategory])
    }
}
