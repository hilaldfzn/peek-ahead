import SwiftUI

/// Colour tokens for the Calm theme. Values come from `DESIGN.md`; change them there first.
enum AppColor {
    static var paper: Color { Color(hex: 0xFBF7F0) }
    static var surface: Color { Color(hex: 0xFFFFFF) }
    static var ink: Color { Color(hex: 0x1F2A33) }
    static var inkMuted: Color { Color(hex: 0x55616B) }
    /// Borders of buttons and cards (3.7:1 on white).
    static var line: Color { Color(hex: 0x8C8478) }
    /// Decorative dividers only, never a control's only boundary.
    static var hairline: Color { Color(hex: 0xE9E2D6) }

    static var primary: Color { Color(hex: 0x0E6B66) }
    static var onPrimary: Color { Color(hex: 0xFFFFFF) }
    static var pipTeal: Color { Color(hex: 0x2BB3A7) }
    static var primaryTint: Color { Color(hex: 0xDFF3F0) }

    static var sun: Color { Color(hex: 0xF2B441) }
    static var sunTint: Color { Color(hex: 0xFCEFD2) }
    static var sunInk: Color { Color(hex: 0x7A5410) }
    static var sky: Color { Color(hex: 0x2A609E) }
    static var skyTint: Color { Color(hex: 0xDCEBF8) }
    /// "Done" and "in place" checks; never the only signal (always with an icon or a word).
    static var leaf: Color { Color(hex: 0x2C6E47) }
    static var leafTint: Color { Color(hex: 0xE3F0E1) }
}

extension Color {
    /// A colour from a 24-bit sRGB hex value, for example `0x0E6B66`.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
