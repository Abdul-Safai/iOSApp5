import UIKit
import AVFoundation

/// Handles saving images/videos into Documents/Media and generating thumbnails.
enum MediaStore {
    static let mediaDirName = "Media"

    static var mediaDirectoryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent(mediaDirName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Save JPEG data to disk.
    static func saveImage(_ data: Data, suggestedName: String? = nil) throws -> (fileName: String, thumb: Data?) {
        let name = (suggestedName ?? UUID().uuidString) + ".jpg"
        let url = mediaDirectoryURL.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)

        // generate small thumbnail (max 200px)
        let thumb = UIImage(data: data).flatMap { ui -> Data? in
            let maxSide: CGFloat = 200
            let scale = min(maxSide / max(ui.size.width, ui.size.height), 1.0)
            let newSize = CGSize(width: ui.size.width * scale, height: ui.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
            ui.draw(in: CGRect(origin: .zero, size: newSize))
            let resized = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return resized?.jpegData(compressionQuality: 0.7)
        }

        return (name, thumb)
    }

    /// Copy a video file URL into our app folder and generate a preview image.
    static func saveVideo(from sourceURL: URL) throws -> (fileName: String, thumb: Data?) {
        let name = UUID().uuidString + ".mov"
        let dest = mediaDirectoryURL.appendingPathComponent(name)
        try FileManager.default.copyItem(at: sourceURL, to: dest)

        // thumbnail from first second
        let asset = AVAsset(url: dest)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.5, preferredTimescale: 600)
        let cg = try? gen.copyCGImage(at: time, actualTime: nil)
        let thumbData = cg.flatMap { UIImage(cgImage: $0).jpegData(compressionQuality: 0.7) }

        return (name, thumbData)
    }

    static func url(for fileName: String) -> URL {
        mediaDirectoryURL.appendingPathComponent(fileName)
    }

    static func delete(fileName: String) {
        let url = self.url(for: fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
