import Foundation
import Combine

@MainActor
final class SavedPapersStore: ObservableObject {
    @Published private(set) var papers: [ArxivPaper] = []

    private let storageKey = "saved_papers_v1"

    init() {
        load()
    }

    // MARK: - Public API
    func isSaved(_ paper: ArxivPaper) -> Bool {
        papers.contains(where: { $0.id == paper.id })
    }

    func toggle(_ paper: ArxivPaper) {
        if let idx = papers.firstIndex(where: { $0.id == paper.id }) {
            papers.remove(at: idx)
        } else {
            papers.append(paper)
        }
        papers.sort(by: { $0.published > $1.published })
        save()
    }

    // MARK: - Persistence
    private func save() {
        do {
            let data = try JSONEncoder().encode(papers)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("[SavedPapersStore] ⚠️ Failed to save:", error)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([ArxivPaper].self, from: data) {
            papers = decoded
        }
    }
} 