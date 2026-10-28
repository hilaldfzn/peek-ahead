import Foundation

/// A source of stories. The app reads bundled JSON files; tests and previews use ``InMemoryStoryProvider``.
protocol StoryProviding: Sendable {
    func loadStories() throws -> [Story]
}

/// Decodes and validates one story from JSON.
struct StoryDecoder: Sendable {
    func decode(_ data: Data) throws(StoryContentError) -> Story {
        let story: Story
        do {
            story = try JSONDecoder().decode(Story.self, from: data)
        } catch {
            throw .malformed(details: String(describing: error))
        }
        try StoryValidator.validate(story)
        return story
    }
}

/// Loads stories from JSON files, for example the ones bundled with the app.
struct FileStoryProvider: StoryProviding {
    let fileURLs: [URL]
    private let decoder = StoryDecoder()

    init(fileURLs: [URL]) {
        // Sorted so the story order is the same on every launch and device.
        self.fileURLs = fileURLs.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    func loadStories() throws -> [Story] {
        let stories = try fileURLs.map { url in
            guard let data = try? Data(contentsOf: url) else {
                throw StoryContentError.unreadable(file: url.lastPathComponent)
            }
            return try decoder.decode(data)
        }
        try StoryValidator.validateLibrary(stories)
        return stories
    }
}

/// A fixed list of stories, for previews and tests.
struct InMemoryStoryProvider: StoryProviding {
    let stories: [Story]

    func loadStories() throws -> [Story] {
        try StoryValidator.validateLibrary(stories)
        return stories
    }
}
