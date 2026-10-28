import Foundation

@testable import AppCore

enum Fixtures {
    static func page(_ id: String, _ sentence: String, scene: StoryScene = .waitingRoom) -> StoryPage {
        StoryPage(id: id, sentence: sentence, sometimesNote: nil, scene: scene)
    }

    static let dentist = Story(
        id: "dentist",
        title: "Going to the dentist",
        language: "en-US",
        review: .placeholder,
        pages: [
            page("p1", "Today I go to the dentist."),
            page("p2", "The dentist has a big chair.", scene: .bigChair),
            page("p3", "Then I go home."),
        ]
    )

    static let withPractice = Story(
        id: "practice",
        title: "A practice day",
        language: "en-US",
        review: .placeholder,
        pages: [page("p1", "Today we go out.")],
        practice: StoryPractice(
            steps: [
                PracticeStep(id: "a", label: "Go in the car", pictogram: .car),
                PracticeStep(id: "b", label: "Wait", pictogram: .waiting),
                PracticeStep(id: "c", label: "Go home", pictogram: .home),
            ],
            calmTools: [.headphones]
        )
    )

    /// Root of the repository, found from this file's location.
    static let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Support
        .deletingLastPathComponent()  // AppCoreTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()

    static let appResources = repositoryRoot.appendingPathComponent("PeekAhead.swiftpm/Resources")
}
