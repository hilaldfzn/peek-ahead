import Foundation
import UIKit

/// Finds files from `Resources/`.
///
/// `.process("Resources")` copies every file to the top level of the app bundle, so files are found by name
/// alone and names must be unique across the subfolders. The other loaded bundles are only a fallback for
/// hosts such as SwiftUI previews.
enum AppResources {
    static func url(forResource name: String, withExtension ext: String) -> URL? {
        for bundle in searchOrder {
            if let url = bundle.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    /// Every resource with the given extension whose file name starts with `prefix`, without duplicates.
    static func urls(withExtension ext: String, prefix: String) -> [URL] {
        let candidates = searchOrder.flatMap { $0.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? [] }
        var seen = Set<String>()
        return candidates.filter { url in
            url.lastPathComponent.hasPrefix(prefix) && seen.insert(url.lastPathComponent).inserted
        }
    }

    static func bundle(containing name: String, withExtension ext: String) -> Bundle? {
        searchOrder.first { $0.url(forResource: name, withExtension: ext) != nil }
    }

    static func image(named name: String) -> UIImage? {
        guard let bundle = bundle(containing: name, withExtension: "png") else { return nil }
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }

    private static var searchOrder: [Bundle] {
        [Bundle.main] + Bundle.allBundles.filter { $0 != Bundle.main }
    }
}
