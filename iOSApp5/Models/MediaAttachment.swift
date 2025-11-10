import Foundation
import SwiftData

@Model
final class MediaAttachment {
    @Attribute(.unique) var id: UUID
    /// For images, this stores the full image data (PNG/JPEG).
    /// For videos, this can be empty `Data()` (we use `filePath` instead).
    var data: Data
    var createdAt: Date
    var note: Note?

    /// "image" or "video"
    var mediaType: String
    /// Local file path if mediaType == "video"
    var filePath: String?

    init(
        id: UUID = UUID(),
        data: Data,
        createdAt: Date = .now,
        note: Note? = nil,
        mediaType: String = "image",
        filePath: String? = nil
    ) {
        self.id = id
        self.data = data
        self.createdAt = createdAt
        self.note = note
        self.mediaType = mediaType
        self.filePath = filePath
    }
}
