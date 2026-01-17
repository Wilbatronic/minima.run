import Vision
import PDFKit
import UniformTypeIdentifiers

/// "The Reader"
/// Extracts and processes text from PDFs and documents.
public class DocumentReader {
    public static let shared = DocumentReader()
    
    private init() {}
    
    /// Extract text from a PDF or Image file
    public func extractText(from url: URL) async throws -> String {
        let contentType = UTType(filenameExtension: url.pathExtension)
        
        if contentType?.conforms(to: .pdf) == true {
            return try await extractTextFromPDF(from: url)
        } else if contentType?.conforms(to: .image) == true {
            guard let image = UIImage(contentsOfFile: url.path) else {
                throw DocumentError.invalidImage
            }
            return try await recognizeText(in: image)
        }
        
        throw DocumentError.unsupportedFormat
    }
    
    private func extractTextFromPDF(from url: URL) async throws -> String {
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
            
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(pageRect)
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
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
            request.minimumTextHeight = 0.01 // Detect small text
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Summarize document intelligently
    public func summarize(text: String, maxTokens: Int = 2000) -> String {
        let maxChars = maxTokens * 4
        if text.count <= maxChars { return text }
        
        // Extract headers or first lines of paragraphs for a better summary
        let lines = text.components(separatedBy: .newlines)
        let headers = lines.filter { $0.range(of: "^[A-Z0-9 ]{5,30}$", options: .regularExpression) != nil }
        
        let beginning = String(text.prefix(maxChars / 2))
        let ending = String(text.suffix(maxChars / 2))
        
        var summary = beginning + "\n\n[... content truncated ...]\n\n"
        if !headers.isEmpty {
            summary += "Key Sections: " + headers.prefix(5).joined(separator: ", ") + "\n\n"
        }
        summary += ending
        
        return summary
    }
}

enum DocumentError: Error {
    case invalidFile
    case invalidImage
    case ocrFailed
    case unsupportedFormat
}
