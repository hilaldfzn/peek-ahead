// swift-tools-version: 6.0

// App Playground manifest (the project you submit).
//
// Xcode and Swift Playgrounds may rewrite this file when you change app settings in their UI (icon, accent
// colour, orientations). Keep hand edits small and re-check them after changing settings there.

import AppleProductTypes
import PackageDescription

let package = Package(
    name: "Peek Ahead",
    platforms: [
        .iOS("18.0")
    ],
    products: [
        .iOSApplication(
            name: "Peek Ahead",
            targets: ["AppModule"],
            bundleIdentifier: "io.github.hilaldfzn.peekahead",
            teamIdentifier: "",
            displayVersion: "0.1",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .leaf),
            accentColor: .presetColor(.teal),
            supportedDeviceFamilies: [
                .pad,
                .phone,
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad])),
            ],
            appCategory: .education
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            resources: [
                .process("Resources")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
