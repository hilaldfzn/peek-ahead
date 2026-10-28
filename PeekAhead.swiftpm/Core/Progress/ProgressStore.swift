import Foundation

/// Everything the app remembers between launches. It stays on the device; nothing is uploaded.
struct ProgressState: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var version = ProgressState.currentVersion
    var roomItems: [RoomItem] = []
    var feelings: [FeelingEntry] = []
    var calmTools: [CalmTool] = []
    var dayPlan: DayPlan?
    var settings = AppSettings()
    /// Stories a grown-up made or copied on this device.
    var userStories: [Story] = []

    init() {}

    /// Photos still used by a saved story. Any other photo file can be removed.
    var referencedPhotoIDs: Set<String> {
        Set(userStories.flatMap { $0.pages.compactMap(\.photoID) })
    }

    private enum CodingKeys: String, CodingKey {
        case version, roomItems, feelings, calmTools, dayPlan, settings, userStories
    }

    // Missing keys fall back to defaults, so a file written by an older version still loads.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        roomItems = try container.decodeIfPresent([RoomItem].self, forKey: .roomItems) ?? []
        feelings = try container.decodeIfPresent([FeelingEntry].self, forKey: .feelings) ?? []
        calmTools = try container.decodeIfPresent([CalmTool].self, forKey: .calmTools) ?? []
        dayPlan = try container.decodeIfPresent(DayPlan.self, forKey: .dayPlan)
        settings = try container.decodeIfPresent(AppSettings.self, forKey: .settings) ?? AppSettings()
        userStories = try container.decodeIfPresent([Story].self, forKey: .userStories) ?? []
    }
}

enum ProgressStoreError: Error, Equatable {
    /// The file was written by a newer version of the app; it is left untouched.
    case newerVersion(Int)
}

/// Where progress is kept. The app uses a JSON file; tests use memory.
@MainActor
protocol ProgressStoring {
    func load() throws -> ProgressState?
    func save(_ state: ProgressState) throws
    /// Moves unreadable data aside (never deletes it), so the app can start fresh.
    func setAsideUnreadable()
}

/// Progress as one small JSON file, written atomically so a crash mid-write can't leave half a file.
///
/// Chosen over SwiftData for now: the data is tiny, the format is readable, and the store is tested on every
/// platform (docs/ARCHITECTURE.md, decision D6).
struct JSONFileProgressStore: ProgressStoring {
    let fileURL: URL

    func load() throws -> ProgressState? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        let state = try Self.decoder.decode(ProgressState.self, from: data)
        guard state.version <= ProgressState.currentVersion else {
            throw ProgressStoreError.newerVersion(state.version)
        }
        return state
    }

    func save(_ state: ProgressState) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try Self.encoder.encode(state).write(to: fileURL, options: .atomic)
    }

    func setAsideUnreadable() {
        let stamp = Int(Date().timeIntervalSince1970)
        let aside = fileURL.deletingPathExtension().appendingPathExtension("unreadable-\(stamp).json")
        try? FileManager.default.moveItem(at: fileURL, to: aside)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

/// Progress kept in memory, for previews and tests.
@MainActor
final class InMemoryProgressStore: ProgressStoring {
    var stored: ProgressState?
    var failSaves = false
    private(set) var setAsideCount = 0

    init(_ stored: ProgressState? = nil) {
        self.stored = stored
    }

    func load() throws -> ProgressState? { stored }

    func save(_ state: ProgressState) throws {
        if failSaves { throw CocoaError(.fileWriteNoPermission) }
        stored = state
    }

    func setAsideUnreadable() {
        setAsideCount += 1
    }
}
