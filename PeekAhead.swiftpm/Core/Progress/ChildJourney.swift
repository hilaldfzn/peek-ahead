import Foundation

/// The order of the child's screens after Home: story → practice → reward → feelings → Home.
/// Each step is skipped when it has nothing to offer.
enum ChildJourney {
    enum Step: Equatable, Sendable {
        case story
        case practice
        case reward
        case feelings
        case home
    }

    static func step(after step: Step, story: Story, rewardsLeft: Bool) -> Step {
        switch step {
        case .story:
            if story.practice?.activities.isEmpty == false { return .practice }
            return rewardsLeft ? .reward : .feelings
        case .practice:
            return rewardsLeft ? .reward : .feelings
        case .reward:
            return .feelings
        case .feelings, .home:
            return .home
        }
    }
}
