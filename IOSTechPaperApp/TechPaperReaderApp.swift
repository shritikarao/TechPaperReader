import SwiftUI

@main
struct TechPaperReaderApp: App {
    @StateObject private var userPreferences = UserPreferences()
    @StateObject private var savedStore = SavedPapersStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                CategorySelectionView()
                    .tabItem {
                        Label("Browse", systemImage: "list.bullet")
                    }
                SavedPapersView()
                    .tabItem {
                        Label("Saved", systemImage: "bookmark")
                    }
            }
            .environmentObject(userPreferences)
            .environmentObject(savedStore)
        }
    }
} 