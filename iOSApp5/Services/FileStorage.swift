import Foundation

enum FileStorage {
    static func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Copy a picked file URL (e.g., from Photos) into Documents and return the destination path string.
    static func copyToDocuments(from sourceURL: URL, filename: String) throws -> String {
        let dest = documentsURL().appendingPathComponent(filename)
        // Remove existing file if any
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.copyItem(at: sourceURL, to: dest)
        return dest.path
    }

    static func removeIfExists(path: String?) {
        guard let path else { return }
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
    }
}
