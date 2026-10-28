import SwiftUI

/// One story, page by page: the scene, the sentence read aloud on request, and Back / Next.
struct StoryPlayerScreen: View {
    @State private var model: StoryPlayerModel
    let onHome: () -> Void
    let onFinish: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize

    init(story: Story, narrator: any Narrating, onHome: @escaping () -> Void, onFinish: @escaping () -> Void) {
        _model = State(initialValue: StoryPlayerModel(story: story, narrator: narrator))
        self.onHome = onHome
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                pageLayout {
                    SceneBackdrop(scene: model.page.scene)
                    textPanel
                }
                .padding(.horizontal, AppSpace.xl)
                .padding(.bottom, AppSpace.xl)
            }
        }
        .background(AppColor.paper)
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { model.stopReading() }
    }

    /// Scene beside the text on iPad; scene above the text on iPhone and at accessibility text sizes.
    private var pageLayout: AnyLayout {
        if sizeClass == .regular && !typeSize.isAccessibilitySize {
            AnyLayout(HStackLayout(alignment: .top, spacing: AppSpace.xl))
        } else {
            AnyLayout(VStackLayout(spacing: AppSpace.lg))
        }
    }

    private var topBar: some View {
        HStack(spacing: AppSpace.md) {
            CircleIconButton(title: "Home", systemImage: "house.fill") {
                model.stopReading()
                onHome()
            }
            Text(model.story.title)
                .font(AppFont.labelChild)
                .foregroundStyle(AppColor.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            if model.isNarrating {
                CircleIconButton(title: "Stop", systemImage: "stop.fill") { model.stopReading() }
            } else {
                CircleIconButton(title: "Read", systemImage: "speaker.wave.2.fill") { model.readAloud() }
            }
        }
        .padding(.horizontal, AppSpace.xl)
        .padding(.vertical, AppSpace.md)
    }

    private var textPanel: some View {
        VStack(alignment: .leading, spacing: AppSpace.lg) {
            VStack(alignment: .leading, spacing: AppSpace.lg) {
                HighlightedSentence(
                    sentence: model.page.sentence,
                    words: model.words,
                    highlightedIndex: model.highlightedWordIndex
                )
                ProgressDots(current: model.pageIndex, total: model.pageCount)
            }
            .padding(AppSpace.xl)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

            if let note = model.page.sometimesNote {
                SometimesNote(text: note)
            }

            navigationButtons
        }
        .frame(maxWidth: .infinity)
    }

    private var navigationButtons: some View {
        HStack(spacing: AppSpace.md) {
            // Child mode never shows disabled controls (DESIGN.md). On the first page Back is hidden but keeps its
            // space, so Next stays in the same place on every page.
            Button("Back") { model.goToPreviousPage() }
                .buttonStyle(.childSecondary)
                .opacity(model.canGoBack ? 1 : 0)
                .allowsHitTesting(model.canGoBack)
                .accessibilityHidden(!model.canGoBack)
            if model.isLastPage {
                Button("Finish") {
                    model.stopReading()
                    onFinish()
                }
                .buttonStyle(.childPrimary)
            } else {
                Button("Next") { model.goToNextPage() }
                    .buttonStyle(.childPrimary)
            }
        }
    }
}

private struct SometimesNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppFont.note)
            .foregroundStyle(AppColor.sky)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpace.md)
            .background(AppColor.skyTint, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }
}
