import SwiftUI
import SwiftData
import MapKit
import AVKit

struct NoteDetailScreen: View {
    @Environment(\.modelContext) private var context
    @Bindable var note: Note

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // IMAGE OR VIDEO RENDER
                if let first = note.attachments.first {
                    if first.mediaType == "image", let ui = image(from: first.data) {
                        Image(uiImage: ui)
                            .resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else if first.mediaType == "video", let path = first.filePath {
                        let url = URL(fileURLWithPath: path)
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }

                Text(note.text).frame(maxWidth: .infinity, alignment: .leading)

                if let coord = note.coordinate {
                    Map(initialPosition: .region(.init(center: coord,
                                                       span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))))
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                HStack {
                    NavigationLink("Edit") { EditNoteView(note: note) }
                    Spacer()
                    // Keep Export JSON (you said you want it there)
                    ShareLink(item: exportJSONURL(),
                              preview: SharePreview("Note JSON", image: Image(systemName: "square.and.arrow.up"))) {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        context.delete(note)
                    } label: { Label("Delete", systemImage: "trash") }
                }
            }
            .padding()
        }
        .navigationTitle(note.title)
    }

    private func image(from data: Data) -> UIImage? {
        UIImage(data: data)
    }

    private func exportJSONURL() -> URL {
        struct DTO: Codable {
            let id: UUID, title: String, text: String, createdAt: Date, updatedAt: Date
            let latitude: Double?, longitude: Double?
        }
        let dto = DTO(id: note.id, title: note.title, text: note.text,
                      createdAt: note.createdAt, updatedAt: note.updatedAt,
                      latitude: note.latitude, longitude: note.longitude)
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = (try? enc.encode(dto)) ?? Data()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("note_\(note.id).json")
        try? data.write(to: url)
        return url
    }
}
