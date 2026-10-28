import Foundation

/// Furniture for Pip's room (KayKit CC0 renders, `Resources/Images/item_*.png`).
enum RoomItem: String, Codable, Sendable, CaseIterable, Identifiable {
    case lamp
    case rug
    case cactus
    case armchair
    case books
    case frame
    case shelf
    case bed

    var id: String { rawValue }
    var imageName: String { "item_\(rawValue)" }
}

/// Which rewards to offer. Nothing is random and nothing can be lost (DESIGN.md): the child is always offered
/// the next items they don't have yet, in a fixed order, and chooses one.
enum RewardCatalog {
    /// The order items are offered in.
    static let order: [RoomItem] = [.lamp, .rug, .cactus, .armchair, .books, .frame, .shelf, .bed]

    static func offer(owned: [RoomItem], count: Int = 3) -> [RoomItem] {
        let ownedSet = Set(owned)
        return Array(order.filter { !ownedSet.contains($0) }.prefix(max(count, 0)))
    }
}

/// The five-step feelings scale. Every answer is accepted; none is right or wrong.
enum Feeling: String, Codable, Sendable, CaseIterable, Identifiable {
    case calm
    case okay
    case unsure
    case upset
    case tooMuch = "too_much"

    var id: String { rawValue }

    var imageName: String {
        switch self {
        case .calm: "feel_1_calm"
        case .okay: "feel_2_okay"
        case .unsure: "feel_3_unsure"
        case .upset: "feel_4_upset"
        case .tooMuch: "feel_5_too_much"
        }
    }
}

/// One feelings check-in, kept on this device only, for the grown-up's notes.
struct FeelingEntry: Codable, Equatable, Sendable {
    let storyID: String
    let storyTitle: String
    let feeling: Feeling
    let date: Date
}

/// Cards a child can hold up to an adult, available on every child screen.
enum NeedCard: String, Sendable, CaseIterable, Identifiable {
    case aBreak = "break"
    case help
    case quiet

    var id: String { rawValue }

    var imageName: String {
        switch self {
        case .aBreak: CalmTool.breakCard.imageName
        case .help: CalmTool.askForHelp.imageName
        case .quiet: CalmTool.quietCorner.imageName
        }
    }
}
