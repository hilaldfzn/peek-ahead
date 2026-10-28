import SwiftUI

/// Loads the story library and hosts the child's path: Home → story → practice → reward → feelings → Home.
struct RootView: View {
    let dependencies: AppDependencies

    @State private var state: LoadState = .loading
    @State private var path: [AppRoute] = []
    @State private var showsGrownUpMode = false

    private var progress: ProgressModel { dependencies.progress }

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
        case .loaded(let bundled):
            HomeView(
                stories: progress.allStories(bundled: bundled),
                progress: progress,
                onOpen: { path = [.story($0)] },
                onOpenRoom: { path = [.pipRoom] },
                onOpenGrownUpMode: { showsGrownUpMode = true }
            )
            .fullScreenCover(isPresented: $showsGrownUpMode) {
                GrownUpRootView(bundled: bundled, dependencies: dependencies) { showsGrownUpMode = false }
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
                onFinish: { advance(after: .story, story: story) }
            )
        case .practice(let story):
            if let practice = story.practice {
                PracticeHubView(
                    practice: practice,
                    dependencies: dependencies,
                    soundsEnabled: progress.settings.soundsEnabled,
                    volumeLimit: progress.settings.previewVolumeLimit,
                    chosenTools: Set(progress.state.calmTools),
                    onToolsChosen: { progress.setCalmTools($0) },
                    onFinish: { advance(after: .practice, story: story) }
                )
            }
        case .reward(let story):
            RewardChoiceView(
                offer: progress.rewardOffer,
                onPlace: { progress.place($0) },
                onContinue: { advance(after: .reward, story: story) }
            )
        case .feelings(let story):
            FeelingsCheckInView(
                onAnswer: { progress.logFeeling($0, for: story) },
                onDone: goHome
            )
        case .pipRoom:
            PipRoomView(items: progress.state.roomItems, onHome: goHome)
        }
    }

    /// Shows the next screen in place of the current one, so Back never returns to a finished step.
    private func advance(after step: ChildJourney.Step, story: Story) {
        let next = ChildJourney.step(after: step, story: story, rewardsLeft: !progress.rewardOffer.isEmpty)
        switch next {
        case .practice: path = [.practice(story)]
        case .reward: path = [.reward(story)]
        case .feelings: path = [.feelings(story)]
        case .story, .home: goHome()
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
