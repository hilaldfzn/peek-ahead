import SwiftUI

/// The page's scene as a pre-rendered picture on the rounded slab.
///
/// The 3D diorama replaces this once the RealityKit spike (`PipStageView`) is proven on device; until then the
/// story never waits on 3D loading.
struct SceneBackdrop: View {
    let scene: StoryScene

    var body: some View {
        BundleImage(name: scene.imageName)
            .scaledToFit()
            .padding(AppSpace.md)
            .frame(maxWidth: .infinity)
            .background(AppColor.primaryTint)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.slab, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(scene.accessibilityDescription))
            .accessibilityAddTraits(.isImage)
    }
}

extension StoryScene {
    var accessibilityDescription: LocalizedStringKey {
        switch self {
        case .waitingRoom: "A quiet waiting room with chairs, a lamp and Pip"
        case .bigChair: "A big chair that leans back, with Pip beside it"
        case .familyVisit: "A family room with a table, a couch and Pip"
        case .pipRoom: "Pip's room with a bed, a lamp and toys"
        case .streetTrip: "A street with a taxi, a building and Pip"
        }
    }
}
