import SwiftUI

/// Loads the story library and hosts the child's path: Home → story → practice → Home.
struct RootView: View {
    let dependencies: AppDependencies

    @State private var state: LoadState = .loading
    @State private var path: [AppRoute] = []
    // Week 5 moves these into saved progress and grown-up settings.
    @State private var chosenTools: Set<CalmTool> = []
    private let soundsEnabled = true
    private let volumeLimit = 1.0

    private enum LoadState {
        case loading
        case loaded([Story])
        case failed
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: AppRoute.self, destination: destination)
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
                path.append(.story(story))
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

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case .story(let story):
            StoryPlayerScreen(
                story: story,
                narrator: dependencies.narrator,
                onHome: goHome,
                onFinish: { finishedReading(story) }
            )
        case .practice(let story):
            if let practice = story.practice {
                PracticeHubView(
                    practice: practice,
                    dependencies: dependencies,
                    soundsEnabled: soundsEnabled,
                    volumeLimit: volumeLimit,
                    chosenTools: chosenTools,
                    onToolsChosen: { chosenTools = $0 },
                    onFinish: goHome
                )
            }
        }
    }

    private func finishedReading(_ story: Story) {
        if story.practice?.activities.isEmpty == false {
            path.append(.practice(story))
        } else {
            goHome()
        }
    }

    private func goHome() {
        path.removeAll()
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
