import Foundation

/// What a grown-up asks for when starting a new story.
struct DraftRequest: Equatable, Sendable {
    var event: EventKind
    /// The grown-up's own words about the event, for example "We visit Nenek. Many cousins, fireworks at night."
    var details: String
    var language: StoryLanguage
}

/// Events the app has templates and scenes for.
enum EventKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case dentist
    case haircut
    case familyVisit = "family_visit"
    case fireDrill = "fire_drill"
    case newPlace = "new_place"

    var id: String { rawValue }
}

enum StoryLanguage: String, Codable, Sendable, CaseIterable, Identifiable {
    case english = "en-US"
    case indonesian = "id-ID"

    var id: String { rawValue }
}

/// Writes a first draft of a story. Every draft is marked as a placeholder and goes through the rule checker; the
/// grown-up edits and approves every page before a child sees it.
protocol StoryDrafting: Sendable {
    func draft(_ request: DraftRequest) async throws -> Story
}
