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

    private lazy var summaryClient: OpenAISummaryClient? = {
        return try? OpenAISummaryClient()
    }()

    private let apiClient = ArxivAPIClient()

    func loadPapers(for categories: [String]) {
        print("[PapersViewModel] requesting papers for categories =", categories)
        Task {
            do {
                isLoading = true
                errorMessage = nil
                papers = []  // clear before incremental load
                var tempCombined: [ArxivPaper] = []
                try await withThrowingTaskGroup(of: [ArxivPaper].self) { group in
                    for cat in categories.prefix(3) { // limit to 3 fastest
                        group.addTask { [apiClient] in
                            try await apiClient.fetchPapers(forCategories: [cat], maxResults: 10)
                        }
                    }
                    for try await arr in group {
                        tempCombined.append(contentsOf: arr)
                        await MainActor.run {
                            var seen = Set(papers.map { $0.id })
                            papers.append(contentsOf: arr.filter { seen.insert($0.id).inserted })
                            papers.sort(by: { $0.published > $1.published })
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
        guard let summaryClient else {
            print("⚠️ OpenAISummaryClient unavailable – missing API key?")
            return
        }

        summarizing.insert(paper.id)
        Task { @MainActor in
            defer { summarizing.remove(paper.id) }
            do {
                let text = try await summaryClient.summarize(paper: paper)
                summaries[paper.id] = text
            } catch {
                print("⚠️ Summary generation failed for \(paper.id):", error)
            }
        }
    }
} 