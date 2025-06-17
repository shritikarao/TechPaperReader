import SwiftUI

struct PapersListView: View {
    let selectedCategories: [String]
    @StateObject private var viewModel = PapersViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading papers…")
            } else if let error = viewModel.errorMessage {
                VStack {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                    Button("Retry") {
                        viewModel.loadPapers(for: selectedCategories)
                    }
                }
            } else {
                List(viewModel.papers) { paper in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(paper.title)
                            .font(.headline)
                        Text(paper.authors.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(paper.published, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Latest Papers")
        .onAppear {
            if viewModel.papers.isEmpty {
                viewModel.loadPapers(for: selectedCategories)
            }
        }
    }
} 