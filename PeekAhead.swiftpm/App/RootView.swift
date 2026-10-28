import SwiftUI

/// Loads the story library and hosts navigation: Home, then a story.
struct RootView: View {
    let dependencies: AppDependencies

    @State private var state: LoadState = .loading
    @State private var path: [Story] = []

    private enum LoadState {
        case loading
        case loaded([Story])
        case failed
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: Story.self) { story in
                    StoryPlayerScreen(story: story, narrator: dependencies.narrator)
                }
        }
        .tint(AppColor.primary)
        // Child mode uses the Calm theme for now. The Night theme will be a grown-up setting rather than
        // following the system appearance (DESIGN.md), so dark mode never changes the look by surprise.
        .preferredColorScheme(.light)
        .task { load() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.paper)
        case .loaded(let stories):
            HomeView(stories: stories) { story in
                path.append(story)
            }
        case .failed:
            ContentUnavailableView(
                "Stories could not be opened",
                systemImage: "book.closed",
                description: Text("Please ask a grown-up to reinstall the app.")
            )
            .background(AppColor.paper)
        }
    }

    private func load() {
        guard case .loading = state else { return }
        do {
            state = .loaded(try dependencies.storyProvider.loadStories())
        } catch {
            Log.content.error("Loading stories failed: \(String(describing: error), privacy: .public)")
            state = .failed
        }
    }
}
