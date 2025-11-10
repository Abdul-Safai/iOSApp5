import SwiftUI
import SwiftData
import PhotosUI
import UserNotifications
import CoreLocation
import UniformTypeIdentifiers

struct AddEditNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title = ""
    @State private var text = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var videoURL: URL?
    @State private var addLocation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Title", text: $title)
                    TextField("Note", text: $text, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                }

                Section("Attachment") {
                    PhotosPicker(
                        selection: $pickerItem,
                        matching: .any(of: [.images, .videos]) // ← images + videos
                    ) {
                        Label("Choose Photo/Video", systemImage: "photo.on.rectangle")
                    }

                    // Preview: image or simple video badge
                    if let imageData, let ui = UIImage(data: imageData) {
                        Image(uiImage: ui)
                            .resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else if let videoURL {
                        HStack(spacing: 8) {
                            Image(systemName: "video.fill")
                            Text(videoURL.lastPathComponent).lineLimit(1)
                            Spacer()
                        }
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }

                Section("Location") {
                    Toggle("Tag current location", isOn: $addLocation)
                }
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", role: .cancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            // Load picked asset: detect image vs video and store accordingly
            .onChange(of: pickerItem) { _, newValue in
                Task {
                    imageData = nil
                    videoURL = nil

                    guard let item = newValue else { return }
                    // Determine type via supportedContentTypes
                    if item.supportedContentTypes.contains(where: { $0.conforms(to: .image) }) {
                        // Load image data
                        imageData = try? await item.loadTransferable(type: Data.self)
                    } else if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                        // Load a local copy of the movie file via our Transferable wrapper
                        if let selection = try? await item.loadTransferable(type: VideoSelection.self) {
                            videoURL = selection.url
                        }
                    }
                }
            }
        }
    }

    private func save() {
        var lat: Double? = nil, lon: Double? = nil

        let finish: () -> Void = {
            let note = Note(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                text: text,
                latitude: lat,
                longitude: lon
            )
            note.updatedAt = .now

            if let data = imageData {
                // image attachment
                note.attachments.append(
                    MediaAttachment(data: data, note: note, mediaType: "image", filePath: nil)
                )
            } else if let url = videoURL {
                // video attachment (store file path, leave data empty)
                note.attachments.append(
                    MediaAttachment(data: Data(), note: note, mediaType: "video", filePath: url.path)
                )
            }

            context.insert(note)
            do {
                try context.save()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                scheduleReminder(for: note)
                dismiss()
            } catch {
                print("SwiftData save error:", error.localizedDescription)
            }
        }

        if addLocation {
            LocationManager.shared.requestOneShot { loc in
                lat = loc?.coordinate.latitude
                lon = loc?.coordinate.longitude
                finish()
            }
        } else {
            finish()
        }
    }

    private func scheduleReminder(for note: Note) {
        Task {
            let center = UNUserNotificationCenter.current()
            _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
            var comp = DateComponents(); comp.hour = 20; comp.minute = 0
            let content = UNMutableNotificationContent()
            content.title = "Remember: \(note.title)"
            content.body = "Review your note today."
            let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: true)
            let req = UNNotificationRequest(identifier: note.id.uuidString, content: content, trigger: trigger)
            try? await center.add(req)
        }
    }
}

/// A Transferable wrapper that copies a picked video into your app’s temp folder
/// and returns a local URL you can play later.
struct VideoSelection: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { value in
            // When sharing out (not used here)
            SentTransferredFile(value.url)
        } importing: { received in
            // Copy the received file into a temp location your app can access
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let dest = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).\(ext)")
            // Remove existing file if any
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.copyItem(at: received.file, to: dest)
            return VideoSelection(url: dest)
        }
    }
}
