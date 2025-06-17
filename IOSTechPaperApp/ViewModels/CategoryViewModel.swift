import Foundation
import Combine

@MainActor
class CategoryViewModel: ObservableObject {
    @Published var categories: [CategoryField] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiClient = ArxivCategoryClient()

    func loadCategories() {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                categories = try await apiClient.fetchCategories()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
} 