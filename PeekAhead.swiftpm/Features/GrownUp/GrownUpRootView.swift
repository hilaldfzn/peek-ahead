import SwiftUI

/// Grown-up mode: plain native iOS lists in SF Pro (DESIGN.md), behind the hold-to-open gate.
struct GrownUpRootView: View {
    let bundled: [Story]
    let dependencies: AppDependencies
    let onClose: () -> Void

    @State private var path: [GrownUpRoute] = []

    private var progress: ProgressModel { dependencies.progress }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if progress.lastSaveFailed {
                    Section {
                        Label(
                            "Changes could not be saved on this iPad. Check that there is free storage.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(AppColor.coral)
                    }
                }
                Section("Stories") {
                    ForEach(progress.allStories(bundled: bundled)) { story in
                        NavigationLink(value: GrownUpRoute.edit(storyID: story.id)) {
                            StoryRow(story: story, isBuiltIn: bundled.contains { $0.id == story.id })
                        }
                    }
                    NavigationLink(value: GrownUpRoute.newStory) {
                        Label("New story", systemImage: "plus")
                    }
                }
                Section {
                    NavigationLink(value: GrownUpRoute.planDay) { Label("Plan the day", systemImage: "calendar") }
                    NavigationLink(value: GrownUpRoute.feelings) {
                        Label("Feelings check-ins", systemImage: "face.smiling")
                    }
                    NavigationLink(value: GrownUpRoute.settings) { Label("Settings", systemImage: "gearshape") }
                }
            }
            .navigationTitle("Grown-up mode")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Back to child mode", action: onClose)
                }
            }
            .navigationDestination(for: GrownUpRoute.self, destination: destination)
        }
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private func destination(_ route: GrownUpRoute) -> some View {
        switch route {
        case .edit(let id):
            if let story = bundled.first(where: { $0.id == id }) {
                StoryEditorView(
                    story: StoryEditorModel.copy(of: story, newID: "story-\(UUID().uuidString.lowercased())"),
                    dependencies: dependencies, bundled: bundled, isCopy: true, isUnsaved: true
                )
            } else if let story = progress.state.userStories.first(where: { $0.id == id }) {
                StoryEditorView(
                    story: story, dependencies: dependencies, bundled: bundled, isCopy: false, isUnsaved: false
                )
            }
        case .draft(let story):
            StoryEditorView(story: story, dependencies: dependencies, bundled: bundled, isCopy: false, isUnsaved: true)
        case .newStory:
            NewStoryView(drafter: dependencies.drafter) { draft in
                path.removeLast()
                path.append(.draft(draft))
            }
        case .planDay:
            PlanDayView(stories: progress.allStories(bundled: bundled), progress: progress)
        case .feelings:
            FeelingsNotesView(progress: progress)
        case .settings:
            SettingsView(progress: progress)
        }
    }
}

enum GrownUpRoute: Hashable {
    case edit(storyID: String)
    case draft(Story)
    case newStory
    case planDay
    case feelings
    case settings
}

private struct StoryRow: View {
    let story: Story
    let isBuiltIn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: story.title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var subtitle: String {
        let pages = String(localized: "\(story.pages.count) pages")
        let origin = isBuiltIn ? String(localized: "built-in, tap to copy") : String(localized: "yours")
        let review = story.review == .reviewed ? String(localized: "reviewed") : String(localized: "not yet reviewed")
        return [pages, origin, review].joined(separator: " \u{00B7} ")
    }
}
