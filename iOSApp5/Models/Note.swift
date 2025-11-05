import Foundation
import SwiftData

/// A note with optional location and multiple media attachments.
@Model
final class Note {
    var id: UUID
    var title: String
    var detail: String
    var createdAt: Date
    var latitude: Double?
    var longitude: Double?
    @Relationship(deleteRule: .cascade) var attachments: [MediaAttachment]

    init(title: String,
         detail: String,
         latitude: Double? = nil,
         longitude: Double? = nil,
         attachments: [MediaAttachment] = []) {
        self.id = UUID()
        self.title = title
        self.detail = detail
        self.createdAt = Date()
        self.latitude = latitude
        self.longitude = longitude
        self.attachments = attachments
    }
}
