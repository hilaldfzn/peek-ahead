import Foundation

/// Builds the drafting coordinator: the on-device model where this SDK and device have it, templates always.
enum Drafters {
    static func make() -> DraftingCoordinator {
        DraftingCoordinator(model: onDeviceModel())
    }

    private static func onDeviceModel() -> (any StoryDrafting)? {
        #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                // Availability is checked again at draft time; the model may still be downloading.
                return FoundationModelsDrafter()
            }
        #endif
        return nil
    }
}
