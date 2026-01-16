import EventKit

/// "The Taskmaster"
/// Integrates with Apple Reminders for task management.
public class RemindersIntegration {
    public static let shared = RemindersIntegration()
    
    private let eventStore = EKEventStore()
    
    private init() {}
    
    /// Request reminders access
    public func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToReminders()
        } catch {
            return false
        }
    }
    
    /// Get incomplete reminders
    public func getIncompleteReminders() async -> [EKReminder] {
        let calendars = eventStore.calendars(for: .reminder)
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: calendars
        )
        
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }
    
    /// Create a new reminder
    public func createReminder(title: String, dueDate: Date? = nil, priority: Int = 0, notes: String? = nil) throws -> EKReminder {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.priority = priority
        reminder.notes = notes
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        }
        
        try eventStore.save(reminder, commit: true)
        print("[Reminders] Created: \(title)")
        return reminder
    }
    
    /// Complete a reminder
    public func complete(_ reminder: EKReminder) throws {
        reminder.isCompleted = true
        reminder.completionDate = Date()
        try eventStore.save(reminder, commit: true)
    }
    
    /// Format reminders for LLM context
    public func formatForContext(reminders: [EKReminder]) -> String {
        guard !reminders.isEmpty else { return "No pending reminders." }
        
        var context = "Pending Reminders:\n"
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        for reminder in reminders.prefix(10) {
            var line = "- \(reminder.title ?? "Untitled")"
            if let dueDate = reminder.dueDateComponents?.date {
                line += " (due: \(formatter.string(from: dueDate)))"
            }
            context += line + "\n"
        }
        return context
    }
}
