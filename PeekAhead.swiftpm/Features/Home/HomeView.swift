import SwiftUI

/// Child home: Pip says hello, and the stories are one tap away.
struct HomeView: View {
    let stories: [Story]
    let onOpen: (Story) -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpace.xl) {
                header
                Text("My stories")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: AppSpace.lg)], spacing: AppSpace.lg) {
                    ForEach(stories) { story in
                        StoryCard(story: story) { onOpen(story) }
                    }
                }
            }
            .padding(AppSpace.xl)
        }
        .background(AppColor.paper)
    }

    /// Side by side on iPad; stacked on iPhone and at accessibility text sizes. `AnyLayout` keeps Pip's
    /// identity when the layout changes, so the 3D model is not loaded twice.
    private var header: some View {
        let isWide = sizeClass == .regular && !typeSize.isAccessibilitySize
        let layout =
            isWide
            ? AnyLayout(HStackLayout(alignment: .center, spacing: AppSpace.xl))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: AppSpace.lg))
        return layout {
            PipStageView()
                .frame(maxWidth: isWide ? 320 : CGFloat.infinity)
                .frame(height: 260)
            VStack(alignment: .leading, spacing: AppSpace.xs) {
                Text("Hi!")
                    .font(AppFont.display)
                    .foregroundStyle(AppColor.ink)
                Text("Pick a story to read with Pip.")
                    .font(AppFont.labelChild)
                    .foregroundStyle(AppColor.inkMuted)
            }
        }
    }
}

private struct StoryCard: View {
    let story: Story
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpace.sm) {
                BundleImage(name: (story.pages.first?.scene ?? .pipRoom).imageName)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .background(AppColor.primaryTint, in: RoundedRectangle(cornerRadius: AppRadius.md))
                Text(story.title)
                    .font(AppFont.labelChild)
                    .foregroundStyle(AppColor.ink)
                    .multilineTextAlignment(.leading)
                HStack(spacing: AppSpace.xs) {
                    Text(languageName)
                    if story.review == .placeholder {
                        // A reminder for development: this wording has not been reviewed by an expert yet.
                        Text("Draft").padding(.horizontal, AppSpace.xs).background(AppColor.sunTint, in: Capsule())
                    }
                }
                .font(AppFont.iconLabel)
                .foregroundStyle(AppColor.inkMuted)
            }
            .padding(AppSpace.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surface, in: shape)
            .overlay(shape.strokeBorder(AppColor.line, lineWidth: AppSize.border))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(story.title), \(languageName)"))
        .accessibilityHint(Text("Opens the story"))
    }

    private var languageName: String {
        Locale.current.localizedString(forIdentifier: story.language) ?? story.language
    }
}
