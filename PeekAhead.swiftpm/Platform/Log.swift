import os

/// Unified logging categories. Logs stay on the device; the app sends nothing anywhere.
enum Log {
    private static let subsystem = "io.github.hilaldfzn.peekahead"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let content = Logger(subsystem: subsystem, category: "content")
    static let narration = Logger(subsystem: subsystem, category: "narration")
    static let stage = Logger(subsystem: subsystem, category: "stage")
}
