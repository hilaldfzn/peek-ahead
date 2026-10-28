import SwiftUI

/// A large tappable card with a picture and a word (DESIGN.md, "Choice card"): at least 160 pt, a 5 pt primary
/// border and a checkmark when selected, and an optional leaf check for "done" or "in the right place".
struct ChoiceCard: View {
    enum Artwork {
        /// A PNG in the app bundle, such as a pictogram or a reward render.
        case bundle(String)
        /// An SF Symbol, for UI choices that have no pictogram.
        case symbol(String)
    }

    let artwork: Artwork
    let title: Text
    var isSelected = false
    var showsCheck = false
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        Button(action: action) {
            VStack(spacing: AppSpace.sm) {
                artworkView
                    .frame(width: 96, height: 96)
                title
                    .font(AppFont.labelChild)
                    .foregroundStyle(AppColor.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppSpace.md)
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(isSelected ? AppColor.primaryTint : AppColor.surface, in: shape)
            .overlay(
                shape.strokeBorder(
                    isSelected ? AppColor.primary : AppColor.line,
                    lineWidth: isSelected ? 5 : AppSize.border
                )
            )
            .overlay(alignment: .topTrailing) { mark }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var artworkView: some View {
        switch artwork {
        case .bundle(let name):
            BundleImage(name: name).scaledToFit()
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(AppColor.primary)
        }
    }

    @ViewBuilder
    private var mark: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(AppColor.primary)
                .padding(AppSpace.sm)
                .accessibilityHidden(true)
        } else if showsCheck {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 30))
                .foregroundStyle(AppColor.leaf)
                .padding(AppSpace.sm)
                .accessibilityHidden(true)
        }
    }
}
