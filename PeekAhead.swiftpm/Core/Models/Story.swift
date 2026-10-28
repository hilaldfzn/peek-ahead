import Foundation

/// A short picture story that prepares a child for one real event, such as a visit to the dentist.
///
/// Stories are plain data. They are bundled as JSON (`Resources/Stories/story-*.json`) and checked by
/// ``StoryValidator`` when they are loaded.
struct Story: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    /// BCP 47 language tag used for narration, for example `en-US` or `id-ID`.
    let language: String
    /// Whether an expert (a child psychologist or an experienced special-education teacher) has approved the wording.
    let review: ReviewStatus
    let pages: [StoryPage]
}

/// One page of a story: a single short sentence shown over one scene.
struct StoryPage: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let sentence: String
    /// An optional "Sometimes…" note that prepares the child for a change, for example a different chair colour.
    let sometimesNote: String?
    let scene: StoryScene
}

/// Review state of a story's wording.
enum ReviewStatus: String, Codable, Sendable {
    /// Draft wording written by the developer. Never show it to a child outside a supervised, consented session.
    case placeholder
    /// Wording approved by the reviewer.
    case reviewed
}

/// The scenes a page can show. Each one has a pre-rendered picture in `Resources/Images`.
enum StoryScene: String, Codable, Sendable, CaseIterable {
    case waitingRoom = "waiting_room"
    case bigChair = "big_chair"
    case familyVisit = "family_visit"
    case pipRoom = "pip_room"
    case streetTrip = "street_trip"

    /// File name (without extension) of the scene's rendered picture in the app bundle.
    var imageName: String { "scene_\(rawValue)" }
}
