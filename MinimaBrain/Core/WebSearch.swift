import Foundation

/// "The Oracle"
/// Web search integration for RAG (Retrieval-Augmented Generation).
/// Uses Brave Search API for privacy-respecting results.
public class WebSearch {
    public static let shared = WebSearch()
    
    // Brave Search API (Privacy-first alternative to Google)
    private let apiEndpoint = "https://api.search.brave.com/res/v1/web/search"
    private var apiKey: String? {
        // Load from secure storage
        return UserDefaults.standard.string(forKey: "minima.braveApiKey")
    }
    
    private init() {}
    
    /// Search the web and return summarized results
    public func search(query: String, count: Int = 5) async throws -> [SearchResult] {
        guard let apiKey = apiKey else {
            throw WebSearchError.noApiKey
        }
        
        var components = URLComponents(string: apiEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "count", value: String(count))
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WebSearchError.requestFailed
        }
        
        let decoded = try JSONDecoder().decode(BraveSearchResponse.self, from: data)
        return decoded.web?.results ?? []
    }
    
    /// Format search results for LLM context injection
    public func formatForContext(_ results: [SearchResult]) -> String {
        var context = "Web Search Results:\n\n"
        for (index, result) in results.enumerated() {
            context += "[\(index + 1)] \(result.title)\n"
            context += "URL: \(result.url)\n"
            context += "\(result.description)\n\n"
        }
        return context
    }
}

// MARK: - Models

public struct SearchResult: Codable {
    public let title: String
    public let url: String
    public let description: String
}

struct BraveSearchResponse: Codable {
    let web: WebResults?
    
    struct WebResults: Codable {
        let results: [SearchResult]
    }
}

enum WebSearchError: Error {
    case noApiKey
    case requestFailed
}
