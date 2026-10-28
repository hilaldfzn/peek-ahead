import SwiftUI

/// Plan the day: turn a story's steps into the Now / Next strip on the child's Home screen.
struct PlanDayView: View {
    let stories: [Story]
    let progress: ProgressModel

    var body: some View {
        List {
            Section("Today\u{2019}s plan") {
                if let plan = progress.state.dayPlan {
                    Text(verbatim: plan.title).font(.headline)
                    ForEach(Array(plan.steps.enumerated()), id: \.element.id) { index, step in
                        HStack {
                            BundleImage(name: step.pictogram.imageName)
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .accessibilityHidden(true)
                            Text(verbatim: step.label)
                            Spacer()
                            Text(stateTitle(plan.state(of: index)))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Clear today\u{2019}s plan", role: .destructive) { progress.setDayPlan(nil) }
                } else {
                    Text("No plan yet. Choose a story below.")
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                ForEach(stories.filter { DayPlan(story: $0) != nil }) { story in
                    Button {
                        progress.setDayPlan(DayPlan(story: story))
                    } label: {
                        Label(story.title, systemImage: "calendar.badge.plus")
                    }
                }
            } header: {
                Text("Make a plan from a story")
            } footer: {
                Text("The child sees the plan on Home and taps \u{201C}I did it\u{201D} after each step.")
            }
        }
        .navigationTitle("Plan the day")
    }

    private func stateTitle(_ state: DayPlan.StepState) -> LocalizedStringKey {
        switch state {
        case .done: "Done"
        case .now: "Now"
        case .next: "Next"
        }
    }
}
