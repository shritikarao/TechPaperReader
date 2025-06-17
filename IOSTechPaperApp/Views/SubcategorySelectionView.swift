import SwiftUI

struct SubcategorySelectionView: View {
    let field: CategoryField
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        List {
            Section(header: Text("Select up to 3")) {
                ForEach(field.subcategories) { sub in
                    Button(action: {
                        preferences.toggle(subcategory: sub.id, in: field.id)
                    }) {
                        HStack {
                            Text(sub.name)
                            Spacer()
                            if preferences.selected(in: field.id).contains(sub.id) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .disabled(!preferences.selected(in: field.id).contains(sub.id) && preferences.selected(in: field.id).count >= 3)
                    .foregroundColor(.primary)
                }
            }

            if !preferences.selected(in: field.id).isEmpty {
                Section {
                    NavigationLink(destination: PapersListView(selectedCategories: preferences.allSelectedSubcategories)) {
                        Text("View Papers")
                    }
                }
            }
        }
        .navigationTitle(field.name)
    }
} 