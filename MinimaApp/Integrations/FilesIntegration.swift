import Foundation
import UniformTypeIdentifiers

/// "The Librarian"
/// Searches and reads local files for context.
public class FilesIntegration {
    public static let shared = FilesIntegration()
    
    private init() {}
    
    /// Search files by name in common directories with progressive results
    public func searchFiles(query: String, in directories: [URL]? = nil) -> AsyncStream<FileResult> {
        let searchDirs = directories ?? getDefaultDirectories()
        
        return AsyncStream { continuation in
            let task = Task {
                for dir in searchDirs {
                    do {
                        let resourceKeys: Set<URLResourceKey> = [.nameKey, .contentModificationDateKey, .fileSizeKey, .contentTypeKey]
                        guard let enumerator = FileManager.default.enumerator(
                            at: dir,
                            includingPropertiesForKeys: Array(resourceKeys),
                            options: [.skipsHiddenFiles, .skipsPackageDescendants]
                        ) else { continue }
                        
                        for case let fileURL as URL in enumerator {
                            if Task.isCancelled { break }
                            
                            let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys)
                            let name = resourceValues?.name ?? fileURL.lastPathComponent
                            
                            if name.localizedCaseInsensitiveContains(query) {
                                let result = FileResult(
                                    url: fileURL,
                                    name: name,
                                    size: resourceValues?.fileSize ?? 0,
                                    modifiedDate: resourceValues?.contentModificationDate ?? Date.distantPast,
                                    contentType: resourceValues?.contentType
                                )
                                continuation.yield(result)
                            }
                        }
                    } catch {
                        print("[Files] Search error in \(dir): \(error)")
                    }
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    private func getDefaultDirectories() -> [URL] {
        var dirs: [URL] = []
        
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            dirs.append(documents)
        }
        if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            dirs.append(downloads)
        }
        if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            dirs.append(desktop)
        }
        
        return dirs
    }
    
    private func searchDirectory(_ dir: URL, for query: String) async throws -> [FileResult] {
        var results: [FileResult] = []
        
        let resourceKeys: Set<URLResourceKey> = [.nameKey, .contentModificationDateKey, .fileSizeKey, .contentTypeKey]
        
        guard let enumerator = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }
        
        for case let fileURL as URL in enumerator {
            let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys)
            let name = resourceValues?.name ?? fileURL.lastPathComponent
            
            if name.localizedCaseInsensitiveContains(query) {
                results.append(FileResult(
                    url: fileURL,
                    name: name,
                    size: resourceValues?.fileSize ?? 0,
                    modifiedDate: resourceValues?.contentModificationDate ?? Date.distantPast,
                    contentType: resourceValues?.contentType
                ))
            }
            
            // Limit results
            if results.count >= 20 { break }
        }
        
        return results
    }
    
    /// Read text content from a file
    public func readTextContent(from url: URL, maxChars: Int = 10000) throws -> String {
        let data = try Data(contentsOf: url)
        
        // Try UTF-8 first
        if let text = String(data: data, encoding: .utf8) {
            return String(text.prefix(maxChars))
        }
        
        // Fall back to other encodings
        for encoding in [String.Encoding.utf16, .ascii, .isoLatin1] {
            if let text = String(data: data, encoding: encoding) {
                return String(text.prefix(maxChars))
            }
        }
        
        throw FilesError.unreadable
    }
    
    /// Format file results for LLM context
    public func formatForContext(_ files: [FileResult]) -> String {
        guard !files.isEmpty else { return "No files found." }
        
        var context = "Files found:\n"
        let formatter = ByteCountFormatter()
        
        for file in files.prefix(10) {
            let size = formatter.string(fromByteCount: Int64(file.size))
            context += "- \(file.name) (\(size))\n"
        }
        return context
    }
}

public struct FileResult {
    public let url: URL
    public let name: String
    public let size: Int
    public let modifiedDate: Date
    public let contentType: UTType?
}

enum FilesError: Error {
    case unreadable
}
