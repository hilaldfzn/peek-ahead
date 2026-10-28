import Foundation
import Observation

/// State and actions for reading one story, page by page.
///
/// The model never reads aloud on its own: narration starts only when the child taps Read, and it stops
/// whenever the page changes, so the screen always matches what the child hears.
@MainActor
@Observable
final class StoryPlayerModel {
    let story: Story
    private(set) var pageIndex = 0
    private(set) var words: [SpokenWord]
    private(set) var highlightedWordIndex: Int?
    private(set) var isNarrating = false

    @ObservationIgnored private let narrator: any Narrating
    @ObservationIgnored private var narrationTask: Task<Void, Never>?
    /// Increases whenever narration starts or stops, so late events from an older narration are ignored.
    @ObservationIgnored private var narrationGeneration = 0

    init(story: Story, narrator: any Narrating) {
        precondition(!story.pages.isEmpty, "Stories are validated before they reach the player")
        self.story = story
        self.narrator = narrator
        self.words = WordSegmenter.words(in: story.pages[0].sentence)
    }

    var page: StoryPage { story.pages[pageIndex] }
    var pageCount: Int { story.pages.count }
    var canGoBack: Bool { pageIndex > 0 }
    var isLastPage: Bool { pageIndex == story.pages.count - 1 }

    func goToNextPage() {
        guard !isLastPage else { return }
        show(pageIndex + 1)
    }

    func goToPreviousPage() {
        guard canGoBack else { return }
        show(pageIndex - 1)
    }

    /// Reads the current page aloud. The returned task ends when the narration ends; the view can ignore it.
    @discardableResult
    func readAloud() -> Task<Void, Never> {
        stopReading()
        let generation = narrationGeneration
        let stream = narrator.narrate(page.sentence, language: story.language)
        let task = Task { [weak self] in
            for await event in stream {
                guard let self, self.narrationGeneration == generation else { return }
                self.handle(event)
            }
            guard let self, self.narrationGeneration == generation else { return }
            self.isNarrating = false
            self.highlightedWordIndex = nil
        }
        narrationTask = task
        return task
    }

    func stopReading() {
        narrationGeneration += 1
        narrationTask?.cancel()
        narrationTask = nil
        narrator.stop()
        isNarrating = false
        highlightedWordIndex = nil
    }

    private func show(_ index: Int) {
        stopReading()
        pageIndex = index
        words = WordSegmenter.words(in: page.sentence)
    }

    private func handle(_ event: NarrationEvent) {
        switch event {
        case .started:
            isNarrating = true
        case .willSpeak(let range):
            highlightedWordIndex = words.indexOfWord(overlapping: range)
        case .finished, .cancelled:
            isNarrating = false
            highlightedWordIndex = nil
        }
    }
}
