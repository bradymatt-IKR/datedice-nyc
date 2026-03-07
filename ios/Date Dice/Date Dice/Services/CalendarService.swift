import EventKit

enum CalendarAddStatus {
    case idle, added, denied, failed
}

struct CalendarService {

    /// Creates a "Date Night" calendar event for the given suggestion.
    /// Uses the user's default calendar (Apple Calendar, Google, Outlook, etc.).
    static func addDateNight(_ suggestion: Suggestion) async -> CalendarAddStatus {
        let store = EKEventStore()

        let granted: Bool
        do {
            granted = try await store.requestFullAccessToEvents()
        } catch {
            return .denied
        }
        guard granted else { return .denied }

        let event = EKEvent(eventStore: store)
        event.title = "Date Night: \(suggestion.name)"
        event.notes = suggestion.desc + (suggestion.tip.map { "\n\nTip: \($0)" } ?? "")
        event.location = suggestion.address.isEmpty
            ? "\(suggestion.area), New York, NY"
            : "\(suggestion.address), New York, NY"

        // Default to today 7\u{2013}10 PM
        var start = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        start.hour = 19
        start.minute = 0
        var end = start
        end.hour = 22

        event.startDate = Calendar.current.date(from: start) ?? Date()
        event.endDate = Calendar.current.date(from: end) ?? Date().addingTimeInterval(3 * 3600)
        event.calendar = store.defaultCalendarForNewEvents

        do {
            try store.save(event, span: .thisEvent)
            return .added
        } catch {
            return .failed
        }
    }
}
