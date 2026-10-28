import Foundation

/// "Put the steps in order": the child taps two cards to swap them. Drag is never required.
///
/// There is no wrong answer and no score. Cards already in their place show a check, and "Help me" moves one card
/// into place for the child (errorless learning), so the game always ends in success.
struct StepOrderingGame: Equatable, Sendable {
    enum TapResult: Equatable, Sendable {
        case selected(Int)
        case deselected
        case swapped(Int, Int)
        case ignored
    }

    private(set) var cards: [PracticeStep]
    private(set) var selectedIndex: Int?
    private let solution: [String]

    /// Shuffles `steps` reproducibly from `seed`. The starting order is never already solved (for 2+ steps).
    init(steps: [PracticeStep], seed: UInt64) {
        solution = steps.map(\.id)
        var generator = SplitMix64(seed: seed)
        var shuffled = steps.shuffled(using: &generator)
        if shuffled.count > 1, shuffled.map(\.id) == solution {
            shuffled.append(shuffled.removeFirst())
        }
        cards = shuffled
    }

    var isSolved: Bool { cards.map(\.id) == solution }

    func isInPlace(_ index: Int) -> Bool {
        cards.indices.contains(index) && cards[index].id == solution[index]
    }

    /// The first position holding the wrong card, or `nil` when solved.
    var firstMisplacedIndex: Int? {
        cards.indices.first { !isInPlace($0) }
    }

    @discardableResult
    mutating func tap(_ index: Int) -> TapResult {
        guard cards.indices.contains(index), !isSolved else { return .ignored }
        guard let selected = selectedIndex else {
            selectedIndex = index
            return .selected(index)
        }
        selectedIndex = nil
        if selected == index { return .deselected }
        cards.swapAt(selected, index)
        return .swapped(selected, index)
    }

    /// Moves the right card into the first wrong position. Returns the two positions that swapped.
    @discardableResult
    mutating func helpOneStep() -> (Int, Int)? {
        guard let target = firstMisplacedIndex,
            let source = cards.firstIndex(where: { $0.id == solution[target] })
        else { return nil }
        selectedIndex = nil
        cards.swapAt(target, source)
        return (target, source)
    }
}

/// A small, fast, seedable generator, so a shuffle can be repeated in tests and previews.
struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
