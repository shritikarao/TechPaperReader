import SwiftUI

@main
struct TechPaperReaderApp: App {
    @StateObject private var userPreferences = UserPreferences()

    var body: some Scene {
        WindowGroup {
            CategorySelectionView()
                .environmentObject(userPreferences)
        }
    }
} 