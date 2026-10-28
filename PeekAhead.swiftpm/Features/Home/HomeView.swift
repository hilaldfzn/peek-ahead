import SwiftUI

/// Child home: Pip says hello, today's plan if a grown-up made one, the stories, and Pip's room.
struct HomeView: View {
    let stories: [Story]
    let progress: ProgressModel
    let onOpen: (Story) -> Void
    let onOpenRoom: () -> Void
    let onOpenGrownUpMode: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpace.xl) {
                HStack {
                    Spacer()
                    GrownUpGateButton(action: onOpenGrownUpMode)
                }
                header
                if progress.state.dayPlan != nil || !progress.state.calmTools.isEmpty {
                    TodayStrip(
                        plan: progress.state.dayPlan,
                        calmTools: progress.state.calmTools,
                        onDidIt: { progress.advanceDayPlan() }
                    )
                }
                Text("My stories")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: AppSpace.lg)], spacing: AppSpace.lg) {
                    ForEach(stories) { story in
                        StoryCard(story: story) { onOpen(story) }
                    }
                }
                PipRoomCard(itemCount: progress.state.roomItems.count, action: onOpenRoom)
            }
            .padding(AppSpace.xl)
        }
        .background(AppColor.paper)
    }

    private var greeting: Text {
        if let name = progress.settings.childName, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return Text("Hi, \(name)!")
        }
        return Text("Hi!")
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
                greeting
                    .font(AppFont.display)
                    .foregroundStyle(AppColor.ink)
                Text("Pick a story to read with Pip.")
                    .font(AppFont.labelChild)
                    .foregroundStyle(AppColor.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            NeedCardButton()
        }
    }
}

private struct PipRoomCard: View {
    let itemCount: Int
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        Button(action: action) {
            HStack(spacing: AppSpace.lg) {
                BundleImage(name: "scene_pip_room")
                    .scaledToFit()
                    .frame(width: 160, height: 120)
                VStack(alignment: .leading, spacing: AppSpace.xs) {
                    Text("Pip's room")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.ink)
                    Text("\(itemCount) things so far")
                        .font(AppFont.labelChild)
                        .foregroundStyle(AppColor.inkMuted)
                }
                Spacer(minLength: 0)
            }
            .padding(AppSpace.md)
            .background(AppColor.surface, in: shape)
            .overlay(shape.strokeBorder(AppColor.line, lineWidth: AppSize.border))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Pip's room, \(itemCount) things so far"))
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
