import Foundation
import SwiftData

/// A simple persisted note with optional photo and location.
/// Uses SwiftData's @Model to generate storage and queries automatically.
@Model
final class Note {
    var id: UUID
    var title: String
    var detail: String
    var createdAt: Date
    var latitude: Double?
    var longitude: Double?
    var photoData: Data? // JPEG/PNG/WebP data

    init(title: String, detail: String, latitude: Double? = nil, longitude: Double? = nil, photoData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.detail = detail
        self.createdAt = Date()
        self.latitude = latitude
        self.longitude = longitude
        self.photoData = photoData
    }
}
