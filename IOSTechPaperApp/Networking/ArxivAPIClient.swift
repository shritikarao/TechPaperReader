import Foundation

final class ArxivAPIClient: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentEntry: [String: Any] = [:]
    private var entries: [[String: Any]] = []
    private var currentCharacters = ""
    private var currentAuthors: [String] = []

    private var completion: ((Result<[ArxivPaper], Error>) -> Void)?

    func fetchPapers(forCategories categories: [String], maxResults: Int = 20) async throws -> [ArxivPaper] {
        guard !categories.isEmpty else { return [] }
        let categoryQuery = categories.map { "cat:\($0)" }.joined(separator: " OR ")
        let encoded = categoryQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? categoryQuery
        let urlString = "https://export.arxiv.org/api/query?search_query=\(encoded)&sortBy=submittedDate&sortOrder=descending&max_results=\(maxResults)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try await withCheckedThrowingContinuation { continuation in
            self.parse(data: data) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func parse(data: Data, completion: @escaping (Result<[ArxivPaper], Error>) -> Void) {
        self.completion = completion
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "entry" {
            currentEntry = [:]
            currentAuthors = []
        } else if elementName == "author" {
            currentCharacters = ""
        } else if elementName == "link", let href = attributeDict["href"], attributeDict["rel"] == "alternate" {
            currentEntry["link"] = href
        }
        currentCharacters = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentCharacters += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let trimmed = currentCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "entry":
            currentEntry["authors"] = currentAuthors
            entries.append(currentEntry)
        case "id", "title", "summary", "published":
            currentEntry[elementName] = trimmed
        case "name":
            currentAuthors.append(trimmed)
        default:
            break
        }
        currentCharacters = ""
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        let papers: [ArxivPaper] = entries.compactMap { dict in
            guard let id = (dict["id"] as? String)?.components(separatedBy: "/").last,
                  let title = dict["title"] as? String,
                  let authors = dict["authors"] as? [String],
                  let summary = dict["summary"] as? String,
                  let publishedStr = dict["published"] as? String,
                  let publishedDate = ArxivPaper.dateFormatter.date(from: publishedStr),
                  let linkStr = dict["link"] as? String,
                  let link = URL(string: linkStr) else { return nil }
            return ArxivPaper(id: id, title: title, authors: authors, summary: summary, published: publishedDate, link: link)
        }
        completion?(.success(papers))
        reset()
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        completion?(.failure(parseError))
        reset()
    }

    private func reset() {
        currentElement = ""
        currentEntry = [:]
        entries = []
        currentCharacters = ""
        currentAuthors = []
        completion = nil
    }
} 