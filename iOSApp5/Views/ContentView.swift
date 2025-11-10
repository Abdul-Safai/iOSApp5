import SwiftUI
import SwiftData
import AVFoundation   // <-- for video thumbnail generation

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    @State private var search = ""
    @State private var showAdd = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "note.text").font(.system(size: 52))
                        Text("Create your first note").font(.title3).bold()
                        Button { showAdd = true } label: {
                            Label("New Note", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filtered) { note in
                            NavigationLink(value: note) { NoteRow(note: note) }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        context.delete(note)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .searchable(text: $search)
            .navigationTitle("iOSApp5 Notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $showAdd) { AddEditNoteView() }
            .navigationDestination(for: Note.self) { note in
                NoteDetailScreen(note: note)
            }
        }
        .sheet(isPresented: .constant(!hasSeenOnboarding)) {
            OnboardingView { hasSeenOnboarding = true }
        }
    }

    private var filtered: [Note] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return notes }
        return notes.filter { $0.title.localizedCaseInsensitiveContains(q) || $0.text.localizedCaseInsensitiveContains(q) }
    }
}

struct NoteRow: View {
    let note: Note

    var body: some View {
        HStack(spacing: 12) {
            mediaThumbnail
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(note.title).font(.headline)
                Text(note.text).lineLimit(1).foregroundStyle(.secondary)
            }
            Spacer()
            Text(note.updatedAt, style: .time).font(.caption).foregroundStyle(.secondary)
        }
    }

    /// Returns either an image from attachment data, a generated video thumbnail, or a placeholder.
    private var mediaThumbnail: some View {
        if let data = note.attachments.first?.data {
            if let ui = UIImage(data: data) {
                // It's an image
                return AnyView(Image(uiImage: ui).resizable().scaledToFill())
            } else if let thumb = makeVideoThumbnail(from: data) {
                // It's (likely) a video; show generated thumbnail with a play badge
                return AnyView(
                    ZStack {
                        Image(uiImage: thumb).resizable().scaledToFill()
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18)).shadow(radius: 2).foregroundStyle(.white)
                    }
                )
            }
        }
        // Fallback placeholder
        return AnyView(
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemFill))
                Image(systemName: "photo").imageScale(.large).foregroundStyle(.secondary)
            }
        )
    }

    /// Generate a thumbnail from video data by writing it to a temp file and sampling a frame.
    private func makeVideoThumbnail(from data: Data) -> UIImage? {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("thumb-\(UUID().uuidString).mov")
        do {
            try data.write(to: tmpURL, options: .atomic)
            let asset = AVAsset(url: tmpURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.1, preferredTimescale: 600)
            let cg = try generator.copyCGImage(at: time, actualTime: nil)
            let img = UIImage(cgImage: cg)
            // best-effort cleanup
            try? FileManager.default.removeItem(at: tmpURL)
            return img
        } catch {
            try? FileManager.default.removeItem(at: tmpURL)
            return nil
        }
    }
}
