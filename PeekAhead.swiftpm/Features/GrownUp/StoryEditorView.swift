import SwiftUI

/// The grown-up story editor: every page with its sentence, kind, scene and optional "Sometimes…" note, and the
/// rule chips under each sentence. Changes are kept only when the grown-up taps Save.
struct StoryEditorView: View {
    let dependencies: AppDependencies
    let bundled: [Story]
    /// Set when this is a copy of a built-in story, which is saved as the grown-up's own.
    let isCopy: Bool
    /// Set when the story is new (a draft or a copy) and has not been saved yet.
    let isUnsaved: Bool

    @State private var editor: StoryEditorModel
    @State private var saveError: StoryContentError?
    @State private var isPreviewing = false
    @State private var pdfURL: URL?
    @State private var confirmingDelete = false
    @Environment(\.dismiss) private var dismiss

    init(story: Story, dependencies: AppDependencies, bundled: [Story], isCopy: Bool, isUnsaved: Bool) {
        _editor = State(initialValue: StoryEditorModel(story: story))
        self.dependencies = dependencies
        self.bundled = bundled
        self.isCopy = isCopy
        self.isUnsaved = isUnsaved
    }

    private var progress: ProgressModel { dependencies.progress }

    var body: some View {
        List {
            Section {
                TextField("Title", text: Binding(get: { editor.story.title }, set: { editor.setTitle($0) }))
                    .font(.title3.weight(.semibold))
                if let source = editor.story.draftSource {
                    DraftBadge(source: source)
                }
                if isCopy {
                    Text("A copy of a built-in story. When you save, it becomes your own story.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ForEach(editor.storyFindings, id: \.self) { finding in
                    RuleChip(finding: finding)
                }
            }

            Section {
                ForEach(editor.story.pages) { page in
                    PageEditorRow(page: page, findings: editor.findings(forPage: page.id), editor: editor)
                }
                .onDelete { editor.deletePages(at: $0) }
                .onMove { editor.movePages(from: $0, to: $1) }
                Button {
                    editor.addPage()
                } label: {
                    Label("Add a page", systemImage: "plus")
                }
            } header: {
                Text("Pages")
            } footer: {
                Text("The checks advise; you decide. A child sees this story only after you save it.")
            }

            Section("Print") {
                if let pdfURL {
                    ShareLink("Share or print the PDF", item: pdfURL)
                } else {
                    Button("Make a printable PDF") { makePDF() }
                }
            }

            if !isCopy, !isUnsaved, !bundled.contains(where: { $0.id == editor.story.id }) {
                Section {
                    Button("Delete this story", role: .destructive) { confirmingDelete = true }
                }
            }
        }
        .navigationTitle(editor.story.title.isEmpty ? Text("Story") : Text(verbatim: editor.story.title))
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                EditButton()
                Button("Preview") { isPreviewing = true }
                    .disabled(editor.storyForSaving().pages.isEmpty)
                Button("Save", action: save)
                    .disabled(!editor.hasChanges && !isUnsaved)
            }
        }
        .onChange(of: editor.story) { pdfURL = nil }
        .fullScreenCover(isPresented: $isPreviewing) {
            StoryPlayerScreen(
                story: editor.storyForSaving(),
                narrator: dependencies.narrator,
                onHome: { isPreviewing = false },
                onFinish: { isPreviewing = false }
            )
        }
        .alert(
            "This story could not be saved",
            isPresented: Binding(get: { saveError != nil }, set: { _ in saveError = nil })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage)
        }
        .confirmationDialog("Delete this story?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                progress.deleteUserStory(id: editor.story.id)
                dismiss()
            }
        }
    }

    private func save() {
        do {
            try progress.saveUserStory(editor.storyForSaving(), bundled: bundled)
            editor.markSaved()
            dismiss()
        } catch {
            saveError = error
        }
    }

    private func makePDF() {
        do {
            pdfURL = try StoryPDFExporter.export(editor.storyForSaving())
        } catch {
            Log.app.error("PDF export failed: \(String(describing: error), privacy: .public)")
        }
    }

    private var saveErrorMessage: String {
        switch saveError {
        case .noPages: String(localized: "Add at least one page with a sentence.")
        case .duplicateStoryID: String(localized: "A built-in story already uses this name inside the app.")
        default: String(localized: "Check that every page has a sentence, then try again.")
        }
    }
}

private struct PageEditorRow: View {
    let page: StoryPage
    let findings: [RuleFinding]
    let editor: StoryEditorModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField(
                "Sentence",
                text: Binding(get: { page.sentence }, set: { editor.setSentence($0, page: page.id) }),
                axis: .vertical
            )
            .font(.custom("Andika", size: 20, relativeTo: .body))

            HStack(spacing: 12) {
                Picker("Kind", selection: Binding(get: { page.kind }, set: { editor.setKind($0, page: page.id) })) {
                    ForEach(PageKind.allCases, id: \.self) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                Picker("Scene", selection: Binding(get: { page.scene }, set: { editor.setScene($0, page: page.id) })) {
                    ForEach(StoryScene.allCases, id: \.self) { scene in
                        Text(scene.title).tag(scene)
                    }
                }
            }
            .pickerStyle(.menu)

            TextField(
                "\u{201C}Sometimes\u{2026}\u{201D} note (optional)",
                text: Binding(get: { page.sometimesNote ?? "" }, set: { editor.setNote($0, page: page.id) }),
                axis: .vertical
            )
            .font(.subheadline)

            FlowChips(findings: findings)
        }
        .padding(.vertical, 6)
    }
}

/// Chips for one page: "Short and clear" when nothing was found.
private struct FlowChips: View {
    let findings: [RuleFinding]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { chips }
            VStack(alignment: .leading, spacing: 6) { chips }
        }
    }

    @ViewBuilder
    private var chips: some View {
        if findings.isEmpty {
            RuleChip(finding: nil)
        } else {
            ForEach(findings, id: \.self) { RuleChip(finding: $0) }
        }
    }
}

extension PageKind {
    var title: LocalizedStringKey {
        switch self {
        case .describes: "Describes"
        case .feelings: "Feelings"
        case .iCan: "I can\u{2026}"
        case .endsWell: "Ends well"
        }
    }
}

extension StoryScene {
    var title: LocalizedStringKey {
        switch self {
        case .waitingRoom: "Waiting room"
        case .bigChair: "Big chair"
        case .familyVisit: "Family room"
        case .pipRoom: "Pip's room"
        case .streetTrip: "Street"
        }
    }
}
