import Foundation

/// A problem found while reading or checking story content.
enum StoryContentError: Error, Equatable, Sendable {
    case unreadable(file: String)
    case malformed(details: String)
    case missingID
    case noPages(storyID: String)
    case duplicatePageID(storyID: String, pageID: String)
    case emptySentence(storyID: String, pageID: String)
    case duplicateStoryID(String)
}

/// Structural checks every story must pass before the app shows it.
///
/// These checks are about data integrity only. Checks on wording (first person, "sometimes", no "don't…")
/// belong to the story rule checker, which is planned for the grown-up editor.
enum StoryValidator {
    static func validate(_ story: Story) throws(StoryContentError) {
        guard !story.id.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw .missingID
        }
        guard !story.pages.isEmpty else {
            throw .noPages(storyID: story.id)
        }
        var seen = Set<String>()
        for page in story.pages {
            guard seen.insert(page.id).inserted else {
                throw .duplicatePageID(storyID: story.id, pageID: page.id)
            }
            guard !page.sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw .emptySentence(storyID: story.id, pageID: page.id)
            }
        }
    }

    static func validateLibrary(_ stories: [Story]) throws(StoryContentError) {
        var seen = Set<String>()
        for story in stories {
            try validate(story)
            guard seen.insert(story.id).inserted else {
                throw .duplicateStoryID(story.id)
            }
        }
    }
}
