import SwiftUI
import SwiftData

@main
struct iOSApp5App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Attach the SwiftData model container at the scene level
        .modelContainer(for: Note.self)
    }
}
