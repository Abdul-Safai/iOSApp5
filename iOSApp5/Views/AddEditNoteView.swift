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
    @State private var videoData: Data?
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
                        matching: .any(of: [.images, .videos])
                    ) { Label("Choose Photo or Video", systemImage: "photo.on.rectangle") }

                    if let data = imageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else if videoData != nil {
                        HStack(spacing: 8) {
                            Image(systemName: "video.fill")
                            Text("Video selected")
                                .foregroundStyle(.secondary)
                        }
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
            // iOS 17-compatible signature avoids generic inference errors
            .onChange(of: pickerItem) { newValue in
                Task { await loadPickedMedia(newValue) }
            }
        }
    }

    private func loadPickedMedia(_ item: PhotosPickerItem?) async {
        imageData = nil
        videoData = nil
        guard let item else { return }

        let types = item.supportedContentTypes
        let isImage = types.contains(where: { $0.conforms(to: .image) })
        let isVideo = types.contains(where: { $0.conforms(to: .movie) || $0.conforms(to: .video) })

        if let data = try? await item.loadTransferable(type: Data.self) {
            if isImage {
                imageData = data
            } else if isVideo {
                videoData = data
            } else {
                // Fallback: guess by size/header; if it decodes as image, treat as image
                if UIImage(data: data) != nil {
                    imageData = data
                } else {
                    videoData = data
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
                note.attachments.append(.init(data: data, type: .image, note: note))
            } else if let data = videoData {
                note.attachments.append(.init(data: data, type: .video, note: note))
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
