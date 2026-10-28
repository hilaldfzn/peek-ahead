import SwiftUI

/// Choose one of three things for Pip's room. The choice is the child's; nothing is random and nothing is lost.
struct RewardChoiceView: View {
    let offer: [RoomItem]
    let onPlace: (RoomItem) -> Void
    let onContinue: () -> Void

    @State private var placed: RoomItem?

    var body: some View {
        PracticeScaffold(title: "Choose one thing for Pip's room", instruction: instruction) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: AppSpace.lg)], spacing: AppSpace.lg) {
                ForEach(offer) { item in
                    ChoiceCard(artwork: .bundle(item.imageName), title: Text(item.title), isSelected: placed == item) {
                        guard placed == nil else { return }
                        placed = item
                        onPlace(item)
                    }
                }
            }
        } buttons: {
            Button(placed == nil ? "Skip" : "Next", action: onContinue)
                .buttonStyle(.childPrimary)
        }
        .toolbar(.hidden, for: .navigationBar)
        // A light tap when the reward is placed (DESIGN.md); iOS turns it off with the system haptics setting.
        .sensoryFeedback(.impact(weight: .light), trigger: placed)
    }

    private var instruction: Text {
        placed == nil
            ? Text("You can look at it in Pip's room later.")
            : Text("It is in Pip's room now. Nothing disappears.")
    }
}

extension RoomItem {
    var title: LocalizedStringKey {
        switch self {
        case .lamp: "Lamp"
        case .rug: "Rug"
        case .cactus: "Cactus"
        case .armchair: "Armchair"
        case .books: "Books"
        case .frame: "Picture frame"
        case .shelf: "Shelf"
        case .bed: "Bed"
        }
    }
}
