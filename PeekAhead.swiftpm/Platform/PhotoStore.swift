import Foundation
import UIKit

/// Grown-ups' photos of real places, kept in the app's own container with complete file protection.
/// Nothing is uploaded, and photos no story uses any more are removed.
enum PhotoStore {
    static var folder: URL {
        AppPaths.appSupport.appendingPathComponent("Photos", isDirectory: true)
    }

    /// Saves a prepared photo (see `FaceBlurrer`) and returns its id.
    static func save(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw CocoaError(.fileWriteUnknown)
        }
        let id = UUID().uuidString.lowercased()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try data.write(to: url(for: id), options: [.atomic, .completeFileProtection])
        return id
    }

    static func image(for id: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: id).path)
    }

    /// Deletes every photo whose id is not in `ids`.
    static func removeUnreferenced(keeping ids: Set<String>) {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        for file in files where !ids.contains(file.deletingPathExtension().lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private static func url(for id: String) -> URL {
        folder.appendingPathComponent("\(id).jpg")
    }
}
