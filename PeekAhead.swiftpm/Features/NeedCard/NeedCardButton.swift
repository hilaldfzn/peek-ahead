import SwiftUI

/// "I need…": on every child screen, one tap shows a big card the child can hold up to an adult.
struct NeedCardButton: View {
    @State private var isPresented = false

    var body: some View {
        CircleIconButton(title: "I need…", systemImage: "hand.raised.fill") {
            isPresented = true
        }
        .fullScreenCover(isPresented: $isPresented) {
            NeedCardSheet { isPresented = false }
        }
    }
}

private struct NeedCardSheet: View {
    let onClose: () -> Void
    @State private var shown: NeedCard?

    var body: some View {
        VStack(spacing: AppSpace.xl) {
            if let shown {
                VStack(spacing: AppSpace.lg) {
                    BundleImage(name: shown.imageName)
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                        .accessibilityHidden(true)
                    Text(shown.title)
                        .font(AppFont.display)
                        .foregroundStyle(AppColor.ink)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
                .accessibilityElement(children: .combine)
                Button("Choose another") { self.shown = nil }
                    .buttonStyle(.childSecondary)
            } else {
                Text("What do you need?")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: AppSpace.lg)], spacing: AppSpace.lg) {
                    ForEach(NeedCard.allCases) { card in
                        ChoiceCard(artwork: .bundle(card.imageName), title: Text(card.title)) { shown = card }
                    }
                }
                Spacer()
            }
            Button("Close", action: onClose)
                .buttonStyle(.childPrimary)
        }
        .padding(AppSpace.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.paper)
    }
}

extension NeedCard {
    var title: LocalizedStringKey {
        switch self {
        case .aBreak: "I need a break"
        case .help: "I need help"
        case .quiet: "I need quiet"
        }
    }
}
