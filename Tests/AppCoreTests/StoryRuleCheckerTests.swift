import Foundation
import Testing

@testable import AppCore

@Suite("Story rule checker")
struct StoryRuleCheckerTests {
    private func page(_ sentence: String, kind: PageKind = .describes, id: String = "p") -> StoryPage {
        StoryPage(id: id, sentence: sentence, sometimesNote: nil, scene: .waitingRoom, kind: kind)
    }

    private func rules(_ sentence: String, language: String = "en-US") -> [RuleFinding.Rule] {
        StoryRuleChecker.check(page(sentence), language: language).map(\.rule)
    }

    @Test(arguments: ["Don't run around when it is loud.", "Don\u{2019}t cry.", "You must sit still.", "Never shout."])
    func flagsDirectivesInEnglish(sentence: String) {
        #expect(rules(sentence).contains(.directive))
    }

    @Test(arguments: ["Jangan berlari.", "Kamu tidak boleh menangis.", "Aku harus duduk diam."])
    func flagsDirectivesInIndonesian(sentence: String) {
        #expect(rules(sentence, language: "id-ID").contains(.directive))
    }

    @Test func flagsPromises() {
        #expect(rules("The dentist will be kind.") == [.absolute])
        #expect(rules("There is always cake.") == [.absolute])
        #expect(rules("Pasti ada kue.", language: "id-ID") == [.absolute])
    }

    @Test func flagsIdioms() {
        #expect(rules("It is a piece of cake.") == [.idiom])
        #expect(rules("Jangan kepala batu.", language: "id-ID").contains(.idiom))
    }

    @Test func flagsLongSentencesButCountsEachSentence() {
        #expect(rules("I walk into the big room and sit on the chair next to my mum today.") == [.length])
        // Two short sentences of 6 words each are fine.
        #expect(rules("I wait in the waiting room. I can hold my favourite toy.").isEmpty)
    }

    @Test func matchesWholeWordsOnly() {
        #expect(rules("Willow trees grow near the school.").isEmpty)  // "will" inside "Willow"
        #expect(rules("The bus stops near the school.").isEmpty)  // "stops" is not "stop"
    }

    @Test func passesShortLiteralSentences() {
        #expect(rules("The dentist has a big chair that goes back.").isEmpty)
        #expect(rules("Dokter gigi punya kursi besar.", language: "id-ID").isEmpty)
    }

    @Test func checksTheDescribingToICanRatio() {
        let tooManyICan = Story(
            id: "s", title: "S", language: "en-US", review: .placeholder,
            pages: [
                page("I go out.", id: "a"), page("I can wave.", kind: .iCan, id: "b"),
                page("Then I go home.", kind: .endsWell, id: "c"),
            ]
        )
        #expect(StoryRuleChecker.check(tooManyICan).map(\.rule) == [.ratio])
    }

    @Test func asksForAGoodEnding() {
        let story = Story(
            id: "s", title: "S", language: "en-US", review: .placeholder,
            pages: [page("I go out.", id: "a")]
        )
        let finding = StoryRuleChecker.check(story).first
        #expect(finding?.rule == .ending)
        #expect(finding?.pageID == nil)
        #expect(finding?.severity == .consider)
    }

    @Test func bundledStoriesNeedNoChanges() throws {
        let folder = Fixtures.appResources.appendingPathComponent("Stories")
        let files = try FileManager.default.contentsOfDirectory(atPath: folder.path)
            .filter { $0.hasPrefix("story-") }
            .map { folder.appendingPathComponent($0) }
        for story in try FileStoryProvider(fileURLs: files).loadStories() {
            let changes = StoryRuleChecker.check(story).filter { $0.severity == .change }
            #expect(changes.isEmpty, "\(story.id): \(changes)")
        }
    }
}

@Suite("Template drafter")
struct TemplateDrafterTests {
    private let drafter = TemplateDrafter(makeID: { "story-test" })

    @Test(arguments: EventKind.allCases, StoryLanguage.allCases)
    func everyTemplateFollowsItsOwnRules(event: EventKind, language: StoryLanguage) throws {
        let story = drafter.makeStory(DraftRequest(event: event, details: "", language: language))
        try StoryValidator.validate(story)
        #expect(StoryRuleChecker.check(story).isEmpty, "\(event) \(language): \(StoryRuleChecker.check(story))")
        #expect(story.review == .placeholder)
        #expect(story.draftSource == .template)
        #expect(story.language == language.rawValue)
    }

    @Test(arguments: StoryLanguage.allCases)
    func extrasFromTheDetailsStillFollowTheRules(language: StoryLanguage) throws {
        let details = "Ramai, berisik, loud and busy, fireworks and kembang api at night"
        for event in EventKind.allCases {
            let story = drafter.makeStory(DraftRequest(event: event, details: details, language: language))
            #expect(StoryRuleChecker.check(story).isEmpty, "\(event) \(language): \(StoryRuleChecker.check(story))")
        }
    }

    @Test func fireworksInTheDetailsAddPagesAndASound() {
        let plain = drafter.makeStory(DraftRequest(event: .familyVisit, details: "", language: .english))
        let withFireworks = drafter.makeStory(
            DraftRequest(event: .familyVisit, details: "Lots of cousins. Fireworks at night!", language: .english)
        )
        #expect(withFireworks.pages.count == plain.pages.count + 2)
        #expect(withFireworks.practice?.sounds.map(\.sound) == [.fireworks])
        #expect(withFireworks.pages.last?.kind == .endsWell)
    }

    @Test func indonesianKeywordsWork() {
        let story = drafter.makeStory(
            DraftRequest(event: .familyVisit, details: "Ada kembang api", language: .indonesian)
        )
        #expect(story.practice?.sounds.map(\.sound) == [.fireworks])
        #expect(story.title == "Lebaran di rumah Nenek")
    }

    @Test func pageIDsAreUnique() {
        let story = drafter.makeStory(DraftRequest(event: .dentist, details: "loud", language: .english))
        #expect(Set(story.pages.map(\.id)).count == story.pages.count)
    }
}
