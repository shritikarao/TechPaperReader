import Foundation
import Combine

@MainActor
class PapersViewModel: ObservableObject {
    @Published var papers: [ArxivPaper] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiClient = ArxivAPIClient()

    func loadPapers(for categories: [String]) {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                papers = try await apiClient.fetchPapers(forCategories: categories)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
} 