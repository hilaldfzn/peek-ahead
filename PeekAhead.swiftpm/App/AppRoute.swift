import Foundation

/// Screens pushed on the child's navigation stack. Home is the root.
enum AppRoute: Hashable {
    case story(Story)
    case practice(Story)
}
