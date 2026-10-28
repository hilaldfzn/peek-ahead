import SwiftUI

/// Start a new story: pick the event, the language, and optionally describe it in your own words. The draft opens
/// in the editor; nothing reaches the child until the grown-up saves it.
struct NewStoryView: View {
    let drafter: DraftingCoordinator
    let onDrafted: (DraftOutcome) -> Void

    @State private var event: EventKind = .dentist
    @State private var language: StoryLanguage = .english
    @State private var details = ""
    @State private var isDrafting = false

    var body: some View {
        Form {
            Section {
                Picker("What is happening?", selection: $event) {
                    ForEach(EventKind.allCases) { Text($0.title).tag($0) }
                }
                Picker("Language", selection: $language) {
                    ForEach(StoryLanguage.allCases) { Text($0.title).tag($0) }
                }
            }
            Section {
                TextField(
                    "For example: We visit Nenek. Many cousins, fireworks at night.",
                    text: $details,
                    axis: .vertical
                )
                .lineLimit(3...6)
            } header: {
                Text("In your own words (optional)")
            } footer: {
                Text(
                    "Drafts are written on this iPad with Apple Intelligence when it is available, and from a template otherwise. Nothing is sent anywhere. You check every page before a child sees it."
                )
            }
            Section {
                Button(action: draft) {
                    if isDrafting {
                        ProgressView()
                    } else {
                        Text("Write a draft")
                    }
                }
                .disabled(isDrafting)
            }
        }
        .navigationTitle("New story")
    }

    private func draft() {
        isDrafting = true
        let request = DraftRequest(event: event, details: details, language: language)
        Task {
            // The coordinator never fails: it falls back to a template and says why.
            let outcome = await drafter.outcome(for: request)
            isDrafting = false
            onDrafted(outcome)
        }
    }
}

extension EventKind {
    var title: LocalizedStringKey {
        switch self {
        case .dentist: "Going to the dentist"
        case .haircut: "A haircut"
        case .familyVisit: "Visiting family (Lebaran)"
        case .fireDrill: "A fire drill at school"
        case .newPlace: "Going somewhere new"
        }
    }
}

extension StoryLanguage {
    var title: LocalizedStringKey {
        switch self {
        case .english: "English"
        case .indonesian: "Bahasa Indonesia"
        }
    }
}
