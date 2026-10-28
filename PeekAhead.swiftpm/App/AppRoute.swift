import Foundation

/// Screens shown on the child's navigation stack. Home is the root.
enum AppRoute: Hashable {
    case story(Story)
    case practice(Story)
    case reward(Story)
    case feelings(Story)
    case pipRoom
}
