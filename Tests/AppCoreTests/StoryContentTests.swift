import Foundation
import Testing

@testable import AppCore

@Suite("Story decoding and validation")
struct StoryContentTests {
    private let decoder = StoryDecoder()

    @Test func decodesAValidStory() throws {
        let json = """
            {
              "id": "haircut", "title": "Haircut", "language": "en-US", "review": "placeholder",
              "pages": [
                { "id": "p1", "sentence": "I sit in the big chair.", "sometimesNote": null, "scene": "big_chair" }
              ]
            }
            """
        let story = try decoder.decode(Data(json.utf8))
        #expect(story.id == "haircut")
        #expect(story.pages.first?.scene == .bigChair)
        #expect(story.review == .placeholder)
    }

    @Test func rejectsUnknownScenes() {
        let json = """
            { "id": "x", "title": "X", "language": "en-US", "review": "reviewed",
              "pages": [ { "id": "p1", "sentence": "Hi.", "scene": "moon_base" } ] }
            """
        #expect {
            try decoder.decode(Data(json.utf8))
        } throws: { error in
            if case .malformed = error as? StoryContentError { return true }
            return false
        }
    }

    @Test func rejectsStoriesWithoutPages() {
        let story = Story(id: "empty", title: "Empty", language: "en-US", review: .placeholder, pages: [])
        #expect(throws: StoryContentError.noPages(storyID: "empty")) {
            try StoryValidator.validate(story)
        }
    }

    @Test func rejectsDuplicatePageIDs() {
        let story = Story(
            id: "dup", title: "Dup", language: "en-US", review: .placeholder,
            pages: [Fixtures.page("p1", "One."), Fixtures.page("p1", "Two.")]
        )
        #expect(throws: StoryContentError.duplicatePageID(storyID: "dup", pageID: "p1")) {
            try StoryValidator.validate(story)
        }
    }

    @Test func rejectsBlankSentences() {
        let story = Story(
            id: "blank", title: "Blank", language: "en-US", review: .placeholder,
            pages: [Fixtures.page("p1", "   ")]
        )
        #expect(throws: StoryContentError.emptySentence(storyID: "blank", pageID: "p1")) {
            try StoryValidator.validate(story)
        }
    }

    @Test func rejectsDuplicateStoryIDsInALibrary() {
        let provider = InMemoryStoryProvider(stories: [Fixtures.dentist, Fixtures.dentist])
        #expect(throws: StoryContentError.duplicateStoryID("dentist")) {
            try provider.loadStories()
        }
    }

    @Test func reportsUnreadableFiles() {
        let missing = URL(fileURLWithPath: "/nonexistent/story-missing.json")
        #expect(throws: StoryContentError.unreadable(file: "story-missing.json")) {
            try FileStoryProvider(fileURLs: [missing]).loadStories()
        }
    }
}

@Suite("Bundled app content")
struct BundledContentTests {
    private var storyFiles: [URL] {
        let folder = Fixtures.appResources.appendingPathComponent("Stories")
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        return names.filter { $0.hasPrefix("story-") && $0.hasSuffix(".json") }
            .map { folder.appendingPathComponent($0) }
    }

    @Test func everyBundledStoryLoads() throws {
        #expect(!storyFiles.isEmpty)
        let stories = try FileStoryProvider(fileURLs: storyFiles).loadStories()
        #expect(stories.count == storyFiles.count)
    }

    @Test func everySceneHasARenderedPicture() {
        let images = Fixtures.appResources.appendingPathComponent("Images")
        for scene in StoryScene.allCases {
            let file = images.appendingPathComponent("\(scene.imageName).png")
            #expect(FileManager.default.fileExists(atPath: file.path), "Missing \(file.lastPathComponent)")
        }
    }

    @Test func placeholderStoriesAreMarked() throws {
        // Until the expert review is done, every bundled story must say so.
        let stories = try FileStoryProvider(fileURLs: storyFiles).loadStories()
        for story in stories {
            #expect(story.review == .placeholder, "\(story.id) is marked reviewed; record the review in docs first")
        }
    }
}
