import Foundation

/// The services the app needs, created once at launch and passed down explicitly.
///
/// Views receive protocols (`StoryProviding`, `Narrating`), so previews and tests can swap in fakes without
/// touching AVFoundation or the file system.
@MainActor
struct AppDependencies {
    let storyProvider: any StoryProviding
    let narrator: any Narrating

    static func live() -> AppDependencies {
        AppDependencies(
            storyProvider: FileStoryProvider.bundled(),
            narrator: SpeechNarrator()
        )
    }
}
