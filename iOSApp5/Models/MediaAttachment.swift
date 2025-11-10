import Foundation
import SwiftData

enum MediaType: String, Codable, Sendable {
    case image
    case video
}

@Model
final class MediaAttachment {
    @Attribute(.unique) var id: UUID
    var data: Data                   // raw image/video data
    var createdAt: Date
    var typeRaw: String              // SwiftData stores simple types reliably

    var note: Note?

    var type: MediaType {
        get { MediaType(rawValue: typeRaw) ?? .image }
        set { typeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        data: Data,
        type: MediaType,
        createdAt: Date = .now,
        note: Note? = nil
    ) {
        self.id = id
        self.data = data
        self.typeRaw = type.rawValue
        self.createdAt = createdAt
        self.note = note
    }
}
