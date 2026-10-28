import Foundation

/// Grown-up settings: the child's sensory profile. Defaults follow DESIGN.md's sensory rules.
struct AppSettings: Codable, Equatable, Sendable {
    /// Sound previews stay off until a grown-up turns them on.
    var soundsEnabled = false
    /// Ceiling for preview volume, from 0 to 1.
    var previewVolumeLimit = 0.7
    var narrationSpeed: NarrationSpeed = .calm
    /// Optional, used only on Home ("Hi, Rafi!"). Never required, never leaves the device.
    var childName: String?

    init() {}

    private enum CodingKeys: String, CodingKey {
        case soundsEnabled, previewVolumeLimit, narrationSpeed, childName
    }

    // Every key is optional, so settings saved by an older version still load, with defaults for new keys.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings()
        soundsEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundsEnabled) ?? defaults.soundsEnabled
        previewVolumeLimit =
            try container.decodeIfPresent(Double.self, forKey: .previewVolumeLimit) ?? defaults.previewVolumeLimit
        narrationSpeed =
            try container.decodeIfPresent(NarrationSpeed.self, forKey: .narrationSpeed) ?? defaults.narrationSpeed
        childName = try container.decodeIfPresent(String.self, forKey: .childName)
    }
}

enum NarrationSpeed: String, Codable, Sendable, CaseIterable {
    /// 0.9× the system rate (DESIGN.md default).
    case calm
    /// 0.75×, for children who need more time per word.
    case slower

    var rateFactor: Float {
        switch self {
        case .calm: 0.9
        case .slower: 0.75
        }
    }
}
