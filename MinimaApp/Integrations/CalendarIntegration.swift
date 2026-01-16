import EventKit

/// "The Scheduler"
/// Integrates with Apple Calendar for scheduling assistance.
public class CalendarIntegration {
    public static let shared = CalendarIntegration()
    
    private let eventStore = EKEventStore()
    
    private init() {}
    
    /// Request calendar access
    public func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            return false
        }
    }
    
    /// Get upcoming events
    public func getUpcomingEvents(days: Int = 7) -> [EKEvent] {
        let calendars = eventStore.calendars(for: .event)
        
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: now)!
        
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: calendars)
        return eventStore.events(matching: predicate)
    }
    
    /// Check availability for a time slot
    public func isAvailable(start: Date, end: Date) -> Bool {
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = eventStore.events(matching: predicate)
        return events.isEmpty
    }
    
    /// Create a new event
    public func createEvent(title: String, start: Date, end: Date, notes: String? = nil) throws -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        try eventStore.save(event, span: .thisEvent)
        print("[Calendar] Created event: \(title)")
        return event
    }
    
    /// Format events for LLM context
    public func formatForContext(events: [EKEvent]) -> String {
        guard !events.isEmpty else { return "No upcoming events." }
        
        var context = "Upcoming Calendar Events:\n"
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        for event in events.prefix(10) {
            context += "- \(event.title ?? "Untitled") on \(formatter.string(from: event.startDate))\n"
        }
        return context
    }
}
