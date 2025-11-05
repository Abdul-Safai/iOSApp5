import SwiftUI
import SwiftData

@main
struct iOSApp5App: App {
    // Create a SwiftData model container for @Model types in this app.
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Note.self) // Auto-migrating local store
        }
    }
}
