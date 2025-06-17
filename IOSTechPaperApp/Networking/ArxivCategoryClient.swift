import Foundation

class ArxivCategoryClient {
    
    enum CategoryError: Error {
        case invalidURL
        case networkError(Error)
        case parsingFailed
    }
    
    func fetchCategories() async throws -> [CategoryField] {
        guard let url = URL(string: "https://arxiv.org/category_taxonomy") else {
            throw CategoryError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw CategoryError.parsingFailed
        }
        
        return try parse(html: htmlString)
    }
    
    private func parse(html: String) throws -> [CategoryField] {
        var results: [CategoryField] = []

        // Regex to capture each top-level field (Computer Science, Mathematics, ...)
        let h2Pattern = "<h2[^>]*class=\\\"accordion-head\\\"[^>]*>(.*?)</h2>"
        let h2Regex = try NSRegularExpression(pattern: h2Pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])

        // Find all <h2 class="accordion-head"> … </h2>
        let matches = h2Regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))

        guard !matches.isEmpty else {
            throw CategoryError.parsingFailed
        }

        // Iterate over matches and grab the slice between them to look for <h4>
        for (index, match) in matches.enumerated() {
            guard let nameRange = Range(match.range(at: 1), in: html) else { continue }
            let fieldName = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)

            // Determine the HTML slice containing its subcats: from end of current <h2> to start of next <h2> or end of doc
            let fieldStart = Range(match.range, in: html)!.upperBound
            let fieldEnd: String.Index
            if index + 1 < matches.count {
                fieldEnd = Range(matches[index + 1].range, in: html)!.lowerBound
            } else {
                fieldEnd = html.endIndex
            }
            let fieldHTML = String(html[fieldStart..<fieldEnd])

            // Regex for subcategory lines:  <h4>cs.AI <span>(Artificial Intelligence)</span></h4>
            let h4Pattern = "<h4>\\s*([A-Za-z0-9.-]+)\\s*<span>\\((.*?)\\)" // capture id (may contain '-') and name
            let h4Regex = try NSRegularExpression(pattern: h4Pattern, options: [.caseInsensitive])
            let subMatches = h4Regex.matches(in: fieldHTML, options: [], range: NSRange(fieldHTML.startIndex..., in: fieldHTML))

            var subcategories: [Subcategory] = []
            for sm in subMatches {
                guard let idRange = Range(sm.range(at: 1), in: fieldHTML),
                      let nameRange = Range(sm.range(at: 2), in: fieldHTML) else { continue }
                let id = String(fieldHTML[idRange])
                let name = String(fieldHTML[nameRange])
                subcategories.append(Subcategory(id: id, name: name))
            }

            if !subcategories.isEmpty {
                let categoryId = subcategories.first!.id.components(separatedBy: ".").first ?? fieldName
                results.append(CategoryField(id: categoryId, name: fieldName, subcategories: subcategories))
            }
        }

        if results.isEmpty {
            throw CategoryError.parsingFailed
        }

        return results
    }
} 