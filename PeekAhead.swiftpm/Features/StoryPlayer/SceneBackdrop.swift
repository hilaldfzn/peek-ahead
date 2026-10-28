import SwiftUI

/// The page's scene as a pre-rendered picture on the rounded slab, or the grown-up's photo of the real place.
///
/// The 3D diorama replaces the pictures once the RealityKit spike (`PipStageView`) is proven on device; until then
/// the story never waits on 3D loading.
struct SceneBackdrop: View {
    let scene: StoryScene
    var photoID: String?

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(AppColor.primaryTint)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.slab, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(photo == nil ? Text(scene.accessibilityDescription) : Text("A photo of the real place"))
            .accessibilityAddTraits(.isImage)
    }

    private var photo: UIImage? {
        photoID.flatMap(PhotoStore.image(for:))
    }

    @ViewBuilder
    private var content: some View {
        if let photo {
            Image(uiImage: photo)
                .resizable()
                .scaledToFit()
        } else {
            BundleImage(name: scene.imageName)
                .scaledToFit()
                .padding(AppSpace.md)
        }
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
