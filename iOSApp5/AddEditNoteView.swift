import SwiftUI
import PhotosUI
import MapKit
import StoreKit
import CoreHaptics
import SwiftData

/// Create a new note: title, detail, optional photo, capture current location.
struct AddEditNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // New note fields
    @State private var titleText = ""
    @State private var detailText = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    // Location & map
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832), // Toronto default
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )

    // Haptics
    @State private var engine: CHHapticEngine?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Title (required)", text: $titleText)
                        .textFieldStyle(.roundedBorder)

                    TextField("Details", text: $detailText, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)

                    // Photo picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo (optional)").font(.subheadline)
                        HStack(alignment: .center, spacing: 12) {
                            if let data = photoData, let ui = UIImage(data: data) {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 96, height: 96)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .accessibilityLabel("Selected photo")
                            } else {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .frame(width: 96, height: 96)
                            }

                            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                                Label("Choose Photo", systemImage: "photo.on.rectangle")
                            }
                            .onChange(of: photoItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        photoData = data
                                    }
                                }
                            }
                        }
                    }

                    // Location preview (requests permission; tags note with lat/long)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location (optional)").font(.subheadline)
                        Map(position: .constant(.region(region)))
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onAppear {
                                // Ask for location when view appears
                                locationManager.request()
                            }
                            .onReceive(locationManager.$lastLocation) { loc in
                                guard let loc else { return }
                                region.center = loc.coordinate
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveNote() }
                        .disabled(titleText.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityLabel("Save note")
                }
            }
            .task { prepareHaptics() }
        }
    }

    private func saveNote() {
        // Capture last known location if available
        let lat = locationManager.lastLocation?.coordinate.latitude
        let lon = locationManager.lastLocation?.coordinate.longitude

        // Persist via SwiftData
        let note = Note(title: titleText.trimmingCharacters(in: .whitespaces),
                        detail: detailText.trimmingCharacters(in: .whitespacesAndNewlines),
                        latitude: lat,
                        longitude: lon,
                        photoData: photoData)
        context.insert(note)
        do {
            try context.save()
            triggerSuccessHaptic()
            requestReviewIfAppropriate()
            dismiss()
        } catch {
            // In a real app: surface an alert; for the assignment, console is fine.
            print("Save failed:", error.localizedDescription)
        }
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptics init error:", error.localizedDescription)
        }
    }

    private func triggerSuccessHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let events = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0),
            CHHapticEvent(eventType: .hapticContinuous,
                          parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                                       CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)],
                          relativeTime: 0.02, duration: 0.15)
        ]
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Haptics play error:", error.localizedDescription)
        }
    }

    private func requestReviewIfAppropriate() {
        // Keep it simple: nudge the system for an in-app review after a save.
        // The system decides whether to show it.
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
