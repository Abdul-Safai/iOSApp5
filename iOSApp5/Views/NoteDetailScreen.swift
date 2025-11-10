import SwiftUI
import SwiftData
import MapKit
import AVKit

struct NoteDetailScreen: View {
    @Environment(\.modelContext) private var context
    @Bindable var note: Note
    @State private var tempVideoURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let att = note.attachments.first {
                    attachmentView(att)
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

    @ViewBuilder
    private func attachmentView(_ att: MediaAttachment) -> some View {
        switch att.type {
        case .image:
            if let ui = UIImage(data: att.data) {
                Image(uiImage: ui).resizable().scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        case .video:
            if let url = makeTempURL(from: att.data) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onDisappear { /* stop playback */ }
            } else {
                Label("Video preview unavailable", systemImage: "exclamationmark.triangle")
            }
        }
    }

    private func makeTempURL(from data: Data) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("att_\(UUID().uuidString).mov")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
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
