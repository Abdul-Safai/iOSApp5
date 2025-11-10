import Foundation
import SwiftData
import CoreLocation

@Model
final class Note {
    // REMOVE @Attribute(.unique) — it breaks saving
    var id: UUID = UUID()
    var title: String
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var latitude: Double?
    var longitude: Double?

    @Relationship(deleteRule: .cascade, inverse: \MediaAttachment.note)
    var attachments: [MediaAttachment]

    init(
        title: String,
        text: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.title = title
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.latitude = latitude
        self.longitude = longitude
        self.attachments = []
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let la = latitude, let lo = longitude else { return nil }
        return .init(latitude: la, longitude: lo)
    }
}
