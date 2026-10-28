import Foundation
import Observation

/// Editing one story in grown-up mode. Every change re-runs the rule checker, so the chips under each sentence are
/// always current. Nothing is saved until the grown-up taps Save.
@MainActor
@Observable
final class StoryEditorModel {
    private(set) var story: Story
    private(set) var findings: [RuleFinding]
    private(set) var hasChanges = false

    @ObservationIgnored private let makePageID: () -> String

    init(story: Story, makePageID: @escaping () -> String = { "p-\(UUID().uuidString.prefix(8).lowercased())" }) {
        self.story = story
        self.makePageID = makePageID
        findings = StoryRuleChecker.check(story)
    }

    /// A copy of a bundled story that the grown-up can change and save as their own.
    static func copy(of story: Story, newID: String) -> Story {
        var copy = story
        copy.id = newID
        copy.review = .placeholder
        return copy
    }

    func findings(forPage pageID: String) -> [RuleFinding] {
        findings.filter { $0.pageID == pageID }
    }

    var storyFindings: [RuleFinding] {
        findings.filter { $0.pageID == nil }
    }

    func setTitle(_ title: String) {
        change { $0.title = title }
    }

    func setSentence(_ sentence: String, page pageID: String) {
        changePage(pageID) { $0.sentence = sentence }
    }

    func setNote(_ note: String, page pageID: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        changePage(pageID) { $0.sometimesNote = trimmed.isEmpty ? nil : note }
    }

    func setKind(_ kind: PageKind, page pageID: String) {
        changePage(pageID) { $0.kind = kind }
    }

    func setScene(_ scene: StoryScene, page pageID: String) {
        changePage(pageID) { $0.scene = scene }
    }

    /// Shows a grown-up's photo on the page instead of the scene, or removes it with `nil`.
    func setPhoto(_ photoID: String?, page pageID: String) {
        changePage(pageID) { $0.photoID = photoID }
    }

    /// Adds an empty describing page after `pageID` (or at the end), reusing that page's scene.
    @discardableResult
    func addPage(after pageID: String? = nil) -> String {
        let id = makePageID()
        change { story in
            let index = pageID.flatMap { id in story.pages.firstIndex { $0.id == id } }
            let scene = index.map { story.pages[$0].scene } ?? story.pages.last?.scene ?? .waitingRoom
            let page = StoryPage(id: id, sentence: "", sometimesNote: nil, scene: scene, kind: .describes)
            story.pages.insert(page, at: index.map { $0 + 1 } ?? story.pages.endIndex)
        }
        return id
    }

    func deletePages(at offsets: IndexSet) {
        change { story in
            for index in offsets.sorted(by: >) where story.pages.indices.contains(index) {
                story.pages.remove(at: index)
            }
        }
    }

    func movePages(from source: IndexSet, to destination: Int) {
        change { story in
            let moving = source.sorted().map { story.pages[$0] }
            for index in source.sorted(by: >) { story.pages.remove(at: index) }
            let insertAt = destination - source.filter { $0 < destination }.count
            story.pages.insert(contentsOf: moving, at: min(max(insertAt, 0), story.pages.count))
        }
    }

    /// The story as it should be saved: blank pages dropped. The grown-up has seen every page, so the draft badge
    /// goes; the expert review status is unchanged.
    func storyForSaving() -> Story {
        var result = story
        result.pages.removeAll { $0.sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        result.draftSource = nil
        return result
    }

    func markSaved() {
        hasChanges = false
    }

    private func changePage(_ pageID: String, _ update: (inout StoryPage) -> Void) {
        change { story in
            guard let index = story.pages.firstIndex(where: { $0.id == pageID }) else { return }
            update(&story.pages[index])
        }
    }

    private func change(_ update: (inout Story) -> Void) {
        update(&story)
        findings = StoryRuleChecker.check(story)
        hasChanges = true
    }
}
