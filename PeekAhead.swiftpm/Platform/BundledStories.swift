import Foundation

extension FileStoryProvider {
    /// The stories shipped with the app: every `story-*.json` file in `Resources/Stories`.
    static func bundled() -> FileStoryProvider {
        FileStoryProvider(fileURLs: AppResources.urls(withExtension: "json", prefix: "story-"))
    }
}
