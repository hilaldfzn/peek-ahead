import Foundation

/// Errors an on-device drafter reports so the coordinator can explain the fallback.
enum DraftingError: Error, Equatable, Sendable {
    /// The model is not available on this device right now (unsupported device, Apple Intelligence off, still
    /// downloading).
    case modelUnavailable
}

/// The result of asking for a draft, with the reason a template was used instead of the model, if one was.
struct DraftOutcome: Sendable {
    enum FallbackReason: Hashable, Sendable {
        /// This build or device has no on-device model.
        case noModel
        /// The model exists but is not ready.
        case modelUnavailable
        /// The model returned an error, for example a guardrail refusal.
        case modelFailed
        /// The model answered, but the draft was not usable (too short, or failed the structural checks).
        case unusableDraft
    }

    let story: Story
    let fallbackReason: FallbackReason?
}

/// Tries the on-device model first and falls back to templates, so drafting always works offline.
///
/// Model output is treated as untrusted input: it is cleaned, checked by the same validator as every other story,
/// marked as a placeholder that the grown-up must review, and given the template's practice steps.
struct DraftingCoordinator: StoryDrafting {
    static let pageRange = 3...8

    let model: (any StoryDrafting)?
    let templates: TemplateDrafter

    init(model: (any StoryDrafting)?, templates: TemplateDrafter = TemplateDrafter()) {
        self.model = model
        self.templates = templates
    }

    func draft(_ request: DraftRequest) async throws -> Story {
        await outcome(for: request).story
    }

    func outcome(for request: DraftRequest) async -> DraftOutcome {
        let template = templates.makeStory(request)
        guard let model else {
            return DraftOutcome(story: template, fallbackReason: .noModel)
        }
        do {
            let draft = try await model.draft(request)
            guard let cleaned = Self.clean(draft, request: request, template: template) else {
                return DraftOutcome(story: template, fallbackReason: .unusableDraft)
            }
            return DraftOutcome(story: cleaned, fallbackReason: nil)
        } catch DraftingError.modelUnavailable {
            return DraftOutcome(story: template, fallbackReason: .modelUnavailable)
        } catch {
            return DraftOutcome(story: template, fallbackReason: .modelFailed)
        }
    }

    /// Makes a model draft safe to show in the editor, or returns `nil` if it is not usable.
    static func clean(_ draft: Story, request: DraftRequest, template: Story) -> Story? {
        let pages =
            draft.pages
            .map { page -> StoryPage in
                var page = page
                page.sentence = page.sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                page.sometimesNote = page.sometimesNote?.trimmingCharacters(in: .whitespacesAndNewlines)
                if page.sometimesNote?.isEmpty == true { page.sometimesNote = nil }
                page.photoID = nil
                return page
            }
            .filter { !$0.sentence.isEmpty }
            .prefix(pageRange.upperBound)
            .enumerated()
            .map { index, page -> StoryPage in
                var page = page
                page.id = "p\(index + 1)"
                return page
            }
        guard pages.count >= pageRange.lowerBound else { return nil }

        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let story = Story(
            id: template.id,
            title: title.isEmpty ? template.title : title,
            language: request.language.rawValue,
            review: .placeholder,
            pages: pages,
            practice: template.practice,
            draftSource: .onDeviceModel
        )
        do {
            try StoryValidator.validate(story)
        } catch {
            return nil
        }
        return story
    }
}
