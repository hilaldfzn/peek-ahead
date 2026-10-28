// swift-tools-version: 6.0

// Development package, not part of the submission.
//
// It compiles the App Playground's platform-independent code (`PeekAhead.swiftpm/Core`) as a library, so the
// logic can be unit-tested with `swift test` on macOS or Linux and in CI. The app itself lives in
// `PeekAhead.swiftpm` and compiles the same files into its own module.

import PackageDescription

let package = Package(
    name: "PeekAheadDev",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    targets: [
        .target(
            name: "AppCore",
            path: "PeekAhead.swiftpm/Core"
        ),
        .testTarget(
            name: "AppCoreTests",
            dependencies: ["AppCore"],
            path: "Tests/AppCoreTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
