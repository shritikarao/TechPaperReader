import Foundation
import PDFKit

enum TextExtractorError: Error {
    case invalidURL
    case downloadFailed
    case pdfParsingFailed
}

final class PDFTextExtractor {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Downloads a PDF from a URL and extracts its text content.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: The concatenated text content of the PDF.
    func extractText(from url: URL) async throws -> String {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TextExtractorError.downloadFailed
        }
        
        guard let pdfDocument = PDFDocument(data: data) else {
            throw TextExtractorError.pdfParsingFailed
        }
        
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let pageContent = page.string {
                fullText.append(pageContent)
            }
        }
        
        return fullText
    }
    
    /// Constructs the PDF link for an arXiv paper and extracts its text.
    ///
    /// - Parameter paper: The `ArxivPaper` to process.
    /// - Returns: The concatenated text content of the paper's PDF.
    func extractText(for paper: ArxivPaper) async throws -> String {
        guard let pdfUrl = URL(string: "https://arxiv.org/pdf/\(paper.id).pdf") else {
            throw TextExtractorError.invalidURL
        }
        return try await extractText(from: pdfUrl)
    }
} 