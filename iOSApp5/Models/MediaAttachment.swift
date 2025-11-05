import Foundation
import SwiftData

/// Kind of media we support.
enum MediaKind: String, Codable, CaseIterable {
    case image
    case video
}

/// A persisted media attachment stored on disk (Documents/Media/…).
/// We keep only a relative path here, plus a tiny thumbnail for lists.
@Model
final class MediaAttachment {
    var id: UUID
    var kind: String          // MediaKind rawValue (SwiftData current limitation)
    var fileName: String      // e.g. "IMG_1234.jpg" or "VID_5678.mov"
    var thumbData: Data?      // small image bytes for list thumbnails
    var createdAt: Date

    init(kind: MediaKind, fileName: String, thumbData: Data?) {
        self.id = UUID()
        self.kind = kind.rawValue
        self.fileName = fileName
        self.thumbData = thumbData
        self.createdAt = Date()
    }

    var mediaKind: MediaKind { MediaKind(rawValue: kind) ?? .image }
}
