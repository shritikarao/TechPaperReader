import Foundation

struct ArxivPaper: Identifiable {
    let id: String
    let title: String
    let authors: [String]
    let summary: String
    let published: Date
    let link: URL
}

extension ArxivPaper {
    static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
} 