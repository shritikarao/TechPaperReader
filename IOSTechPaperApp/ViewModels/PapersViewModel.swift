import Foundation
import Combine

@MainActor
class PapersViewModel: ObservableObject {
    @Published var papers: [ArxivPaper] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Summary support
    @Published var summaries: [String: String] = [:] // paper.id -> summary text
    private var summarizing: Set<String> = []        // in-flight ids

    // Full text summary support
    @Published var fullSummaries: [String: String] = [:]
    private var summarizingFull: Set<String> = []

    private lazy var xaiClient: XAIClient? = {
        return try? XAIClient()
    }()

    private let textExtractor = PDFTextExtractor()
    private let apiClient = ArxivAPIClient()

    func loadPapers(for categories: [String]) {
        print("[PapersViewModel] requesting papers for categories =", categories)
        Task {
            do {
                isLoading = true
                errorMessage = nil
                papers = []  // clear before incremental load
                
                try await withThrowingTaskGroup(of: [ArxivPaper].self) { group in
                    for cat in categories.prefix(3) { // limit to 3 fastest
                        group.addTask { [apiClient] in
                            try await apiClient.fetchPapers(forCategories: [cat], maxResults: 10)
                        }
                    }
                    for try await papersBatch in group {
                        await MainActor.run {
                            let uniquePapers = papersBatch.filter { newPaper in
                                !self.papers.contains(where: { $0.id == newPaper.id })
                            }
                            self.papers.append(contentsOf: uniquePapers)
                            self.papers.sort(by: { $0.published > $1.published })
                        }
                    }
                }

                print("[PapersViewModel] total unique papers =", papers.count)
            } catch {
                errorMessage = error.localizedDescription
                print("[PapersViewModel] ⚠️ fetch failed:", error)
            }
            isLoading = false
        }
    }

    // MARK: - Summary helpers
    func summary(for paper: ArxivPaper) -> String? {
        summaries[paper.id]
    }

    func isSummarizing(_ paper: ArxivPaper) -> Bool {
        summarizing.contains(paper.id)
    }

    func generateSummary(for paper: ArxivPaper) {
        guard summaries[paper.id] == nil, !isSummarizing(paper) else { return }
        guard let client = xaiClient else {
            print("⚠️ XAIClient unavailable – missing or invalid API key.")
            return
        }

        summarizing.insert(paper.id)
        Task { @MainActor in
            defer { summarizing.remove(paper.id) }
            do {
                let text = try await client.summarize(paper: paper)
                summaries[paper.id] = text
            } catch {
                print("⚠️ Summary generation failed for \(paper.id):", error)
            }
        }
    }

    // MARK: - Full Summary Helpers
    func fullSummary(for paper: ArxivPaper) -> String? {
        fullSummaries[paper.id]
    }

    func isSummarizingFull(_ paper: ArxivPaper) -> Bool {
        summarizingFull.contains(paper.id)
    }

    func generateFullSummary(for paper: ArxivPaper) {
        guard fullSummaries[paper.id] == nil, !isSummarizingFull(paper) else { return }
        guard let client = xaiClient else {
            print("⚠️ XAIClient unavailable – missing or invalid API key.")
            return
        }

        summarizingFull.insert(paper.id)
        Task { @MainActor in
            defer { summarizingFull.remove(paper.id) }
            do {
                let fullText = try await textExtractor.extractText(for: paper)
                let summary = try await client.summarize(text: fullText)
                fullSummaries[paper.id] = summary
            } catch {
                print("⚠️ Full summary generation failed for \(paper.id):", error)
            }
        }
    }
} 