import Foundation
import Combine

class UserPreferences: ObservableObject {
    // key: field id (e.g., "cs"), value: up to 3 subcategory ids within that field
    @Published private(set) var selections: [String: Set<String>] = [:] {
        didSet { persist() }
    }

    init() {
        if let saved = UserDefaults.standard.dictionary(forKey: "selections") as? [String: [String]] {
            selections = saved.mapValues { Set($0) }
        }
    }

    // MARK: - Public helpers
    func selected(in fieldId: String) -> Set<String> {
        selections[fieldId] ?? []
    }

    var allSelectedSubcategories: [String] {
        selections.values.flatMap { $0 }
    }

    func toggle(subcategory: String, in fieldId: String) {
        var set = selections[fieldId] ?? []
        if set.contains(subcategory) {
            set.remove(subcategory)
        } else if set.count < 3 {
            set.insert(subcategory)
        }
        selections[fieldId] = set
    }

    // MARK: - Persistence
    private func persist() {
        let encoded = selections.mapValues { Array($0) }
        UserDefaults.standard.set(encoded, forKey: "selections")
    }
} 