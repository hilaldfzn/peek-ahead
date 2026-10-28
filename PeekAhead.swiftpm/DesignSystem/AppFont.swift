import SwiftUI

/// Type tokens from `DESIGN.md`. Every style scales with Dynamic Type through `relativeTo:`.
///
/// Fredoka (rounded, for UI) and Andika (designed for early readers, for story text) are bundled under the
/// SIL Open Font License and registered at launch by `FontRegistrar`.
enum AppFont {
    static var display: Font { fredoka(44, .semibold, relativeTo: .largeTitle) }
    static var title: Font { fredoka(32, .semibold, relativeTo: .title) }
    static var buttonChild: Font { fredoka(26, .semibold, relativeTo: .title2) }
    static var labelChild: Font { fredoka(20, .medium, relativeTo: .headline) }
    static var iconLabel: Font { fredoka(16, .semibold, relativeTo: .caption) }

    static var storySentence: Font { .custom("Andika", size: 34, relativeTo: .title) }
    static var storySentenceCompact: Font { .custom("Andika", size: 26, relativeTo: .title2) }
    static var note: Font { .custom("Andika", size: 22, relativeTo: .body) }

    /// Extra space between story lines (line height 1.45 at 34 pt).
    static let storyLineSpacing: CGFloat = 15

    private static func fredoka(_ size: CGFloat, _ weight: Font.Weight, relativeTo style: Font.TextStyle) -> Font {
        Font.custom("Fredoka", size: size, relativeTo: style).weight(weight)
    }
}
