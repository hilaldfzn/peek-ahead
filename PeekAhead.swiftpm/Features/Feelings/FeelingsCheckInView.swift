import SwiftUI

/// "How do I feel?": five faces, each with its word. Every answer gets the same thanks; none is judged.
struct FeelingsCheckInView: View {
    let onAnswer: (Feeling) -> Void
    let onDone: () -> Void

    @State private var answer: Feeling?

    var body: some View {
        PracticeScaffold(title: "How do I feel?", instruction: Text("Pick a face. Every feeling is okay.")) {
            VStack(spacing: AppSpace.xl) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: AppSpace.md)], spacing: AppSpace.md) {
                    ForEach(Feeling.allCases) { feeling in
                        ChoiceCard(
                            artwork: .bundle(feeling.imageName), title: Text(feeling.title),
                            isSelected: answer == feeling
                        ) {
                            guard answer == nil else { return }
                            answer = feeling
                            onAnswer(feeling)
                        }
                    }
                }
                if answer != nil {
                    HStack(spacing: AppSpace.md) {
                        BundleImage(name: "pip_teal")
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .accessibilityHidden(true)
                        Text("Thank you for telling me. Every feeling is okay.")
                            .font(AppFont.labelChild)
                            .foregroundStyle(AppColor.ink)
                    }
                    .padding(AppSpace.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColor.primaryTint, in: RoundedRectangle(cornerRadius: AppRadius.lg))
                }
            }
        } buttons: {
            Button(answer == nil ? "Skip" : "Back to Home", action: onDone)
                .buttonStyle(.childPrimary)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension Feeling {
    var title: LocalizedStringKey {
        switch self {
        case .calm: "calm"
        case .okay: "okay"
        case .unsure: "unsure"
        case .upset: "upset"
        case .tooMuch: "too much"
        }
    }
}
