import Testing

@testable import AppCore

@MainActor
@Suite("Story player")
struct StoryPlayerModelTests {
    private let narrator = ScriptedNarrator()

    private func makeModel() -> StoryPlayerModel {
        StoryPlayerModel(story: Fixtures.dentist, narrator: narrator)
    }

    @Test func startsOnTheFirstPage() {
        let model = makeModel()
        #expect(model.pageIndex == 0)
        #expect(!model.canGoBack)
        #expect(!model.isLastPage)
        #expect(model.words.first?.text == "Today")
    }

    @Test func pagesForwardAndBackWithinBounds() {
        let model = makeModel()
        model.goToPreviousPage()
        #expect(model.pageIndex == 0)

        model.goToNextPage()
        model.goToNextPage()
        #expect(model.isLastPage)
        model.goToNextPage()
        #expect(model.pageIndex == 2)

        model.goToPreviousPage()
        #expect(model.pageIndex == 1)
        #expect(model.words.map(\.text) == ["The", "dentist", "has", "a", "big", "chair"])
    }

    @Test func neverReadsAloudUntilAsked() {
        let model = makeModel()
        model.goToNextPage()
        #expect(narrator.spokenTexts.isEmpty)
        #expect(!model.isNarrating)
    }

    @Test func highlightsTheWordBeingSpoken() async {
        let model = makeModel()
        model.goToNextPage()
        model.readAloud()
        #expect(narrator.spokenTexts == ["The dentist has a big chair."])

        narrator.send(.started)
        #expect(await waitUntil { model.isNarrating })

        narrator.send(.willSpeak(utf16Range: 18..<21))
        #expect(await waitUntil { model.highlightedWordIndex == 4 })
    }

    @Test func clearsTheHighlightWhenNarrationFinishes() async {
        let model = makeModel()
        let task = model.readAloud()
        narrator.send(.started)
        narrator.send(.willSpeak(utf16Range: 0..<5))
        narrator.finish()
        await task.value
        #expect(!model.isNarrating)
        #expect(model.highlightedWordIndex == nil)
    }

    @Test func changingPageStopsNarration() async {
        let model = makeModel()
        model.readAloud()
        narrator.send(.started)
        #expect(await waitUntil { model.isNarrating })

        model.goToNextPage()
        #expect(narrator.stopCount >= 1)
        #expect(!model.isNarrating)
        #expect(model.highlightedWordIndex == nil)
    }

    @Test func eventsFromAnEarlierNarrationAreIgnored() async {
        let model = makeModel()
        model.readAloud()
        narrator.send(.started)
        #expect(await waitUntil { model.isNarrating })

        // Reading again cancels the first narration; its late "cancelled" must not stop the second one.
        model.readAloud()
        narrator.send(.started)
        narrator.send(.willSpeak(utf16Range: 6..<8))
        #expect(await waitUntil { model.highlightedWordIndex == 1 })
        #expect(model.isNarrating)
    }
}

@Suite("Pip motion")
struct PipMotionTests {
    @Test func staysStillWithReduceMotion() {
        #expect(PipMotion.forSettings(reduceMotion: true) == nil)
    }

    @Test func movesCalmlyOtherwise() throws {
        let motion = try #require(PipMotion.forSettings(reduceMotion: false))
        #expect(motion.bobHeight <= 0.05)
        #expect(motion.bobPeriod >= 2)
        #expect(motion.waveCount <= 3)
    }
}
