import Foundation
import Testing

@testable import AppCore

@Suite("Practice content")
struct PracticeContentTests {
    @Test func olderStoryFilesStillLoad() throws {
        let json = """
            { "id": "old", "title": "Old", "language": "en-US", "review": "placeholder",
              "pages": [ { "id": "p1", "sentence": "I go.", "sometimesNote": null, "scene": "big_chair" } ] }
            """
        let story = try StoryDecoder().decode(Data(json.utf8))
        #expect(story.pages[0].kind == .describes)
        #expect(story.practice == nil)
    }

    @Test func decodesPracticeAndPageKinds() throws {
        let json = """
            { "id": "p", "title": "P", "language": "en-US", "review": "placeholder",
              "pages": [ { "id": "p1", "sentence": "Then I go home.", "scene": "pip_room", "kind": "ends_well" } ],
              "practice": {
                "steps": [ { "id": "a", "label": "A", "pictogram": "step_car" },
                           { "id": "b", "label": "B", "pictogram": "step_home" } ],
                "sounds": [ { "sound": "fire_alarm", "label": "The alarm" } ],
                "calmTools": [ "headphones", "ask_help" ]
              } }
            """
        let story = try StoryDecoder().decode(Data(json.utf8))
        #expect(story.pages[0].kind == .endsWell)
        #expect(story.practice?.activities == [.orderSteps, .soundPreview, .calmTools])
        #expect(story.practice?.calmTools == [.headphones, .askForHelp])
    }

    @Test func offersOnlyActivitiesWithContent() throws {
        let practice = StoryPractice(steps: [PracticeStep(id: "a", label: "A", pictogram: .car)], calmTools: [.breathe])
        #expect(practice.activities == [.calmTools])  // one step is not a game
    }

    @Test func rejectsDuplicateStepIDs() {
        let step = PracticeStep(id: "a", label: "A", pictogram: .car)
        let story = Story(
            id: "s", title: "S", language: "en-US", review: .placeholder,
            pages: [Fixtures.page("p1", "Hi.")], practice: StoryPractice(steps: [step, step])
        )
        #expect(throws: StoryContentError.duplicateStepID(storyID: "s", stepID: "a")) {
            try StoryValidator.validate(story)
        }
    }

    @Test func onlyTheFireAlarmIsCapped() {
        for sound in PreviewSound.allCases {
            #expect(sound.volumeCap == (sound == .fireAlarm ? 0.4 : 1.0))
        }
    }

    @Test func everySoundHasAFile() {
        let folder = Fixtures.appResources.appendingPathComponent("Sounds")
        for sound in PreviewSound.allCases {
            let file = folder.appendingPathComponent("\(sound.fileName).m4a")
            #expect(FileManager.default.fileExists(atPath: file.path), "Missing \(file.lastPathComponent)")
        }
    }

    @Test func everyPictogramHasAnImage() {
        let folder = Fixtures.appResources.appendingPathComponent("Pictograms")
        let names = Pictogram.allCases.map(\.imageName) + CalmTool.allCases.map(\.imageName)
        for name in names {
            let file = folder.appendingPathComponent("\(name).png")
            #expect(FileManager.default.fileExists(atPath: file.path), "Missing \(file.lastPathComponent)")
        }
    }
}
