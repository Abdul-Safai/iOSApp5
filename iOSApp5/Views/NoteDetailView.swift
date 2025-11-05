import SwiftUI
import MapKit
import AVKit
import SwiftData

struct NoteDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    let note: Note
    var onShare: (() -> Void)? = nil

    @State private var region = MKCoordinateRegion()
    var hasLocation: Bool { note.latitude != nil && note.longitude != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Media gallery
                if !note.attachments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Attachments").font(.headline)
                        ForEach(note.attachments) { att in
                            AttachmentView(attachment: att)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.corner))
                        }
                    }
                    .padding()
                    .glassCard()
                }

                // Text
                VStack(alignment: .leading, spacing: 12) {
                    Text(note.title).font(.title.bold())
                    Text(note.detail).font(.body)
                    HStack {
                        Image(systemName: "calendar"); Text(note.createdAt, style: .date)
                        Image(systemName: "clock").padding(.leading, 8); Text(note.createdAt, style: .time)
                    }.foregroundStyle(.secondary).font(.caption)
                }
                .padding()
                .glassCard()

                // Map
                if hasLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location").font(.headline)
                        Map(position: .constant(.region(region)))
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.corner))
                            .onAppear {
                                if let lat = note.latitude, let lon = note.longitude {
                                    region = MKCoordinateRegion(
                                        center: .init(latitude: lat, longitude: lon),
                                        span: .init(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                    )
                                }
                            }
                    }
                    .padding()
                    .glassCard()
                }

                // Action bar
                HStack(spacing: 12) {
                    Button {
                        let summary = shareSummary()
                        let av = UIActivityViewController(activityItems: [summary], applicationActivities: nil)
                        UIApplication.shared.firstKeyWindow?.rootViewController?.present(av, animated: true)
                        onShare?()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        note.attachments.forEach { MediaStore.delete(fileName: $0.fileName) }
                        context.delete(note)
                        try? context.save()
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
        .navigationTitle("Details")
    }

    private func shareSummary() -> String {
        var text = "Title: \(note.title)\nDetails: \(note.detail)"
        if let lat = note.latitude, let lon = note.longitude { text += "\nLocation: \(lat), \(lon)" }
        text += "\nCreated: \(note.createdAt.formatted(date: .abbreviated, time: .shortened))"
        text += "\nAttachments: \(note.attachments.count)"
        return text
    }
}

// MARK: - Attachment rendering
struct AttachmentView: View {
    let attachment: MediaAttachment

    var body: some View {
        switch attachment.mediaKind {
        case .image:
            if let data = try? Data(contentsOf: MediaStore.url(for: attachment.fileName)),
               let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFit()
            } else {
                placeholder
            }
        case .video:
            VideoPlayer(player: AVPlayer(url: MediaStore.url(for: attachment.fileName)))
                .frame(height: 240)
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.corner).fill(.quaternary).frame(height: 160)
            Image(systemName: "exclamationmark.triangle").font(.title).foregroundStyle(.secondary)
        }
    }
}

private extension UIApplication {
    var firstKeyWindow: UIWindow? {
        // Best-effort way to grab a window for UIActivityViewController presentation
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}
