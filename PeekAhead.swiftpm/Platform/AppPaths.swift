import Foundation

/// Where the app keeps its files. Everything lives in the app's own container; nothing leaves the device.
enum AppPaths {
    static var progressFile: URL {
        appSupport.appendingPathComponent("progress.json")
    }

    static var appSupport: URL {
        let base =
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("PeekAhead", isDirectory: true)
    }
}
