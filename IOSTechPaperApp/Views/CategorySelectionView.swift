import SwiftUI

struct CategorySelectionView: View {
    @StateObject private var viewModel = CategoryViewModel()
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Fetching Categories...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                        Button("Retry") {
                            viewModel.loadCategories()
                        }
                    }
                } else {
                    List {
                        ForEach(viewModel.categories) { field in
                            NavigationLink(value: field) {
                                Text(field.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Field")
            .navigationDestination(for: CategoryField.self) { field in
                SubcategorySelectionView(field: field)
                    .environmentObject(preferences)
            }
        }
        .onAppear {
            if viewModel.categories.isEmpty {
                viewModel.loadCategories()
            }
        }
    }
}

struct CategorySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CategorySelectionView()
            .environmentObject(UserPreferences())
    }
} 