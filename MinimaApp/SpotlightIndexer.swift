import CoreSpotlight
import MobileCoreServices

/// "The Archivist"
/// Indexes past conversations for Spotlight search.
/// Allows users to search "What did Minima say about X?" from Spotlight.
public class SpotlightIndexer {
    public static let shared = SpotlightIndexer()
    
    private let domainIdentifier = "com.minima.conversations"
    
    private init() {}
    
    /// Index a conversation
    public func indexConversation(id: String, query: String, response: String, date: Date) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = query
        attributeSet.contentDescription = response
        attributeSet.keywords = extractKeywords(from: query + " " + response)
        attributeSet.contentCreationDate = date
        attributeSet.contentModificationDate = date
        
        let item = CSSearchableItem(
            uniqueIdentifier: id,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        
        // Items expire after 30 days by default
        item.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: date)
        
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("[Spotlight] Indexing failed: \(error)")
            } else {
                print("[Spotlight] Indexed conversation: \(id)")
            }
        }
    }
    
    /// Remove a specific conversation from index
    public func removeConversation(id: String) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [id]) { error in
            if let error = error {
                print("[Spotlight] Deletion failed: \(error)")
            }
        }
    }
    
    /// Clear all indexed conversations
    public func clearAll() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
            if let error = error {
                print("[Spotlight] Clear failed: \(error)")
            } else {
                print("[Spotlight] All conversations cleared.")
            }
        }
    }
    
    /// Extract keywords from text
    private func extractKeywords(from text: String) -> [String] {
        // Simple keyword extraction (in real app, use NLTagger)
        let words = text.lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .filter { $0.count > 3 }
        return Array(Set(words).prefix(20))
    }
}
