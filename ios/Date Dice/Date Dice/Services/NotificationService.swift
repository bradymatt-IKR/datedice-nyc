import UserNotifications

struct NotificationService {

    // MARK: - Permission

    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Schedule

    /// "Tonight's the night!" reminder at 5 PM on the day of lock-in.
    static func scheduleDateReminder(for suggestion: Suggestion) {
        let content = UNMutableNotificationContent()
        content.title = "Tonight's the night! \(suggestion.emoji)"
        content.body = "You're heading to \(suggestion.name)"
        if !suggestion.address.isEmpty {
            content.body += " \u{2014} \(suggestion.address)"
        }
        content.sound = .default
        content.userInfo = ["suggestionId": suggestion.id.uuidString]

        // Fire at 5 PM today. If it's already past 5 PM, the notification
        // simply won't fire (which is fine — they're already getting ready).
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = 17
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "date-reminder-\(suggestion.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// "How was last night?" prompt at 10 AM the next morning.
    static func schedulePostDatePrompt(for suggestion: Suggestion) {
        let content = UNMutableNotificationContent()
        content.title = "How was last night? \(suggestion.emoji)"
        content.body = "Rate your date at \(suggestion.name)"
        content.sound = .default
        content.userInfo = ["suggestionId": suggestion.id.uuidString, "action": "rate"]

        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return }
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "date-followup-\(suggestion.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel

    /// Remove all pending notifications for a suggestion (e.g., when completing or removing).
    static func cancelNotifications(for suggestionId: UUID) {
        let ids = [
            "date-reminder-\(suggestionId.uuidString)",
            "date-followup-\(suggestionId.uuidString)",
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
