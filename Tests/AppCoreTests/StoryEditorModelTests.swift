import Foundation
import Testing

@testable import AppCore

@MainActor
@Suite("Story editor")
struct StoryEditorModelTests {
    private func makeEditor() -> StoryEditorModel {
        var counter = 0
        return StoryEditorModel(story: Fixtures.dentist) {
            counter += 1
            return "new\(counter)"
        }
    }

    @Test func rechecksRulesOnEveryChange() {
        let editor = makeEditor()
        #expect(editor.storyFindings.map(\.rule) == [.ending])
        editor.setSentence("Don't run around.", page: "p2")
        #expect(editor.findings(forPage: "p2").map(\.rule) == [.directive])
        editor.setSentence("I walk next to Mum.", page: "p2")
        #expect(editor.findings(forPage: "p2").isEmpty)
        editor.setKind(.endsWell, page: "p3")
        #expect(editor.storyFindings.isEmpty)
        #expect(editor.hasChanges)
    }

    @Test func addsPagesAfterAGivenPageWithItsScene() {
        let editor = makeEditor()
        let id = editor.addPage(after: "p2")
        #expect(editor.story.pages.map(\.id) == ["p1", "p2", "new1", "p3"])
        #expect(editor.story.pages[2].scene == .bigChair)
        editor.addPage()
        #expect(editor.story.pages.last?.id == "new2")
        #expect(id == "new1")
    }

    @Test func movesAndDeletesPagesLikeAList() {
        let editor = makeEditor()
        editor.movePages(from: [0], to: 3)  // first page to the end
        #expect(editor.story.pages.map(\.id) == ["p2", "p3", "p1"])
        editor.movePages(from: [2], to: 0)
        #expect(editor.story.pages.map(\.id) == ["p1", "p2", "p3"])
        editor.deletePages(at: [1])
        #expect(editor.story.pages.map(\.id) == ["p1", "p3"])
    }

    @Test func savingDropsBlankPagesAndTheDraftBadge() {
        var draft = Fixtures.dentist
        draft.draftSource = .template
        let editor = StoryEditorModel(story: draft)
        editor.addPage()
        editor.setNote("   ", page: "p1")
        let saved = editor.storyForSaving()
        #expect(saved.pages.count == 3)
        #expect(saved.draftSource == nil)
        #expect(saved.pages[0].sometimesNote == nil)
    }

    @Test func aCopyOfABundledStoryIsADraftWithItsOwnID() {
        var reviewed = Fixtures.dentist
        reviewed.review = .reviewed
        let copy = StoryEditorModel.copy(of: reviewed, newID: "mine")
        #expect(copy.id == "mine")
        #expect(copy.review == .placeholder)
        #expect(copy.pages == reviewed.pages)
    }
}

@MainActor
@Suite("Grown-up stories in saved progress")
struct UserStoriesTests {
    @Test func savesUpdatesAndDeletesUserStories() throws {
        let store = InMemoryProgressStore()
        let model = ProgressModel(store: store)
        var story = Fixtures.withPractice
        try model.saveUserStory(story, bundled: [Fixtures.dentist])
        story.title = "Changed"
        try model.saveUserStory(story, bundled: [Fixtures.dentist])
        #expect(store.stored?.userStories.map(\.title) == ["Changed"])
        #expect(model.allStories(bundled: [Fixtures.dentist]).map(\.id) == ["dentist", "practice"])
        model.deleteUserStory(id: story.id)
        #expect(model.state.userStories.isEmpty)
    }

    @Test func refusesInvalidStoriesAndClashingIDs() {
        let model = ProgressModel(store: InMemoryProgressStore())
        let empty = Story(id: "e", title: "E", language: "en-US", review: .placeholder, pages: [])
        #expect(throws: StoryContentError.noPages(storyID: "e")) {
            try model.saveUserStory(empty, bundled: [])
        }
        #expect(throws: StoryContentError.duplicateStoryID("dentist")) {
            try model.saveUserStory(Fixtures.dentist, bundled: [Fixtures.dentist])
        }
    }

    @Test func clearsFeelingsOnly() {
        let model = ProgressModel(store: InMemoryProgressStore())
        model.place(.lamp)
        model.logFeeling(.calm, for: Fixtures.dentist)
        model.clearFeelings()
        #expect(model.state.feelings.isEmpty)
        #expect(model.state.roomItems == [.lamp])
    }
}
