import Foundation
import Testing

@testable import AppCore

@Suite("Rewards, day plan and journey")
struct RewardsAndPlanTests {
    @Test func offersTheNextThreeItemsInAFixedOrder() {
        #expect(RewardCatalog.offer(owned: []) == [.lamp, .rug, .cactus])
        #expect(RewardCatalog.offer(owned: [.rug]) == [.lamp, .cactus, .armchair])
    }

    @Test func neverOffersAnItemTheChildHas() {
        let owned: [RoomItem] = [.lamp, .cactus, .books]
        #expect(Set(RewardCatalog.offer(owned: owned)).isDisjoint(with: owned))
    }

    @Test func offersFewerWhenFewAreLeftAndNoneWhenAllAreOwned() {
        let almostAll = Array(RewardCatalog.order.dropLast())
        #expect(RewardCatalog.offer(owned: almostAll) == [.bed])
        #expect(RewardCatalog.offer(owned: RewardCatalog.order).isEmpty)
    }

    @Test func everyRoomItemAndFeelingHasAPicture() {
        let images = Fixtures.appResources.appendingPathComponent("Images")
        let pictograms = Fixtures.appResources.appendingPathComponent("Pictograms")
        for item in RoomItem.allCases {
            let file = images.appendingPathComponent("\(item.imageName).png")
            #expect(FileManager.default.fileExists(atPath: file.path), "Missing \(file.lastPathComponent)")
        }
        for name in Feeling.allCases.map(\.imageName) + NeedCard.allCases.map(\.imageName) {
            let file = pictograms.appendingPathComponent("\(name).png")
            #expect(FileManager.default.fileExists(atPath: file.path), "Missing \(file.lastPathComponent)")
        }
    }

    @Test func dayPlanMovesFromNowToNext() throws {
        var plan = try #require(DayPlan(story: Fixtures.withPractice))
        #expect(plan.now?.id == "a")
        #expect(plan.next?.id == "b")
        #expect(plan.state(of: 0) == .now)
        plan.advance()
        #expect(plan.state(of: 0) == .done)
        #expect(plan.state(of: 1) == .now)
        plan.advance()
        plan.advance()
        #expect(plan.isFinished)
        #expect(plan.now == nil)
        plan.goBack()  // from "all done" back to the last step
        #expect(plan.now?.id == "c")
    }

    @Test func noDayPlanFromAStoryWithoutSteps() {
        #expect(DayPlan(story: Fixtures.dentist) == nil)
    }

    @Test func journeySkipsWhatHasNothingToOffer() {
        let withPractice = Fixtures.withPractice
        let without = Fixtures.dentist
        #expect(ChildJourney.step(after: .story, story: withPractice, rewardsLeft: true) == .practice)
        #expect(ChildJourney.step(after: .story, story: without, rewardsLeft: true) == .reward)
        #expect(ChildJourney.step(after: .story, story: without, rewardsLeft: false) == .feelings)
        #expect(ChildJourney.step(after: .practice, story: withPractice, rewardsLeft: true) == .reward)
        #expect(ChildJourney.step(after: .reward, story: withPractice, rewardsLeft: true) == .feelings)
        #expect(ChildJourney.step(after: .feelings, story: withPractice, rewardsLeft: true) == .home)
    }
}

@MainActor
@Suite("Saved progress")
struct ProgressModelTests {
    private let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func startsWithCalmDefaults() {
        let model = ProgressModel(store: InMemoryProgressStore())
        #expect(model.settings.soundsEnabled == false)
        #expect(model.settings.narrationSpeed == .calm)
        #expect(model.state.roomItems.isEmpty)
        #expect(model.rewardOffer == [.lamp, .rug, .cactus])
    }

