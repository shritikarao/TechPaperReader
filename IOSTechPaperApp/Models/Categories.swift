import Foundation

struct CategoryField: Identifiable, Hashable {
    let id: String
    let name: String
    let subcategories: [Subcategory]
}

struct Subcategory: Identifiable, Hashable {
    let id: String
    let name: String
} 