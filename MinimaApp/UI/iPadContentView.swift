import SwiftUI

/// iPad-Optimized Layout with Split View Support
struct iPadContentView: View {
    @State private var selectedConversation: Conversation?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar: Conversation List
            ConversationListView(selectedConversation: $selectedConversation)
                .navigationTitle("Minima")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { /* New conversation */ }) {
                            Image(systemName: "plus")
                        }
                    }
                }
        } detail: {
            // Main: Chat View
            if let conversation = selectedConversation {
                ChatView(conversation: conversation)
            } else {
                ContentUnavailableView(
                    "Select a Conversation",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Choose a conversation from the sidebar or start a new one.")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct ConversationListView: View {
    @Binding var selectedConversation: Conversation?
    @State private var conversations: [Conversation] = []
    
    var body: some View {
        List(selection: $selectedConversation) {
            ForEach(conversations, id: \.id) { conversation in
                NavigationLink(value: conversation) {
                    VStack(alignment: .leading) {
                        Text(conversation.title)
                            .font(.headline)
                        Text(conversation.updatedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                // Delete conversation
            }
        }
        .listStyle(.sidebar)
        .task {
            // Load conversations
        }
    }
}

struct ChatView: View {
    let conversation: Conversation
    @State private var inputText: String = ""
    
    var body: some View {
        VStack {
            // Messages
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(conversation.messages, id: \.id) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Input
            HStack {
                TextField("Message...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(20)
                
                Button(action: { /* Send */ }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
            }
            .padding()
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MessageBubble: View {
    let message: Message
    
    var isUser: Bool { message.role == "user" }
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(message.content)
                .padding(12)
                .background(isUser ? Color.blue : Color.secondary.opacity(0.2))
                .foregroundColor(isUser ? .white : .primary)
                .cornerRadius(16)
            
            if !isUser { Spacer() }
        }
    }
}
