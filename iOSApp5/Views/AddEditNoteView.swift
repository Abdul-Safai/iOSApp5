import SwiftUI
import PhotosUI
import MapKit
import StoreKit
import CoreHaptics
import SwiftData
import UniformTypeIdentifiers

struct AddEditNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme

    /// Callback so ContentView can show a toast
    var onSaved: (() -> Void)? = nil

    // Fields
    @State private var titleText = ""
    @State private var detailText = ""

    // Media picker
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var previews: [(kind: MediaKind, image: UIImage)] = []

    // Location
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )

    // Haptics
    @State private var engine: CHHapticEngine?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // MARK: Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField("E.g., Lab Demo Recap", text: $titleText)
                            .padding(.horizontal, 14)               // ← proper left/right inset
                            .padding(.vertical, 12)
                            .background(AppTheme.cardBackground(scheme),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(.separator.opacity(0.4))
                            )
                            .textInputAutocapitalization(.sentences)
                    }
                    .padding(.horizontal)
                    .glassCard()

                    // MARK: Details
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Details")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextEditor(text: $detailText)
                            .padding(.horizontal, 14)               // ← same inset as title
                            .padding(.vertical, 12)
                            .frame(minHeight: 120)
                            .background(AppTheme.cardBackground(scheme),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(.separator.opacity(0.4))
                            )
                    }
                    .padding(.horizontal)
                    .glassCard()

                    // MARK: Attachments
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Attachments")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            PhotosPicker(selection: $pickerItems,
                                         maxSelectionCount: 6,
                                         matching: .any(of: [.images, .videos])) {
                                Label("Add", systemImage: "plus.circle.fill")
                            }
                        }

                        if !previews.isEmpty {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                                ForEach(Array(previews.enumerated()), id: \.offset) { _, item in
                                    ZStack {
                                        Image(uiImage: item.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 110)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        if item.kind == .video {
                                            Image(systemName: "play.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.white)
                                                .shadow(radius: 3)
                                        }
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .scale))
                        } else {
                            HStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled").font(.title2)
                                Text("Add images or videos (up to 6).")
                                Spacer()
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                    .onChange(of: pickerItems) { _, items in
                        Task { await loadPreviews(items: items) }
                    }

                    // MARK: Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location (optional)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Map(position: .constant(.region(region)))
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .onAppear { locationManager.request() }
                            .onReceive(locationManager.$lastLocation) { loc in
                                guard let loc else { return }
                                region.center = loc.coordinate
                            }
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)

                    // MARK: Save
                    PrimaryButton(title: "Save Note", systemImage: "checkmark.circle.fill") {
                        Task { await saveNote() }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .disabled(titleText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.top, 12)
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
            .task { prepareHaptics() }
        }
    }

    // MARK: - Helpers

    private func loadPreviews(items: [PhotosPickerItem]) async {
        withAnimation { previews.removeAll() }
        for item in items {
            guard let type = item.supportedContentTypes.first else { continue }
            if type.conforms(to: .image) {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    withAnimation(.spring) { previews.append((.image, ui)) }
                }
            } else if type.conforms(to: .movie) {
                withAnimation(.spring) {
                    previews.append((.video, UIImage(systemName: "video.fill")!))
                }
            }
        }
    }

    private func saveNote() async {
        let lat = locationManager.lastLocation?.coordinate.latitude
        let lon = locationManager.lastLocation?.coordinate.longitude
        let note = Note(title: titleText.trimmingCharacters(in: .whitespacesAndNewlines),
                        detail: detailText.trimmingCharacters(in: .whitespacesAndNewlines),
                        latitude: lat, longitude: lon)

        // Convert picker items to persisted attachments
        for item in pickerItems {
            guard let t = item.supportedContentTypes.first else { continue }
            if t.conforms(to: .image), let data = try? await item.loadTransferable(type: Data.self) {
                if let (name, thumb) = try? MediaStore.saveImage(data) {
                    note.attachments.append(MediaAttachment(kind: .image, fileName: name, thumbData: thumb))
                }
            } else if t.conforms(to: .movie), let url = try? await item.loadTransferable(type: URL.self) {
                if let (name, thumb) = try? MediaStore.saveVideo(from: url) {
                    note.attachments.append(MediaAttachment(kind: .video, fileName: name, thumbData: thumb))
                }
            }
        }

        context.insert(note)
        do {
            try context.save()
            triggerSuccessHaptic()
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
            onSaved?()
            dismiss()
        } catch {
            print("Save failed:", error.localizedDescription)
        }
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
    }

    private func triggerSuccessHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let taps = [CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0)]
        if let pattern = try? CHHapticPattern(events: taps, parameters: []),
           let player = try? engine?.makePlayer(with: pattern) {
            try? player.start(atTime: 0)
        }
    }
}
