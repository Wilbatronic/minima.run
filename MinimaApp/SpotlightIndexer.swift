import CoreSpotlight
import MobileCoreServices
import NaturalLanguage

/// "The Archivist"
/// Indexes past conversations for Spotlight search with semantic awareness.
public class SpotlightIndexer {
    public static let shared = SpotlightIndexer()
    
    private let domainIdentifier = "com.minima.conversations"
    private let indexingQueue = DispatchQueue(label: "com.minima.spotlight", qos: .background)
    
    private init() {}
    
    /// Index a conversation asynchronously
    public func indexConversation(id: String, query: String, response: String, date: Date) {
        indexingQueue.async {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = query
            attributeSet.contentDescription = response
            
            // Semantic tagging: Detect people, places, and key topics
            let allText = "\(query) \(response)"
            attributeSet.keywords = self.extractSemanticKeywords(from: allText)
            
            attributeSet.contentCreationDate = date
            attributeSet.contentModificationDate = date
            
            let item = CSSearchableItem(
                uniqueIdentifier: id,
                domainIdentifier: self.domainIdentifier,
                attributeSet: attributeSet
            )
            
            item.expirationDate = Calendar.current.date(byAdding: .day, value: 90, to: date) // Longer retention
            
            CSSearchableIndex.default().indexSearchableItems([item]) { error in
                if let error = error {
                    print("[Spotlight] Indexing failed for \(id): \(error)")
                }
            }
        }
    }
    
    private func extractSemanticKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType, .lemma])
        tagger.string = text
        
        var keywords = Set<String>()
        
        // 1. Named Entity Recognition
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            if let tag = tag {
                keywords.insert(String(text[range]))
            }
            return true
        }
        
        // 2. High-value words (Lemmatized)
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: options) { tag, range in
            let word = String(text[range]).lowercased()
            if word.count > 4 { // Basic noise filter
                keywords.insert(word)
            }
            return true
        }
        
        return Array(keywords.prefix(30))
    }
}
