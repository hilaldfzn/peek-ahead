import Foundation
import Testing

@testable import AppCore

/// A drafter that returns or throws whatever the test sets.
private struct StubDrafter: StoryDrafting {
    let result: @Sendable () throws -> Story

    func draft(_ request: DraftRequest) async throws -> Story {
        try result()
    }
}

private struct SomeModelError: Error {}

@Suite("Drafting with fallback")
struct DraftingCoordinatorTests {
    private let request = DraftRequest(event: .familyVisit, details: "fireworks", language: .indonesian)
    private let templates = TemplateDrafter(makeID: { "story-new" })

    private func modelStory(_ sentences: [String], title: String = "Lebaran") -> Story {
        Story(
            id: "model-chosen-id", title: title, language: "en-US", review: .reviewed,
            pages: sentences.enumerated().map { index, sentence in
                StoryPage(
                    id: "same", sentence: sentence, sometimesNote: "  ", scene: .familyVisit,
                    kind: index == sentences.count - 1 ? .endsWell : .describes, photoID: "smuggled"
                )
            }
        )
    }

    @Test func usesTheModelDraftAfterCleaningIt() async {
        let model = StubDrafter {
            modelStory(["  Kami ke rumah Nenek. ", "Ada banyak sepupu.", "", "Lalu kami pulang."])
        }
        let outcome = await DraftingCoordinator(model: model, templates: templates).outcome(for: request)
        let story = outcome.story
        #expect(outcome.fallbackReason == nil)
        #expect(story.draftSource == .onDeviceModel)
        #expect(story.review == .placeholder)  // the model can't mark its own work as reviewed
        #expect(story.id == "story-new")
        #expect(story.language == "id-ID")
        #expect(story.pages.map(\.id) == ["p1", "p2", "p3"])
        #expect(story.pages.first?.sentence == "Kami ke rumah Nenek.")
        #expect(story.pages.allSatisfy { $0.sometimesNote == nil && $0.photoID == nil })
        #expect(story.practice?.sounds.map(\.sound) == [.fireworks])  // practice comes from the template
    }

    @Test func fallsBackWhenThereIsNoModel() async {
        let outcome = await DraftingCoordinator(model: nil, templates: templates).outcome(for: request)
        #expect(outcome.fallbackReason == .noModel)
        #expect(outcome.story.draftSource == .template)
    }

    @Test func fallsBackWhenTheModelIsUnavailable() async {
        let model = StubDrafter { throw DraftingError.modelUnavailable }
        let outcome = await DraftingCoordinator(model: model, templates: templates).outcome(for: request)
        #expect(outcome.fallbackReason == .modelUnavailable)
        #expect(outcome.story.title == "Lebaran di rumah Nenek")
    }

    @Test func fallsBackWhenTheModelFailsOrRefuses() async {
        let model = StubDrafter { throw SomeModelError() }
        let outcome = await DraftingCoordinator(model: model, templates: templates).outcome(for: request)
        #expect(outcome.fallbackReason == .modelFailed)
        #expect(outcome.story.draftSource == .template)
    }

    @Test func fallsBackWhenTheDraftIsTooShort() async {
        let model = StubDrafter { modelStory(["Hi.", "  "]) }
        let outcome = await DraftingCoordinator(model: model, templates: templates).outcome(for: request)
        #expect(outcome.fallbackReason == .unusableDraft)
    }

    @Test func capsVeryLongDrafts() async {
        let model = StubDrafter { modelStory((1...20).map { "Line \($0)." }) }
        let outcome = await DraftingCoordinator(model: model, templates: templates).outcome(for: request)
        #expect(outcome.story.pages.count == DraftingCoordinator.pageRange.upperBound)
    }

    @Test func keepsTheTemplateTitleWhenTheModelGivesNone() async {
        let model = StubDrafter { modelStory(["A.", "B.", "C."], title: "  ") }
        let outcome = await DraftingCoordinator(model: model, templates: templates).outcome(for: request)
        #expect(outcome.story.title == "Lebaran di rumah Nenek")
    }
}

@MainActor
@Suite("Page photos")
struct PagePhotoTests {
    @Test func olderPagesHaveNoPhoto() throws {
        let json = #"{ "id": "p", "sentence": "Hi.", "sometimesNote": null, "scene": "big_chair" }"#
        let page = try JSONDecoder().decode(StoryPage.self, from: Data(json.utf8))
        #expect(page.photoID == nil)
    }

    @Test func editorSetsAndRemovesPhotos() {
        let editor = StoryEditorModel(story: Fixtures.dentist)
        editor.setPhoto("photo-1", page: "p2")
        #expect(editor.story.pages[1].photoID == "photo-1")
        editor.setPhoto(nil, page: "p2")
        #expect(editor.story.pages[1].photoID == nil)
    }

    @Test func knowsWhichPhotosAreStillUsed() throws {
        let model = ProgressModel(store: InMemoryProgressStore())
        var story = Fixtures.withPractice
        story.pages[0].photoID = "keep"
        try model.saveUserStory(story, bundled: [])
        #expect(model.state.referencedPhotoIDs == ["keep"])
        model.deleteUserStory(id: story.id)
        #expect(model.state.referencedPhotoIDs.isEmpty)
    }
}
