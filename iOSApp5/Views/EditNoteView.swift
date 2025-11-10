import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct EditNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var note: Note

    @State private var pickerItem: PhotosPickerItem?
    @State private var newImageData: Data?
    @State private var newVideoData: Data?

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Title", text: $note.title)
                TextField("Note", text: $note.text, axis: .vertical)
                    .lineLimit(6, reservesSpace: true)
            }

            Section("Attachment") {
                if let att = note.attachments.first {
                    AttachmentEditorPreview(attachment: att)
                } else {
                    Text("No attachment").foregroundStyle(.secondary)
                }

                PhotosPicker(
                    selection: $pickerItem,
                    matching: .any(of: [.images, .videos])
                ) { Label("Replace with Photo or Video", systemImage: "arrow.triangle.2.circlepath") }

                if newImageData != nil || newVideoData != nil {
                    Button(role: .destructive) {
                        newImageData = nil; newVideoData = nil
                    } label: { Label("Cancel Replacement", systemImage: "xmark.circle") }
                }

                if note.attachments.first != nil {
                    Button(role: .destructive) {
                        if let existing = note.attachments.first {
                            context.delete(existing)
                            note.attachments.removeAll()
                        }
                    } label: { Label("Remove Attachment", systemImage: "trash") }
                }
            }
        }
        .navigationTitle("Edit Note")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    // Apply replacement if chosen
                    if let data = newImageData {
                        replaceAttachment(with: data, type: .image)
                    } else if let data = newVideoData {
                        replaceAttachment(with: data, type: .video)
                    }
                    note.updatedAt = .now
                    try? context.save()
                    dismiss()
                }
            }
        }
        .onChange(of: pickerItem) { newValue in
            Task { await loadPickedMedia(newValue) }
        }
    }

    private func replaceAttachment(with data: Data, type: MediaType) {
        if let existing = note.attachments.first {
            context.delete(existing)
            note.attachments.removeAll()
        }
        note.attachments.append(.init(data: data, type: type, note: note))
        newImageData = nil; newVideoData = nil
    }

    private func loadPickedMedia(_ item: PhotosPickerItem?) async {
        newImageData = nil; newVideoData = nil
        guard let item else { return }
        let types = item.supportedContentTypes
        let isImage = types.contains(where: { $0.conforms(to: .image) })
        let isVideo = types.contains(where: { $0.conforms(to: .movie) || $0.conforms(to: .video) })

        if let data = try? await item.loadTransferable(type: Data.self) {
            if isImage {
                newImageData = data
            } else if isVideo {
                newVideoData = data
            } else {
                if UIImage(data: data) != nil { newImageData = data } else { newVideoData = data }
            }
        }
    }
}

private struct AttachmentEditorPreview: View {
    let attachment: MediaAttachment
    var body: some View {
        switch attachment.type {
        case .image:
            if let ui = UIImage(data: attachment.data) {
                Image(uiImage: ui).resizable().scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Label("Image preview unavailable", systemImage: "exclamationmark.triangle")
            }
        case .video:
            HStack(spacing: 8) {
                Image(systemName: "video.fill")
                Text("Video attached").foregroundStyle(.secondary)
            }
        }
    }
}
