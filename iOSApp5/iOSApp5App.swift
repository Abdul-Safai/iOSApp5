import SwiftUI
import SwiftData

@main
struct iOSApp5App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Note.self, MediaAttachment.self])
    }
}
