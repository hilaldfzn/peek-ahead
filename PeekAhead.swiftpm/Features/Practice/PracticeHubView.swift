import SwiftUI

/// After the story: pick any of the practice activities, in any order, or skip them all.
struct PracticeHubView: View {
    let practice: StoryPractice
    let dependencies: AppDependencies
    let soundsEnabled: Bool
    let volumeLimit: Double
    let chosenTools: Set<CalmTool>
    let onToolsChosen: (Set<CalmTool>) -> Void
    let onFinish: () -> Void

    @State private var active: PracticeActivity?
    @State private var done: Set<PracticeActivity> = []

    var body: some View {
        PracticeScaffold(title: "Let's practise", instruction: Text("Pick one. You can skip.")) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: AppSpace.lg)], spacing: AppSpace.lg) {
                ForEach(practice.activities) { activity in
                    ChoiceCard(
                        artwork: .symbol(activity.symbol),
                        title: Text(activity.title),
                        showsCheck: done.contains(activity)
                    ) {
                        active = activity
                    }
                    .accessibilityValue(done.contains(activity) ? Text("Done") : Text(""))
                }
            }
        } buttons: {
            Button(done.isEmpty ? "Skip" : "I'm done", action: onFinish)
                .buttonStyle(.childPrimary)
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $active) { activity in
            activityView(activity)
        }
    }

    @ViewBuilder
    private func activityView(_ activity: PracticeActivity) -> some View {
        switch activity {
        case .orderSteps:
            OrderStepsView(steps: practice.steps) { finish(activity) }
        case .soundPreview:
            SoundPreviewView(
                cues: practice.sounds,
                player: dependencies.soundPlayer,
                soundsEnabled: soundsEnabled,
                volumeLimit: volumeLimit
            ) { finish(activity) }
        case .calmTools:
            CalmToolsView(tools: practice.calmTools, initiallyChosen: chosenTools) { tools in
                onToolsChosen(tools)
                finish(activity)
            }
        }
    }

    private func finish(_ activity: PracticeActivity) {
        done.insert(activity)
        active = nil
    }
}
