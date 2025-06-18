import Foundation

final class ArxivAPIClient {
    // Use a URLSession with sensible timeouts to avoid long hangs
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15  // seconds per request
        config.timeoutIntervalForResource = 20 // overall resource timeout
        return URLSession(configuration: config)
    }()

    // MARK: - Public API
    func fetchPapers(forCategories categories: [String], maxResults: Int = 20) async throws -> [ArxivPaper] {
        guard !categories.isEmpty else { return [] }
        let categoryQuery = categories.map { "cat:\($0)" }.joined(separator: " OR ")
        let encoded = categoryQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? categoryQuery
        let urlString = "https://export.arxiv.org/api/query?search_query=\(encoded)&sortBy=submittedDate&sortOrder=descending&max_results=\(maxResults)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        print("[ArxivAPIClient] GET", url.absoluteString)
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        let (data, _) = try await ArxivAPIClient.session.data(for: request)
        print("[ArxivAPIClient] received \(data.count) bytes")

        // Early sanity check: ensure we have XML, otherwise throw early.
        guard let firstByte = data.first, firstByte == 0x3C /* '<' */ else {
            throw NSError(domain: "ArxivAPIClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid XML response"])
        }

        let parserDelegate = ParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = parserDelegate
        if !parser.parse() {
            throw parser.parserError ?? NSError(domain: "ArxivAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse feed"])
        }
        return parserDelegate.papers
    }

    // MARK: - Private helper delegate (synchronous)
    private final class ParserDelegate: NSObject, XMLParserDelegate {
        private var currentElement = ""
        private var currentEntry: [String: Any] = [:]
        private var entries: [[String: Any]] = []
        private var currentCharacters = ""
        private var currentAuthors: [String] = []
        private var currentCategories: [String] = []

        var papers: [ArxivPaper] {
            print("[ArxivAPIClient] raw entry dictionaries count =", entries.count)
            if let first = entries.first {
                print("[ArxivAPIClient] first entry keys =", first.keys)
            }
            let mapped: [ArxivPaper] = entries.compactMap { dict in
                guard let id = (dict["id"] as? String)?.components(separatedBy: "/").last,
                      let title = dict["title"] as? String,
                      let authors = dict["authors"] as? [String],
                      let summary = dict["summary"] as? String,
                      let publishedStr = dict["published"] as? String,
                      let publishedDate = ArxivPaper.dateFormatter.date(from: publishedStr) else { return nil }

                // Build paper link: use provided link or fallback to canonical abs URL
                let link: URL
                if let linkStr = dict["link"] as? String, let l = URL(string: linkStr) {
                    link = l
                } else {
                    link = URL(string: "https://arxiv.org/abs/\(id)")!
                }

                let categories = dict["categories"] as? [String] ?? []
                return ArxivPaper(id: id, title: title, authors: authors, summary: summary, published: publishedDate, link: link, categories: categories)
            }
            print("[ArxivAPIClient] parsed papers count =", mapped.count)
            return mapped
        }

        // MARK: XMLParserDelegate
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            currentElement = elementName
            if elementName == "entry" {
                currentEntry = [:]
                currentAuthors = []
                currentCategories = []
            } else if elementName == "link", let href = attributeDict["href"], currentEntry["link"] == nil {
                currentEntry["link"] = href
            } else if elementName == "category", let term = attributeDict["term"] {
                currentCategories.append(term)
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
                currentEntry["categories"] = currentCategories
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
    }
} 