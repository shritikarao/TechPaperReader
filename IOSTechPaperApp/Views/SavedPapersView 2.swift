import SwiftUI

struct SavedPapersView: View {
    @EnvironmentObject private var savedStore: SavedPapersStore

    var body: some View {
        NavigationStack {
            if savedStore.papers.isEmpty {
                Text("No saved papers yet.")
                    .foregroundColor(.secondary)
            } else {
                List(savedStore.papers) { paper in
                    NavigationLink(value: paper) {
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
                    }
                }
                .navigationDestination(for: ArxivPaper.self) { paper in
                    PaperDetailView(paper: paper)
                }
            }
            .navigationTitle("Saved")
        }
    }
}

// Simple Detail view reuse
struct PaperDetailView: View {
    let paper: ArxivPaper

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(paper.title)
                    .font(.title2)
                    .bold()
                Text(paper.authors.joined(separator: ", "))
                    .font(.subheadline)
                Text(paper.published, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Divider()
                Text(paper.summary)
            }
            .padding()
        }
        .navigationTitle("Paper")
        .navigationBarTitleDisplayMode(.inline)
    }
} 
