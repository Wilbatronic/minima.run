import Vision
import PDFKit
import UniformTypeIdentifiers

/// "The Reader"
/// Extracts and processes text from PDFs and documents.
public class DocumentReader {
    public static let shared = DocumentReader()
    
    private init() {}
    
    /// Extract text from a PDF file
    public func extractText(from url: URL) async throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw DocumentError.invalidFile
        }
        
        var fullText = ""
        
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            if let pageText = page.string {
                fullText += pageText + "\n\n"
            }
        }
        
        // If no text (scanned PDF), use OCR
        if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fullText = try await extractTextWithOCR(from: url)
        }
        
        return fullText
    }
    
    /// OCR for scanned documents
    public func extractTextWithOCR(from url: URL) async throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw DocumentError.invalidFile
        }
        
        var fullText = ""
        
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // Render page to image
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(pageRect)
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            // Run OCR
            let pageText = try await recognizeText(in: image)
            fullText += pageText + "\n\n"
        }
        
        return fullText
    }
    
    /// Vision-based text recognition
    public func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw DocumentError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let text = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                
                continuation.resume(returning: text)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Summarize document for context injection
    public func summarize(text: String, maxTokens: Int = 2000) -> String {
        // Rough tokenization (4 chars per token)
        let maxChars = maxTokens * 4
        if text.count <= maxChars {
            return text
        }
        
        // Take beginning + end (most important parts usually)
        let halfMax = maxChars / 2
        let beginning = String(text.prefix(halfMax))
        let ending = String(text.suffix(halfMax))
        
        return beginning + "\n\n[... content truncated ...]\n\n" + ending
    }
}

enum DocumentError: Error {
    case invalidFile
    case invalidImage
    case ocrFailed
}
