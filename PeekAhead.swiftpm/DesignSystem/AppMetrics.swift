import CoreGraphics

/// Spacing scale from `DESIGN.md`.
enum AppSpace {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

/// Corner radii from `DESIGN.md`. `slab` frames every 3D scene.
enum AppRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 20
    static let lg: CGFloat = 28
    static let xl: CGFloat = 36
    static let slab: CGFloat = 44
}

/// Control sizes for child mode: big, predictable targets.
enum AppSize {
    static let childButtonHeight: CGFloat = 88
    static let iconButton: CGFloat = 72
    static let border: CGFloat = 3
}
