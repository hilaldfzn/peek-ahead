import CoreText
import Foundation

/// Registers the bundled fonts for this process, so `Font.custom("Fredoka", …)` and `Font.custom("Andika", …)`
/// resolve. App Playgrounds have no Info.plist entry for fonts, so this runs once at launch.
enum FontRegistrar {
    static let fontFiles = ["Fredoka-Variable", "Andika-Regular", "Andika-Bold"]

    static func registerBundledFonts() {
        for name in fontFiles {
            guard let url = AppResources.url(forResource: name, withExtension: "ttf") else {
                Log.app.error("Font file missing: \(name, privacy: .public)")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                let reason = error.map { String(describing: $0.takeRetainedValue()) } ?? "unknown"
                Log.app.error("Could not register \(name, privacy: .public): \(reason, privacy: .public)")
            }
        }
    }
}
