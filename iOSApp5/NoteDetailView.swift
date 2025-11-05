import SwiftUI
import MapKit
import SwiftData

/// Shows a note with large photo, full text, map if location exists, and ShareLink.
struct NoteDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var region = MKCoordinateRegion()
    let note: Note

    var hasLocation: Bool { note.latitude != nil && note.longitude != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let data = note.photoData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Note photo")
                }

                Text(note.title)
                    .font(.title.bold())

                Text(note.detail)
                    .font(.body)

                Text("Created \(note.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .foregroundStyle(.secondary)

                if hasLocation {
                    Map(position: .constant(.region(region)))
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onAppear {
                            if let lat = note.latitude, let lon = note.longitude {
                                region = MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                )
                            }
                        }
                }

                ShareLink(items: [shareText()]) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel("Share this note")
            }
            .padding()
        }
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    context.delete(note)
                    try? context.save()
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func shareText() -> String {
        var base = "Title: \(note.title)\nDetails: \(note.detail)"
        if let lat = note.latitude, let lon = note.longitude {
            base += "\nLocation: \(lat), \(lon)"
        }
        base += "\nCreated: \(note.createdAt.formatted(date: .abbreviated, time: .shortened))"
        return base
    }
}
