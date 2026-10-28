import Foundation

/// The day's Now / Next strip: a few steps in order, planned by a grown-up.
struct DayPlan: Codable, Equatable, Sendable {
    enum StepState: Equatable, Sendable {
        case done
        case now
        case next
    }

    var title: String
    var steps: [PracticeStep]
    /// Index of the current step. Equal to `steps.count` when every step is done.
    private(set) var currentIndex: Int

    init(title: String, steps: [PracticeStep], currentIndex: Int = 0) {
        self.title = title
        self.steps = steps
        self.currentIndex = min(max(currentIndex, 0), steps.count)
    }

    /// A plan made from a story's practice steps, or `nil` if the story has none.
    init?(story: Story) {
        guard let steps = story.practice?.steps, !steps.isEmpty else { return nil }
        self.init(title: story.title, steps: steps)
    }

    var now: PracticeStep? { steps.indices.contains(currentIndex) ? steps[currentIndex] : nil }
    var next: PracticeStep? { steps.indices.contains(currentIndex + 1) ? steps[currentIndex + 1] : nil }
    var isFinished: Bool { currentIndex >= steps.count }

    func state(of index: Int) -> StepState {
        if index < currentIndex { return .done }
        return index == currentIndex ? .now : .next
    }

    mutating func advance() {
        currentIndex = min(currentIndex + 1, steps.count)
    }

    mutating func goBack() {
        currentIndex = max(currentIndex - 1, 0)
    }
}
