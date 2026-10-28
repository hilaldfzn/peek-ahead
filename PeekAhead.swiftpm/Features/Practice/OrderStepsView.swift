import SwiftUI

/// "Put the steps in order": tap two cards to swap them. Cards in the right place get a check, and
/// "Help me" places one card for the child, so the game always ends well.
struct OrderStepsView: View {
    @State private var game: StepOrderingGame
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(steps: [PracticeStep], seed: UInt64 = .random(in: 0...UInt64.max), onDone: @escaping () -> Void) {
        _game = State(initialValue: StepOrderingGame(steps: steps, seed: seed))
        self.onDone = onDone
    }

    var body: some View {
        PracticeScaffold(title: "Put the steps in order", instruction: instruction) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: AppSpace.lg)], spacing: AppSpace.lg) {
                ForEach(Array(game.cards.enumerated()), id: \.element.id) { index, step in
                    VStack(spacing: AppSpace.xs) {
                        Text(verbatim: "\(index + 1)")
                            .font(AppFont.title)
                            .foregroundStyle(AppColor.inkMuted)
                            .accessibilityHidden(true)
                        ChoiceCard(
                            artwork: .bundle(step.pictogram.imageName),
                            title: Text(verbatim: step.label),
                            isSelected: game.selectedIndex == index,
                            showsCheck: game.isInPlace(index)
                        ) {
                            change { game.tap(index) }
                        }
                        .accessibilityLabel(Text("Place \(index + 1): \(step.label)"))
                        .accessibilityHint(Text("Tap two cards to swap them"))
                    }
                }
            }
        } buttons: {
            if !game.isSolved {
                Button("Help me") { change { game.helpOneStep() } }
                    .buttonStyle(.childSecondary)
            }
            Button("Done", action: onDone)
                .buttonStyle(.childPrimary)
        }
    }

    private var instruction: Text {
        game.isSolved ? Text("Yes! That is the order.") : Text("Tap two cards to swap them.")
    }

    private func change(_ update: () -> Void) {
        if reduceMotion {
            update()
        } else {
            withAnimation(.easeInOut(duration: 0.25), update)
        }
    }
}
