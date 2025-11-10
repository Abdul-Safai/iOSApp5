import SwiftUI
import SwiftData

@main
struct iOSApp5App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // SwiftData models used by the app
        .modelContainer(for: [Note.self, MediaAttachment.self])
        
    }
}
