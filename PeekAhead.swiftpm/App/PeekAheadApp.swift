import SwiftUI

@main
struct PeekAheadApp: App {
    private let dependencies: AppDependencies

    init() {
        FontRegistrar.registerBundledFonts()
        dependencies = .live()
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
