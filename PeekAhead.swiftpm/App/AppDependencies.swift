import Foundation

/// The services the app needs, created once at launch and passed down explicitly.
///
/// Views receive protocols (`StoryProviding`, `Narrating`, `SoundPlaying`), so previews and tests can swap in
/// fakes without touching AVFoundation or the file system.
@MainActor
struct AppDependencies {
    let storyProvider: any StoryProviding
    let narrator: any Narrating
    let soundPlayer: any SoundPlaying
    let progress: ProgressModel
    let drafter: any StoryDrafting

    static func live() -> AppDependencies {
        let progress = ProgressModel(store: JSONFileProgressStore(fileURL: AppPaths.progressFile))
        if progress.startedFresh {
            Log.app.notice("Saved progress could not be read; started fresh and kept the old file aside")
        }
        return AppDependencies(
            storyProvider: FileStoryProvider.bundled(),
            narrator: SpeechNarrator(speed: { progress.settings.narrationSpeed }),
            soundPlayer: AudioPreviewPlayer(),
            progress: progress,
            drafter: TemplateDrafter()
        )
    }
}
