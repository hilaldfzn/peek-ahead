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
    /// Practice that follows the story. Optional: a story without it goes straight to the reward.
    let practice: StoryPractice?

    init(
        id: String,
        title: String,
        language: String,
        review: ReviewStatus,
        pages: [StoryPage],
        practice: StoryPractice? = nil
    ) {
        self.id = id
        self.title = title
        self.language = language
        self.review = review
        self.pages = pages
        self.practice = practice
    }
}

/// One page of a story: a single short sentence shown over one scene.
struct StoryPage: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let sentence: String
    /// An optional "Sometimes…" note that prepares the child for a change, for example a different chair colour.
    let sometimesNote: String?
    let scene: StoryScene
    /// What the sentence does. The rule checker uses it for the describing-to-directing ratio and the ending.
    let kind: PageKind

    init(id: String, sentence: String, sometimesNote: String?, scene: StoryScene, kind: PageKind = .describes) {
        self.id = id
        self.sentence = sentence
        self.sometimesNote = sometimesNote
        self.scene = scene
        self.kind = kind
    }

    private enum CodingKeys: String, CodingKey {
        case id, sentence, sometimesNote, scene, kind
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        sentence = try container.decode(String.self, forKey: .sentence)
        sometimesNote = try container.decodeIfPresent(String.self, forKey: .sometimesNote)
        scene = try container.decode(StoryScene.self, forKey: .scene)
        // Older story files have no kind; treat their pages as describing.
        kind = try container.decodeIfPresent(PageKind.self, forKey: .kind) ?? .describes
    }
}

/// The job a sentence does in the story (DESIGN.md, story language rules).
enum PageKind: String, Codable, Sendable, CaseIterable {
    /// Says what happens or what is there: "The dentist has a big chair."
    case describes
    /// Names a feeling, without judging it: "Some children feel excited."
    case feelings
    /// Something the child can do: "I can hold my favourite toy."
    case iCan = "i_can"
    /// Something good and true to finish on: "Then I go home."
    case endsWell = "ends_well"
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