    @Test func savesAfterEveryChange() {
        let store = InMemoryProgressStore()
        let model = ProgressModel(store: store, now: { self.fixedDate })
        model.place(.lamp)
        model.place(.lamp)  // placing twice keeps one
        model.logFeeling(.okay, for: Fixtures.dentist)
        model.setCalmTools([.sunglasses, .headphones])
        model.updateSettings { $0.soundsEnabled = true }
        #expect(store.stored?.roomItems == [.lamp])
        #expect(
            store.stored?.feelings == [
                FeelingEntry(storyID: "dentist", storyTitle: "Going to the dentist", feeling: .okay, date: fixedDate)
            ])
        #expect(store.stored?.calmTools == [.headphones, .sunglasses])  // in catalogue order
        #expect(store.stored?.settings.soundsEnabled == true)
    }

    @Test func keepsOnlyTheMostRecentCheckIns() {
        let model = ProgressModel(store: InMemoryProgressStore())
        for _ in 0..<(ProgressModel.feelingsLimit + 5) {
            model.logFeeling(.calm, for: Fixtures.dentist)
        }
        #expect(model.state.feelings.count == ProgressModel.feelingsLimit)
    }

    @Test func reportsAFailedSaveWithoutLosingTheChange() {
        let store = InMemoryProgressStore()
        store.failSaves = true
        let model = ProgressModel(store: store)
        model.place(.rug)
        #expect(model.lastSaveFailed)
        #expect(model.state.roomItems == [.rug])
    }

    @Test func deleteAllDataResetsEverything() {
        let store = InMemoryProgressStore()
        let model = ProgressModel(store: store)
        model.place(.rug)
        model.updateSettings { $0.childName = "Rafi" }
        model.deleteAllData()
        #expect(model.state == ProgressState())
        #expect(store.stored == ProgressState())
    }

    @Test func dayPlanAdvancesAndIsSaved() throws {
        let store = InMemoryProgressStore()
        let model = ProgressModel(store: store)
        model.setDayPlan(DayPlan(story: Fixtures.withPractice))
        model.advanceDayPlan()
        #expect(store.stored?.dayPlan?.now?.id == "b")
    }
}

@MainActor
@Suite("Progress file")
struct JSONFileProgressStoreTests {
    private func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("peek-ahead-tests-\(UUID().uuidString)")
            .appendingPathComponent("progress.json")
    }

    @Test func roundTripsThroughAFile() throws {
        let url = temporaryFile()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = JSONFileProgressStore(fileURL: url)
        let model = ProgressModel(store: store)
        model.place(.cactus)
        model.logFeeling(.unsure, for: Fixtures.dentist)
        model.setDayPlan(DayPlan(story: Fixtures.withPractice))

        let reloaded = ProgressModel(store: JSONFileProgressStore(fileURL: url))
        #expect(reloaded.state == model.state)
        #expect(!reloaded.startedFresh)
    }

    @Test func noFileMeansAFreshStart() throws {
        let store = JSONFileProgressStore(fileURL: temporaryFile())
        #expect(try store.load() == nil)
    }

    @Test func anUnreadableFileIsSetAsideNotDeleted() throws {
        let url = temporaryFile()
        let folder = url.deletingLastPathComponent()
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: url)

        let model = ProgressModel(store: JSONFileProgressStore(fileURL: url))
        #expect(model.startedFresh)
        #expect(model.state == ProgressState())
        let files = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        #expect(files.contains { $0.hasPrefix("progress.unreadable-") })
    }

    @Test func aFileFromANewerVersionIsNeverOverwritten() throws {
        let url = temporaryFile()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let newer = Data(#"{ "version": 99, "roomItems": ["bed"] }"#.utf8)
        try newer.write(to: url)

        let model = ProgressModel(store: JSONFileProgressStore(fileURL: url))
        model.place(.lamp)
        #expect(model.startedFresh)
        #expect(model.lastSaveFailed)
        #expect(try Data(contentsOf: url) == newer)
    }

    @Test func olderFilesWithMissingKeysStillLoad() throws {
        let url = temporaryFile()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"{ "version": 1, "roomItems": ["rug"], "settings": { "soundsEnabled": true } }"#.utf8).write(to: url)

        let state = try #require(try JSONFileProgressStore(fileURL: url).load())
        #expect(state.roomItems == [.rug])
        #expect(state.settings.soundsEnabled)
        #expect(state.settings.previewVolumeLimit == AppSettings().previewVolumeLimit)
    }
}
