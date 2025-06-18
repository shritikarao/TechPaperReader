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
                if viewModel.papers.isEmpty {
                    Text("No papers found for the selected categories.")
                        .foregroundColor(.secondary)
                        .padding()
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

                            if let summary = viewModel.summary(for: paper) {
                                Text(summary)
                                    .font(.footnote)
                                    .padding(.top, 4)
                            } else {
                                if viewModel.isSummarizing(paper) {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.75)
                                        Text("Summarizing abstract...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Button("Generate Summary") {
                                        viewModel.generateSummary(for: paper)
                                    }
                                    .font(.footnote)
                                    .padding(.top, 4)
                                }
                            }

                            // Removed full paper summary to avoid duplicate summaries
                        }
                        .padding(.vertical, 4)
                    }
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