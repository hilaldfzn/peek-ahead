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
    let drafter: DraftingCoordinator

    static func live() -> AppDependencies {
        let progress = ProgressModel(store: JSONFileProgressStore(fileURL: AppPaths.progressFile))
        if progress.startedFresh {
            // Keep every photo: the set-aside progress file may still refer to them.
            Log.app.notice("Saved progress could not be read; started fresh and kept the old file aside")
        } else {
            // Photos added in the editor but never saved are removed at the next launch.
            PhotoStore.removeUnreferenced(keeping: progress.state.referencedPhotoIDs)
        }
        return AppDependencies(
            storyProvider: FileStoryProvider.bundled(),
            narrator: SpeechNarrator(speed: { progress.settings.narrationSpeed }),
            soundPlayer: AudioPreviewPlayer(),
            progress: progress,
            drafter: Drafters.make()
        )
    }
}
