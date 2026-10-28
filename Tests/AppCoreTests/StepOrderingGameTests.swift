import Testing

@testable import AppCore

@Suite("Put the steps in order")
struct StepOrderingGameTests {
    private let steps = [
        PracticeStep(id: "car", label: "Go in the car", pictogram: .car),
        PracticeStep(id: "wait", label: "Wait in the waiting room", pictogram: .waiting),
        PracticeStep(id: "teeth", label: "The dentist counts my teeth", pictogram: .dentist),
        PracticeStep(id: "home", label: "Go home", pictogram: .home),
    ]

    @Test(arguments: 0..<50)
    func neverStartsSolved(seed: Int) {
        let game = StepOrderingGame(steps: steps, seed: UInt64(seed))
        #expect(!game.isSolved)
        #expect(Set(game.cards.map(\.id)) == Set(steps.map(\.id)))
    }

    @Test func sameSeedGivesTheSameOrder() {
        let a = StepOrderingGame(steps: steps, seed: 7)
        let b = StepOrderingGame(steps: steps, seed: 7)
        #expect(a.cards == b.cards)
    }

    @Test func twoStepsStartSwapped() {
        let game = StepOrderingGame(steps: Array(steps.prefix(2)), seed: 1)
        #expect(game.cards.map(\.id) == ["wait", "car"])
    }

    @Test func tappingTwoCardsSwapsThem() {
        var game = StepOrderingGame(steps: steps, seed: 3)
        let before = game.cards
        #expect(game.tap(0) == .selected(0))
        #expect(game.selectedIndex == 0)
        #expect(game.tap(2) == .swapped(0, 2))
        #expect(game.selectedIndex == nil)
        #expect(game.cards[0] == before[2])
        #expect(game.cards[2] == before[0])
    }

    @Test func tappingTheSameCardAgainDeselectsIt() {
        var game = StepOrderingGame(steps: steps, seed: 3)
        game.tap(1)
        #expect(game.tap(1) == .deselected)
        #expect(game.selectedIndex == nil)
    }

    @Test func helpMovesOneCardIntoPlaceUntilSolved() {
        var game = StepOrderingGame(steps: steps, seed: 11)
        var helps = 0
        while !game.isSolved, helps < steps.count {
            let misplaced = game.firstMisplacedIndex
            #expect(game.helpOneStep() != nil)
            if let misplaced { #expect(game.isInPlace(misplaced)) }
            helps += 1
        }
        #expect(game.isSolved)
        #expect(game.helpOneStep() == nil)
    }

    @Test func aSolvedGameIgnoresTaps() {
        var game = StepOrderingGame(steps: steps, seed: 5)
        while game.helpOneStep() != nil {}
        #expect(game.tap(0) == .ignored)
    }

    @Test func outOfRangeTapsAreIgnored() {
        var game = StepOrderingGame(steps: steps, seed: 5)
        #expect(game.tap(99) == .ignored)
    }
}
