import Foundation

/// Practice that follows a story. Every part is optional, and the child can always skip it.
struct StoryPractice: Hashable, Codable, Sendable {
    /// The event's steps in the right order, for "Put the steps in order".
    let steps: [PracticeStep]
    /// Sounds the child may hear there, previewed quietly first.
    let sounds: [SoundCue]
    /// Calm tools to offer for this event.
    let calmTools: [CalmTool]

    init(steps: [PracticeStep] = [], sounds: [SoundCue] = [], calmTools: [CalmTool] = []) {
        self.steps = steps
        self.sounds = sounds
        self.calmTools = calmTools
    }

    private enum CodingKeys: String, CodingKey {
        case steps, sounds, calmTools
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        steps = try container.decodeIfPresent([PracticeStep].self, forKey: .steps) ?? []
        sounds = try container.decodeIfPresent([SoundCue].self, forKey: .sounds) ?? []
        calmTools = try container.decodeIfPresent([CalmTool].self, forKey: .calmTools) ?? []
    }

    /// The activities this practice can offer, in the order the child sees them.
    var activities: [PracticeActivity] {
        var result: [PracticeActivity] = []
        if steps.count >= 2 { result.append(.orderSteps) }
        if !sounds.isEmpty { result.append(.soundPreview) }
        if !calmTools.isEmpty { result.append(.calmTools) }
        return result
    }
}

enum PracticeActivity: String, Hashable, Sendable, CaseIterable, Identifiable {
    case orderSteps
    case soundPreview
    case calmTools

    var id: String { rawValue }
}

/// One step of the real event, shown as a card with a pictogram and a short label.
struct PracticeStep: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let label: String
    let pictogram: Pictogram
}

/// Original schedule pictograms (`Resources/Pictograms/step_*.png`).
enum Pictogram: String, Codable, Sendable, CaseIterable {
    case waiting = "step_waiting"
    case breakfast = "step_breakfast"
    case book = "step_book"
    case car = "step_car"
    case dentist = "step_dentist"
    case home = "step_home"

    var imageName: String { rawValue }
}

/// A sound the child may hear at the event, with a friendly name ("The little brush (it buzzes)").
struct SoundCue: Identifiable, Hashable, Codable, Sendable {
    let sound: PreviewSound
    let label: String

    var id: String { sound.rawValue }
}

/// The original 5-second preview loops in `Resources/Sounds`.
enum PreviewSound: String, Codable, Sendable, CaseIterable {
    case hairClipper = "hair_clipper"
    case dentistDrill = "dentist_drill"
    case suction
    case handDryer = "hand_dryer"
    case schoolBell = "school_bell"
    case fireAlarm = "fire_alarm"
    case bedugDrum = "bedug_drum"
    case fireworks
    case thunderRain = "thunder_rain"

    var fileName: String { rawValue }

    /// The loudest this sound may ever play, as a share of full volume. The fire alarm is capped at 0.4.
    var volumeCap: Double { self == .fireAlarm ? 0.4 : 1.0 }
}

/// Calm tools a child can choose before an event (`Resources/Pictograms/tool_*.png`).
enum CalmTool: String, Codable, Sendable, CaseIterable, Identifiable {
    case headphones
    case sunglasses
    case squishy
    case breathe
    case quietCorner = "quiet_corner"
    case breakCard = "break_card"
    case askForHelp = "ask_help"
    case holdHand = "hold_hand"

    var id: String { rawValue }
    var imageName: String { "tool_\(rawValue)" }
}
