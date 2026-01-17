import Foundation
import SwiftData

/// "The Memory Palace"
/// Persistent storage for conversation history with iCloud sync.

@available(iOS 17.0, macOS 14.0, *)
@Model
public class Conversation {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var title: String
    public var messages: [Message]
    
    public init(title: String = "New Conversation") {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.title = title
        self.messages = []
    }
}

@available(iOS 17.0, macOS 14.0, *)
@Model
public class Message {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var role: String // "user", "assistant", "system"
    public var content: String
    public var tokensUsed: Int?
    
    public init(role: String, content: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.role = role
        self.content = content
    }
}

@available(iOS 17.0, macOS 14.0, *)
public class ConversationHistory {
    public static let shared = ConversationHistory()
    
    private var container: ModelContainer?
    
    private init() {
        setupContainer()
    }
    
    private func setupContainer() {
        do {
            let schema = Schema([Conversation.self, Message.self])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic // Enable iCloud sync
            )
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("[History] Failed to create container: \(error)")
        }
    }
    
    @MainActor
    public func createConversation(title: String = "New Chat") -> Conversation? {
        guard let container = container else { return nil }
        let context = container.mainContext
        let conversation = Conversation(title: title)
        context.insert(conversation)
        try? context.save()
        return conversation
    }
    
    @MainActor
    public func addMessage(to conversation: Conversation, role: String, content: String) {
        guard let container = container else { return }
        let message = Message(role: role, content: content)
        conversation.messages.append(message)
        conversation.updatedAt = Date()
        try? container.mainContext.save()
        
        // Index for Spotlight
        SpotlightIndexer.shared.indexConversation(
            id: message.id.uuidString,
            query: role == "user" ? content : "",
            response: role == "assistant" ? content : "",
            date: message.timestamp
        )
    }
    
    @MainActor
    public func fetchConversations() -> [Conversation] {
        guard let container = container else { return [] }
        let descriptor = FetchDescriptor<Conversation>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return (try? container.mainContext.fetch(descriptor)) ?? []
    }
    
    @MainActor
    public func deleteConversation(_ conversation: Conversation) {
        guard let container = container else { return }
        container.mainContext.delete(conversation)
        try? container.mainContext.save()
    }
    
    @MainActor
    public func searchMessages(query: String) -> [Message] {
        guard let container = container else { return [] }
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { message in
                message.content.contains(query)
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? container.mainContext.fetch(descriptor)) ?? []
    }
}
